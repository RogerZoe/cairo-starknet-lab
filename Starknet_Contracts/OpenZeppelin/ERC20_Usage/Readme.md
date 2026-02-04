
# ERC20 Usage in Cairo: Dispatcher & Allowance Model

This folder documents **how a Cairo contract interacts with an ERC20 token**
using OpenZeppelin interfaces and dispatchers.

This is not inheritance.
This is **explicit cross-contract communication**.

---

## Core Concept

In Cairo, contracts **cannot call other contracts directly**.

Instead:
1. An interface defines the ABI
2. Cairo generates a Dispatcher
3. The dispatcher performs external calls

---

## What is a Dispatcher?

```rust
let token = IERC20Dispatcher { contract_address: STRK_TOKEN };
````

A dispatcher is a **typed handle** to an already deployed contract.

It:

* Knows the ERC20 ABI
* Encodes calldata
* Executes cross-contract calls safely

It does **not** store state or deploy anything.

---

## Why traits must be imported

In Cairo:

* Structs hold data
* Traits define behavior

```rust
use openzeppelin::interfaces::erc20::IERC20DispatcherTrait;
```

Without the trait in scope:

* Methods like `balance_of` do not exist
* The code fails to compile

---

## Allowance Mental Model (Important)

ERC20 allowance is always:

```
allowance[owner][spender]
```

In this example:

* `owner` = caller (user)
* `spender` = this contract

The user must approve the contract **before** calling `reset`.

```text
User → approves → Contract
Contract → pulls tokens → Owner
```

The user trusts the **contract logic**, not the owner directly.

---

## Why `get_contract_address()` is used

```rust
let this = get_contract_address();
```

The contract itself is the spender calling `transfer_from`.

Allowance must be granted to **this contract**, not to the owner.

---

## Execution Order (Security)

1. Balance check
2. Allowance check
3. Token transfer
4. State mutation
5. Event emission

State changes only occur **after payment succeeds**.

---

