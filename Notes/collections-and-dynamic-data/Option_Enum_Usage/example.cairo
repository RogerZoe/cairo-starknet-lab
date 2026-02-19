use core::option::Option;
use core::option::Option::{Some, None};

#[executable]
fn main() {

    //////////////////////////////////
    ///        Normal Way           ///
    ///  (Using sentinel values)   ///
    //////////////////////////////////

    // Sample array
    let mut arr = array![1, 2, 4, 5, 6];

    // If value is NOT found, this returns -1
    // Problem: -1 is a "fake" value and can be misused by the caller
    println!("{}", getIndex(@arr, -1));

    //////////////////////////////////
    ///        Enum / Option Way    ///
    ///  (Idiomatic and safe)      ///
    //////////////////////////////////

    // Returns Option<i64>
    // Some(index) if found
    // None if not found
    let ans = optionalGetIndex(@arr, -1);

    // Explicitly shows absence instead of lying with -1
    println!("{:?}", ans);

    //////////////////////////////////
    ///        Better / Explicit Way ///
    ///  (Manual bounds + Option)   ///
    //////////////////////////////////

    // Uses span.get(index) which returns Option
    // Demonstrates explicit bounds checking + ownership
    let result = better_way(@arr, 4);
    println!("{:?}", result);
}

/// BetterWay:
/// - Manually iterates using an index
/// - Uses `get()` which returns Option instead of panicking
/// - Explicitly handles "end of array" using None
/// - Demonstrates Box, unbox(), and dereferencing
fn better_way(arr: @Array<felt252>, value: felt252) -> Option<usize> {
    let mut index: usize = 0;

    // Convert array to a Span for safe iteration
    let span = arr.span();

    loop {
        match span.get(index) {
            // get(index) returned Some(...)
            Some(element_box) => {
                // element_box: Box<@felt252>
                // unbox() -> @felt252
                // * -> felt252
                if *element_box.unbox() == value {
                    // Found the value, return its index
                    break Some(index);
                }

                // Move to the next index
                index += 1;
            },

            // get(index) returned None
            // This means index is out of bounds → stop searching
            None => {
                break None;
            },
        }
    }
}

/// Option-based approach using iterator
/// - Cleaner and more idiomatic
/// - Bounds handled implicitly by the iterator
/// - Still returns Option to represent absence
fn optionalGetIndex(arr: @Array<felt252>, value: felt252) -> Option<i64> {
    let mut index = 0;

    for element in arr.span() {
        if *element == value {
            return Option::Some(index);
        }
        index += 1;
    }

    // Explicitly return None if value is not found
    Option::None
}

/// Old-style approach using sentinel value (-1)
/// - Returns a valid type even when value is missing
/// - Caller must "remember" that -1 means not found
/// - Easy to misuse and cause bugs
fn getIndex(arr: @Array<felt252>, value: felt252) -> i64 {
    let mut index = 0;

    for element in arr.span() {
        if *element == value {
            return index;
        }
        index += 1;
    }

    // Fake value representing "not found"
    -1
}
