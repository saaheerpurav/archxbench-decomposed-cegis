# Repaired contract notes

- Original testbench printed expected and actual matrices but never emitted machine-readable `[PASS]` or `[FAIL]` checks.
- This fixture preserves the two original test cases: `A x A` for values 1..16 and `A x I` for values 0..15.
- The fixture turns the expected matrices already printed by the original testbench into 32 explicit output checks.
- The fixture removes the testbench-local `include` directive; the runner supplies the generated DUT as `systolic_matrix_mult.v`.
- The original source benchmark is unchanged.
