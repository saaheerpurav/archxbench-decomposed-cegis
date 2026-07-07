# Repaired contract status

- HOLD: no principled repaired executable contract is generated yet.
- The shipped golden file is a dict with `real_out` and `imag_out` arrays, while the testbench writes a list of objects with `real` and `imag` fields.
- The shipped comparator is copied from a scalar filter benchmark and cannot compare the FFT output structure correctly.
- The input contract is also ambiguous: stimuli are JSON floats / FP32 hex words, while the testbench uses `$fscanf("%d %d")` into 16-bit signed ports.
- Repairing only the output schema would still leave an unspecified numeric encoding for the inputs, so this row is held rather than patched to fit the golden file.
- The original source benchmark is unchanged.
