#[executable]
fn assignment() {
    let a: u32 = 10;
    let b: u32 = 3;

    let result = a - b;
    println!("{} - {} = {}", a, b, result); // Output: 10 - 3 = 7

    let c: felt252 = 3;
    let d: felt252 = 10;
    println!("{} - {} = {}", c, d, c - d);  // Ouput: 3 - 10 = 3618502788666131213697322783095070105623107215331596699973092056135872020474 
    // so felt252 is not for arithmetic opeations!
}
