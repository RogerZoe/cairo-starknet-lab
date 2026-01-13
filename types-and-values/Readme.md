# Types & Values 🔢

This folder studies how **values behave** in Cairo — not just how they are declared.

The goal is to understand:
- What a value really represents
- How mutability differs from ownership
- Where assumptions from other languages break

## What lives here
- Integer behavior and constraints
- Mutability vs reassignment
- Type-level guarantees
- Value passing semantics

## Typical questions explored
- Does mutability affect ownership?
- Are values copied or moved?
- What invariants does the type system enforce?

## Why this matters
Incorrect assumptions about values can lead to:
- Broken invariants
- Incorrect state transitions
- Silent logical errors in contracts
