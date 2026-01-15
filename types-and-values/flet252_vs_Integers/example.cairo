fn main() {
    // StarkNet prime P:
    // P = 2^251 + 17 * 2^192 + 1
    // We don't need the exact value, just that it exists.

    // Simulate "near the maximum" value
    let max = felt252::MAX; // P - 1

    // -----------------------------
    // ADDITION (OVERFLOW)
    // -----------------------------
    // Expected (integer intuition):
    // (P - 1) + 1 = P
    //
    // Actual (felt252):
    // P ≡ 0 (mod P)
    let add = max + 1;
    println!("(P-1) + 1 = {}", add); // ❌ prints 0 (WRONG)

    // -----------------------------
    // SUBTRACTION (UNDERFLOW)
    // -----------------------------
    // Expected (integer intuition):
    // 0 - 1 = -1
    //
    // Actual (felt252):
    // -1 ≡ P - 1 (mod P)
    let sub = 0 - 1;
    println!("0 - 1 = {}", sub); //  prints HUGE number (WRONG)

    // -----------------------------
    // MULTIPLICATION (WRAPAROUND)
    // -----------------------------
    // Expected (integer intuition):
    // (P - 1) * 2 = 2P - 2
    //
    // Actual (felt252):
    // 2P - 2 ≡ P - 2 (mod P)
    let mul = max * 2;
    println!("(P-1) * 2 = {}", mul); //  WRONG

    // -----------------------------
    // DIVISION (BLOCKED)
    // -----------------------------
    // Expected (integer intuition):
    // 1 / 2 = 0
    //
    // Actual (felt252):
    // 1 / 2 = inverse(2) = (P + 1) / 2 (HUGE)
    //
    // Cairo REFUSES to compile this to prevent silent bugs.
    //
    // println!("{}", 1 / 2); //  compile-time error
}
