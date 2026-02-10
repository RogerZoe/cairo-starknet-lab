 use starknet::ContractAddress;
 use snforge_std::{declare}; //Imports/loads the contract class into your test environment
 use snforge_std::{ContractClassTrait}; //Provides helper functions to work with contract classes [.deploy()]
 use snforge_std::DeclareResultTrait; // Adds methods to handle the result that declare() returns [ .unwrap()]
use practise::counter::ICounterDispatcher;
use practise::counter::ICounterDispatcherTrait;


fn deploy_contract(counter: u32) -> ICounterDispatcher {
    let contract = declare("counter").unwrap().contract_class(); 

// 2. Constructor arguments
    let owner: ContractAddress = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d.try_into().unwrap();
    
    //3. serialize constructor arguments
    let mut constrcuctor_args= array![];
    counter.serialize(ref constrcuctor_args);
    owner.serialize(ref constrcuctor_args);

    let (contract_address, _)= contract.deploy(@constrcuctor_args).unwrap();
    ICounterDispatcher { contract_address: contract_address }
}

#[test]
fn initialize_counter() {
    let dispatcher = deploy_contract(5);
    
    let current_counter = dispatcher.get_counter();
    let expected_counter = 5;
    assert!(current_counter == expected_counter, "Counter should be 5");
}

#[test]
fn increase_counter() {
    let dispatcher =deploy_contract(5);

    dispatcher.increase_counter();
    let current_counter= dispatcher.get_counter();
    assert!(current_counter == 6, "Counter should be 6");
}

#[test]
fn decrease_counter_success() {
    let dispatcher =deploy_contract(5);

    dispatcher.decrease_counter();
    let current_counter= dispatcher.get_counter();
    assert!(current_counter == 4, "Counter should be 6");
}

#[test]
#[should_panic(expected: "The counter cant be negative")]
fn decrease_counter_fail() {
    let dispatcher =deploy_contract(0);

    dispatcher.decrease_counter();
}
