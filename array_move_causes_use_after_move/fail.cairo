use array::ArrayTrait;

// A simple function that takes ownership of an array
fn consume_array(arr: Array<u128>) -> u128 {
    // Just return the length to "use" it
    arr.len()
}

fn main() {
    let mut my_array = Array::<u128>::new();
    my_array.append(10);
    my_array.append(20);
    my_array.append(30);

    // ✅ First use: pass to function → ARRAY IS MOVED
    let len = consume_array(my_array);

    // ❌ SECOND USE: try to use `my_array` again → COMPILE ERROR!
    my_array.append(40); // ← This line causes the failure

    // (We won't even reach here)
}
