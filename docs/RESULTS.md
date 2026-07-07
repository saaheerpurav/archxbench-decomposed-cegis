# Results

This file contains clean result tables only. A row is a paper claim only if it appears here.

For paper table construction, use the separated plan in `docs/PAPER_AUDIT.md`:
original ArchXBench main evidence, baseline context, repaired-contract evidence, held/excluded rows, and artifact-backed vs score-only rows must stay separate.

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
| `aes_decryption` | L6 | C4i | `42,123,456` | 3/3 solved, all `8/8` | external golden JSON | clean L6 golden solve |

## Golden-Verified Secondary Rows

These rows are clean but not central claims yet.

| Design | Level | Method | Seed | Result | Why secondary |
|---|---:|---|---:|---|---|
| `conv1d` | L5 | C4tl | `42` | `16/16` golden | one seed only |
| `harris_corner_detection` | L5 | C2g | `42` | `16384/16384` golden | baseline context |
| `conv2d` | L5 | C2g | `42,123,456` | 3/3 solved, all `4096/4096` golden | strong baseline context |
| `dct_idct_8pt_pipelined` | L5 | C2g | `42,123,456` | 3/3 solved, all `16/16` golden | strong baseline context |
| `unsharp_mask` | L5 | C2g | `42,123,456` | 3/3 solved, all `65536/65536` golden | artifact-backed reruns |
| `aes_decryption` | L6 | C2g | `42,123,456` | 3/3 solved, all `8/8` golden | strong baseline context |

Artifacts are indexed in `artifacts/inventories/artifact_index.csv`; older showcase rows may also appear under `artifacts/curated/golden_verified_secondary/`.

## Diagnostics

Diagnostics are not claims. They live under `artifacts/curated/diagnostics/`.

Known diagnostic categories:

- native-pass but golden-fail rows, such as old L5/L6 seed-42 rows
- imported rows with no golden fields
- `conv1d` C4tl seeds `123,456`, which failed reference-decomposition validation
- failed debug rows for DCT, FIR-family designs, `conv_3d`, and `quantized_matmul`
- historical L4 FIR C4i GPT-5.5 log/metrics-only rows: `band_pass_fir` 0/5, `high_pass_fir` 2/5, `low_pass_fir` 1/5; see `artifacts/inventories/log_metric_only_results.csv`
- repaired L4 FIR pilot rows: C2g/C4i/C4tl seed `42` all fail on `band_pass_fir`, `high_pass_fir`, and `low_pass_fir`; best score is 5/1001
- repaired L6 FP FIR rows: C2g solves `fp_band_pass_fir` and `fp_high_pass_fir` 3/3 on validated repaired contracts; C4i/C4tl seed `42` pilots fail
- `fft_streaming_64pt` C2g is partial only: seed `42` solves `128/128`, while seeds `123,456,789,1024` fail; the released file-output schema/comparator is internally inconsistent
- `newton_raphson_polynomial` original checker appears capped at `97/100` because three root/residual checks are unsatisfiable simultaneously
- `systolic_gemm` rows without reliable golden evidence
- old score-only `unsharp_mask` C2g near-miss rows; current artifact-backed C2g reruns solve seeds `42,123,456`

### C4a Weak-Target Sweep

`C4a` was run as a targeted research attempt on the remaining weak targets with
`gpt-5.5`, seeds `42,123,456`. Two extra `newton_raphson_polynomial`
seeds (`789,1024`) were added on 2026-07-07 because the original C4a sweep
reached a near miss.

Artifacts: `artifacts/raw_runs/adaptive_c4a_weak_targets_20260704/`
Extra Newton artifacts: `artifacts/raw_runs/newton_poly_c4a_extra_20260707/`

| Design | Result |
|---|---|
| `unsharp_mask` | 0/3 solved; best `63780/65536` |
| `fft_streaming_64pt` | 0/3 solved; all `0/1` |
| `conv_3d` | 0/3 solved; all `0/0` |
| `quantized_matmul` | 0/3 solved; two `0/0`, one final compile failure |
| `newton_raphson_polynomial` | 0/5 solved in the main C4a sweep; separate debug artifact reaches `97/100`, matching the audited effective ceiling |

Conclusion: this is negative evidence. C4a should not be framed as a paper method improvement.

### Repaired-Contract Track

These rows are not original ArchXBench results. They use repaired executable contracts under
`artifacts/benchmark_contracts/archxbench_repaired/`.

Artifacts: `artifacts/raw_runs/repaired_contracts_20260705/`
Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`

| Design | Method | Seeds | Result | Interpretation |
|---|---|---|---|---|
| `conv_3d` repaired contract | C2g | `42,123,456` | 3/3 solved, all `23064/23064` golden | benchmark repair unlocks the task; C2g is strongest |
| `conv_3d` repaired contract | C4i | `42,123,456` | 2/3 solved, seeds `42,123` | partial decomposed result |
| `conv_3d` repaired contract | C4tl | `42,123,456` | 0/3 solved | negative |
| `multich_conv2d` repaired contract | C2g | `42,123,456` | 3/3 solved, all `30752/30752` golden | repaired contract is solvable |
| `multich_conv2d` repaired contract | C4i | `42,123,456` | 3/3 solved, all `30752/30752` golden | repaired contract is solvable |
| `multich_conv2d` repaired contract | C4tl | `42,123,456` | 3/3 solved, all `30752/30752` golden | repaired contract is solvable |
| `quantized_matmul` repaired contract, initial | C2g/C4i/C4tl | `42,123,456` each | 0/9 solved | exposed remaining signed-quantization and runner issues |
| `quantized_matmul` repaired contract, runner-fixed | C2g | `42,123,456` | 3/3 solved, all `64/64` golden | repaired contract is solvable |
| `quantized_matmul` repaired contract, runner-fixed | C4i | `42,123,456` | 3/3 solved, all `64/64` golden | repaired contract is solvable |
| `quantized_matmul` repaired contract, runner-fixed | C4tl | `42,123,456` | 0/3 solved | reference decomposition failed |
| `fp_band_pass_fir` repaired contract | C2g | `42,123,456` | 3/3 solved, all `1000/1000` golden | repaired contract is solvable; C2g is strongest |
| `fp_band_pass_fir` repaired contract | C4i/C4tl | `42` | C4i `804/1000`, C4tl `0/1000` | negative pilot |
| `fp_high_pass_fir` repaired contract | C2g | `42,123,456` | 3/3 solved, all `1000/1000` golden | repaired contract is solvable; C2g is strongest |
| `fp_high_pass_fir` repaired contract | C4i/C4tl | `42` | C4i `969/1000`, C4tl `969/1000` | near-miss negative pilot |
| `newton_raphson_polynomial` repaired contract | C2g | `42,123,456` | 3/3 solved, all `97/97` | original checker has 3 unsatisfiable residual checks; repaired checker is oracle-validated |
| `newton_raphson_polynomial` repaired contract | C4i | `42,123,456` | 1/3 solved, seed `456`; other scores `87/97`, `89/97` | partial repaired-contract result |
| `newton_raphson_polynomial` repaired contract | C4tl | `42,123,456` | 1/3 solved, seed `456`; other scores `16/97`, `17/97` | partial repaired-contract result |
| `systolic_gemm` repaired contract | C2g | `42,123,456` | 0/3 solved | 30-call monolithic repair failed all seeds |
| `systolic_gemm` repaired contract | C4i | `42,123,456` | 0/3 solved | all seeds failed final compile |
| `systolic_gemm` repaired contract | C4tl | `42,123,456` | 0/3 solved | reference decompositions failed |

Do not merge these rows into original ArchXBench solve-rate tables.
