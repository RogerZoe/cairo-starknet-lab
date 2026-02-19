use starknet::ContractAddress;
use snforge_std::{
    declare,
    start_cheat_caller_address,
};

use snforge_std::ContractClassTrait;
use snforge_std::DeclareResultTrait;

use practise::ITokenDispatcher;
use practise::ITokenDispatcherTrait;
use practise::{IAttackerDispatcher, IAttackerDispatcherTrait};

//////////////////////////////////////////////////////////////
/// Helper: Deploy Token
//////////////////////////////////////////////////////////////
fn deploy_contract() -> ITokenDispatcher {

    let contract = declare("Token").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();

    ITokenDispatcher { contract_address }
}

//////////////////////////////////////////////////////////////
/// Basic deployment test
//////////////////////////////////////////////////////////////
#[test]
fn test_deploy() {

    let dispatcher = deploy_contract();

    // Initial supply must be zero
    assert!(dispatcher.total_supply() == 0);

    // Mint tokens
    dispatcher.deposit(10);

    assert!(dispatcher.total_supply() == 10);
}

//////////////////////////////////////////////////////////////
/// Reentrancy test
///
/// Expected behavior:
/// Second withdraw triggers reentrancy guard panic.
//////////////////////////////////////////////////////////////
#[test]
#[should_panic]
fn test_reentrancy_attack() {

    // Deploy Token
    let token_contract = declare("Token").unwrap().contract_class();
    let (token_address, _) = token_contract.deploy(@array![]).unwrap();
    let token = ITokenDispatcher { contract_address: token_address };

    // Deploy Attacker
    let attacker_contract = declare("Attacker").unwrap().contract_class();
    let (attacker_address, _) = attacker_contract.deploy(@array![]).unwrap();
    let attacker = IAttackerDispatcher { contract_address: attacker_address };

    // Simulate attacker calling token
    start_cheat_caller_address(token_address, attacker_address);

    assert(token.total_supply() == 0, 'initial supply wrong');

    // Launch attack
    // Should panic due to reentrancy guard
    attacker.attack(token_address);

    // If guard fails, this executes
    let final_supply = token.total_supply();
    println!("Final total supply: {}", final_supply);
}
