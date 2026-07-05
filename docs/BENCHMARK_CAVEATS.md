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

FIR-family results are diagnostics only. The benchmark/spec-contract issue around coefficients and hidden reference behavior is unresolved.

## FFT Designs

L4 `fft_16pt_iterative` and `ifft_16pt_iterative` are clean self-checking solves.

L6 `fft_streaming_64pt` is different. Current C4i/C4tl rows fail golden comparison and are diagnostics.

## DCT And Systolic GEMM

`dct_idct_8pt_pipelined` is solved by C2g in the current repo-local evidence. C4i/C4tl rows are diagnostics unless promoted in `docs/RESULTS.md`.

`systolic_gemm` has pass-score rows without reliable golden evidence. Do not claim it as solved.

## Repaired Benchmark Contracts

`conv_3d` and `quantized_matmul` have documented executable-contract issues in the original benchmark files. A repaired-contract copy now lives under `artifacts/benchmark_contracts/archxbench_repaired/`.

Results from this repaired root must be reported separately from original ArchXBench results. See `docs/EXECUTABLE_CONTRACT_REPAIR.md`.
