# Repaired contract notes

- This design is copied into the repaired root for audit completeness, but it is intentionally not marked runnable yet.
- The original testbench references `inputs/stimuli_fp.json` and `outputs/lowpass_out_fp.json`, while the shipped files are `inputs/stimuli.json` and `outputs/golden_output.json`.
- Unlike the band/high-pass FP FIRs, the coefficient list is not present in the testbench.
- Do not run or claim this row until the coefficient oracle is recovered from an upstream source or independently validated.
- The original source benchmark is unchanged.
