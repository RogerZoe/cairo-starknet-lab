
use starknet::ContractAddress;


#[starknet::interface]
pub trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);
    fn decrease_counter(ref self: T);
    fn set_counter(ref self: T, new_value: u32);
    fn reset_counter(ref self: T);
}

#[starknet::contract]
pub mod counter {
    use super::ICounter;
    use starknet::{get_caller_address, get_contract_address, ContractAddress};
    // Required traits for storage access
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    // OpenZeppelin imports
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    
    use crate::utils::{strk_address,strk_to_wei};

    // Component declaration
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable implementation
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
   pub struct Storage {
        counter: u32,
        // Substorage for the Ownable component
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    //
    #[event]
    #[derive(Drop, starknet::Event)]
   pub enum Event {
        CounterChanged: CounterChanged,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
   pub struct CounterChanged {
        #[key]
       pub caller: ContractAddress,
        pub old_value: u32,
        pub new_value: u32,
        pub reason: ChangeReason
    }

    #[derive(Drop, Copy, Serde)]
   pub enum ChangeReason {
       Increase,
       Decrease,
        Set,
        Reset
    }

    //
    #[constructor]
    fn constructor(ref self: ContractState, init_value: u32, owner: ContractAddress) {
        self.counter.write(init_value);
        // Initializing the owner via the Ownable component
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl ICounterImpl of ICounter<ContractState> {
        //
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        //
        fn increase_counter(ref self: ContractState) {
            let current_counter = self.counter.read();
            let new_counter = current_counter + 1;
            self.counter.write(new_counter);

            // Emit event
            self.emit(Event::CounterChanged(CounterChanged {
                caller: get_caller_address(),
                old_value: current_counter,
                new_value: new_counter,
                reason: ChangeReason::Increase
            }));
        }

        //
        fn decrease_counter(ref self: ContractState) {
            let current_counter = self.counter.read();
            // Underflow protection with descriptive error
            assert!(current_counter > 0, "The counter cant be negative");
            
            let new_counter = current_counter - 1;
            self.counter.write(new_counter);

            self.emit(Event::CounterChanged(CounterChanged {
                caller: get_caller_address(),
                old_value: current_counter,
                new_value: new_counter,
                reason: ChangeReason::Decrease
            }));
        }

        //
        fn set_counter(ref self: ContractState, new_value: u32) {
            // Access control via Ownable component
            self.ownable.assert_only_owner();
            
            let old_counter = self.counter.read();
            self.counter.write(new_value);

            self.emit(Event::CounterChanged(CounterChanged {
                caller: get_caller_address(),
                old_value: old_counter,
                new_value: new_value,
                reason: ChangeReason::Set
            }));
        }

        //
        fn reset_counter(ref self: ContractState) {
            // 1 STRK (10^18)
            let payment_amount: u256 = strk_to_wei(5); 
            // Standard Stark Token address
            let strk_token_address: ContractAddress = strk_address();
            let caller = get_caller_address();
            let contract_address = get_contract_address();
            let owner = self.ownable.owner();
            
            // Interaction with ERC20 contract
            let dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
            
            // Check balance
            let balance = dispatcher.balance_of(caller);
            assert(balance >= payment_amount, 'User doesnt have enough balance');
            
            // Check allowance
            let allowance = dispatcher.allowance(caller, contract_address);
            assert(allowance >= payment_amount, 'Contract not allowed to spend');
            
            // Perform transfer
            let success = dispatcher.transfer_from(caller, owner, payment_amount);
            assert(success, 'Transferring stark failed');

            // Reset state
            let old_counter = self.counter.read();
            self.counter.write(0);

            self.emit(Event::CounterChanged(CounterChanged {
                caller: caller,
                old_value: old_counter,
                new_value: 0,
                reason: ChangeReason::Reset
            }));
        }
    }
}
