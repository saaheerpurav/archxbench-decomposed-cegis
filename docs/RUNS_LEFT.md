# Runs Left

This is the only run queue. It is derived from:

- `artifacts/inventories/run_matrix_l3_l6.csv`
- `artifacts/inventories/repaired_contract_run_matrix.csv`
- `artifacts/inventories/log_metric_only_results.csv`

Last audited: 2026-07-08 after `l3_c4tl_batch2_20260708`.

Primary goal: AAAI-27 acceptance. Time is not a constraint. Do not sacrifice experimental cleanliness for speed, and do not run benchmark repairs just to convert failures into wins. Repairs must be minimal, principled, oracle-validated, and reported separately from original ArchXBench results.

## Required Runs

No experiment runs remain in the current paper-cleanliness queue.

The selected L3 C4tl condition-coverage batch has been completed on seeds `42,123,456`.

Completed from this queue:

| Level | Design | Method | Seeds | Result | Artifact root |
|---|---|---|---|---|---|
| L3 | `fp_adder` | C4tl | `42,123,456` | 3/3 solved, all `36/36` | `artifacts/raw_runs/l3_c4tl_batch1_20260708/` |
| L3 | `fp_multiplier` | C4tl | `42,123,456` | 3/3 solved, all `10/10` | `artifacts/raw_runs/l3_c4tl_batch1_20260708/` |
| L3 | `gauss_siedel` | C4tl | `42,123,456` | 1/3 solved; seed `123` scored `50/50`, seed `42` scored `47/50`, seed `456` scored `49/50` | `artifacts/raw_runs/l3_c4tl_batch1_20260708/` |
| L3 | `gradient_descent` | C4tl | `42,123,456` | 3/3 solved, all `50/50` | `artifacts/raw_runs/l3_c4tl_batch2_20260708/` |
| L3 | `newton_raphson_sqrt` | C4tl | `42,123,456` | 3/3 solved, all `50/50` | `artifacts/raw_runs/l3_c4tl_batch2_20260708/` |
| L3 | `newton_raphson_polynomial` | C4tl | `42,123,456` | 0/3 solved, all `17/100` | `artifacts/raw_runs/l3_c4tl_batch2_20260708/` |

## Complete Original-Contract Rows

These have enough evidence for the current paper framing.

| Level | Design | Clean methods |
|---|---|---|
| L3 | `fp_adder` | `C4i` 3/3 |
| L3 | `fp_multiplier` | `C4i` 3/3 |
| L3 | `gauss_siedel` | `C4i` 3/3 |
| L3 | `gradient_descent` | `C4i` 3/3 |
| L3 | `newton_raphson_sqrt` | `C4i` 3/3 |
| L4 | `fft_16pt_iterative` | `C2g` 3/3, `C4tl` 3/3 main seeds; C4tl 5/5 with robustness seeds |
| L4 | `fp_adder_pipeline` | `C1` 3/3, `C2g` 3/3, `C4i` 3/3, `C4tl` 3/3 main seeds; C4tl 5/5 with robustness seeds |
| L4 | `fp_mult_pipeline` | `C1` 3/3, `C2g` 3/3, `C4i` 3/3, `C4tl` 3/3 main seeds; C4tl 5/5 with robustness seeds |
| L4 | `ifft_16pt_iterative` | `C2g` 3/3, `C4tl` 3/3 main seeds; C4tl 5/5 with robustness seeds |
| L5 | `conv1d` | `C1` 3/3, `C2g` 3/3, `C4i` 3/3 |
| L5 | `conv2d` | `C2g` 3/3 |
| L5 | `dct_idct_8pt_pipelined` | `C2g` 3/3 |
| L5 | `harris_corner_detection` | `C2g` 3/3, `C4i` 3/3 |
| L5 | `unsharp_mask` | `C2g` 3/3 artifact-backed on seeds `42,123,456` |
| L6 | `aes_decryption` | `C2g` 3/3, `C4i` 3/3 |
| L6 | `aes_encryption` | `C1` 3/3, `C2g` 3/3, `C4i` 3/3 |

Additional L3 C4tl support rows now run:

| Level | Design | C4tl result |
|---|---|---|
| L3 | `fp_adder` | 3/3 solved |
| L3 | `fp_multiplier` | 3/3 solved |
| L3 | `gauss_siedel` | 1/3 solved; near misses on two seeds |
| L3 | `gradient_descent` | 3/3 solved |
| L3 | `newton_raphson_sqrt` | 3/3 solved |
| L3 | `newton_raphson_polynomial` | 0/3 solved |

## Repaired-Contract Rows

These rows are complete for the current paper, but they must stay separate from original ArchXBench results.

| Design | Repaired-contract result |
|---|---|
| `conv_3d` | C2g 3/3 solved; C4i 2/3 solved; C4tl 0/3 solved |
| `multich_conv2d` | C2g 3/3 solved; C4i 3/3 solved; C4tl 3/3 solved |
| `quantized_matmul` runner-fixed | C2g 3/3 solved; C4i 3/3 solved; C4tl 0/3 solved |
| `fp_band_pass_fir` | oracle-validated repaired contract; C2g 3/3 solved; C4i/C4tl seed-42 pilots fail |
| `fp_high_pass_fir` | oracle-validated repaired contract; C2g 3/3 solved; C4i/C4tl seed-42 pilots fail/near-miss |
| `newton_raphson_polynomial` | oracle-validated repaired checker; C2g 3/3 solved; C4i 1/3 solved; C4tl 1/3 solved |
| `systolic_gemm` | repaired display-only checker; C2g/C4i/C4tl all 0/3 |
| L4 FIR family | repaired single-seed pilots all fail |

## Excluded Or Held

Do not run these unless a principled benchmark-contract audit changes the status.

| Level | Design/group | Status |
|---|---|---|
| L4 | `band_pass_fir`, `high_pass_fir`, `low_pass_fir` | exclude from primary and repaired-contract positive tables due to inconsistent evaluation contracts where specification and executable testbench disagree on filter coefficients/source-of-truth behavior; repaired pilots are negative |
| L5 | `systolic_gemm` | genuine capability boundary after checker repair; all current methods remain 0/3 |
| L6 | `fp_low_pass_fir` | hold because the released files do not expose an explicit coefficient/cutoff oracle |
| L6 | `fft_streaming_64pt` | exclude from result tables because the released benchmark contains unresolved input/output contract ambiguities, including mismatched output schema and input numeric encoding |

## Artifact Debt, Not Run Debt

Trusted score-only rows are valid experimental results. Missing generated RTL is artifact collection debt for paper/code release, not a reason to discard the score.

Artifact collection can be done later for release polish. It is not part of the current experiment queue.

## What Is Left

No experiment run is currently queued.

Remaining work before submission is paper writing and final manuscript consistency checks. Artifact-release cleanup is not part of the current run queue.

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
