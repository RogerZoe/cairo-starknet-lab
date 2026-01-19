

## `Array.at()` vs `Array.get()` in Cairo

This example demonstrates the **critical difference** between `Array.at()` and `Array.get()` when accessing array elements in Cairo.

The short version:

* **`at(index)`** → *panics immediately* if the index is out of bounds
* **`get(index)`** → returns `Option`, allowing graceful handling of out-of-bounds access

---

## Key Differences

| Method | Behavior | Return Type | Error Handling | Use Case |
|--------|----------|-------------|----------------|----------|
| **`.at(index)`** | Direct access | `&T` | **Panics** on out-of-bounds | When index is guaranteed valid |
| **`.get(index)`** | Safe access | `Option<&T>` | Returns `None` on out-of-bounds | When index might be invalid |

---

## Performance Notes

- **`.at()`**: Slightly faster (no `Option` wrapper, direct access)
- **`.get()`**: Minimal overhead (bounds check + `Option` creation)

In practice, the performance difference is negligible unless you're in extremely tight loops.

## Best Practices

1. **Use `.get()` when:**
   - Index comes from user input or external source
   - Index is calculated dynamically
   - You need graceful error handling
   - Writing library/framework code

2. **Use `.at()` when:**
   - Index is from a trusted range (e.g., loop counter)
   - You've already validated bounds
   - Performance is critical (proven by profiling)
   - Writing internal/private functions

3. **Always:**
   - Handle the `None` case when using `.get()`
   - Include bounds checks before using `.at()`
   - Prefer `for` loops with ranges for simple iteration

---

## Summary

- **`.at()` → "Crash on error"** - Use when you can guarantee index validity
- **`.get()` → "Handle the error"** - Use for defensive programming

Choose based on your error handling strategy and confidence in index validity.

