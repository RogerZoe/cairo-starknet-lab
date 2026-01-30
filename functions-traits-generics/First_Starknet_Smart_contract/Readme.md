# Counter Contract – My First StarkNet Program

This is my first smart contract written in Cairo for StarkNet.

The goal of this project is to understand:
- StarkNet contract structure
- Storage and state updates
- Interfaces (ABI)
- Events and event emission
- Basic testing and debugging with snforge

---

## What This Contract Does

This contract implements a simple on-chain counter.

It allows:
- Reading the current number
- Incrementing the number by 1
- Decrementing the number by 1

Every time the counter changes, an event is emitted with:
- The caller’s address
- The previous value
- The new value
- The reason for the change (increment or decrement)

---

## Contract Structure

### Interface
The `Number` interface defines the public API of the contract:
- `get_number()`
- `increment()`
- `decrement()`

### Storage
The contract stores a single variable:
- `num: u16`

### Constructor
The constructor runs once at deployment and initializes the counter.

### Events
The `CounterChanged` event is emitted whenever the counter value changes.
It helps off-chain tools and indexers track state changes.

---

## Why I Built This

This project is part of my learning journey into:
- StarkNet
- Cairo
- Smart contract security and auditing

The focus is on understanding fundamentals rather than building a production-ready app.

---

## Tools Used

- Cairo
- StarkNet
- snforge (for testing)
- StarkNet events and ABI system

---

## Notes

- This contract does not include advanced safety checks (like underflow protection).
- It is meant for learning purposes.
- Improvements and tests will be added as I learn more.

---

## Status

🚧 Learning project  
✅ Compiles  
✅ Emits events  
🧪 Tests in progress

