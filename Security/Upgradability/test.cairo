use snforge_std::{
    declare,
    ContractClassTrait,
    DeclareResultTrait,
    replace_bytecode,
    ReplaceBytecodeError,
};

use practise::{
    ICounterV1Dispatcher, ICounterV1DispatcherTrait,
    ICounterV2BrokenDispatcher, ICounterV2BrokenDispatcherTrait,
    ICounterV2CorrectDispatcher, ICounterV2CorrectDispatcherTrait,
};

#[test]
fn test_storage_upgrade_behavior() {
    // Declare contracts
    let v1_class = declare("CounterV1").unwrap().contract_class();
    let broken_class = declare("CounterV2_Broken").unwrap().contract_class();
    let correct_class = declare("CounterV2_Correct").unwrap().contract_class();

    // Deploy V1 (no constructor args → empty calldata)
    let calldata: Array<felt252> = array![];
    let (contract_address, _) = v1_class.deploy(@calldata).unwrap();

    let v1_dispatcher = ICounterV1Dispatcher { contract_address };

    // Set value using V1
    v1_dispatcher.set(100);
    assert(v1_dispatcher.get() == 100, 'V1_SET_FAILED');

    /////////////////////////////////////
    // Upgrade to BROKEN V2
    /////////////////////////////////////
    
    // Replace the contract's bytecode with broken V2
    replace_bytecode(contract_address, *broken_class.class_hash).unwrap();

    let broken_dispatcher = ICounterV2BrokenDispatcher { contract_address };
    
    // Broken V2 reads from `counter_value` slot (different from `value`)
    // Since nothing was written there, it returns 0
    let broken_value = broken_dispatcher.get();
    assert(broken_value == 0, 'SHOULD_BE_ZERO');

    /////////////////////////////////////
    // Upgrade to CORRECT V2
    /////////////////////////////////////
    
    // Replace bytecode with correct V2
    replace_bytecode(contract_address, *correct_class.class_hash).unwrap();

    let correct_dispatcher = ICounterV2CorrectDispatcher { contract_address };
    
    // Correct V2 reads from `value` slot (same as V1)
    // Storage is preserved!
    let correct_value = correct_dispatcher.get();
    assert(correct_value == 100, 'STORAGE_NOT_PRESERVED');

    // Test increment works
    correct_dispatcher.increment();
    assert(correct_dispatcher.get() == 101, 'INCREMENT_FAILED');
}
