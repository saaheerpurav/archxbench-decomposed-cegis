# Benchmark Caveats

## Golden Verification

For file-output designs, native simulator completion is not enough. A row counts as solved only if `golden_correct == golden_total` and `golden_total > 0`.

Rows with native `1/1` pass but failing or missing golden scores are diagnostics.

The file-output contract audit is recorded in `artifacts/inventories/file_output_contract_audit.csv`.
Three original benchmark designs emit no native PASS/FAIL tokens and rely entirely on post-simulation
golden comparison: `conv_3d`, `multich_conv2d`, and `quantized_matmul`.

## Self-Checking Testbenches

Some designs have official self-checking testbenches and do not use external golden JSON. For these, use `best_passes/total_tests`.

## FIR Designs

FIR-family rows are diagnostics/repaired-contract evidence only. L4 FIR has repaired-contract fixtures and a completed negative pilot. L6 `fp_band_pass_fir` and `fp_high_pass_fir` now have validated repaired contracts and C2g solves, while `fp_low_pass_fir` remains a benchmark-contract hold because the coefficient oracle is not explicit.

Current repaired-contract status:

- L4 FIR repaired fixtures now live under `artifacts/benchmark_contracts/archxbench_repaired/level-4/`.
- Those fixtures remove stale file-output testbenches and keep only embedded-golden `tb_selfcheck.v`.
- Single-seed repaired-contract pilots were run for C2g, C4i, and C4tl on `band_pass_fir`, `high_pass_fir`, and `low_pass_fir`.
- Result: all nine pilot cells failed, with best scores only 0-5/1001. Do not claim FIR as solved.
- L6 `fp_band_pass_fir` and `fp_high_pass_fir` have repaired fixtures that remove hidden `dut.coeffs` writes and repair file-output JSON comma handling. Oracle validation passes `1000/1000`, and C2g solves both repaired contracts 3/3.
- L6 `fp_low_pass_fir` remains held out because the coefficient oracle is still not explicit.

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

L6 `fft_streaming_64pt` is different. Current C4i/C4tl rows fail golden comparison and are diagnostics. C2g has one clean seed (`42`, `128/128`) but fails four other seeds (`123,456,789,1024`), so it is partial rather than robust.

## DCT And Systolic GEMM

`dct_idct_8pt_pipelined` is solved by C2g in the current repo-local evidence. C4i/C4tl rows are diagnostics unless promoted in `docs/RESULTS.md`.

`systolic_gemm` has pass-score rows without reliable golden evidence in the original benchmark because the checker only prints expected values. A repaired-contract checker exists, but C2g/C4i/C4tl all fail 3/3; do not claim it as solved.

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
