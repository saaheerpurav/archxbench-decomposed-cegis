# Runs Left

This is the only run queue.

## Required For Current Claims

None.

The current claims in [RESULTS.md](RESULTS.md) already have repo-local artifacts.

## AAAI No-Compromise Matrix Completion

The current claims are supported, but the full method matrix is uneven. For AAAI-grade comparison, complete the matched GPT-5.5 matrix for the primary methods:

- `C1`
- `C2g`
- `C4i`
- `C4tl`

Use [../artifacts/inventories/run_matrix_l3_l6.csv](../artifacts/inventories/run_matrix_l3_l6.csv) as the source of truth before and after every batch.

### Priority 1: Complete C2g L5/L6 Baselines

C2g is the strongest monolithic baseline. Do these before adding more C4i/C4tl runs.

Completed GPT-5.5 C2g baseline rows:

| Design | Status |
|---|---|
| `conv1d` | complete, seeds `42,123,456`, clean `3/3`, golden `16/16` |
| `harris_corner_detection` | complete, seeds `42,123,456`, clean `3/3`, golden `16384/16384` |
| `aes_encryption` | complete, seeds `42,123,456`, clean `3/3`, golden `8/8` |
| `conv2d` | complete, seeds `42,123,456`, clean `3/3`, golden `4096/4096` |
| `fft_streaming_64pt` | complete, seeds `42,123,456`, clean `1/3`; seed `42` golden `128/128`, seeds `123,456` produced `0/0` golden |
| `unsharp_mask` | complete, seeds `42,123,456`, clean `0/3`; best seeds `42,456` are `65535/65536` |

Remaining GPT-5.5 C2g rows:

| Design | Seeds / action |
|---|---|
| `aes_decryption` | rerun seeds `42,123,456` only after confirming the prior charmap failure is fixed |
| `dct_idct_8pt_pipelined` | run seeds `123,456` after one diagnostic check of seed `42` failure |
| `conv_3d` | run seeds `123,456` only if seed `42` failure is understood |
| `quantized_matmul` | run seeds `123,456` only if seed `42` failure is understood |
| `fp_band_pass_fir` | hold until FIR benchmark/spec-contract caveat is resolved |
| `fp_high_pass_fir` | hold until FIR benchmark/spec-contract caveat is resolved |
| `fp_low_pass_fir` | hold until FIR benchmark/spec-contract caveat is resolved |

### Priority 2: Complete C4i Seeds For Non-Broken L4/L5/L6 Rows

Run GPT-5.5 C4i seeds `123,456` where only seed `42` exists and the benchmark/checker is usable:

| Level | Designs |
|---|---|
| L4 | `fft_16pt_iterative`, `fp_adder_pipeline`, `fp_mult_pipeline`, `ifft_16pt_iterative` |
| L5 | `conv2d`, `dct_idct_8pt_pipelined`, `unsharp_mask` |
| L6 | `aes_decryption`, `fft_streaming_64pt`, `conv_3d`, `quantized_matmul` |

Already complete on C4i seeds `42,123,456`:

- L3 all current C4i rows
- `conv1d`
- `harris_corner_detection`
- `aes_encryption`

Hold until benchmark/spec-contract caveat is resolved:

- L4 FIR-family designs
- L6 `fp_band_pass_fir`, `fp_high_pass_fir`, `fp_low_pass_fir`

### Priority 3: Complete C4tl Only Where It Is Part Of The Story

C4tl is currently strongest on the L4 core designs and weak/messy on L5/L6 golden verification. Run more C4tl only to support ablation/fairness, not as the main method.

Already complete on C4tl seeds `42,123,456,789,1024`:

- `fp_mult_pipeline`
- `fp_adder_pipeline`
- `fft_16pt_iterative`
- `ifft_16pt_iterative`

Optional C4tl seeds `123,456`:

- `harris_corner_detection`
- `aes_encryption`
- `fft_streaming_64pt`
- `aes_decryption`
- `conv2d`
- `unsharp_mask`
- `dct_idct_8pt_pipelined`
- `conv_3d`
- `quantized_matmul`

Do not promote C4tl rows unless they are strict-clean under the correct verifier. Native simulator pass is not enough for L5/L6.

### Exclusions / Hold Until Fixed

| Design | Reason |
|---|---|
| `multich_conv2d` | benchmark loader/testbench issue; currently excluded |
| `systolic_gemm` | no reliable golden evidence in repo; decide checker first |
| FIR-family designs | benchmark/spec-contract caveat unresolved |

### Execution Rules

- Use `--parallel 2` for overnight paper-quality runs.
- Use `--parallel 3` only for lighter diagnostic batches.
- After every batch:
  - copy/promote only strict-clean rows as needed
  - run `python scripts\build_artifact_index.py`
  - run `python scripts\build_run_matrix.py`
  - update this file if the queue changes
  - commit and push

## Clean Optional Expansion

None currently queued.

`conv1d` C4i and `aes_encryption` C4i have been completed on seeds `42,123,456` with complete golden scores.

## Do Not Blind-Run

Do not run these just to fill a table. They need a method or checker decision first:

| Design | Current status |
|---|---|
| `aes_encryption` C4tl | seed `42` fails golden; C4i is already clean on `42,123,456` |
| `aes_decryption` | current C4i/C4tl rows are not golden-clean |
| `fft_streaming_64pt` | C2g seed `42` is golden-clean; C4i/C4tl seed `42` fail golden |
| `conv1d` C4tl | seed `42` is clean, but seeds `123,456` failed reference-decomposition validation |
| `conv2d` | current C4i/C4tl rows fail or partially match golden |
| `unsharp_mask` | current C4i/C4tl rows partially match golden |
| `harris_corner_detection` C4tl | current C4tl seed `42` fails golden; C4i is already clean on `42,123,456` |
| `systolic_gemm` | no reliable golden evidence in repo |
| `conv_3d` | diagnostic rows fail |
| `quantized_matmul` | diagnostic rows fail |
| `dct_idct_8pt_pipelined` | diagnostic rows fail |
| FIR-family designs | benchmark/spec-contract caveat unresolved |
