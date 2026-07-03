# Results

This file contains clean result tables only. A row is a paper claim only if it appears here.

## Main Claims

All rows use GPT-5.5 or Codex GPT-5.5 as recorded in `result.json`.

| Design | Level | Method | Seeds | Result | Verification | Interpretation |
|---|---:|---|---|---|---|---|
| `fp_multiplier` | L3 | C4i | `42,123,456` | 3/3 solved, all `10/10` | official self-checking testbench | solved, not exclusive |
| `fp_adder` | L3 | C4i | `42,123,456` | 3/3 solved, all `36/36` | official self-checking testbench | solved, not exclusive |
| `newton_raphson_sqrt` | L3 | C4i | `42,123,456` | 3/3 solved, all `50/50` | official self-checking testbench | solved, not exclusive |
| `gauss_siedel` | L3 | C4i | `42,123,456` | 3/3 solved, all `50/50` | official self-checking testbench | C4i win over C2g |
| `gradient_descent` | L3 | C4i | `42,123,456` | 3/3 solved, all `50/50` | official self-checking testbench | C4i win over C2g |
| `newton_raphson_polynomial` | L3 | C4i | `42,123,456` | 0/3 solved, best `89/100` | official self-checking testbench | negative result |
| `fp_mult_pipeline` | L4 | C4tl | `42,123,456,789,1024` | 5/5 solved, all `31/31` | official self-checking testbench | robust L4 solve |
| `fp_adder_pipeline` | L4 | C4tl | `42,123,456,789,1024` | 5/5 solved, all `23/23` | official self-checking testbench | robust L4 solve |
| `fft_16pt_iterative` | L4 | C4tl | `42,123,456,789,1024` | 5/5 solved, all `33/33` | official self-checking testbench | robust L4 solve |
| `ifft_16pt_iterative` | L4 | C4tl | `42,123,456,789,1024` | 5/5 solved, all `33/33` | official self-checking testbench | robust L4 solve |
| `harris_corner_detection` | L5 | C4i | `42,123,456` | 3/3 solved, all `16384/16384` | external golden JSON | solved, not exclusive |
| `conv1d` | L5 | C4i | `42,123,456` | 3/3 solved, all `16/16` | external golden JSON | clean L5 golden solve |
| `aes_encryption` | L6 | C4i | `42,123,456` | 3/3 solved, all `8/8` | external golden JSON | clean L6 golden solve |

## Golden-Verified Secondary Rows

These rows are clean but not central claims yet.

| Design | Level | Method | Seed | Result | Why secondary |
|---|---:|---|---:|---|---|
| `conv1d` | L5 | C4tl | `42` | `16/16` golden | one seed only |
| `harris_corner_detection` | L5 | C2g | `42` | `16384/16384` golden | baseline context |

Artifacts live under `artifacts/curated/golden_verified_secondary/`.

## Diagnostics

Diagnostics are not claims. They live under `artifacts/curated/diagnostics/`.

Known diagnostic categories:

- native-pass but golden-fail rows, such as old L5/L6 seed-42 rows
- imported rows with no golden fields
- `conv1d` C4tl seeds `123,456`, which failed reference-decomposition validation
- failed debug rows for DCT, FIR-family designs, `conv_3d`, and `quantized_matmul`
- `systolic_gemm` rows without reliable golden evidence
