# Results

Last synchronized: 2026-07-17.

This is the canonical paper-facing result source. Original ArchXBench contracts,
repaired contracts, and held/excluded rows are reported separately. Historical
diagnostics do not override the tables below.

Trial identifiers `42,123,456` denote independent stochastic replications; the
provider does not expose deterministic model-seed control. C1 is pass@5 within
each trial. C1 uses five trials on `fp_adder` and `fp_multiplier`; main results
otherwise use three trials. C4tl Level-4 rows additionally use trials `789,1024`.

## Original-Contract Results

These are the 16 original-contract rows reported in the paper. Full rows solve
every main trial; partial rows solve at least one but not every main trial.

| Level | Design | C1 | C2g | C4i | C4tl | Evidence |
|---|---|---:|---:|---:|---:|---|
| L3 | `fp_adder` | 0/5 | 1/5 | 3/3 | 3/3 | self-checking; C1 is pass@5 per trial |
| L3 | `fp_multiplier` | 0/5 | 0/3 | 3/3 | 3/3 | self-checking |
| L3 | `gauss_siedel` | 0/3 | 0/3 | 3/3 | 1/3 | self-checking |
| L3 | `gradient_descent` | 0/3 | 0/3 | 3/3 | 3/3 | self-checking |
| L3 | `newton_raphson_sqrt` | 0/3 | 0/3 | 3/3 | 3/3 | self-checking |
| L3 | `newton_raphson_polynomial` | 0/3 | 0/3 | 0/3 | 0/3 | released checker ceiling: 97/100 |
| L4 | `fft_16pt_iterative` | 0/3 | 3/3 | 0/3 | 3/3 | self-checking; C4tl 5/5 with robustness trials |
| L4 | `ifft_16pt_iterative` | 0/3 | 3/3 | 0/3 | 3/3 | self-checking; C4tl 5/5 with robustness trials |
| L4 | `fp_adder_pipeline` | 3/3 | 3/3 | 3/3 | 3/3 | self-checking; C4tl 5/5 with robustness trials |
| L4 | `fp_mult_pipeline` | 3/3 | 3/3 | 3/3 | 3/3 | self-checking; C4tl 5/5 with robustness trials |
| L5 | `conv1d` | 3/3 | 3/3 | 3/3 | 3/3 | golden verified, 16/16 |
| L5 | `conv2d` | 0/3 | 3/3 | 0/3 | 0/3 | golden verified, 4096/4096 |
| L5 | `dct_idct_8pt_pipelined` | 0/3 | 3/3 | 0/3 | 0/3 | golden verified, 16/16 |
| L5 | `unsharp_mask` | 0/3 | 3/3 | 0/3 | 1/3 | golden verified, 65536/65536 |
| L6 | `aes_encryption` | 3/3 | 3/3 | 3/3 | 3/3 | golden verified, 8/8 |
| L6 | `aes_decryption` | 3/3 | 3/3 | 3/3 | 3/3 | golden verified, 8/8 |

Original-contract coverage is L3 6/6, L4 4/7, L5 4/6, and L6 2/9
released rows. Excluded or repaired-only rows are not counted as method failures.

## Figure 3 Counts

| Level | Coverage | C1 full/partial | C2g full/partial | C4i full/partial | C4tl full/partial |
|---|---:|---:|---:|---:|---:|
| L3 | 6/6 | 0/0 | 0/1 | 5/0 | 4/1 |
| L4 | 4/7 | 2/0 | 4/0 | 2/0 | 4/0 |
| L5 | 4/6 | 1/0 | 4/0 | 1/0 | 1/1 |
| L6 | 2/9 | 2/0 | 2/0 | 2/0 | 2/0 |

Figure 3 uses absolute verified row counts, not percentages over all released
rows.

## Repaired-Contract Results

These are not original ArchXBench solves. Every row uses a copied,
oracle-validated fixture and remains separate from the original-contract table.

| Design | C2g | C4i | C4tl | Interpretation |
|---|---:|---:|---:|---|
| `conv_3d` | 3/3 | 3/3 | 3/3 | repaired file/output contract makes the task executable |
| `multich_conv2d` | 3/3 | 3/3 | 3/3 | repaired executable contract |
| `quantized_matmul` | 3/3 | 3/3 | 3/3 | signed-quantization/runner-fixed contract |
| `harris_corner_detection` | 3/3 | 0/3 | 0/3 | exact repaired dimensions/cardinality/comparator; monolithic-only |
| `fp_band_pass_fir` | 3/3 | 1/3 | 2/3 | recovered and validated coefficient oracle |
| `fp_high_pass_fir` | 3/3 | 1/3 | 1/3 | recovered and validated coefficient oracle |
| `fp_low_pass_fir` | 3/3 | 1/3 | 2/3 | upstream-history oracle; released row remains held |
| `newton_raphson_polynomial` | 3/3 | 2/3 | 2/3 | repaired 97/97 checker |
| `systolic_gemm` | 3/3 | 3/3 | 3/3 | 32 exact checks; runner records 33/33 including summary token |

C2g fully solves all nine repaired rows. C4i and C4tl each fully solve four
rows and partially solve four more.

### Corrected Level-4 Q1.15 FIR Fixtures

These copied fixtures are reported separately from both the original table and
the nine-row repaired table above.

| Design | C2g | C4i | C4tl |
|---|---:|---:|---:|
| `band_pass_fir` | 3/3 | 0/3 | 0/3 |
| `high_pass_fir` | 2/3 | 0/3 | 0/3 |
| `low_pass_fir` | 2/3 | 0/3 | 0/3 |

## Second-Model Validation

Claude Sonnet 5 was evaluated on selected original hard-frontier rows.

| Design | C2g | C4tl |
|---|---:|---:|
| `fft_16pt_iterative` | 3/3 | 3/3 |
| `ifft_16pt_iterative` | 3/3 | 3/3 |
| `aes_encryption` | 3/3 GV | 0/3 GV |
| `aes_decryption` | 3/3 GV | 0/3 GV |

## Mechanism Ablation

| Design | Fixed-order C4i | Random-order C4i | C4tl main trials |
|---|---:|---:|---:|
| `fft_16pt_iterative` | 0/3 | 2/3 | 3/3 |
| `ifft_16pt_iterative` | 0/3 | 1/3 | 3/3 |

Random order improves the combined FFT/IFFT result from 0/6 to 3/6, below
C4tl's 6/6 main-trial result.

## Held Or Excluded

| Design/group | Status | Reason |
|---|---|---|
| Original L4 FIR family | excluded | released specification and executable coefficients disagree |
| Original `harris_corner_detection` | repaired-only | released dimensions/cardinality/comparator are not a credible exact oracle |
| Original `systolic_gemm` | repaired-only | released checker is display-only |
| Original L6 FP FIR family | repaired-only/held | recovered validated oracles are reported only under repaired contracts |
| `fft_streaming_64pt` | excluded | unresolved schema and numeric-encoding ambiguities |

## Evidence Policy

- File-output solves require strict golden verification and exact cardinality.
- Native simulation completion alone is not a solve.
- Original and repaired contracts must never be merged into one solve-rate denominator.
- Historical score-only diagnostics remain in the artifact inventory but do not
  override the canonical tables above.
