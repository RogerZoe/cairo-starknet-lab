

# 📘 Upgradeability in Starknet (OpenZeppelin Approach)

## Why We Usually Don’t Use Proxy Patterns in Starknet

If you come from Solidity, your brain expects:

```
User → Proxy → delegatecall → Implementation
```

Because on Ethereum:

* Contract bytecode is immutable
* Storage lives at the proxy
* delegatecall is required to preserve state

But Starknet is architecturally different.

### 🔬 Starknet Has Native Upgradeability

In Starknet:

Each deployed contract instance stores:

* Contract storage
* A class hash (pointer to code)

Upgrading a contract is simply:

```
Replace class hash
```

That’s done using:

```
replace_class_syscall
```

This means:

* Address stays the same
* Storage stays the same
* Only logic changes

No delegatecall.
No fallback forwarding.
No proxy storage juggling.

---

## Why Proxy Pattern Is Rarely Used in Starknet

Proxy patterns in Starknet introduce unnecessary complexity:

| Problem             | Why It’s Risky                    |
| ------------------- | --------------------------------- |
| Fallback forwarding | ABI mismatch issues               |
| Selector forwarding | Manual selector handling          |
| Storage duplication | Proxy + implementation layouts    |
| More attack surface | Forwarding bugs, selector clashes |

Since Starknet gives us native upgrade support, proxy patterns are usually avoided.

OpenZeppelin Cairo contracts also use the native upgrade model.

---

# 🏗 How OpenZeppelin Upgradeability Works

OpenZeppelin provides:

```
UpgradeableComponent
```

Which wraps:

* replace_class_syscall
* Zero class hash protection
* Upgrade event emission
* Clean integration with Ownable

---

# Step-by-Step: Using OpenZeppelin Upgradeable Component

---

## 1️⃣ Install Dependencies

In `Scarb.toml`:

```toml
openzeppelin = "x.x.x"
openzeppelin_upgrades = "x.x.x"
```

(Use latest compatible version.)

---

## 2️⃣ Create an Upgradeable Contract

```rust
#[starknet::contract]
mod UpgradeableCounter {

    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use starknet::{ClassHash, ContractAddress};

    // Attach components
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,

        value: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
    }

    #[external(v0)]
    fn set(ref self: ContractState, new_value: u256) {
        self.value.write(new_value);
    }

    #[external(v0)]
    fn get(self: @ContractState) -> u256 {
        self.value.read()
    }

    #[abi(embed_v0)]
    impl UpgradeImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {

            // Restrict upgrade to owner
            self.ownable.assert_only_owner();

            // Perform native class replacement
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}
```

---

# What Happens Internally

When `upgrade()` is called:

1. Ownership is verified
2. new_class_hash is validated (non-zero)
3. replace_class_syscall executes
4. Upgraded event is emitted

Storage remains untouched.

---

# 🔁 How You Deploy and Upgrade (Workflow)

### Deploy V1

```
Deploy UpgradeableCounter with owner
```

### Declare V2

```
declare("UpgradeableCounterV2")
```

### Upgrade

```
upgrade(new_class_hash)
```

Address remains same.
Logic changes.
Storage preserved.

---

# 🧠 What You Must Be Careful About

Upgrade safety depends entirely on storage compatibility.

### ⚠️ Dangerous Changes

* Renaming storage variable
* Changing storage type
* Reordering struct fields incorrectly
* Removing variables
* Reusing substorage incorrectly

Example of breaking upgrade:

```rust
value: u256
```

Changed to:

```rust
counter_value: u256
```

Storage key changes → old data becomes inaccessible.

---

# 🔐 What You Should Always Implement

* Ownable or role-based upgrade control
* Zero hash check
* Upgrade event emission
* Backwards-compatible storage layout

Never allow arbitrary upgrades.

---

# 🧪 How You Test Upgrade

You should test:

1. Storage before upgrade
2. Upgrade execution
3. Storage after upgrade
4. New logic behavior
5. Access control enforcement
6. Broken upgrade scenario

---

# 🧭 When To Use Proxy Pattern Instead?

Almost never in Starknet.

Possible cases:

* Cross-system architecture mirroring Ethereum
* Experimental meta-contract systems
* Very custom dispatch logic

For normal upgradeable contracts:

Use native replace_class + OpenZeppelin.

---

# 🎯 What You Do In Coding Practice

When building upgradeable contracts:

1. Start with V1
2. Define storage carefully
3. Add Ownable
4. Add UpgradeableComponent
5. Write tests for upgrade
6. Create V2 with same storage layout
7. Simulate upgrade
8. Add regression tests

Always think:

> If I upgrade this, will old storage still map correctly?

---

# 🧠 Mental Model Summary

Ethereum:
Proxy required.

Starknet:
Class hash replacement is built-in.

OpenZeppelin:
Wraps native syscall safely.

Upgrade safety = storage compatibility + access control.

---

# 📌 Final Takeaway

In Starknet:

Upgrade is not about forwarding calls.

Upgrade is about preserving storage invariants.

If storage remains consistent,
upgrade is safe.

If storage changes incorrectly,
state corruption is silent.

That’s the real risk.

---
