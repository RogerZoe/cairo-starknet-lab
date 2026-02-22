use starknet::{ClassHash, ContractAddress, syscalls};
use core::num::traits::Zero;

////////////////////////////////////////////////////////////
// INTERFACES
////////////////////////////////////////////////////////////

#[starknet::interface]
pub trait ICounterV1<TContractState> {
    fn set(ref self: TContractState, new_value: u256);
    fn get(self: @TContractState) -> u256;
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}

#[starknet::interface]
pub trait ICounterV2Broken<TContractState> {
    fn set(ref self: TContractState, new_value: u256);
    fn get(self: @TContractState) -> u256;
}

#[starknet::interface]
pub trait ICounterV2Correct<TContractState> {
    fn increment(ref self: TContractState);
    fn get(self: @TContractState) -> u256;
}

////////////////////////////////////////////////////////////
// IMPLEMENTATION V1 (Upgradeable)
////////////////////////////////////////////////////////////

#[starknet::contract]
pub mod CounterV1 {

    use super::*;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        owner: ContractAddress,
        value: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl CounterV1Impl of super::ICounterV1<ContractState> {

        fn set(ref self: ContractState, new_value: u256) {
            self.value.write(new_value);
        }

        fn get(self: @ContractState) -> u256 {
            self.value.read()
        }

        // Native upgrade
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {

            let caller = starknet::get_caller_address();
            assert(caller == self.owner.read(), 'NOT_OWNER');
            assert(!new_class_hash.is_zero(), 'ZERO_CLASS_HASH');

            syscalls::replace_class_syscall(new_class_hash).unwrap();
        }
    }
}

////////////////////////////////////////////////////////////
// IMPLEMENTATION V2 (BROKEN - RENAMED STORAGE)
////////////////////////////////////////////////////////////

#[starknet::contract]
pub mod CounterV2_Broken {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        owner: ContractAddress,
        counter_value: u256, // renamed -> breaks storage
    }

    #[abi(embed_v0)]
    impl CounterV2BrokenImpl of super::ICounterV2Broken<ContractState> {

        fn set(ref self: ContractState, new_value: u256) {
            self.counter_value.write(new_value);
        }

        fn get(self: @ContractState) -> u256 {
            self.counter_value.read()
        }
    }
}

////////////////////////////////////////////////////////////
// IMPLEMENTATION V2 (CORRECT - STORAGE PRESERVED)
////////////////////////////////////////////////////////////

#[starknet::contract]
pub mod CounterV2_Correct {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        owner: ContractAddress,
        value: u256, // same name as V1
    }

    #[abi(embed_v0)]
    impl CounterV2CorrectImpl of super::ICounterV2Correct<ContractState> {

        fn increment(ref self: ContractState) {
            let current = self.value.read();
            self.value.write(current + 1);
        }

        fn get(self: @ContractState) -> u256 {
            self.value.read()
        }
    }
}

