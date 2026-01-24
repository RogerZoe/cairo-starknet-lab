// ============================================================
// CONTROL FLOW PLAYGROUND — Cairo
// Demonstrates:
// if / else
// while
// loop
// match
// if let
// while let
// let else
// ============================================================

#[derive(Drop, Copy)]
enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter,
}

fn get_optional_value(flag: bool) -> Option<u32> {
    if flag {
        Some(10)
    } else {
        None
    }
}

#[executable]
fn main() {
    // --------------------------------------------------------
    // 1. if / else  → boolean logic only
    // --------------------------------------------------------
    let balance: u32 = 50;

    if balance > 0 {
        println!("Balance exists");
    } else {
        println!("Balance is zero");
    }

    // --------------------------------------------------------
    // 2. while → boolean-based loop
    // --------------------------------------------------------
    let mut i: u32 = 0;

    while i < 3 {
        println!("while loop iteration: {}", i);
        i += 1;
    }

    // --------------------------------------------------------
    // 3. loop → infinite loop with explicit exit
    // --------------------------------------------------------
    let mut retries: u32 = 0;

    loop {
        retries += 1;

        if retries == 2 {
            println!("Exiting loop after retries");
            break;
        }
    }

    // --------------------------------------------------------
    // 4. match → exhaustive pattern matching
    // --------------------------------------------------------
    let coin: Coin = Coin::Quarter;

    match coin {
        Coin::Penny => println!("Penny"),
        Coin::Nickel => println!("Nickel"),
        Coin::Dime => println!("Dime"),
        Coin::Quarter => println!("Quarter"),
    }

    // --------------------------------------------------------
    // 5. if let → care about ONE pattern, ignore others
    // --------------------------------------------------------
    let maybe_value: Option<u32> = get_optional_value(true);

    if let Some(v) = maybe_value {
        println!("if let extracted value: {}", v);
    }

    // --------------------------------------------------------
    // 6. let else → MUST match or exit early (guard clause)
    // --------------------------------------------------------
    let Some(required_value) = get_optional_value(true) else {
        println!("Required value missing, exiting");
        return;
    };

    println!("let else ensured value: {}", required_value);

    // --------------------------------------------------------
    // 7. while let → loop while pattern keeps matching
    // --------------------------------------------------------
    let mut numbers: Array<u32> = array![1, 2, 3, 4];
    let mut total: u32 = 0;

    while let Some(n) = numbers.pop_front() {
        total += n;
    }

    println!("Sum using while let: {}", total);

    // --------------------------------------------------------
    // 8. Combining ideas: match vs if let side-by-side
    // --------------------------------------------------------
    let another_coin: Coin = Coin::Dime;

    // match → when every case matters
    match another_coin {
        Coin::Quarter => println!("Special handling"),
        _ => println!("Non-quarter coin"),
    }

    // if let → when only one case matters
    if let Coin::Quarter = another_coin {
        println!("This will not run");
    }

    // --------------------------------------------------------
    // END
    // --------------------------------------------------------
    println!("Control flow demo completed");
}
