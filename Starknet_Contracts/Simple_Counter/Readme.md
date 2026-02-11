
# 🧮 Starknet Counter – Cairo + Foundry Testing

A simple but security-focused Counter contract built in Cairo for Starknet, fully tested using Foundry (snforge).

This project goes beyond a basic counter. It includes:

* Access control using OpenZeppelin Ownable
* Event emission with structured reasons
* ERC20 payment logic (STRK) for resetting the counter
* Full unit & integration testing with snforge
* Caller simulation using cheatcodes
* Balance + allowance validation testing

The goal of this project is to deeply understand Starknet contract execution, caller context, and testing patterns — not just write passing tests.

---

## 🏗 Contract Overview

### Features

* Initialize counter with custom value
* Increase / Decrease counter
* Owner-only `set_counter`
* Paid `reset_counter`:

  * Requires 1 STRK payment
  * Validates balance
  * Validates allowance
  * Transfers STRK to owner
  * Emits structured event

---

## 📦 Architecture

* `counter.cairo` → Core contract logic
* `utils.cairo` → STRK address & helper conversions
* `tests/` → Integration tests using snforge
* OpenZeppelin Ownable component
* ERC20 interaction via `IERC20Dispatcher`

---

## 🧪 Testing Strategy

Tests simulate real Starknet behavior using:

* `declare` and `deploy`
* Generated dispatchers
* `spy_events()` to assert emitted events
* `start_cheat_caller_address()` to simulate msg.sender
* `set_balance()` to mock STRK balances

### Test Coverage Includes

* ✅ Constructor initialization
* ✅ Increase / Decrease logic
* ✅ Underflow protection
* ✅ Owner-only access control
* ✅ Non-owner rejection
* ✅ Insufficient balance failure
* ✅ Missing allowance failure
* ✅ Successful reset with ERC20 transfer
* ✅ Event validation for every state change

This project ensures both **state correctness** and **economic correctness**.

---

## 🔐 Security Concepts Demonstrated

* Caller alignment (balance + allowance must match caller)
* Access control enforcement
* Underflow protection
* Event integrity
* External contract interaction safety
* Economic flow validation

---

## 🚀 Running Tests

```bash
snforge test
```

Run specific test:

```bash
snforge test <test_name>
```

---

## 🧠 What This Project Teaches

* How Starknet handles caller context
* Why dispatcher + trait imports matter
* How calldata & constructor serialization works
* How ERC20 approvals interact with contracts
* Why testing reveals logic flaws early

Testing here is not just verification — it’s simulation of real Starknet execution physics.

---



