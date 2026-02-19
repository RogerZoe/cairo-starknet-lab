# Ownership & Memory 🧬

This folder explores Cairo’s **memory model** and **ownership rules**.

The emphasis is on:
- Why rules exist
- What errors they prevent
- How ownership flows through code

## What lives here
- Ownership rules
- Move semantics
- Double free scenarios
- Stack vs heap misconceptions
- Snapshots and references

## Typical questions explored
- Why does this fail at compile time?
- What exactly is being moved?
- How does Cairo prevent memory unsafety?

## Why this matters
Ownership mistakes are often logic mistakes.
Understanding memory behavior early:
- Simplifies audits
- Prevents unsafe patterns
- Improves reasoning about state

