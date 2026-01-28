

###  Generics and Traits in Cairo

Generics allow us to write reusable code that works with **multiple types**, while traits define **what operations those types must support**.

Together, they let Cairo enforce correctness **at compile time**, without runtime checks.

---

###  Generics

A generic type is a **placeholder for a concrete type**.

```rust
fn example<T>(value: T) -> T {
    value
}
```

Here, `T` can be `u8`, `u16`, `felt252`, or any other type.

The compiler will generate a **separate concrete version** of the function for each type used (this is called *monomorphization*).

---

###  Why Traits Are Needed

Generic types are **unknown** to the compiler.

If a function:

* compares values (`>`)
* copies values (`*`)
* drops values at the end of scope

then the compiler must be told that the generic type supports these operations.

This is done using **trait bounds**.

---

### 🔹 Trait Bounds Example

```rust
fn largest<T, +PartialOrd<T>, +Copy<T>, +Drop<T>>(ref list: Array<T>) -> T
```

This means:

* `T` must support comparison (`PartialOrd`)
* `T` must be copyable (`Copy`)
* `T` must be droppable (`Drop`)

Each trait bound directly corresponds to an operation used inside the function.

---

###  Key Takeaways

* **Generics remove code duplication**
* **Traits enforce behavior contracts**
* **Every operation on `T` must be justified by a trait**
* **Cairo never guesses — everything must be explicit**
* **Generic code is safe, predictable, and auditable**

---

###  Mental Model

> Generics define *what varies*
> Traits define *what is allowed*
> The compiler enforces everything

