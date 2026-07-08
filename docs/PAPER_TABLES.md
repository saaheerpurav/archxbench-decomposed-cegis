# Paper Tables

Date: 2026-07-09

Working paper title:

**Autonomous Synthesis of Hard RTL Designs via Iterative Repair and Modular Decomposition**

This file is the paper-facing table source. It uses only existing repo-local evidence. It does not request or imply any reruns.

Rules:

- Original ArchXBench rows and repaired-contract rows must be reported separately.
- Main seeds are `42,123,456`.
- Extra C4tl L4 seeds `789,1024` are robustness/appendix evidence.
- Trusted score-only rows are valid result evidence when labeled, but are not artifact-backed.
- Held/excluded rows are not failures to run; they are benchmark-contract decisions.

## Table 1: Main Original ArchXBench Evidence

| Level | Design(s) | Main result | Evidence class | Interpretation |
|---|---|---|---|---|
| L3 | `fp_adder`, `fp_multiplier`, `gauss_siedel`, `gradient_descent`, `newton_raphson_sqrt` | C4i solves 3/3 on all five | artifact-backed | strongest method-value evidence over C1/C2g |
| L3 | `fp_adder`, `fp_multiplier`, `gradient_descent`, `newton_raphson_sqrt` | C4tl solves 3/3 | artifact-backed | C4tl support evidence |
| L3 | `gauss_siedel` | C4tl solves 1/3 | artifact-backed | C4i is stronger on this row |
| L4 | `fft_16pt_iterative`, `ifft_16pt_iterative`, `fp_adder_pipeline`, `fp_mult_pipeline` | C4tl solves 3/3 main seeds; 5/5 including robustness seeds | artifact-backed | strongest hard-level coverage evidence |
| L5 | `conv1d`, `harris_corner_detection` | C4i solves 3/3 with golden verification | artifact-backed | clean L5 golden evidence |
| L6 | `aes_encryption`, `aes_decryption` | C4i solves 3/3 with golden verification | artifact-backed | clean L6 golden evidence |

## Table 2: Baseline Context

| Level | Design(s) | Baseline result | Evidence class | Interpretation |
|---|---|---|---|---|
| L3 | `fp_adder` | C2g solves 1/5; C1 solves 0/5 | artifact-backed/logged matrix | C4i/C4tl improve over direct prompting |
| L3 | `fp_multiplier`, `gauss_siedel`, `gradient_descent`, `newton_raphson_sqrt` | C1/C2g solve 0/3 or 0/5 | artifact-backed/logged matrix | C4i gives the cleanest L3 method-value evidence |
| L4 | `fft_16pt_iterative`, `ifft_16pt_iterative` | C2g solves 3/3; C1/C4i solve 0/3 | artifact-backed/logged matrix | C2g is a strong baseline on some hard rows |
| L4 | `fp_adder_pipeline`, `fp_mult_pipeline` | C1/C2g/C4i/C4tl all solve 3/3 main seeds | artifact-backed/logged matrix | not exclusive method wins |
| L5 | `conv2d`, `dct_idct_8pt_pipelined`, `unsharp_mask` | C2g solves 3/3 with golden verification | artifact-backed | C2g is strongest on these rows |
| L5 | `conv1d`, `harris_corner_detection` | C1/C2g also solve 3/3 where present | artifact-backed for C2g rows | useful ablation context |
| L6 | `aes_encryption`, `aes_decryption` | C1/C2g are strong; C2g solves 3/3 | artifact-backed for C2g rows | C4i does not dominate C2g globally |

## Table 3: Repaired Executable-Contract Evidence

These rows are not original ArchXBench solves.

| Design | Repaired-contract result | Evidence class | Interpretation |
|---|---|---|---|
| `conv_3d` | C2g 3/3, C4i 2/3, C4tl 0/3 | artifact-backed for C2g and solved C4i rows | benchmark-contract repair unlocks intended task |
| `multich_conv2d` | C2g/C4i/C4tl all 3/3 | artifact-backed | clean repaired-contract validation |
| `quantized_matmul` runner-fixed | C2g 3/3, C4i 3/3, C4tl 0/3 | artifact-backed | file-format/runner contract mattered |
| `fp_band_pass_fir` | C2g 3/3; C4i/C4tl seed-42 pilots fail | artifact-backed | repaired-contract C2g win |
| `fp_high_pass_fir` | C2g 3/3; C4i/C4tl seed-42 pilots fail/near-miss | artifact-backed | repaired-contract C2g win |
| `newton_raphson_polynomial` | C2g 3/3, C4i 1/3, C4tl 1/3 on `97/97` repaired checker | artifact-backed | original checker has three unsatisfiable residual checks |
| `systolic_gemm` | C2g/C4i/C4tl all 0/3 after checker repair | artifact-backed | genuine capability boundary |
| L4 FIR family | C2g/C4i/C4tl seed-42 pilots all fail | artifact-backed | negative benchmark-audit evidence |

## Table 4: Held Or Excluded Rows

| Design/group | Status | Paper wording |
|---|---|---|
| L4 `band_pass_fir`, `high_pass_fir`, `low_pass_fir` | exclude from positive tables | inconsistent evaluation contracts where specification and executable testbench disagree on filter coefficients/source-of-truth behavior |
| L6 `fp_low_pass_fir` | hold | released files do not expose an explicit coefficient/cutoff oracle |
| L6 `fft_streaming_64pt` | exclude | unresolved input/output contract ambiguities, including mismatched output schema and input numeric encoding |
| L5 `systolic_gemm` | negative repaired-contract row | after converting display-only expected matrices into executable checks, all methods remain 0/3 |

## Table 5: Full L3-L6 Accounting

| Category | Designs |
|---|---|
| Clean original-contract positive rows | `fp_adder`, `fp_multiplier`, `gauss_siedel`, `gradient_descent`, `newton_raphson_sqrt`, `fft_16pt_iterative`, `ifft_16pt_iterative`, `fp_adder_pipeline`, `fp_mult_pipeline`, `conv1d`, `conv2d`, `dct_idct_8pt_pipelined`, `harris_corner_detection`, `unsharp_mask`, `aes_encryption`, `aes_decryption` |
| Original-contract partial/negative diagnostics | `newton_raphson_polynomial`, `fft_streaming_64pt` |
| Repaired-contract rows | `conv_3d`, `multich_conv2d`, `quantized_matmul`, `fp_band_pass_fir`, `fp_high_pass_fir`, `newton_raphson_polynomial`, `systolic_gemm`, L4 FIR family |
| Held/excluded | L4 FIR family from positive tables, `fp_low_pass_fir`, `fft_streaming_64pt` |

## Final Pre-Paper Status

No experiment run is currently queued.

Remaining work before submission is paper writing and final manuscript consistency checks. The Priority 1 and Priority 2 C2g artifact-collection reruns were completed on 2026-07-09.
