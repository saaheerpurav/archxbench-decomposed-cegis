# Runs Left

This is the only run queue. It is derived from `artifacts/inventories/run_matrix_l3_l6.csv`.

Last audited: 2026-07-07 after repository-local result and artifact audit.

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
| L5 | `unsharp_mask` | `C2g` 3/3 artifact-backed on seeds `42,123,456` |
| L6 | `aes_decryption` | `C2g` 3/3, `C4i` 3/3 |
| L6 | `aes_encryption` | `C1` 3/3, `C2g` 3/3, `C4i` 3/3 |

### Original-Contract Diagnostics, Not Run Queue

These rows explain original benchmark behavior. They are not queued for more original-contract runs.

| Level | Design | Current status |
|---|---|---|
| L3 | `newton_raphson_polynomial` | original checker has three unsatisfiable checks; repo-local C4a debug reaches the effective ceiling `97/100` |
| L6 | `fft_streaming_64pt` | `C2g` seed `42` clean `128/128`; seeds `123,456,789,1024` fail; input encoding, output schema, and comparator are inconsistent |
| L6 | `conv_3d` | DONE: original contract is flawed; repaired-contract track is complete, so no more original-contract runs |
| L6 | `quantized_matmul` | DONE: original contract is flawed; repaired-contract runner-fixed track is complete, so no more original-contract runs |
| L3 | `newton_raphson_polynomial` repaired contract | DONE: oracle-validated repaired checker; C2g 3/3 solved, C4i 1/3 solved, C4tl 1/3 solved |

### Log/Metrics-Only Historical Results

These runs were found in committed logs and old aggregate metrics, but the generated RTL/result artifacts were not preserved. They are remembered in `artifacts/inventories/log_metric_only_results.csv` and are not artifact-backed paper claims.

| Level | Design | Method | Historical result |
|---|---|---|---|
| L4 | `band_pass_fir` | C4i GPT-5.5, seeds `42,123,456,789,1024` | 0/5 solved; best `5/1001` |
| L4 | `high_pass_fir` | C4i GPT-5.5, seeds `42,123,456,789,1024` | 2/5 solved; seeds `456,1024` scored `1001/1001` |
| L4 | `low_pass_fir` | C4i GPT-5.5, seeds `42,123,456,789,1024` | 1/5 solved; seed `123` scored `1001/1001` |

### Latest Targeted Research Attempt

`C4a` was run on all five weak targets with `gpt-5.5`, seeds `42,123,456`, under
`artifacts/raw_runs/adaptive_c4a_weak_targets_20260704/`.

Two extra `newton_raphson_polynomial` C4a seeds (`789,1024`) were then run under
`artifacts/raw_runs/newton_poly_c4a_extra_20260707/`.

Result: 0/17 diagnostic solves.

| Design | C4a result |
|---|---|
| `unsharp_mask` | failed all three seeds; best `63780/65536` |
| `fft_streaming_64pt` | failed all three seeds; all `0/1` |
| `conv_3d` | failed all three seeds; all `0/0` |
| `quantized_matmul` | failed all three seeds; two `0/0`, one final compile failure |
| `newton_raphson_polynomial` | failed five seeds; best `96/100`; extra seeds scored `88/100` and `94/100` |

Conclusion: C4a is negative evidence. Do not promote it as a method improvement.

### Repaired-Contract Batch

`conv_3d`, `multich_conv2d`, `quantized_matmul`, and `systolic_gemm` were rerun against repaired executable contracts under
`artifacts/benchmark_contracts/archxbench_repaired/`.

Artifacts: `artifacts/raw_runs/repaired_contracts_20260705/`
Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`

| Design | Repaired-contract result |
|---|---|
| `conv_3d` | C2g 3/3 solved; C4i 2/3 solved; C4tl 0/3 solved |
| `multich_conv2d` | C2g 3/3 solved; C4i 3/3 solved; C4tl 3/3 solved |
| `quantized_matmul` initial | C2g 0/3, C4i 0/3, C4tl 0/3; exposed signed-quantization and runner issues |
| `quantized_matmul` runner-fixed | C2g 3/3 solved; C4i 3/3 solved; C4tl 0/3 solved |
| `systolic_gemm` | C2g 0/3, C4i 0/3, C4tl 0/3; repaired display-only checker, but no method solved it |
| L4 FIR repaired pilot | C2g/C4i/C4tl seed `42` all failed on `band_pass_fir`, `high_pass_fir`, and `low_pass_fir`; best score 5/1001 |
| L6 FP FIR repaired contracts | Oracle validation passed for `fp_band_pass_fir` and `fp_high_pass_fir`; C2g solves both 3/3, C4i/C4tl seed `42` pilots fail |
| `newton_raphson_polynomial` repaired contract | Oracle validation passed with `97/97` executable checks and 3 skipped impossible residual checks; C2g 3/3 solved, C4i 1/3 solved, C4tl 1/3 solved |

### Excluded Or Hold

Do not blind-run these until the checker/spec issue is resolved.

| Level | Design | Reason |
|---|---|---|
| L4 | `band_pass_fir` | repaired-contract pilot complete and negative; do not rerun without a new general method |
| L4 | `high_pass_fir` | repaired-contract pilot complete and negative; historical C4i log/metrics-only result is 2/5 solved but not artifact-backed |
| L4 | `low_pass_fir` | repaired-contract pilot complete and negative; historical C4i log/metrics-only result is 1/5 solved but not artifact-backed |
| L5 | `systolic_gemm` | original checker is display-only; repaired-contract track completed with 0/9 solves |
| L6 | `fp_band_pass_fir` | original contract issue; repaired-contract C2g 3/3 complete |
| L6 | `fp_high_pass_fir` | original contract issue; repaired-contract C2g 3/3 complete |
| L6 | `fp_low_pass_fir` | still held out; coefficient oracle not explicit |
| L6 | `multich_conv2d` | original benchmark contract issue; repaired-contract track complete |
| L6 | `fft_streaming_64pt` | hold; output schema, comparator, and input encoding are internally inconsistent, so no principled repaired run exists yet |

## What Is Left To Run

No same-method, same-seed completion run is currently queued for the existing claims.

The controlled audit has now been done for the remaining weak rows. The only useful next work is principled contract repair or genuinely general research attempts, not table filling. The target is AAAI-27 acceptance, so do not run or repair just to inflate solve counts. Any benchmark repair must be minimal, principled, and reported separately from original ArchXBench results.

| Priority | Action |
|---|---|
| 1 | Keep `fft_streaming_64pt` on hold unless a principled repair specifies both numeric input encoding and output schema, then validates an oracle DUT. Do not run more original-contract seeds. |
| 2 | Keep `fp_low_pass_fir` held out unless the coefficient/cutoff oracle is found explicitly. Deriving coefficients from golden output would be overfitting. |
| 3 | No more original-contract `conv_3d` / `quantized_matmul` / `newton_raphson_polynomial` runs are needed; flaw evidence and repaired-contract rows are already complete. |
| 4 | Keep `systolic_gemm` parked unless a genuinely new general method appears; repaired-contract run is complete and negative. |
| 5 | Rerun any C1/C2g score-only baseline row before using it as artifact-backed paper evidence; see `docs/ARTIFACT_AUDIT_STATUS.md`. |

## Execution Rules

- Use `artifacts/inventories/run_matrix_l3_l6.csv` as the source of truth for repo-local `result.json` cells before and after every batch.
- Use `artifacts/inventories/repaired_contract_run_matrix.csv` only for repaired-contract rows. Do not merge repaired-contract rows into the original ArchXBench matrix.
- Use `artifacts/inventories/log_metric_only_results.csv` only for historical log/metrics-only rows that lack saved RTL/result artifacts.
- Use `--parallel 2` for overnight paper-quality runs.
- For repaired-contract runs, set `ARCHXBENCH_ROOT` explicitly and record that root in the run note.
- After every batch:
  - run `python scripts\build_artifact_index.py`
  - run `python scripts\build_run_matrix.py`
  - run `python scripts\build_repaired_contract_matrix.py` if repaired-contract runs changed
  - run `python scripts\audit_file_output_contracts.py` if benchmark contracts or testbenches changed
  - update this file
  - do not push unless explicitly requested
