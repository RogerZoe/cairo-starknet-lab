

# Starknet L1 ↔ L2 Interoperability Security Notes

This document summarizes common vulnerabilities and pitfalls in Starknet L1 ↔ L2 messaging systems, especially relevant for bridge and cross-layer protocol audits.

---

# 1. Invalid L1 → L2 Address Conversion

## Problem

Ethereum addresses are `uint160`.
Starknet addresses are `felt252` (field elements).

If a `uint256` sent from L1 is ≥ Starknet field prime, it will wrap modulo `p`, causing silent corruption.

## Vulnerable L1 Code

```solidity
function deposit(uint256 to, uint256 amount) external {
    token.transferFrom(msg.sender, address(this), amount);

    messaging.sendMessageToL2(
        l2Address,
        selector,
        [to, amount]
    );
}
```

No validation on `to`.

## Secure Version

```solidity
uint256 constant STARKNET_FIELD_PRIME =
    0x800000000000011000000000000000000000000000000000000000000000001;

function deposit(uint256 to, uint256 amount) external {
    require(to > 0 && to < STARKNET_FIELD_PRIME, "invalid address");

    messaging.sendMessageToL2(
        l2Address,
        selector,
        [to, amount]
    );
}
```

Always ensure values fit inside Starknet’s field.

---

# 2. L1 → L2 Message Not Processed

## Problem

Messages are not executed immediately.
They are processed later by the sequencer.

If not processed (bug, gas spike, revert), funds may be stuck.

## Cancellation Mechanism

```solidity
starknetMessaging.startL1ToL2MessageCancellation(...);

// wait 5 days

starknetMessaging.cancelL1ToL2Message(...);
```

Always design bridges with cancellation or refund logic.

---

# 3. Not Enough Wei for L1 → L2 Communication

## Problem

`sendMessageToL2()` requires ETH to cover storage and execution.

If insufficient `msg.value`, transaction reverts.

## Correct Usage

```solidity
function deposit(uint256[] calldata payload) external payable {
    require(msg.value >= 20000 wei, "insufficient fee");

    messaging.sendMessageToL2{value: msg.value}(
        l2Address,
        selector,
        payload
    );
}
```

Fee must scale with payload size in production systems.

---

# 4. Wrong Serialization in L1 → L2 Messages

## Problem

Cairo uses `felt252`. Solidity uses `uint256`.

Cairo `u256` = two felts (low, high).

## Cairo Side

```rust
#[l1_handler]
fn deposit(
    ref self: ContractState,
    from_address: felt252,
    user: felt252,
    amount: u256
) {}
```

## Correct Solidity Serialization

```solidity
function split(uint256 value)
    internal pure
    returns (uint256 low, uint256 high)
{
    low = uint128(value);
    high = value >> 128;
}

(uint256 low, uint256 high) = split(amount);

uint256;
payload[0] = user;
payload[1] = low;
payload[2] = high;
```

Wrong serialization causes silent corruption.

---

# 5. L2 Function Not Callable From L1

## Problem

Only functions marked with `#[l1_handler]` can be triggered from L1.

They must include `from_address`.

## Correct L2 Function

```rust
#[l1_handler]
fn deposit(
    ref self: ContractState,
    from_address: felt252,
    user: felt252,
    amount_low: felt252,
    amount_high: felt252
) {}
```

Also remember:

* Solidity selector = first 4 bytes of keccak
* Starknet selector = Pedersen hash of function name (no types)

Selectors are different systems.

---

# 6. L1 → L2 Caller Not Validated

## Problem

Validating caller only on L1 is not enough.

Anyone can directly call `sendMessageToL2()`.

## Vulnerable L2 Code

```rust
#[l1_handler]
fn set_owner_from_l1(
    ref self: ContractState,
    from_address: felt252,
    new_owner: ContractAddress
) {
    self.owner.write(new_owner);
}
```

No validation of `from_address`.

## Secure Version

```rust
const TRUSTED_L1: felt252 = 0x1234;

#[l1_handler]
fn set_owner_from_l1(
    ref self: ContractState,
    from_address: felt252,
    new_owner: ContractAddress
) {
    assert(from_address == TRUSTED_L1, 'unauthorized');
    self.owner.write(new_owner);
}
```

Always validate `from_address`.

---

# 7. L2 Message Not Consumed on L1

## Problem

L2 → L1 messages must be manually consumed.

If not consumed, funds remain locked.

## L2 Send

```rust
send_message_to_l1_syscall(
    l1Address,
    payload.span()
);
```

## L1 Consume

```solidity
function withdraw(uint256 fromAddress, uint256[] calldata payload) external {
    messaging.consumeMessageFromL2(fromAddress, payload);

    // safe to process
}
```

`consumeMessageFromL2()` ensures:

* Message exists
* Not already consumed
* Caller is intended recipient

Without consumption → no execution.

---

# 8. Overconstrained L1 ↔ L2 Interaction

## Problem

L2 allows action.
L1 rejects it.

If L2 burns tokens and L1 reverts, funds are lost.

## Vulnerable Pattern

L2:

```rust
self.balances.write(user, 0);
send_message_to_l1_syscall(...);
```

L1:

```solidity
require(recipient != address(0), "invalid");
```

If recipient = 0:

* L2 burns
* L1 reverts
* Funds gone

## Fix

Mirror constraints on L2:

```rust
assert(recipient != 0, 'invalid recipient');
```

Always enforce receiving layer constraints on sending layer.

---

