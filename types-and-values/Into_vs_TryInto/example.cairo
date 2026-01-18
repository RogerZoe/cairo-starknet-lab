#[executable]
fn main() {
    ///////////////////////////////////
    ///    INTO [SMALLER -> BIGGER ]///
    ///////////////////////////////////
    
    let x:u8=255;
    let y:u16=x.into();
    let z:u32=y.into();
    println!("{}",z); // Safe and secure conversion


    ///////////////////////////////////
    ///   TRYINTO [BIGGER-> SMALLER]///
    ///////////////////////////////////
    
    let x1:felt252=12334;
    let y1:u8=x1.try_into().unwrap();
    println!("{}",y1); // error: Panicked with 0x4f7074696f6e3a3a756e77726170206661696c65642e ('Option::unwrap failed.').

}
