# Repaired contract notes

- The original testbench loaded coefficients through `dut.coeffs[j]`, which assumes a hidden internal DUT memory name not present in the public module interface.
- This fixture removes the hierarchical coefficient write. The DUT must hard-code the coefficient set listed in the testbench/spec.
- The file-output JSON writer is repaired so commas depend on actual `valid_out` writes instead of loop indices.
- The generic runner now compares 32-bit hex JSON outputs as IEEE-754 floats with the benchmark's +/-1.0 tolerance.
- The original source benchmark is unchanged.
