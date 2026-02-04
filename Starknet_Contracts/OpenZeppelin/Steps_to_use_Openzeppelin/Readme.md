
# Using OpenZeppelin Components in Cairo (StarkNet)

This folder documents **how to correctly use OpenZeppelin components in Cairo**, using
`OwnableComponent` as a concrete example.

The goal is learning correctness, not production complexity.

---

## Why OpenZeppelin in Cairo is different

Cairo does **not** use inheritance like Solidity.
Instead, it uses **components** that must be explicitly wired into a contract.

Nothing is automatic.
Every step encodes intent.

---

## Mandatory Steps (in order)

### 1. Import the component
```rust
use openzeppelin::access::ownable::OwnableComponent;
````

---

### 2. Attach the component

```rust
component!(
    path: OwnableComponent,
    storage: ownable,
    event: OwnableEvent,
);
```

This binds the component’s logic, storage, and events to the contract.

---

### 3. Embed ABI and internal implementation

```rust
#[abi(embed_v0)]
impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
```

* ABI impl → exposes public functions
* Internal impl → enables internal guards like `assert_only_owner`

---

### 4. Add substorage

```rust
#[substorage(v0)]
ownable: OwnableComponent::Storage,
```

Each component owns isolated storage.
No implicit slot sharing.

---

### 5. Initialize in constructor

```rust
self.ownable.initializer(owner);
```

Components are **not auto-initialized**.
Skipping this causes runtime failures.

---

### 6. Use the component

```rust
self.ownable.assert_only_owner();
```

Ownership only works if explicitly enforced.

---

## Example Contract

`ownable_counter.cairo` demonstrates:

* an Ownable counter
* restricted setter function
* event emission
* correct OpenZeppelin wiring

---


