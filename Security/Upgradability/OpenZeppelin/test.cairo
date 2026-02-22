use snforge_std::{
    declare,
    ContractClassTrait,
    DeclareResultTrait,
    replace_bytecode,
    start_cheat_caller_address,
    stop_cheat_caller_address,
};

use starknet::ContractAddress;
use starknet::contract_address_const;

use practise::{
    ICounterV1Dispatcher,
    ICounterV1DispatcherTrait,
    ICounterV2BrokenDispatcher,
    ICounterV2BrokenDispatcherTrait,
    ICounterV2CorrectDispatcher,
    ICounterV2CorrectDispatcherTrait,
};

////////////////////////////////////////////////////////////
// TEST 1 — Native upgrade using replace_bytecode
////////////////////////////////////////////////////////////

#[test]
fn test_native_upgrade_flow() {
    // Declare contract classes (only declares code, does not deploy)
    let v1_class = declare("CounterV1").unwrap().contract_class();
    let v2_class = declare("CounterV2_Correct").unwrap().contract_class();

    // Create deterministic owner address (constant address)
    let owner: ContractAddress = contract_address_const::<0x123>();
    
    // Constructor expects owner as felt252
    let owner_felt: felt252 = owner.into();
    let mut calldata: Array<felt252> = array![owner_felt];
    
    // Deploy V1 contract with owner set in storage
    let (contract_address, _) = v1_class.deploy(@calldata).unwrap();

    // Create dispatcher pointing to deployed address
    let v1 = ICounterV1Dispatcher { contract_address };

    // Write state using V1 logic
    v1.set(100);

    // Read state to confirm storage write succeeded
    let value = v1.get();
    assert(value == 100, 'SET_FAILED');

    // Perform upgrade at protocol level (no contract logic involved)
    // This directly replaces the class hash at this address
    replace_bytecode(contract_address, *v2_class.class_hash).unwrap();

    // Now interact using V2 interface (same address, new logic)
    let v2 = ICounterV2CorrectDispatcher { contract_address };

    // Storage should still contain old value
    let value = v2.get();
    assert(value == 100, 'STORAGE_LOST');

    // Execute new function introduced in V2
    v2.increment();

    // Ensure new logic works on preserved storage
    let value = v2.get();
    assert(value == 101, 'INCREMENT_FAILED');
}

////////////////////////////////////////////////////////////
// TEST 2 — Upgrade using contract's own upgrade() function
////////////////////////////////////////////////////////////

#[test]
fn test_native_upgrade_via_contract() {
    let v1_class = declare("CounterV1").unwrap().contract_class();
    let v2_class = declare("CounterV2_Correct").unwrap().contract_class();

    let owner: ContractAddress = contract_address_const::<0x456>();
    
    let owner_felt: felt252 = owner.into();
    let mut calldata: Array<felt252> = array![owner_felt];
    
    let (contract_address, _) = v1_class.deploy(@calldata).unwrap();

    let v1 = ICounterV1Dispatcher { contract_address };

    // Write state using V1 logic
    v1.set(200);

    let value = v1.get();
    assert(value == 200, 'SET_FAILED');

    // Simulate call from owner
    // This overrides msg.sender for this contract call only
    start_cheat_caller_address(contract_address, owner);

    // Call contract-level upgrade function
    // This internally calls replace_class_syscall
    v1.upgrade(*v2_class.class_hash);

    // Restore normal caller behavior
    stop_cheat_caller_address(contract_address);

    // Now logic is V2
    let v2 = ICounterV2CorrectDispatcher { contract_address };

    // Confirm storage survived class replacement
    let value = v2.get();
    assert(value == 200, 'STORAGE_LOST');

    // Use new V2 functionality
    v2.increment();

    let value = v2.get();
    assert(value == 201, 'INCREMENT_FAILED');
}

////////////////////////////////////////////////////////////
// TEST 3 — Broken upgrade (renamed storage)
////////////////////////////////////////////////////////////

#[test]
fn test_broken_upgrade_loses_storage() {
    let v1_class = declare("CounterV1").unwrap().contract_class();
    let broken_class = declare("CounterV2_Broken").unwrap().contract_class();

    let owner: ContractAddress = contract_address_const::<0x789>();
    
    let owner_felt: felt252 = owner.into();
    let mut calldata: Array<felt252> = array![owner_felt];
    
    let (contract_address, _) = v1_class.deploy(@calldata).unwrap();

    let v1 = ICounterV1Dispatcher { contract_address };

    // Write value using original storage slot name "value"
    v1.set(999);

    let value = v1.get();
    assert(value == 999, 'SET_FAILED');

    // Upgrade to version that renamed storage to "counter_value"
    // Storage slot key changes -> data becomes inaccessible
    replace_bytecode(contract_address, *broken_class.class_hash).unwrap();

    let broken = ICounterV2BrokenDispatcher { contract_address };

    // Since broken version reads from different slot,
    // it sees default value (0)
    let value = broken.get();
    assert(value == 0, 'SHOULD_BE_ZERO');
}

////////////////////////////////////////////////////////////
// TEST 4 — Access control enforcement
////////////////////////////////////////////////////////////

#[test]
#[should_panic(expected: 'NOT_OWNER')]
fn test_only_owner_can_upgrade() {
    let v1_class = declare("CounterV1").unwrap().contract_class();
    let v2_class = declare("CounterV2_Correct").unwrap().contract_class();

    // Define legitimate owner
    let owner: ContractAddress = contract_address_const::<0x123456>();

    // Define attacker
    let attacker: ContractAddress = contract_address_const::<0x789012>();
    
    let owner_felt: felt252 = owner.into();
    let mut calldata: Array<felt252> = array![owner_felt];
    
    let (contract_address, _) = v1_class.deploy(@calldata).unwrap();

    let v1 = ICounterV1Dispatcher { contract_address };

    // Simulate attacker as caller
    start_cheat_caller_address(contract_address, attacker);

    // This should revert with NOT_OWNER
    v1.upgrade(*v2_class.class_hash);

    stop_cheat_caller_address(contract_address);
}
