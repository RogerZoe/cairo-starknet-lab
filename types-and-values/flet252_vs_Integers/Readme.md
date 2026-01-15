


# `felt252` vs Integers in Cairo 

As you can see in the code above, **the same arithmetic behaves very differently** depending on whether you use `felt252` (default) or integer types (`u32`, `u128`, `u256`).

This difference is **one of the most common sources of Cairo bugs**.

---

## What `felt252` really means

* `felt252` is a **field element**, not an integer
* All arithmetic is done **modulo a large prime `P`**
* Operations **never fail**
* Overflow and underflow **silently wrap**
* Results are mathematically valid, but often **logically wrong**

### Consequences (from the code above)

* `a - b` → becomes a **huge positive number**, not negative
* `a + b` → works until it silently wraps near `P`
* `a * b` → works until it silently wraps
* `a / b` → **blocked by the compiler** to prevent silent misuse

 **No panic, no revert, still provable**

---

## What integer types (`u32`, `u128`, `u256`) guarantee

* Values are **bounded**
* Overflow and underflow **panic instead of lying**
* Division behaves like **normal integer division**
* Invalid arithmetic **cannot be proven**

### Consequences (from the code above)

* `a - b` → **runtime panic** (underflow)
* `a + b`, `a * b` → safe within bounds
* `a / b` → truncates (`123 / 140 = 0`)
* Division by zero → panic

**Fail fast instead of failing silently**

---

## Security rule of thumb 

Use **integer types** for:

* balances
* amounts
* counters
* fees
* indexes
* timestamps
* anything with bounds or ordering

Use **felt252** for:

* hashes
* signatures
* selectors
* addresses
* calldata
* cryptographic values
* opaque identifiers

---

## One-line summary

```text
felt252 proves math.
integers protect intent.
```

This distinction alone will save you from **entire classes of Cairo vulnerabilities**.

