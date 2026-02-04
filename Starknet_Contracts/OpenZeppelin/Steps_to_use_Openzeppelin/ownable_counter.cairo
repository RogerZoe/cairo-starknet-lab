#[starknet::interface]
pub trait ICounter<TContractState> {
    fn get(self: @TContractState) -> u16;
    fn increment(ref self: TContractState);
    fn set(ref self: TContractState, value: u16);
}

#[starknet::contract]
mod OwnableCounter {
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};

    // 1. Attach OpenZeppelin Ownable component
    component!(
        path: OwnableComponent,
        storage: ownable,
        event: OwnableEvent,
    );

    // 2. Embed ABI and internal logic
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u16,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterSet: CounterSet,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterSet {
        caller: ContractAddress,
        old_value: u16,
        new_value: u16,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // 3. Initialize Ownable
        self.ownable.initializer(owner);
        self.counter.write(0);
    }

    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        fn get(self: @ContractState) -> u16 {
            self.counter.read()
        }

        fn increment(ref self: ContractState) {
            let value = self.counter.read();
            self.counter.write(value + 1);
        }

        fn set(ref self: ContractState, value: u16) {
            // 4. Use Ownable guard
            self.ownable.assert_only_owner();

            let old = self.counter.read();
            self.counter.write(value);

            self.emit(
                CounterSet {
                    caller: get_caller_address(),
                    old_value: old,
                    new_value: value,
                }
            );
        }
    }
}
