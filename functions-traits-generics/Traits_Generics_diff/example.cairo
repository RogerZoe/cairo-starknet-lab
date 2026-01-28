// ❌ This version LOOKS generic but is actually incomplete
// Because the compiler does not know what operations T supports.
//
// - We compare values using `>`
// - We copy values using `*number`
// - We return a value of type T
//
// Without trait bounds, the compiler cannot guarantee
// that T supports comparison, copying, or dropping.

fn largest<T>(ref number_list: Array<T>) -> T {
    // pop_front() returns Option<T>
    // unwrap() gives us the first element (assumes non-empty array)
    let mut largest = number_list.pop_front().unwrap();

    // span() lets us iterate without consuming the array
    for number in number_list.span() {
        // `number` is of type @T (a snapshot)
        // `*number` tries to copy @T -> T
        if *number > largest {
            largest = *number;
        }
    }

    largest
}


// ✅ Correct generic version WITH trait bounds
//
// Here we explicitly tell the compiler what T is allowed to do:
//
// +PartialOrd<T> → allows comparison using `>`
// +Copy<T>       → allows copying from @T to T using `*`
// +Drop<T>       → allows values of type T to be safely dropped
//
// This makes the generic logic valid and safe.

fn largest<T, +PartialOrd<T>, +Copy<T>, +Drop<T>>(ref number_list: Array<T>) -> T {
    let mut largest = number_list.pop_front().unwrap();

    for number in number_list.span() {
        if *number > largest {
            largest = *number;
        }
    }

    largest
}

#[executable]
fn main() {

    //////////////////////////////
    ///   Using Generics       ///
    //////////////////////////////
    //
    // Same function works for different concrete types
    // because the compiler will generate specialized versions
    // for each type (monomorphization).

    let mut number_list = array![34, 50, 25, 100, 65];

    let result = largest(ref number_list);
    println!("The largest number is {}", result);

    // Same function, different type (u16 instead of u8)
    // No code duplication required
    let mut number_list: Array<u16> = array![102, 34, 255, 89, 54, 2, 43, 8];

    let result = largest(ref number_list);
    println!("The largest number is {}", result);

    /////////////////////////////////
    /// Generics with Trait Bounds //
    /////////////////////////////////
    //
    // Traits act as *compile-time contracts*
    // ensuring that generic types support the
    // operations used inside the function.
}
