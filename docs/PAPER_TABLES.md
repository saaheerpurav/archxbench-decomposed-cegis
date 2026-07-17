# Paper Tables

Last synchronized: 2026-07-17.

This is the compact source for the ASP-DAC paper's result tables and Figure 3.
Use `RESULTS.md` for evidence details.

## Reporting Rules

- C1 is direct pass@5 within each independent trial.
- Trial IDs `42,123,456` are stochastic replications, not controlled model seeds.
- Original, repaired, and held/excluded contracts remain separate.
- File-output solves require strict golden verification.
- Extra C4tl Level-4 trials `789,1024` are robustness evidence.

## Original-Contract Heatmap

| Level | Design | C1 | C2g | C4i | C4tl |
|---|---|---:|---:|---:|---:|
| L3 | `fp_adder` | 0/5 | 1/5 | 3/3 | 3/3 |
| L3 | `fp_multiplier` | 0/5 | 0/3 | 3/3 | 3/3 |
| L3 | `gauss_siedel` | 0/3 | 0/3 | 3/3 | 1/3 |
| L3 | `gradient_descent` | 0/3 | 0/3 | 3/3 | 3/3 |
| L3 | `newton_raphson_sqrt` | 0/3 | 0/3 | 3/3 | 3/3 |
| L3 | `newton_raphson_polynomial` | 0/3 | 0/3 | 0/3 | 0/3 |
| L4 | `fft_16pt_iterative` | 0/3 | 3/3 | 0/3 | 3/3 |
| L4 | `ifft_16pt_iterative` | 0/3 | 3/3 | 0/3 | 3/3 |
| L4 | `fp_adder_pipeline` | 3/3 | 3/3 | 3/3 | 3/3 |
| L4 | `fp_mult_pipeline` | 3/3 | 3/3 | 3/3 | 3/3 |
| L5 | `conv1d` | 3/3 | 3/3 | 3/3 | 3/3 |
| L5 | `conv2d` | 0/3 | 3/3 | 0/3 | 0/3 |
| L5 | `dct_idct_8pt_pipelined` | 0/3 | 3/3 | 0/3 | 0/3 |
| L5 | `unsharp_mask` | 0/3 | 3/3 | 0/3 | 1/3 |
| L6 | `aes_encryption` | 3/3 | 3/3 | 3/3 | 3/3 |
| L6 | `aes_decryption` | 3/3 | 3/3 | 3/3 | 3/3 |

Coverage shown/released: L3 6/6, L4 4/7, L5 4/6, L6 2/9.

## Figure 3

Panel (a), 16 evaluated original-contract rows:

| Condition | Full | Partial | Unsolved |
|---|---:|---:|---:|
| C1 | 5 | 0 | 11 |
| C2g | 10 | 1 | 5 |
| C4i | 10 | 0 | 6 |
| C4tl | 11 | 2 | 3 |

Panel (b), nine independently validated repaired-contract rows:

| Condition | Full | Partial | Unsolved |
|---|---:|---:|---:|
| C2g | 9 | 0 | 0 |
| C4i | 4 | 4 | 1 |
| C4tl | 4 | 4 | 1 |

The panels use separate absolute-count axes and contract populations. C1 is
omitted from the repaired panel because it was not evaluated there.

## Repaired-Contract Table

| Design | C2g | C4i | C4tl |
|---|---:|---:|---:|
| `conv_3d` | 3/3 | 3/3 | 3/3 |
| `multich_conv2d` | 3/3 | 3/3 | 3/3 |
| `quantized_matmul` | 3/3 | 3/3 | 3/3 |
| `harris_corner_detection` | 3/3 | 0/3 | 0/3 |
| `fp_band_pass_fir` | 3/3 | 1/3 | 2/3 |
| `fp_high_pass_fir` | 3/3 | 1/3 | 1/3 |
| `fp_low_pass_fir` | 3/3 | 1/3 | 2/3 |
| `newton_raphson_polynomial` | 3/3 | 2/3 | 2/3 |
| `systolic_gemm` | 3/3 | 3/3 | 3/3 |

## Second-Model Table

| Design | Sonnet 5 C2g | Sonnet 5 C4tl |
|---|---:|---:|
| `fft_16pt_iterative` | 3/3 | 3/3 |
| `ifft_16pt_iterative` | 3/3 | 3/3 |
| `aes_encryption` | 3/3 GV | 0/3 GV |
| `aes_decryption` | 3/3 GV | 0/3 GV |

## Paper Interpretation

- Strongest clean frontier evidence: original FFT/IFFT under C2g and C4tl.
- Strongest decomposition-over-monolith evidence: matched GPT-5.5 L3 trials.
- C2g is a primary baseline and fully solves every row in the repaired table.
- C4tl's Level-4 5/5 evidence is robustness, not an exclusive main-trial win
  over C2g.
- Harris appears only in the repaired table.
