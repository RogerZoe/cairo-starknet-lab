# Collections & Dynamic Data 📦

This folder focuses on **composite data structures** and how they behave under Cairo’s rules.

Dynamic data is where most real-world complexity appears.

## What lives here
- Arrays
- Structs
- Tuples
- Composite ownership behavior

## Typical questions explored
- Are arrays copied or moved?
- How ownership flows through structs
- Hidden costs of cloning
- Composite types and safety assumptions

## Why this matters
Most protocol state lives inside collections.
Misunderstanding their behavior can:
- Break accounting logic
- Enable subtle bugs
- Increase audit risk

