use starknet::ContractAddress;

#[starknet::interface]
pub trait IRegistry<TContractState> {
    // External function to register a user with first & last name
    fn register_user(ref self: TContractState, user_fname: felt252, user_lname: felt252);

    // Checks whether the caller is already registered
    fn is_user_registered(self: @TContractState) -> bool;

    // Blacklists a user (implementation-defined behavior)
    fn blacklist_user(ref self: TContractState, user_id: u8);

    // Returns how much weight a user can still use
    fn get_user_available_weight(self: @TContractState, address: ContractAddress) -> u256;

    // Consumes a portion of a user's weight
    fn use_weights(ref self: TContractState, address: ContractAddress, weights: u256);
}

//! We use a component because this registry logic is reusable across multiple contracts.
//! Components are not deployable by themselves; they are embedded into contracts.
#[starknet::component]
pub mod RegistryComponent {

    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use crate::types::User;
    use super::IRegistry;

    #[storage]
    pub struct Storage {
        // Maps a Starknet address to its corresponding User struct
        pub users: Map<ContractAddress, User>,

        // Total number of registered users
        pub user_count: u8,

        // Default weight assigned to a newly registered user
        pub user_weight: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        // Emitted when a user registers
        UserRegistered: UserRegistered,

        // Emitted when a user is blacklisted
        UserBlacklisted: UserBlacklisted,

        // Re-emits ERC20 events if this component interacts with ERC20 logic
        ERC20Event: ERC20Component::Event,
    }

    #[derive(Drop, starknet::Event)]
    pub struct UserRegistered {
        // Address of the registered user (typed, not felt252, for safety & tooling)
        user: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct UserBlacklisted {
        // ContractAddress is used instead of felt252 to preserve address semantics
        user: ContractAddress,
        timestamp: u64,
    }

    // This block implements the IRegistry interface FOR THE COMPONENT STATE.
    // #[embeddable_as] allows a parent contract to expose this implementation.
    #[embeddable_as(RegistryImpl)]
    pub impl RegistryComponentImpl<
        TContractState,
        +HasComponent<TContractState>,
    > of IRegistry<ComponentState<TContractState>> {

        fn register_user(
            ref self: ComponentState<TContractState>,
            user_fname: felt252,
            user_lname: felt252,
        ) {
            // Caller becomes the registered user
            let user_Address = get_caller_address();

            // Increment user count to derive user id
            let user_id = self.user_count.read() + 1;

            // Fetch default weight assigned to users
            let weight = self.user_weight.read();

            let user = User {
                id: user_id,
                fname: user_fname,
                lname: user_lname,
                total_weight: weight,
                used_weight: 0,
            };

            // Store user data keyed by address
            self.users.entry(user_Address).write(user);

            // Emit registration event
            self.emit(
                UserRegistered {
                    user: user_Address,
                    timestamp: get_block_timestamp(),
                }
            )
        }

        fn is_user_registered(self: @ComponentState<TContractState>) -> bool {
            let user_Address = get_caller_address();
            let user = self.users.entry(user_Address).read();

            // If the map entry was never set, it returns Default::default()
            if user == Default::default() {
                false
            } else {
                true
            }
        }

        fn blacklist_user(ref self: ComponentState<TContractState>, user_id: u8) {
            let user_address = get_caller_address();

            // Writing Default::default() effectively removes the user data
            self.users.entry(user_address).write(Default::default());

            // Emit blacklist event
            self.emit(
                UserBlacklisted {
                    user: user_address,
                    timestamp: get_block_timestamp(),
                }
            )
        }

        fn get_user_available_weight(
            self: @ComponentState<TContractState>,
            address: ContractAddress,
        ) -> u256 {
            let user = self.users.entry(address).read();

            // Remaining usable weight
            user.total_weight - user.used_weight
        }

        fn use_weights(
            ref self: ComponentState<TContractState>,
            address: ContractAddress,
            weights: u256,
        ) {
            let mut user = self.users.entry(address).read();

            // Increase consumed weight
            user.used_weight += weights;

            self.users.entry(address).write(user);
        }
    }

    // Components cannot have constructors.
    // This internal initializer must be called by the parent contract’s constructor.
    #[generate_trait]
    pub impl InternalFunctions<
        TContractState,
        +HasComponent<TContractState>,
    > of InternalTrait<TContractState> {

        fn initializer(
            ref self: ComponentState<TContractState>,
            user_weight: u256,
        ) {
            // Initialize component storage
            self.user_count.write(0);
            self.user_weight.write(user_weight);
        }
    }
}
