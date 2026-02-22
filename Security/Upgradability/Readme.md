

# 📘 Proxy Pattern in Starknet

## Overview

The Proxy Pattern separates:

* **Storage** → lives in the proxy
* **Logic** → lives in implementation contracts

Users interact only with the **proxy address**.

The proxy forwards calls to the current implementation using:

```
library_call_syscall
```

This is Starknet’s equivalent of `delegatecall` in Solidity.

---

## How It Works

Execution flow:

```
User
  ↓
Proxy Contract
  ↓ (library_call_syscall)
Implementation Logic
```

Important:

* Storage used is the proxy’s storage
* Implementation contract has no independent storage
* Upgrading means changing the implementation class hash inside proxy

---

## Key Mechanism

Proxy contains:

* `implementation: ClassHash`
* `admin: ContractAddress`
* `__default__` forwarding function
* `upgrade()` function

Forwarding happens inside `__default__`:

```
library_call_syscall(class_hash, selector, calldata)
```

This executes implementation logic in proxy’s storage context.

---

## Upgrade Flow

1. Deploy Implementation V1
2. Deploy Proxy with V1 class hash
3. Users interact with proxy
4. Admin updates implementation class hash
5. Proxy forwards calls to new logic
6. Storage remains unchanged

---

## Risks

* Storage layout mismatch breaks state
* Incorrect forwarding breaks ABI
* Missing access control allows malicious upgrades
* Selector collisions

---

## When To Use Proxy Pattern

Rare in Starknet.

Starknet provides **native upgradeability** via class replacement.

Proxy pattern is mostly used when:

* Porting Ethereum architecture
* Building advanced meta-contract systems
* Studying delegate-style behavior

---


