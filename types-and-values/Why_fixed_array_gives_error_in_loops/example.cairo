#[executable]
fn main() {
    /////////////////////////////////////////////
    ///        Fixed-size Array               ///
    /////////////////////////////////////////////

    let my_arr = [1, 2, 3, 4, 5];

    //  Not allowed:
    // let mut i = 0;
    // while i < 5 {
    //     println!("{}", my_arr[i]); // ERROR
    //     i += 1;
    // }

    //  Correct way:
    // span() exposes the fixed-size array as runtime data
    let span_array = my_arr.span();
    let mut i = 0;
    while i < span_array.len() {
        println!("{}", span_array[i]);
        i += 1;
    }

    /////////////////////////////////////////////
    ///        Dynamic Array                  ///
    /////////////////////////////////////////////

    // Dynamic arrays exist at runtime
    let mut arr: Array<u32> = array![1, 2, 4, 5];

    // Mutation is allowed
    arr.append(3);
    arr.append(4);
    arr.append(6);

    // Indexing and looping work
    let mut i = 0;
    while i < arr.len() {
        println!("{}", arr[i]);
        i += 1;
    }
}
