use starknet::ClassHash;
use starknet::ContractAddress;

////////////////////////////////////////////////////////////
// INTERFACES
////////////////////////////////////////////////////////////

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

#[starknet::interface]
pub trait ISimpleProxy<TContractState> {
    fn upgrade(ref self: TContractState, new_impl: ClassHash);
    fn get_impl(self: @TContractState) -> ClassHash;
}

////////////////////////////////////////////////////////////
// IMPLEMENTATION V1
////////////////////////////////////////////////////////////

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

#[starknet::contract]
pub mod CounterV2_Correct {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        value: u256, // same name - storage preserved
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
// SIMPLE PROXY (Using library_call_syscall)
////////////////////////////////////////////////////////////

#[starknet::contract]
pub mod SimpleProxy {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::ClassHash;
    use starknet::ContractAddress;
    use starknet::syscalls::library_call_syscall;
    use starknet::SyscallResultTrait;

    #[storage]
    pub struct Storage {
        implementation: ClassHash,
        admin: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        impl_hash: ClassHash,
        admin: ContractAddress,
    ) {
        self.implementation.write(impl_hash);
        self.admin.write(admin);
    }

    // Fallback function - delegates unknown calls to implementation
    #[external(v0)]
    fn __default__(ref self: ContractState, selector: felt252, calldata: Array<felt252>) -> Array<felt252> {
        let class_hash = self.implementation.read();
        
        // library_call_syscall executes code from another class
        // but uses THIS contract's storage
        let result = library_call_syscall(
            class_hash,
            selector,
            calldata.span()
        ).unwrap_syscall();
        
        // Convert Span back to Array for return
        let mut output: Array<felt252> = array![];
        let mut i: usize = 0;
        loop {
            if i >= result.len() {
                break;
            }
            output.append(*result.at(i));
            i += 1;
        };
        output
    }

    #[abi(embed_v0)]
    impl SimpleProxyImpl of super::ISimpleProxy<ContractState> {
        fn upgrade(ref self: ContractState, new_impl: ClassHash) {
            let caller = starknet::get_caller_address();
            assert(caller == self.admin.read(), 'NOT_ADMIN');
            self.implementation.write(new_impl);
        }

        fn get_impl(self: @ContractState) -> ClassHash {
            self.implementation.read()
        }
    }
}
