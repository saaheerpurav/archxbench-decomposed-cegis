# Paper Audit

Date: 2026-07-07

This is the paper-readiness and baseline gap map. It is derived from `artifacts/inventories/run_matrix_l3_l6.csv`, `artifacts/inventories/repaired_contract_run_matrix.csv`, the C4a diagnostic sweep in `artifacts/raw_runs/adaptive_c4a_weak_targets_20260704/`, and the extra C4a Newton run in `artifacts/raw_runs/newton_poly_c4a_extra_20260707/`.

## Bottom Line

The current paper is viable only if it is framed honestly:

- Strong: hard ArchXBench RTL synthesis can be solved across L3-L6 with verifier-grounded decomposed/CEGIS-style pipelines.
- Strong: C4i has clear wins on selected L3 designs where C1/C2g fail.
- Strong: C4tl robustly solves the four core L4 rows across five seeds.
- Strong: L5/L6 golden-verified solves exist, including `conv1d`, `harris_corner_detection`, `aes_encryption`, and `aes_decryption`.
- Weak: C4i/C4tl do not dominate C2g globally.
- Weak: C2g is the clean winner on several L5 rows.
- Negative: C4a was tried on all weak targets and got 0/15 solves; two extra C4a Newton seeds also failed, for 0/17 diagnostic solves overall.

The paper should not claim a universal method win. It should claim a verified, decomposed RTL synthesis pipeline with hard benchmark solves, clear ablations, and transparent benchmark caveats.

## Paper-Facing Table Plan

Use these tables in the paper. Do not merge rows across table classes.

### Table A: Original ArchXBench Main Evidence

These are the clean original-benchmark rows to emphasize. They are artifact-backed unless noted.

| Level | Designs | Main evidence | Paper use |
|---|---|---|---|
| L3 | `fp_adder`, `fp_multiplier`, `gauss_siedel`, `gradient_descent`, `newton_raphson_sqrt` | C4i solves 3/3; C1/C2g fail or are weaker | strongest method-value evidence |
| L4 | `fft_16pt_iterative`, `ifft_16pt_iterative`, `fp_adder_pipeline`, `fp_mult_pipeline` | C4tl solves 5/5; C2g also solves FFT/IFFT and both pipelines solve under multiple methods | strongest hard-level coverage evidence |
| L5 | `conv1d`, `harris_corner_detection` | C4i solves 3/3 with golden verification | clean golden-verified L5 evidence |
| L6 | `aes_encryption`, `aes_decryption` | C4i solves 3/3 with golden verification | clean golden-verified L6 evidence |

### Table B: Original ArchXBench Baseline Context

These are real original-benchmark results, but they should be framed as baseline/context rows rather than the central method claim.

| Level | Designs | Evidence | Artifact status |
|---|---|---|---|
| L5 | `conv2d`, `dct_idct_8pt_pipelined`, `unsharp_mask` | C2g solves 3/3 with golden verification | `unsharp_mask` is artifact-backed; `conv2d` and `dct_idct_8pt_pipelined` are score-only unless rerun |
| L5 | `conv1d`, `harris_corner_detection` | C1/C2g also solve 3/3 | useful for ablation context; some C2g rows are score-only |
| L6 | `aes_encryption`, `aes_decryption` | C1/C2g are strong baselines; C2g solves 3/3 | C2g rows are score-only unless rerun |
| L6 | `fft_streaming_64pt` | C2g solves only seed `42`; four other seeds fail | partial diagnostic only, not a robust solve |

### Table C: Repaired-Contract Evidence

These rows must be reported as repaired executable contracts, not original ArchXBench solves.

| Design | Repaired-contract result | Paper use |
|---|---|---|
| `conv_3d` | C2g 3/3, C4i 2/3, C4tl 0/3 | benchmark-contract repair unlocks intended task; not a C4tl win |
| `multich_conv2d` | C2g/C4i/C4tl all 3/3 | clean repaired-contract validation result |
| `quantized_matmul` | runner-fixed repair: C2g 3/3, C4i 3/3, C4tl 0/3 | shows file-format/runner contract mattered |
| `fp_band_pass_fir`, `fp_high_pass_fir` | C2g 3/3 on both; C4i/C4tl pilots fail or near-miss | benchmark-contract result; C2g strongest |
| `newton_raphson_polynomial` | repaired checker: C2g 3/3, C4i 1/3, C4tl 1/3 | shows original checker ceiling and repaired executable contract |
| `systolic_gemm` | C2g/C4i/C4tl all 0/3 | negative repaired-contract result |
| L4 FIR family | single-seed repaired pilots all fail | negative benchmark-audit evidence |

### Table D: Held Or Excluded Rows

These should not appear as solve-rate wins.

| Design/group | Final status | Reason |
|---|---|---|
| `fft_streaming_64pt` | hold | input encoding, output schema, and comparator are inconsistent |
| `fp_low_pass_fir` | hold | coefficient/cutoff oracle is not explicit |
| `band_pass_fir`, `high_pass_fir`, `low_pass_fir` | exclude from positive claims | repaired L4 pilots are negative; historical successes are log/metrics-only |
| `systolic_gemm` | negative | repaired checker exists and all current methods fail |

### Table E: Artifact-Backed Vs Score-Only

| Evidence class | Rows |
|---|---|
| Artifact-backed main claims | all rows in `docs/RESULTS.md` Main Claims |
| Artifact-backed repaired positives | `multich_conv2d`, `quantized_matmul` runner-fixed, `fp_band_pass_fir`, `fp_high_pass_fir`, `newton_raphson_polynomial`; `conv_3d` C4i is artifact-backed, C2g is score-only |
| Score-only baseline rows | C2g `aes_encryption`, `aes_decryption`, `conv1d`, `conv2d`, `dct_idct_8pt_pipelined`, `harris_corner_detection`, and repaired-contract C2g `conv_3d` |
| Log/metrics-only historical rows | L4 FIR C4i historical sweep: `band_pass_fir`, `high_pass_fir`, `low_pass_fir` |

## Official L3-L6 Coverage

ArchXBench L3-L6 has 28 designs in this repo.

| Category | Designs |
|---|---|
| Clean main/secondary solves | `fp_adder`, `fp_multiplier`, `gauss_siedel`, `gradient_descent`, `newton_raphson_sqrt`, `fft_16pt_iterative`, `ifft_16pt_iterative`, `fp_adder_pipeline`, `fp_mult_pipeline`, `conv1d`, `conv2d`, `dct_idct_8pt_pipelined`, `harris_corner_detection`, `unsharp_mask`, `aes_encryption`, `aes_decryption` |
| Partial or unsolved original-contract diagnostics | `newton_raphson_polynomial`, `fft_streaming_64pt` |
| Original-contract flawed, repaired-contract complete | `conv_3d`, `quantized_matmul`, `multich_conv2d`, `newton_raphson_polynomial` |
| Excluded or hold | `band_pass_fir`, `high_pass_fir`, `low_pass_fir`, `fp_band_pass_fir`, `fp_high_pass_fir`, `fp_low_pass_fir`, `fft_streaming_64pt`, `systolic_gemm` |

## Matched Baseline Status

The key paper tables can be clean if we avoid overclaiming.

| Level | Design | Baseline situation |
|---|---|---|
| L3 | `fp_adder` | C1 0/5, C2g 1/5, C4i 3/3 |
| L3 | `fp_multiplier` | C1 0/5, C2g 0/3, C4i 3/3 |
| L3 | `gauss_siedel` | C1 0/3, C2g 0/3, C4i 3/3 |
| L3 | `gradient_descent` | C1 0/3, C2g 0/3, C4i 3/3 |
| L3 | `newton_raphson_sqrt` | C1 0/3, C2g 0/3, C4i 3/3 |
| L4 | `fft_16pt_iterative` | C1 0/3, C2g 3/3, C4i 0/3, C4tl 5/5 |
| L4 | `ifft_16pt_iterative` | C1 0/3, C2g 3/3, C4i 0/3, C4tl 5/5 |
| L4 | `fp_adder_pipeline` | C1 3/3, C2g 3/3, C4i 3/3, C4tl 5/5 |
| L4 | `fp_mult_pipeline` | C1 3/3, C2g 3/3, C4i 3/3, C4tl 5/5 |
| L5 | `conv1d` | C1 3/3, C2g 3/3, C4i 3/3, C4tl 1/3 |
| L5 | `conv2d` | C1 0/3, C2g 3/3, C4i 0/3, C4tl 0/3 |
| L5 | `dct_idct_8pt_pipelined` | C1 0/3, C2g 3/3, C4i 0/3, C4tl 0/3 |
| L5 | `harris_corner_detection` | C1 0/3, C2g 3/3, C4i 3/3, C4tl 0/3 |
| L5 | `unsharp_mask` | C1 0/3, C2g 3/3, C4i 0/3, C4tl 0/3 |
| L6 | `aes_encryption` | C1 3/3, C2g 3/3, C4i 3/3, C4tl 2/3 |
| L6 | `aes_decryption` | C1 1/3, C2g 3/3, C4i 3/3, C4tl 1/3 |

Interpretation:

- L3 is the cleanest evidence that C4i adds value over C1/C2g.
- L4 is strong coverage evidence, but not always an exclusive method win because C2g also solves FFT/IFFT and pipelines are easy for multiple conditions.
- L5/L6 are strong capability evidence, but C2g must be treated as a serious baseline and often matches or beats C4i/C4tl.

## Negative And Partial Rows

| Design | Current best evidence |
|---|---|
| `newton_raphson_polynomial` | Original checker has three unsatisfiable checks; C4a debug reaches the effective ceiling `97/100`; no original `100/100` possible without contract repair |
| `fft_streaming_64pt` | C2g is 1/5: seed `42` clean `128/128`, seeds `123,456,789,1024` fail; released output schema/comparator are inconsistent |
| `conv_3d` | DONE for run planning: original contract is flawed and fails; repaired-contract track is complete with C2g 3/3 and C4i 2/3 |
| `quantized_matmul` | DONE for run planning: original contract is flawed and fails; runner-fixed repaired-contract track is complete with C2g 3/3 and C4i 3/3 |

## Exclusions And Holds

| Design group | Status |
|---|---|
| FIR family | Exclude unless the benchmark/spec-contract issue is repaired and documented. Some rows show apparent C2g solves, but these should not become claims while the FIR contract remains disputed. |
| `systolic_gemm` | Original checker is display-only. Repaired-contract run is complete and negative: C2g/C4i/C4tl all 0/3. |
| `multich_conv2d` | Original contract issue. Repaired-contract rows are complete and must stay separate from original ArchXBench tables. |
| `fft_streaming_64pt` | Hold. The issue is not only output schema; the input numeric encoding and copied scalar comparator are also inconsistent, so no repaired-contract run is claimable yet. |

### Repaired FIR Pilot

L4 FIR repaired fixtures were created under `artifacts/benchmark_contracts/archxbench_repaired/level-4/` by removing stale file-output testbenches and using only embedded-golden `tb_selfcheck.v`.

Single-seed pilots on repaired L4 FIR are negative:

| Design | C2g seed 42 | C4i seed 42 | C4tl seed 42 |
|---|---:|---:|---:|
| `band_pass_fir` | 1/1001 | 5/1001 | 2/1001 |
| `high_pass_fir` | 4/1001 | 4/1001 | 0/1001 |
| `low_pass_fir` | 3/1001 | 5/1001 | 3/1001 |

Interpretation: repaired L4 FIR did not unlock a positive result with current methods. Do not spend more L4 FIR runs unless there is a new general method.

### Repaired L6 FP FIR

The L6 FP FIR fixtures were repaired separately under `artifacts/benchmark_contracts/archxbench_repaired/level-6/`.
The repaired contracts expose public coefficients, remove the hidden-DUT coefficient dependency, and fix malformed JSON output.
Oracle validation passed for both repaired fixtures:

| Design | Oracle validation | C2g seeds | C4i/C4tl pilot |
|---|---:|---:|---|
| `fp_band_pass_fir` | `1000/1000` | 3/3 solved, all `1000/1000` | seed `42` failed: C4i `804/1000`, C4tl `0/1000` |
| `fp_high_pass_fir` | `1000/1000` | 3/3 solved, all `1000/1000` | seed `42` failed: C4i `969/1000`, C4tl `969/1000` |

Interpretation: repaired L6 FP FIR is a useful benchmark-contract repair result, but it is not a C4i/C4tl win. C2g is the strongest method on these repaired rows.

### Historical FIR Sweep

A GitHub-history audit found a historical C4i GPT-5.5 L4 FIR sweep in committed logs and old aggregate metrics. These are remembered but not promoted as artifact-backed claims:

| Design | C4i GPT-5.5 seeds | Result | Evidence status |
|---|---|---|---|
| `band_pass_fir` | `42,123,456,789,1024` | 0/5 solved; best `5/1001` | log/metrics-only |
| `high_pass_fir` | `42,123,456,789,1024` | 2/5 solved; seeds `456,1024` scored `1001/1001` | log/metrics-only |
| `low_pass_fir` | `42,123,456,789,1024` | 1/5 solved; seed `123` scored `1001/1001` | log/metrics-only |

Inventory: `artifacts/inventories/log_metric_only_results.csv`.

These results matter for historical completeness, but they do not change the paper-claim table because the generated RTL/result artifacts for those specific cells were not preserved.

## What Would Strengthen The AAAI Paper

Do these only if the goal is maximum paper strength, not incremental cleanup.

1. Formalize the claim around verifier-grounded decomposed RTL synthesis, not C4i/C4tl beating C2g everywhere.
2. Add a clear result table that separates:
   - exclusive C4i wins
   - matched solves
   - C2g wins
   - unsolved/near-miss rows
   - excluded benchmark-contract rows
3. Write a benchmark-audit section explaining why golden verification is required and why FIR/systolic/multich are excluded or held.
4. If running more experiments, do not run another small C4 variant. The useful research attempts are:
   - repair or formally validate excluded benchmark checkers only when the repair is principled and oracle-validated
   - optional repaired contract for `fft_streaming_64pt` only if input encoding and output schema can both be specified and oracle-validated
   - repaired contract for `newton_raphson_polynomial` only if the unsatisfiable test cases are explicitly addressed
5. Avoid claiming C4a. It is negative evidence.

## Current Run Recommendation

No table-filling run is currently required for the existing claims.

The repaired-contract track has now been run:

- repaired `conv_3d`: C2g 3/3, C4i 2/3, C4tl 0/3
- repaired `multich_conv2d`: C2g 3/3, C4i 3/3, C4tl 3/3
- repaired `quantized_matmul`, initial file-format repair: C2g/C4i/C4tl all 0/3
- repaired `quantized_matmul`, after signed-quantization clarification and runner fix: C2g 3/3, C4i 3/3, C4tl 0/3
- repaired L6 FP FIR: C2g 3/3 on `fp_band_pass_fir` and `fp_high_pass_fir`; C4i/C4tl seed-42 pilots fail
- repaired `systolic_gemm`: C2g 0/3, C4i 0/3, C4tl 0/3
- repaired `newton_raphson_polynomial`: oracle validation passes; C2g 3/3, C4i 1/3, C4tl 1/3 on the `97/97` repaired checker
- these rows must remain separate from original ArchXBench tables

Current highest-value next attempts:

- only a principled `fft_streaming_64pt` contract repair if input encoding and output schema can both be specified and oracle-validated
- no more original-contract `conv_3d` / `quantized_matmul` runs are needed because repaired-contract rows are already complete
