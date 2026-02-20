use starknet::ContractAddress;
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};
use core::ecdsa;

/// Message that gets hashed and signed off-chain.
/// This is what the signature cryptographically authorizes.
///
/// IMPORTANT:
/// - It binds execution to specific inputs (a, b)
/// - It binds to a specific nonce (anti-replay)
/// - It binds to a specific chain
/// - It binds to a specific contract address
#[derive(Hash, Drop, Copy, Serde)]
struct SignedMessage {
    a: felt252,
    b: felt252,
    nonce: felt252,
    chain_id: felt252,
    contract_address: ContractAddress,
}

/// Public interface exposed by the contract
#[starknet::interface]
pub trait ISecure<TContractState> {

    /// Executes addition only if:
    /// - Nonce is correct
    /// - Chain ID matches execution context
    /// - Signature is valid
    fn secure_add(
        ref self: TContractState,
        a: felt252,
        b: felt252,
        nonce: felt252,
        chain_id: felt252,
        sig_r: felt252,
        sig_s: felt252
    );

    /// Returns cumulative total
    fn get_total(self: @TContractState) -> felt252;

    /// Returns stored nonce for a user
    fn get_nonce(self: @TContractState, user: ContractAddress) -> felt252;
}

#[starknet::contract]
pub mod SecureContract {

    use super::{SignedMessage, ISecure};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::get_tx_info;  
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use core::ecdsa;
    use starknet::storage::{
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
        Map
    };

    /// Persistent contract storage
    #[storage]
    struct Storage {

        /// Public key authorized to sign messages
        authorized_pubkey: felt252,

        /// Accumulates results of secure_add calls
        total: felt252,

        /// Per-user nonce to prevent replay attacks
        nonces: Map<ContractAddress, felt252>,
    }

    /// Constructor sets authorized signer
    #[constructor]
    fn constructor(ref self: ContractState, pub_key: felt252) {
        self.authorized_pubkey.write(pub_key);
    }

    #[abi(embed_v0)]
    impl SecureImpl of super::ISecure<ContractState> {

        fn secure_add(
            ref self: ContractState,
            a: felt252,
            b: felt252,
            nonce: felt252,
            chain_id: felt252,
            sig_r: felt252,
            sig_s: felt252
        ) {

            let caller = get_caller_address();

            // -----------------------------
            // 1️ NONCE VALIDATION
            // -----------------------------
            // Prevents same signature from being reused.
            // Ensures each signature is tied to one unique state.
            let expected_nonce = self.nonces.read(caller);
            assert(nonce == expected_nonce, 'Invalid nonce');

            // -----------------------------
            // 2️ CHAIN ID VALIDATION
            // -----------------------------
            // Prevents cross-chain replay.
            // Ensures signature was meant for this chain.
            let tx_info = get_tx_info().unbox();
            let current_chain_id: felt252 = tx_info.chain_id;
            assert(chain_id == current_chain_id, 'Invalid chain');

            // -----------------------------
            // 3️ DOMAIN SEPARATION
            // -----------------------------
            // Bind signature to this specific contract instance.
            let current_contract = get_contract_address();

            let message = SignedMessage {
                a,
                b,
                nonce,
                chain_id,
                contract_address: current_contract,
            };

            // Hash structured message using Poseidon
            let hash = PoseidonTrait::new()
                .update_with(message)
                .finalize();

            let pub_key = self.authorized_pubkey.read();

            // -----------------------------
            // 4️ SIGNATURE VERIFICATION
            // -----------------------------
            // Ensures message was signed by authorized key.
            let is_valid = ecdsa::check_ecdsa_signature(hash, pub_key, sig_r, sig_s);
            assert(is_valid, 'Invalid signature');

            // -----------------------------
            // 5️ STATE MUTATION
            // -----------------------------
            // Execute authorized logic only after all checks pass.
            let result = a + b;
            let current_total = self.total.read();
            self.total.write(current_total + result);

            // Increment nonce AFTER successful execution.
            // This invalidates the signature permanently.
            self.nonces.write(caller, expected_nonce + 1);
        }

        fn get_total(self: @ContractState) -> felt252 {
            self.total.read()
        }

        fn get_nonce(self: @ContractState, user: ContractAddress) -> felt252 {
            self.nonces.read(user)
        }
    }
}

#[cfg(test)]
mod tests {

    use super::{ISecureDispatcher, ISecureDispatcherTrait};
    use snforge_std::{
        declare, 
        ContractClassTrait, 
        DeclareResultTrait,
        start_cheat_caller_address,
        start_cheat_chain_id_global,
    };
    use starknet::ContractAddress;

    /// Mock public key used for testing
    fn get_test_pubkey() -> felt252 {
        0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
    }

    /// Deterministic caller address for tests
    fn get_test_caller() -> ContractAddress {
        starknet::contract_address_const::<0x123456>()
    }

    /// Helper to deploy contract
    fn deploy_contract(pub_key: felt252) -> ISecureDispatcher {
        let contract = declare("SecureContract").unwrap().contract_class();
        let (contract_address, _) = contract.deploy(@array![pub_key]).unwrap();
        ISecureDispatcher { contract_address }
    }

    /// Ensures initial storage is correct
    #[test]
    fn test_initial_state() {
        let pub_key = get_test_pubkey();
        let dispatcher = deploy_contract(pub_key);
        let caller = get_test_caller();

        assert(dispatcher.get_total() == 0, 'Total should be 0');
        assert(dispatcher.get_nonce(caller) == 0, 'Nonce should be 0');
    }

    /// Verifies chain ID protection blocks cross-chain replay
    #[test]
    #[should_panic(expected: ('Invalid chain',))]
    fn test_fails_on_wrong_chain() {

        let pub_key = get_test_pubkey();
        let dispatcher = deploy_contract(pub_key);
        let caller = get_test_caller();

        // Simulate caller + chain context
        start_cheat_caller_address(dispatcher.contract_address, caller);
        start_cheat_chain_id_global(1);

        let wrong_chain: felt252 = 9999;

        // Should panic before signature validation
        dispatcher.secure_add(5, 5, 0, wrong_chain, 0, 0);
    }

    /// Placeholder replay test
    /// Note: This will not reach nonce logic because signature is invalid.
    /// Proper replay testing requires valid signature generation.
    #[test]
    #[should_panic(expected: ('Invalid nonce',))]
    fn test_replay_attack_fails() {

        let pub_key = get_test_pubkey();
        let dispatcher = deploy_contract(pub_key);
        let caller = get_test_caller();

        start_cheat_caller_address(dispatcher.contract_address, caller);
        start_cheat_chain_id_global(1);

        // Replay logic demonstration requires valid signature.
        // With fake signature, execution fails earlier at signature validation.
    }

    /// Ensures invalid signature is rejected
    #[test]
    #[should_panic(expected: ('Invalid signature',))]
    fn test_invalid_signature_fails() {

        let pub_key = get_test_pubkey();
        let dispatcher = deploy_contract(pub_key);
        let caller = get_test_caller();

        start_cheat_caller_address(dispatcher.contract_address, caller);
        start_cheat_chain_id_global(1);

        dispatcher.secure_add(10, 20, 0, 1, 0, 0);
    }
}
