use starknet::ContractAddress;
use core::integer::u256;

//////////////////////////////////////////////////////////////
/// TOKEN INTERFACE
///
/// Defines the public API exposed by the Token contract.
/// This is what external contracts interact with.
//////////////////////////////////////////////////////////////
#[starknet::interface]
pub trait IToken<ContractState> {
    /// Returns total supply of tokens.
    fn total_supply(self: @ContractState) -> u256;

    /// Transfers tokens.
    ///  NOTE: In this implementation this function is flawed.
    /// It increases total supply instead of moving balances.
    fn transfer(ref self: ContractState, to: ContractAddress, amount: u256);

    /// Mints tokens to caller.
    ///  No access control — anyone can mint.
    fn deposit(ref self: ContractState, amount: u256);

    /// Burns caller’s tokens.
    /// Protected by reentrancy guard.
    fn withdraw(ref self: ContractState, amount: u256);
}

//////////////////////////////////////////////////////////////
/// RECEIVER INTERFACE
///
/// Used as a callback hook during withdraw.
/// This intentionally introduces a reentrancy surface.
/// Similar concept to ERC777 hooks.
//////////////////////////////////////////////////////////////
#[starknet::interface]
pub trait IReceiver<ContractState> {
    /// Called by Token contract during withdraw.
    fn on_withdraw(ref self: ContractState, amount: u256);
}
#[starknet::contract]
pub mod Token {

    use super::IToken;
    use super::IReceiverDispatcher;
    use super::IReceiverDispatcherTrait;
    use starknet::ContractAddress;
    use core::integer::u256;
    use starknet::get_caller_address;
    use core::starknet::storage::Map;
    use starknet::storage::{
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess
    };

    //////////////////////////////////////////////////////////
    /// OpenZeppelin Reentrancy Guard
    ///
    /// Prevents nested re-entry into protected functions.
    //////////////////////////////////////////////////////////
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;

    component!(
        path: ReentrancyGuardComponent,
        storage: reentrancy_guard,
        event: ReentrancyGuardEvent
    );

    // Exposes start() and end() functions
    impl ReentrancyGuardInternalImpl =
        ReentrancyGuardComponent::InternalImpl<ContractState>;

    //////////////////////////////////////////////////////////
    /// STORAGE LAYOUT
    ///
    /// total_supply: Tracks global token supply.
    /// balances: Maps user address to token balance.
    /// reentrancy_guard: Substorage for protection mechanism.
    //////////////////////////////////////////////////////////
    #[storage]
    pub struct Storage {
        total_supply: u256,
        balances: Map<ContractAddress, u256>,

        #[substorage(v0)]
        reentrancy_guard: ReentrancyGuardComponent::Storage,
    }

    //////////////////////////////////////////////////////////
    /// EVENTS
    //////////////////////////////////////////////////////////
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
    }

    //////////////////////////////////////////////////////////
    /// TOKEN IMPLEMENTATION
    //////////////////////////////////////////////////////////
    #[abi(embed_v0)]
    impl TokenImpl of super::IToken<ContractState> {

        /// Returns total token supply.
        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        //////////////////////////////////////////////////////
        ///  FLAWED TRANSFER
        ///
        /// Instead of transferring between balances,
        /// this incorrectly increases total supply.
        ///
        /// This is intentionally left unchanged for lab use.
        //////////////////////////////////////////////////////
        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) {
            let current = self.total_supply();
            self.total_supply.write(current + amount);
        }

        //////////////////////////////////////////////////////
        /// DEPOSIT (Mint)
        ///
        /// Anyone can call this.
        /// No access control.
        ///
        /// Includes basic overflow checks.
        //////////////////////////////////////////////////////
        fn deposit(ref self: ContractState, amount: u256) {

            let caller = get_caller_address();

            let user_balance = self.balances.read(caller);
            let current_supply = self.total_supply();

            // Manual overflow safety
            assert!(user_balance + amount >= user_balance, "Balance Overflow");
            assert!(current_supply + amount >= current_supply, "Supply Overflow");

            self.total_supply.write(current_supply + amount);
            self.balances.write(caller, user_balance + amount);
        }

        //////////////////////////////////////////////////////
        /// WITHDRAW (Burn)
        ///
        /// Reentrancy protected.
        /// Follows Check-Effects-Interactions pattern.
        ///
        /// Steps:
        /// 1. Start guard
        /// 2. Check balance
        /// 3. Update state
        /// 4. External callback
        /// 5. End guard
        //////////////////////////////////////////////////////
        fn withdraw(ref self: ContractState, amount: u256) {

            //  Prevent nested entry
            self.reentrancy_guard.start();

            let caller = get_caller_address();
            let user_balance = self.balances.read(caller);
            let current = self.total_supply();

            assert!(user_balance >= amount, "Insufficient balance");

            //  Effects before interaction
            self.total_supply.write(current - amount);
            self.balances.write(caller, user_balance - amount);

            //  External call
            // If caller is contract, reentrancy attempt possible here.
            let receiver = IReceiverDispatcher { contract_address: caller };
            receiver.on_withdraw(amount);

            //  Release guard
            self.reentrancy_guard.end();
        }
    }
}
