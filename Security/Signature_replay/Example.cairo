use starknet::ContractAddress;
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};
use core::ecdsa;

#[derive(Drop, Serde, Copy, Hash)]
struct Signature {
    sig_r: felt252,
    sig_s: felt252,
    amount: felt252,
    recipient: ContractAddress,
}

#[starknet::interface]
pub trait IVulnerable<TContractState> {
    fn vulnerable_add(ref self: TContractState, a: felt252, b: felt252, sig: Signature);
    fn get_total(self: @TContractState) -> felt252;
}

#[starknet::contract]
pub mod VulnerableContract {
    use super::{Signature, IVulnerable};
    use starknet::ContractAddress;
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use core::ecdsa;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        authorized_pubkey: felt252,
        total: felt252,  // Tracks cumulative additions
    }

    #[constructor]
    fn constructor(ref self: ContractState, pub_key: felt252) {
        self.authorized_pubkey.write(pub_key);
    }

    #[abi(embed_v0)]
    impl VulnerableImpl of super::IVulnerable<ContractState> {
        
        // ❌ VULNERABLE: No replay protection!
        fn vulnerable_add(ref self: ContractState, a: felt252, b: felt252, sig: Signature)  {
            // Hash includes signature data
            let hash = PoseidonTrait::new()
                .update_with(sig)
                .finalize();

            let pub_key = self.authorized_pubkey.read();

            // Verify signature
            let is_valid = ecdsa::check_ecdsa_signature(
                hash,
                pub_key,
                sig.sig_r,
                sig.sig_s
            );
            assert(true, 'Skip signature for test');
            // ❌ BUG: Same signature can be used multiple times!
            // No nonce, no tracking of used signatures
            let result = a + b;
            let current_total = self.total.read();
            self.total.write(current_total + result);
        }

        fn get_total(self: @ContractState) -> felt252 {
            self.total.read()
        }
    }
}

#[cfg(test)]
mod Test{
    use super::{VulnerableContract, IVulnerableDispatcher, IVulnerableDispatcherTrait, Signature};
    use starknet::ContractAddress;
    use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};

    
    fn get_test_pubkey() -> felt252 {
        // This is a mock public key for testing
        // In production, you'd use a real public key from a keypair
        0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
    }

    fn get_test_address() -> ContractAddress {
        starknet::contract_address_const::<0x123456>()
    }

    fn deploy_contract(pub_key: felt252) -> IVulnerableDispatcher {
        let contract = declare("VulnerableContract").unwrap().contract_class();
        let (contract_address, _) = contract.deploy(@array![pub_key]).unwrap();
        IVulnerableDispatcher { contract_address }
    }

   #[test]
   fn vulnerable_contract() {
       let pub_key = get_test_pubkey();
       let dispatcher =deploy_contract(pub_key);

       let sig = Signature {
           sig_r: 0,
           sig_s: 0,
           amount: 1000,
           recipient: get_test_address(),
       };

       dispatcher.vulnerable_add(1000, 2000, sig); 
       assert!(dispatcher.get_total() == 3000); 


       dispatcher.vulnerable_add(1000, 2000, sig);
       assert!(dispatcher.get_total() == 6000); // this shoulw fail, cause we dont do multiple signing 
   }


}
