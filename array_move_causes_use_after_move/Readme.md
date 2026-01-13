Question:
Are arrays copied when passed to a function?

Experiment:
Passing an Array to a function moves ownership. Reusing it causes a compile-time error.

Conclusion:
Arrays are moved by default. Cloning is explicit and has cost.

Security note:
Incorrect assumptions here can break invariants when arrays track balances or permissions.

