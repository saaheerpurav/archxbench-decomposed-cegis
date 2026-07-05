# Paper Audit

Date: 2026-07-05

This is the paper-readiness and baseline gap map. It is derived from `artifacts/inventories/run_matrix_l3_l6.csv` plus the C4a diagnostic sweep in `artifacts/raw_runs/adaptive_c4a_weak_targets_20260704/`.

## Bottom Line

The current paper is viable only if it is framed honestly:

- Strong: hard ArchXBench RTL synthesis can be solved across L3-L6 with verifier-grounded decomposed/CEGIS-style pipelines.
- Strong: C4i has clear wins on selected L3 designs where C1/C2g fail.
- Strong: C4tl robustly solves the four core L4 rows across five seeds.
- Strong: L5/L6 golden-verified solves exist, including `conv1d`, `harris_corner_detection`, `aes_encryption`, and `aes_decryption`.
- Weak: C4i/C4tl do not dominate C2g globally.
- Weak: C2g is the clean winner on several L5 rows.
- Negative: C4a was tried on all weak targets and got 0/15 solves.

The paper should not claim a universal method win. It should claim a verified, decomposed RTL synthesis pipeline with hard benchmark solves, clear ablations, and transparent benchmark caveats.

## Official L3-L6 Coverage

ArchXBench L3-L6 has 28 designs in this repo.

| Category | Designs |
|---|---|
| Clean main/secondary solves | `fp_adder`, `fp_multiplier`, `gauss_siedel`, `gradient_descent`, `newton_raphson_sqrt`, `fft_16pt_iterative`, `ifft_16pt_iterative`, `fp_adder_pipeline`, `fp_mult_pipeline`, `conv1d`, `conv2d`, `dct_idct_8pt_pipelined`, `harris_corner_detection`, `aes_encryption`, `aes_decryption` |
| Partial or unsolved but valid diagnostics | `newton_raphson_polynomial`, `unsharp_mask`, `fft_streaming_64pt`, `conv_3d`, `quantized_matmul` |
| Excluded or hold | `band_pass_fir`, `high_pass_fir`, `low_pass_fir`, `fp_band_pass_fir`, `fp_high_pass_fir`, `fp_low_pass_fir`, `systolic_gemm` |

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
| L6 | `aes_encryption` | C1 3/3, C2g 3/3, C4i 3/3, C4tl 2/3 |
| L6 | `aes_decryption` | C1 1/3, C2g 3/3, C4i 3/3, C4tl 1/3 |

Interpretation:

- L3 is the cleanest evidence that C4i adds value over C1/C2g.
- L4 is strong coverage evidence, but not always an exclusive method win because C2g also solves FFT/IFFT and pipelines are easy for multiple conditions.
- L5/L6 are strong capability evidence, but C2g must be treated as a serious baseline and often matches or beats C4i/C4tl.

## Negative And Partial Rows

| Design | Current best evidence |
|---|---|
| `newton_raphson_polynomial` | C4i best `89/100`; C4a best `96/100`; no clean solve |
| `unsharp_mask` | C2g best `65535/65536`; C4a best `63780/65536`; no clean solve |
| `fft_streaming_64pt` | C2g has one clean seed `128/128`, but not robust across seeds; C4i/C4tl/C4a fail |
| `conv_3d` | C1/C2g/C4i/C4tl/C4a all fail cleanly |
| `quantized_matmul` | C1/C2g/C4i/C4tl/C4a all fail cleanly |

## Exclusions And Holds

| Design group | Status |
|---|---|
| FIR family | Exclude unless the benchmark/spec-contract issue is repaired and documented. Some rows show apparent C2g solves, but these should not become claims while the FIR contract remains disputed. |
| `systolic_gemm` | Hold. Existing pass rows do not provide reliable golden evidence. |
| `multich_conv2d` | Original contract issue. Repaired-contract rows are complete and must stay separate from original ArchXBench tables. |

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
   - repair or formally validate excluded benchmark checkers
   - targeted benchmark-specific repair for `unsharp_mask` or `newton_raphson_polynomial`
   - a new verification-driven method that attacks `conv_3d` or `quantized_matmul`
5. Avoid claiming C4a. It is negative evidence.

## Current Run Recommendation

No table-filling run is currently required for the existing claims.

The repaired-contract track has now been run:

- repaired `conv_3d`: C2g 3/3, C4i 2/3, C4tl 0/3
- repaired `multich_conv2d`: C2g 3/3, C4i 3/3, C4tl 3/3
- repaired `quantized_matmul`, initial file-format repair: C2g/C4i/C4tl all 0/3
- repaired `quantized_matmul`, after signed-quantization clarification and runner fix: C2g 3/3, C4i 3/3, C4tl 0/3
- these rows must remain separate from original ArchXBench tables

Current highest-value next attempts:

- repair/validate the FIR and `systolic_gemm` benchmark contracts, then rerun only if the checker is trustworthy
- targeted solve attempt on `unsharp_mask`, because it is a near miss at `65535/65536`
- targeted solve attempt on `newton_raphson_polynomial`, because C4a reached `96/100`
