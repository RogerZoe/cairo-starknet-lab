use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Book {
    pub book_id: u8,
    pub book_name: felt252,
    pub author: felt252,
    pub current_holder: ContractAddress, // By default, librarian is the book holder
    pub borrowed: bool,
    pub deleted: bool,
    pub weight: u256,
}

#[derive(Copy, Drop, Serde, starknet::Store, Default, PartialEq)]
pub struct User {
    pub id: u8,
    pub fname: felt252,
    pub lname: felt252,
    pub total_weight: u256,
    pub used_weight: u256
}
