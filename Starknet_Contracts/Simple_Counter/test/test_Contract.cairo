use starknet::ContractAddress;
use snforge_std::{
    declare,
    spy_events,
    start_cheat_caller_address,
    stop_cheat_caller_address,
    set_balance,
    Token
}; 
// snforge utilities:
// - declare → loads contract class for deployment
// - spy_events → capture emitted events
// - cheat caller → simulate msg.sender
// - set_balance → mock native STRK balance in tests

use snforge_std::ContractClassTrait; 
use snforge_std::DeclareResultTrait; 

use practise::counter::ICounterDispatcher;
use practise::counter::ICounterDispatcherTrait;

use snforge_std::EventSpyAssertionsTrait;

use practise::counter::counter::{CounterChanged,ChangeReason,Event};
use practise::utils::{strk_address,strk_to_wei};

use openzeppelin::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};


/// Mocked owner address for consistent test environment
fn owner_address() -> ContractAddress {
    'owner'.try_into().unwrap()
}

/// Mocked user address to simulate external caller
fn user_address() -> ContractAddress {
    'user'.try_into().unwrap()
}


/// Deploys the Counter contract with a given initial value
/// Handles declaration + constructor calldata serialization
fn deploy_contract(counter: u32) -> ICounterDispatcher {
    let contract = declare("counter").unwrap().contract_class(); 

    // Constructor args: initial counter value + owner address
    let owner: ContractAddress = owner_address();

    let mut constrcuctor_args = array![];
    counter.serialize(ref constrcuctor_args);
    owner.serialize(ref constrcuctor_args);

    let (contract_address, _) = contract.deploy(@constrcuctor_args).unwrap();

    // Dispatcher allows calling external functions safely
    ICounterDispatcher { contract_address }
}

#[test]
fn initialize_counter() {
    // Verify constructor initializes storage correctly
    let dispatcher = deploy_contract(5);

    let current_counter = dispatcher.get_counter();
    assert!(current_counter == 5, "Counter should be 5");
}

#[test]
fn increase_counter() {
    let dispatcher = deploy_contract(5);

    // Capture events emitted during execution
    let mut catcher = spy_events();

    // Simulate user calling the contract
    start_cheat_caller_address(dispatcher.contract_address, user_address());
    dispatcher.increase_counter();
    stop_cheat_caller_address(dispatcher.contract_address);

    // Validate state mutation
    assert!(dispatcher.get_counter() == 6, "Counter should be 6");

    // Expected emitted event structure
    let expected_event = CounterChanged {
        caller: user_address(),
        old_value: 5,
        new_value: 6,
        reason: ChangeReason::Increase,
    };

    // Assert event was emitted correctly
    catcher.assert_emitted(@array![(
        dispatcher.contract_address,
        Event::CounterChanged(expected_event),
    )]);
}

#[test]
fn decrease_counter_success() {
    let dispatcher = deploy_contract(5);
    let mut catcher = spy_events();

    // Simulate user decreasing counter
    start_cheat_caller_address(dispatcher.contract_address, user_address());
    dispatcher.decrease_counter();
    stop_cheat_caller_address(dispatcher.contract_address);

    assert!(dispatcher.get_counter() == 4, "Counter should be 4");

    let expected_event = CounterChanged {
        caller: user_address(),
        old_value: 5,
        new_value: 4,
        reason: ChangeReason::Decrease,
    };

    catcher.assert_emitted(@array![(
        dispatcher.contract_address,
        Event::CounterChanged(expected_event),
    )]);
}

#[test]
#[should_panic(expected: "The counter cant be negative")]
fn decrease_counter_fail() {
    // Underflow protection check
    let dispatcher = deploy_contract(0);
    dispatcher.decrease_counter();
}

#[test]
fn set_counter_only_owner() {
    let dispatcher = deploy_contract(5);
    let mut catcher = spy_events();

    // Only owner should be able to set counter
    start_cheat_caller_address(dispatcher.contract_address, owner_address());
    dispatcher.set_counter(0);
    stop_cheat_caller_address(dispatcher.contract_address);

    assert!(dispatcher.get_counter() == 0, "Counter should be 0");

    let expected_event = CounterChanged {
        caller: owner_address(),
        old_value: 5,
        new_value: 0,
        reason: ChangeReason::Set,
    };

    catcher.assert_emitted(@array![(
        dispatcher.contract_address,
        Event::CounterChanged(expected_event),
    )]);
}

#[test]
#[should_panic]
fn set_counter_non_owner() {
    // Non-owner attempting restricted action should revert
    let dispatcher = deploy_contract(5);

    start_cheat_caller_address(dispatcher.contract_address, user_address());
    dispatcher.set_counter(0);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
#[should_panic]
fn reset_counter_insufficient_balance() {
    // User has no STRK balance → should revert
    let dispatcher = deploy_contract(5);

    start_cheat_caller_address(dispatcher.contract_address, user_address());
    dispatcher.reset_counter();
}

#[test]
#[should_panic]
fn reset_counter_No_allowance() {
    // User has balance but does NOT approve spending
    let dispatcher = deploy_contract(5);

    let user = user_address();
    set_balance(user, 1000000000000000000, Token::STRK);

    start_cheat_caller_address(dispatcher.contract_address, owner_address());
    dispatcher.reset_counter();
}

#[test]
fn reset_counter_success() {
    let dispatcher = deploy_contract(5);
    let mut catcher = spy_events();

    let user = user_address();

    // Give user 10 STRK
    set_balance(user, strk_to_wei(10), Token::STRK);

    // ERC20 dispatcher to interact with STRK contract
    let erc20 = IERC20Dispatcher { contract_address: strk_address() };

    // User approves contract to spend 5 STRK
    start_cheat_caller_address(erc20.contract_address, user_address());
    erc20.approve(dispatcher.contract_address, strk_to_wei(5));
    stop_cheat_caller_address(erc20.contract_address);

    // User calls reset (must be same address that approved)
    start_cheat_caller_address(dispatcher.contract_address, user_address());
    dispatcher.reset_counter();
    stop_cheat_caller_address(dispatcher.contract_address);

    // Validate state reset
    assert!(dispatcher.get_counter() == 0, "Counter should be 0");

    // Validate token transfers:
    // User paid 5 STRK
    assert!(erc20.balance_of(user) == strk_to_wei(5), "User should have 5 STRK");

    // Owner received 5 STRK
    assert!(erc20.balance_of(owner_address()) == strk_to_wei(5), "Owner should have 5 STRK");

    let expected_event = CounterChanged {
        caller: user_address(),
        old_value: 5,
        new_value: 0,
        reason: ChangeReason::Reset,
    };

    catcher.assert_emitted(@array![(
        dispatcher.contract_address,
        Event::CounterChanged(expected_event),
    )]);
}
