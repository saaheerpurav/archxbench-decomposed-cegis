# Runs Left

This is the only run queue. It is derived from `artifacts/inventories/run_matrix_l3_l6.csv`.

Last audited: 2026-07-04 after the C4a weak-target sweep.

## Required For Current Claims

None.

The current claim rows in `docs/RESULTS.md` have repo-local artifacts and at least three clean seeds unless explicitly marked secondary.

## Matrix Status

### Complete Claim-Ready Rows

These have enough clean evidence for the current paper framing.

| Level | Design | Clean methods |
|---|---|---|
| L3 | `fp_adder` | `C4i` 3/3 |
| L3 | `fp_multiplier` | `C4i` 3/3 |
| L3 | `gauss_siedel` | `C4i` 3/3 |
| L3 | `gradient_descent` | `C4i` 3/3 |
| L3 | `newton_raphson_sqrt` | `C4i` 3/3 |
| L4 | `fft_16pt_iterative` | `C2g` 3/3, `C4tl` 5/5 |
| L4 | `fp_adder_pipeline` | `C1` 3/3, `C2g` 3/3, `C4i` 3/3, `C4tl` 5/5 |
| L4 | `fp_mult_pipeline` | `C1` 3/3, `C2g` 3/3, `C4i` 3/3, `C4tl` 5/5 |
| L4 | `ifft_16pt_iterative` | `C2g` 3/3, `C4tl` 5/5 |
| L5 | `conv1d` | `C1` 3/3, `C2g` 3/3, `C4i` 3/3 |
| L5 | `conv2d` | `C2g` 3/3 |
| L5 | `dct_idct_8pt_pipelined` | `C2g` 3/3 |
| L5 | `harris_corner_detection` | `C2g` 3/3, `C4i` 3/3 |
| L6 | `aes_decryption` | `C2g` 3/3, `C4i` 3/3 |
| L6 | `aes_encryption` | `C1` 3/3, `C2g` 3/3, `C4i` 3/3 |

### Partial Valid Results

These are real results, but not enough to present as robust method wins.

| Level | Design | Current status |
|---|---|---|
| L3 | `newton_raphson_polynomial` | no clean solve; best `C4i` is `89/100` |
| L5 | `unsharp_mask` | no clean solve; best `C2g` is `65535/65536` |
| L6 | `fft_streaming_64pt` | `C2g` seed `42` clean `128/128`; seeds `123,456` fail |
| L6 | `conv_3d` | no clean solve across `C1`, `C2g`, `C4i`, `C4tl` |
| L6 | `quantized_matmul` | no clean solve across `C1`, `C2g`, `C4i`, `C4tl` |

### Latest Targeted Research Attempt

`C4a` was run on all five weak targets with `gpt-5.5`, seeds `42,123,456`, under
`artifacts/raw_runs/adaptive_c4a_weak_targets_20260704/`.

Result: 0/15 solves.

| Design | C4a result |
|---|---|
| `unsharp_mask` | failed all three seeds; best `63780/65536` |
| `fft_streaming_64pt` | failed all three seeds; all `0/1` |
| `conv_3d` | failed all three seeds; all `0/0` |
| `quantized_matmul` | failed all three seeds; two `0/0`, one final compile failure |
| `newton_raphson_polynomial` | failed all three seeds; best `96/100`, no golden denominator |

Conclusion: C4a is negative evidence. Do not promote it as a method improvement.

### Excluded Or Hold

Do not blind-run these until the checker/spec issue is resolved.

| Level | Design | Reason |
|---|---|---|
| L4 | `band_pass_fir` | FIR benchmark/spec-contract caveat unresolved |
| L4 | `high_pass_fir` | FIR benchmark/spec-contract caveat unresolved |
| L4 | `low_pass_fir` | FIR benchmark/spec-contract caveat unresolved |
| L5 | `systolic_gemm` | no reliable golden evidence; native pass is not enough |
| L6 | `fp_band_pass_fir` | FIR benchmark/spec-contract caveat unresolved |
| L6 | `fp_high_pass_fir` | FIR benchmark/spec-contract caveat unresolved |
| L6 | `fp_low_pass_fir` | FIR benchmark/spec-contract caveat unresolved |
| L6 | `multich_conv2d` | benchmark loader/testbench issue; currently excluded |

## What Is Left To Run

No same-method, same-seed completion run is currently queued for the existing claims.

The only useful next runs are targeted research attempts, not table filling:

| Priority | Action |
|---|---|
| 1 | Decide whether to exclude or repair the FIR-family benchmark contract. |
| 2 | Decide whether `systolic_gemm` has a valid golden checker; otherwise keep it excluded. |
| 3 | If expanding coverage, design a genuinely new method or benchmark-specific repair for `unsharp_mask`, `fft_streaming_64pt`, `conv_3d`, `quantized_matmul`, and `newton_raphson_polynomial`. C4a was tried and failed, so re-running it is not justified by current evidence. |
| 4 | If the paper needs a C4tl ablation table, use the existing C4tl rows as negative/partial evidence; do not promote native-pass rows without golden verification. |

## Execution Rules

- Use `artifacts/inventories/run_matrix_l3_l6.csv` as the source of truth before and after every batch.
- Use `--parallel 2` for overnight paper-quality runs.
- After every batch:
  - run `python scripts\build_artifact_index.py`
  - run `python scripts\build_run_matrix.py`
  - update this file
  - do not push unless explicitly requested
