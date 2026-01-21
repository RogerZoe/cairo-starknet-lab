#[derive(Copy, Drop)]
struct MyStruct {
    name: felt252,
    age: felt252,
    height: felt252,
    Gender: felt252,
}

#[derive(Copy, Drop)]
struct MyStruct_2 {
    name: ByteArray,
    age: felt252,
    height: felt252,
    Gender: felt252,
}

#[executable]
fn main() {
    /////////////////////////////////
    /// Struct with only Copy fields
    /////////////////////////////////

    let user = MyStruct { name: 'Glare', age: 25, height: 180, Gender: 'F' };
    println!("{}", user.Gender);

    // All fields are Copy, so accessing them does NOT move ownership
    let user2 = MyStruct { name: user.name, age: 23, height: 152, Gender: user.Gender };
    let user3 = MyStruct { name: user.name, age: 23, height: 152, Gender: user.Gender };

    assert(user.name == user2.name, 'user and user2 names differ');
    assert(user2.name == user3.name, 'user2 and user3 names differ');

    /////////////////////////////////////////
    /// Struct containing a non-Copy field
    /////////////////////////////////////////

    let user = MyStruct_2 { name: "Glare", age: 25, height: 180, Gender: 'F' };
    println!("{}", user.Gender);

    // `ByteArray` is NOT Copy, so accessing `user.name` moves ownership
    let user2 = MyStruct_2 { name: user.name, age: 23, height: 152, Gender: user.Gender };

    // The following would fail because `user.name` was already moved above
    // let user3 = MyStruct_2 { name: user.name, age: 23, height: 152, Gender: user.Gender };

    // These comparisons also fail because `user` is partially moved
    // assert(user.name == user2.name, 'user and user2 names differ');
}
