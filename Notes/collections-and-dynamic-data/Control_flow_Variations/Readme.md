

## Cairo Control Flow — Practical Reference

This code demonstrates **all major Cairo control-flow constructs** in a single, well-commented example.

Cairo separates **boolean logic** from **data-shape logic**. This file exists to make that separation obvious and practical.

### What’s covered

**Boolean control flow**

* `if / else` → branch on true / false conditions
* `while` → loop while a boolean condition holds
* `loop` → explicit infinite loop with manual exit

**Pattern-based control flow**

* `match` → exhaustive handling of enum variants
* `if let` → act on one pattern, ignore the rest
* `while let` → loop while a pattern keeps matching
* `let else` → enforce invariants with early exit

### Why this matters

Most bugs in smart contracts come from:

* assuming a value exists
* assuming a state can’t happen
* handling “happy paths” only

Cairo’s control-flow model forces those assumptions to be written down explicitly, making the code easier to reason about and audit.



