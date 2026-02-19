
# Cairo · StarkNet Lab 🧪⚡

A public research lab for understanding **Cairo** and **StarkNet** from first principles.

This repository is **not** a tutorial.
It is a collection of **questions, experiments, and conclusions** that emerged while learning how StarkNet actually works — especially from a **security and auditing perspective**.

---

## 🧠 Philosophy

Most bugs come from **wrong assumptions**, not bad syntax.

This repo exists to:
- challenge assumptions
- test behaviors with minimal code
- document what *actually* happens
- separate **execution guarantees** from **logic correctness**

Each folder contains **small, focused experiments** answering one concrete question.

---

## 📂 Repository Structure

```

cairo-starknet-lab/
├── DEFI/
├── Notes/
├── Security/
├── Starknet_Contracts/

```
DEFI
Create Readme.md
2 days ago
Notes
Starknet-Notes
2 minutes ago
Security
Create Readme.md
now
Starknet_Contracts

Each top-level folder represents a **risk domain** — areas where misunderstandings can lead to bugs, failed invariants, or flawed audits.

---

## 🔍 What You’ll Find Inside

- Minimal Cairo programs (often intentionally small)
- Failing examples with explanations
- Short READMEs answering:
  - *What was the question?*
  - *What was tested?*
  - *What was learned?*
- Security-oriented observations where relevant

No boilerplate. No copy-paste notes.

---

## 🧪 Folder Overview

###  `execution-and-proofs`
How StarkNet executes programs and what STARK proofs **do and do not** guarantee.

> Proofs verify execution — not business logic.

---

###  `types-and-values`
How values behave in Cairo:
mutability, reassignment, and type-level assumptions.

> Mutability ≠ ownership.

---

###  `collections-and-dynamic-data`
Arrays, structs, tuples — and the hidden complexity inside composite data.

> Most protocol state lives here. So do most mistakes.

---

###  `ownership-and-memory`
Ownership rules, move semantics, and Cairo’s memory safety model.

> Many “logic bugs” start as ownership misunderstandings.

---

###  `functions-traits-generics`
Abstractions, traits, and generics — and how they affect reasoning and audits.

> Abstraction hides complexity. This folder exposes it.

---

###  `testing-and-failure-modes`
How Cairo programs fail:
panic, Result, test behavior, and execution halting.

> Auditing is about failure paths, not happy paths.

---

## 🧠 How to Read This Repo

This repo is **not linear**.
You don’t read it top to bottom.

Instead:
- Pick a folder
- Open a subfolder
- Read the question
- Look at the experiment
- Read the conclusion

That’s the intended flow.

---

## 🧩 Why This Exists (Security Perspective)

STARK proofs change *who* verifies execution — not *what* is correct.

Logical correctness, invariants, and assumptions:
- still require human reasoning
- still require audits
- still fail silently if misunderstood

This repo is training ground for that reasoning.

---

> “If an assumption feels obvious, it probably deserves an experiment.”
```
