fn main() {

////////////////////////////////////////////////////////
//                   felt252                          //
////////////////////////////////////////////////////////


    // Default type is felt252
    let a = 123;
    let b = 140;

    // SUBTRACTION
    // Expected (integer intuition): 123 - 140 = -17
    // Actual (felt252): wraps modulo P → HUGE positive number
    println!("a - b (felt252) = {}", a - b);

    // ADDITION
    // Expected (integer intuition): 123 + 140 = 263
    // Actual (felt252): works here, BUT can silently overflow near P
    println!("a + b (felt252) = {}", a + b);

    // MULTIPLICATION
    // Expected (integer intuition): 123 * 140 = 17220
    // Actual (felt252): works here, BUT can silently wrap modulo P
    println!("a * b (felt252) = {}", a * b);

    // DIVISION
    // Expected (integer intuition): 1 / 2 = 0
    // Actual (felt252): undefined for humans
    // Cairo PREVENTS this by refusing to compile
    println!("{}", 1 / 2); //  compile-time error


////////////////////////////////////////////////////////
//                   Integers                         //
////////////////////////////////////////////////////////
    // Explicitly declare u32 types 
    let c: u32 = 123;
    let d: u32 = 140;

    
    // ADDITION
    // For u32: 123 + 140 = 263  Works fine (within u32 range)
    // But: u32 also panics on overflow (MAX = 4,294,967,295)
    println!("c + d (u32) = {}", c + d);

    // MULTIPLICATION  
    // For u32: 123 * 140 = 17,220  Works fine (within u32 range)
    // But: u32 also panics on overflow if result > MAX
    println!("c * d (u32) = {}", c * d);
    
    // SUBTRACTION
    // For u32: 123 - 140 =  PANIC at runtime (underflow)
    // u32 types have overflow/underflow protection!
    println!("c - d (u32) = {}", c - d); //  This will panic!

    // DIVISION
    // For u32: 123 / 140 = 0  Integer division (truncates)
    // Note: Division by zero also panics
    println!("c / d (u32) = {}", c / d); // Outputs 0

}
