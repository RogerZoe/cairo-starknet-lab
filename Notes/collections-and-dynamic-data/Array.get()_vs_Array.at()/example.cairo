#[executable]
fn main() {
    ////////////////////////////////////
    ///   Using Array.at()           ///
    ////////////////////////////////////

    let mut array: Array<felt252> = ArrayTrait::new();
    array.append(12);
    array.append(13);
    array.append(14);

    let mut i = 0;

    loop {
        // `.at(i)` assumes the index is valid.
        // If `i` ever goes out of bounds, the program panics immediately.
        if i < 3 {
            println!("at(): {}", *array.at(i));
        } else {
            break;
        }

        i = i + 1;
    }

    ////////////////////////////////////
    ///   Using Array.get()          ///
    ////////////////////////////////////

    let mut j = 0;

    loop {
        match array.get(j) {
            // `get(j)` safely returns an Option
            Some(value) => {
                println!("get(): {}", *value);
                j = j + 1;
            },

            // When the index is out of bounds, we get `None`
            // instead of a panic, so we can handle it explicitly.
            None => {
                println!("out of bounds");
                break;
            },
        }
    }
}
