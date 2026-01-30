// Define a StarkNet interface (ABI)
// This tells the outside world what functions this contract exposes
#[starknet::interface]
pub trait Number<ContractState> {
    // Read-only function: does not modify storage
    fn get_number(self: @ContractState) -> u16;

    // State-changing functions
    fn increment(ref self: ContractState);
    fn decrement(ref self: ContractState);
}

#[starknet::contract]
pub mod Contract {
    // Traits required to read/write from StarkNet storage
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    // Used for events (caller address) and access control
    use starknet::{ContractAddress, get_caller_address};

    // ---------------- STORAGE ----------------

    // Persistent contract storage
    #[storage]
    struct Storage {
        // Single counter stored on-chain
        num: u16,
    }

    // ---------------- EVENTS ----------------

    // Top-level event enum (required by StarkNet)
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        // Event variant emitted when counter changes
        CounterChanged: CounterChanged,
    }

    // Event payload structure
    #[derive(Drop, starknet::Event)]
    struct CounterChanged {
        // Who called the function
        caller: ContractAddress,

        // Value before change
        initial_value: u16,

        // Value after change
        new_value: u16,

        // Why the value changed
        Reason: ChangeReason,
    }

    // Enum describing why the counter changed
    // Must derive Serde to be used inside events
    #[derive(Drop, Copy, Serde)]
    enum ChangeReason {
        Increment,
        Decrement,
        Reset,
    }

    // ---------------- CONSTRUCTOR ----------------

    // Constructor runs once at deployment
    // Initializes the counter value
    #[constructor]
    fn constructor(ref self: ContractState, initialValue: u16) {
        self.num.write(initialValue);
    }

    // ---------------- IMPLEMENTATION ----------------

    // Embed ABI v0 and implement the interface
    #[abi(embed_v0)]
    impl NumberImpl of super::Number<ContractState> {

        // Read the current counter value
        fn get_number(self: @ContractState) -> u16 {
            self.num.read()
        }

        // Increment the counter by 1 and emit an event
        fn increment(ref self: ContractState) {
            let current = self.num.read();
            self.num.write(current + 1);
            let new_Value = self.num.read();

            // Create event struct
            let event = CounterChanged {
                caller: get_caller_address(),
                initial_value: current,
                new_value: new_Value,
                Reason: ChangeReason::Increment,
            };

            // Emit the event
            self.emit(event);
        }

        // Decrement the counter by 1 and emit an event
        fn decrement(ref self: ContractState) {
            let current = self.num.read();
            self.num.write(current - 1);
            let new_Value = self.num.read();

            // Create event struct
            let event = CounterChanged {
                caller: get_caller_address(),
                initial_value: current,
                new_value: new_Value,
                Reason: ChangeReason::Decrement,
            };

            // Emit the event
            self.emit(event);
        }
    }
}
