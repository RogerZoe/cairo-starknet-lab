// These are common Starknet types used in proxy storage.
// ClassHash identifies contract logic.
// ContractAddress identifies deployed contract location.
use starknet::ClassHash;
use starknet::ContractAddress;

////////////////////////////////////////////////////////////
// INTERFACES
////////////////////////////////////////////////////////////

// /*
// Interfaces define the ABI surface.

// Key idea:
// The interface determines what dispatchers get generated.

// The storage layout is NOT defined here.
// Only function signatures are.

// Interfaces are important when:
// - Other contracts call this one
// - You want ABI stability across upgrades
// */

#[starknet::interface]
pub trait ICounterV1<TContractState> {
    fn set(ref self: TContractState, new_value: u256);
    fn get(self: @TContractState) -> u256;
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
// IMPLEMENTATION V1
////////////////////////////////////////////////////////////

// /*
// CounterV1 defines initial storage layout.

// CRITICAL:
// Storage address for `value` is computed as:

// hash("value")

// This name becomes the storage key.
// Renaming it later will change the storage location.
// */

#[starknet::contract]
pub mod CounterV1 {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        value: u256,
    }

    #[abi(embed_v0)]
    impl CounterV1Impl of super::ICounterV1<ContractState> {
        fn set(ref self: ContractState, new_value: u256) {
            self.value.write(new_value);
        }

        fn get(self: @ContractState) -> u256 {
            self.value.read()
        }
    }
}

////////////////////////////////////////////////////////////
// IMPLEMENTATION V2 (BROKEN - RENAMED STORAGE)
////////////////////////////////////////////////////////////

// /*
// This version renames `value` → `counter_value`.

// Storage key becomes:

// hash("counter_value")

// That is NOT the same as hash("value").

// Result:
// Existing storage remains untouched,
// but reads now point to a different key.

// This causes silent state desync.
// */

#[starknet::contract]
pub mod CounterV2_Broken {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        counter_value: u256, // renamed (breaks storage)
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
// IMPLEMENTATION V2 (CORRECT)
////////////////////////////////////////////////////////////
// /*
// This version preserves the original storage variable name.

// Storage key remains:

// hash("value")

// Therefore:
// - Old state is preserved.
// - Upgrade is safe.
// */

#[starknet::contract]
pub mod CounterV2_Correct {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        value: u256, // same name
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

////////////////////////////////////////////////////////////
// SIMPLE PROXY
////////////////////////////////////////////////////////////

// /*
// This proxy stores:

// - implementation class hash (logic pointer)
// - admin address (upgrade authority)

// Important:
// Storage lives in THIS contract.
// Logic lives in implementation contract.

// In Starknet, you can either:
// 1. Use proxy pattern like this
// 2. Use native class replacement (replace_bytecode)

// This proxy does NOT forward calls yet.
// It only demonstrates upgrade storage control.
// */

#[starknet::contract]
pub mod SimpleProxy {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::ClassHash;
    use starknet::ContractAddress;

    #[storage]
    pub struct Storage {
        implementation: ClassHash,
        admin: ContractAddress,
    }

    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        impl_hash: ClassHash,
        admin: ContractAddress,
    ) {
        self.implementation.write(impl_hash);
        self.admin.write(admin);
    }

// /*
//     Upgrade function:
//     - Only admin can call
//     - Changes implementation pointer
//     - Does NOT change storage
//     */
    #[external(v0)]
    pub fn upgrade(ref self: ContractState, new_impl: ClassHash) {
        let caller = starknet::get_caller_address();
        assert(caller == self.admin.read(), 'NOT_ADMIN');
        self.implementation.write(new_impl);
    }

    #[external(v0)]
    pub fn get_impl(self: @ContractState) -> ClassHash {
        self.implementation.read()
    }
}
