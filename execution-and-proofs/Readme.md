# Execution & Proofs 🧠⚡

This folder explores how Cairo programs are **executed**, **proven**, and **verified** in StarkNet.

The focus here is not syntax, but **mental models**:
- What the STARK proof actually guarantees
- What correctness means in a provable execution system
- What *is not* protected by proofs (logic bugs, broken invariants)

## What lives here
- Questions about provable programs
- Execution flow (DECLARE / INVOKE)
- Determinism and address predictability
- Panic behavior and execution halting
- Why L1 can verify without re-executing code

## What does NOT live here
- Language syntax
- Data structures
- Ownership rules

## Why this matters
Understanding execution guarantees is critical for:
- Designing correct protocols
- Auditing StarkNet contracts
- Avoiding false security assumptions based on proofs
