# Repaired contract notes

- The original checker compares each case against a real-valued 50-iteration Newton solver and also checks `|p(root)| <= EPSILON`.
- Cases 6, 13, and 35 cannot satisfy both checks simultaneously under the released 16-bit Q8.8 fixed-point contract.
- Case 6 uses a polynomial with no real root, so the real Newton iterate does not have a near-zero residual.
- Case 13 is the constant polynomial `p(x)=1`, so the residual check cannot pass for any root.
- Case 35's real Newton iterate is not within the residual tolerance under Q8.8 rounding.
- This fixture keeps all root-comparison checks and all satisfiable residual checks, but marks those three residual checks as `SKIP_REPAIRED_CONTRACT` without `[PASS]` or `[FAIL]` tokens.
- The original source benchmark is unchanged.
