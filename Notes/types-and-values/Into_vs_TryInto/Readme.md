# Type Conversions in Cairo: `Into` vs `TryInto`

This example shows why Cairo has **two different ways** to convert types.

## Why Type Conversion Exists in Cairo

Cairo is a **strict and safety-focused language**.
It never guesses how to convert values and never silently changes data.

So Cairo asks one simple question:

> **Can this conversion ever fail?**

Based on the answer, Cairo uses either `Into` or `TryInto`.

---

## `Into` — Safe Conversions (Smaller → Bigger)

Use `Into` when:

* the target type is **larger**
* the value will **always fit**
* no data can be lost

Example:

```rust
let x: u8 = 255;
let y: u16 = x.into();
let z: u32 = y.into();
```

Why this is safe:

* `u16` can hold all `u8` values
* `u32` can hold all `u16` values
* Cairo guarantees no overflow

`Into` never fails and has no runtime cost.

---

## `TryInto` — Risky Conversions (Bigger → Smaller)

Use `TryInto` when:

* the target type is **smaller**
* overflow is possible
* conversion might fail

Example:

```rust
let x1: felt252 = 12334;
let y1: u8 = x1.try_into().unwrap();
```

Why this can fail:

* `felt252` can store very large numbers
* `u8` can only store values up to `255`
* `12334` does not fit into `u8`

So Cairo **panics instead of silently truncating**.

---

## Why `TryInto` Returns `Option<T>`

`try_into()` returns:

* `Some(value)` if conversion succeeds
* `None` if conversion fails

Calling `.unwrap()` means:

> “I am sure this value fits. Crash if I’m wrong.”

This makes assumptions **explicit and auditable**.

---

## Why Cairo Needs Both

If Cairo had only one conversion method:

* it would either silently truncate (dangerous)
* or always panic (unusable)

Instead, Cairo forces you to be explicit:

| Conversion Type | Method    |
| --------------- | --------- |
| Always safe     | `Into`    |
| Might fail      | `TryInto` |

---

## Simple Rule to Remember

* **Smaller → Bigger** → `Into`
* **Bigger → Smaller** → `TryInto`

This rule works in almost all cases.
