# Benchmark Caveats

Last synchronized: 2026-07-17

## Golden Verification

For file-output designs, native simulator completion is not enough. A row counts as solved only if `golden_correct == golden_total` and `golden_total > 0`.

Rows with native `1/1` pass but failing or missing golden scores are diagnostics.

The file-output contract audit is recorded in `artifacts/inventories/file_output_contract_audit.csv`.
Three original benchmark designs emit no native PASS/FAIL tokens and rely entirely on post-simulation
golden comparison: `conv_3d`, `multich_conv2d`, and `quantized_matmul`.

## Self-Checking Testbenches

Some designs have official self-checking testbenches and do not use external golden JSON. For these, use `best_passes/total_tests`.

## FIR Designs

FIR-family rows are diagnostics/repaired-contract evidence only.

We exclude released L4 FIR designs from the original-contract table because the
specification and executable coefficients disagree. Corrected Q1.15 copied
fixtures are reported separately.

The repaired L6 FP FIR table contains all three designs. C2g solves all three 3/3;
C4i scores 1/3 on each; C4tl scores 2/3, 1/3, and 2/3. The low-pass oracle comes
from official upstream history and does not convert the released row into an
original-contract result.

Current repaired-contract status:

- L4 FIR repaired fixtures now live under `artifacts/benchmark_contracts/archxbench_repaired/level-4/`.
- Those fixtures remove stale file-output testbenches and keep only embedded-golden `tb_selfcheck.v`.
- Final corrected-fixture result: C2g solves band/high/low at 3/3, 2/3, and
  2/3; C4i and C4tl are 0/3 on all three. Do not claim these as released
  original-contract solves.
- L6 `fp_band_pass_fir` and `fp_high_pass_fir` have repaired fixtures that remove hidden `dut.coeffs` writes and repair file-output JSON comma handling. Oracle validation passes `1000/1000`, and C2g solves both repaired contracts 3/3.
- L6 `fp_low_pass_fir` remains held under the released contract; only the
  separately labelled upstream-oracle repaired row is reported.

See `docs/EXECUTABLE_CONTRACT_REPAIR.md` and `artifacts/inventories/repaired_contract_run_matrix.csv`.

A historical C4i GPT-5.5 L4 FIR sweep was run for five seeds (`42,123,456,789,1024`) and is recorded in repo-local committed logs and `artifacts/inventories/log_metric_only_results.csv`. These rows are intentionally kept as log/metrics-only evidence because the corresponding generated RTL/result artifacts were not preserved:

| Design | Historical C4i result | Evidence status |
|---|---|---|
| `band_pass_fir` | 0/5 solved; best `5/1001` | log/metrics-only |
| `high_pass_fir` | 2/5 solved; seeds `456,1024` scored `1001/1001` | log/metrics-only |
| `low_pass_fir` | 1/5 solved; seed `123` scored `1001/1001` | log/metrics-only |

Inventory: `artifacts/inventories/log_metric_only_results.csv`.

Do not present these as artifact-backed paper claims unless they are rerun with saved RTL. They can be cited internally as evidence that the C4i FIR sweep was attempted and had partial score success.

## FFT Designs

L4 `fft_16pt_iterative` and `ifft_16pt_iterative` are clean self-checking solves.

L6 `fft_streaming_64pt` is excluded from result tables. Current C4i/C4tl rows fail golden comparison and are diagnostics. C2g has one clean seed (`42`, `128/128`) but fails four other seeds (`123,456,789,1024`), so it is partial rather than robust.

Contract audit finding: the released benchmark contains unresolved input/output contract ambiguities. The shipped golden file is a dict with `real_out` and `imag_out` arrays, while `tb_fft_streaming_64pt.v` writes a list of objects with `real` and `imag` fields. The shipped `scripts/compare_outputs.py` is also a copied scalar-filter comparator and cannot compare the FFT dict/list structure correctly. The input side is ambiguous: the stimuli are JSON floats / FP32 hex words, while the testbench reads decimal integer pairs into 16-bit signed ports. Keep this row excluded unless a principled repaired contract specifies numeric encoding, normalizes the output schema, and validates an oracle DUT.

## Newton-Raphson Polynomial

`newton_raphson_polynomial` is self-checking, but the released testbench is not fully satisfiable. It performs two checks per 50 test cases: root comparison against a real-number Newton solver and polynomial residual verification. Three checks are structurally impossible to satisfy simultaneously:

- case 6: polynomial has no real root, but the testbench still demands both real-Newton root proximity and low residual
- case 13: constant polynomial `p(x)=1`, so residual verification cannot pass
- case 35: real Newton reference does not land near a residual-zero point within the fixed-point tolerance

Therefore the effective ceiling is `97/100`, not `100/100`, unless the benchmark contract is repaired. A repo-local C4a debug artifact reaches `97/100`; do not spend more method runs chasing `100/100` on the original checker.

A repaired contract now exists under `artifacts/benchmark_contracts/archxbench_repaired/level-3/newton_raphson_polynomial/`. It skips only the three impossible polynomial residual checks while preserving all 50 root-comparison checks and the remaining 47 residual checks. Oracle validation passes `97/97` with 3 explicit skipped residual checks. Repaired-contract runs are separate from original ArchXBench results: C2g solves 3/3, C4i solves 2/3, and C4tl solves 2/3.

## Harris Corner Detection

The released testbench's image dimensions and permissive binary comparator do
not define a credible exact oracle. The acceptance-repaired fixture restores the
released 128x128 cardinality and exact comparison. Final repaired results are
C2g 3/3, C4i 0/3, and C4tl 0/3. Harris must not appear in the original-contract
table even when a legacy artifact path contains `original` or `main_claims`.

## DCT And Systolic GEMM

`dct_idct_8pt_pipelined` is solved by C2g in the current repo-local evidence. C4i/C4tl rows are diagnostics unless promoted in `docs/RESULTS.md`.

`systolic_gemm` has pass-score rows without reliable evidence in the original benchmark because the checker only prints expected values. The repaired fixture converts the two displayed expected matrices into 32 exact executable checks. After correcting the repaired testbench filename so the runner selects it, an oracle passes all 32 assertions and Codex CLI GPT-5.5 C2g/C4i/C4tl each solve 3/3. These are repaired-contract results only; the original-contract rows remain diagnostics.

## Unsharp Mask

`unsharp_mask` has artifact-backed C2g solves on seeds `42,123,456`.

Artifact locations:

- seeds `42,456`: `artifacts/raw_runs/unsharp_c2g_artifact_rerun_20260706/`
- seed `123`: `artifacts/raw_runs/unsharp_c2g_seed123_artifact_rerun_20260706/`

All three saved RTL files score `65536/65536` against the shipped `golden_output.json`.

The older C2g near-miss rows in `overnight_c2g_priority1_20260703` are score-only and have no generated RTL. Do not use those old rows as artifact-backed evidence.

The shipped golden does not match a textbook centered 3x3 unsharp-mask reference. Treat `unsharp_mask` as a valid ArchXBench executable-contract solve, but avoid using it as a qualitative example of textbook image-processing semantics.

## Repaired Benchmark Contracts

`conv_3d`, `multich_conv2d`, `quantized_matmul`, and `systolic_gemm` have documented executable-contract issues in the original benchmark files. A repaired-contract copy now lives under `artifacts/benchmark_contracts/archxbench_repaired/`.

Results from this repaired root must be reported separately from original ArchXBench results. See `docs/EXECUTABLE_CONTRACT_REPAIR.md`.
