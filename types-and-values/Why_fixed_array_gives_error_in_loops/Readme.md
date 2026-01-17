

# Fixed-size Arrays vs Dynamic Arrays in Cairo

As you can see in the above code, Cairo treats **fixed-size arrays** and **dynamic arrays** very differently. This difference is the reason why looping and indexing work for one but not the other.

This README explains **why that happens**, in simple terms.

---

## Fixed-size Array (`[T; N]`)

```rust
let my_arr = [1, 2, 3, 4, 5];
```

Even though this looks like a normal array, in Cairo this is **not a runtime array**.

### What is really happening?

* Fixed-size arrays are **compile-time data**
* Their values are written directly into the program
* They are **not stored in memory**
* They do **not have indexes or offsets**

Because of this, Cairo **does not allow**:

* looping directly over them
* accessing elements using `my_arr[i]`

That’s why this gives an error:

```rust
while i < 5 {
    println!("{}", my_arr[i]); // Error
}
```

Here, `i` is known only at runtime, but fixed-size array elements exist only at compile time. Cairo cannot use a runtime value to select compile-time constants.

---

## Using `.span()` with Fixed-size Arrays

To loop over a fixed-size array, Cairo requires you to **explicitly expose it as runtime data** using `.span()`.

```rust
let span_array = my_arr.span();
```

What `.span()` does:

* Converts compile-time data into a **runtime read-only view**
* Does not allocate memory
* Makes indexing and looping allowed

Now this works:

```rust
let mut i = 0;
while i < span_array.len() {
    println!("{}", span_array[i]);
    i += 1;
}
```

---

## Dynamic Array (`Array<T>`)

```rust
let mut arr2: Array<u32> = array![1, 2, 4, 5];
```

Dynamic arrays are **real runtime data**.

### Why dynamic arrays work

* Their values exist during execution
* They are stored in the execution trace
* They support indexing, looping, and mutation

That’s why this works without any error:

```rust
while i < arr2.len() {
    println!("{}", arr2[i]); // Works
    i += 1;
}
```

You can also modify them:

```rust
arr2.append(3);
arr2.append(4);
arr2.append(6);
```

---

## Simple Rule to Remember

* **Fixed-size array** → compile-time → no direct indexing or looping
* **Span** → runtime view → indexing and looping allowed
* **Array<T>** → runtime memory → full indexing, looping, and mutation

---

## Final Takeaway

Cairo only allows looping and indexing on **runtime data**.
Fixed-size arrays are part of the program itself, not runtime memory.
That’s why `.span()` exists — to safely bridge compile-time data into runtime usage.

Once you understand this rule, Cairo’s behavior becomes predictable and consistent.

