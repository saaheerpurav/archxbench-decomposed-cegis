# Executable Contract Repair

Last synchronized: 2026-07-17

Detailed chronology below preserves early pilots where useful. The final
paper-facing outcomes are the nine-row repaired table in `RESULTS.md`; later
acceptance-repaired runs supersede the early pilot totals.

This is the current stronger-method direction. It is separate from the original ArchXBench claim tables.

## Idea

Some hard ArchXBench failures are not only synthesis failures. A few rows have benchmark-contract problems: the spec, testbench, reference model, file format, or golden comparator do not agree.

Executable Contract Repair treats the benchmark contract itself as an object to audit:

1. Compare the natural-language spec, testbench, Python/reference model, input files, and golden files.
2. Repair only infrastructure/spec-contract inconsistencies.
3. Keep the original benchmark unchanged.
4. Put repaired contracts under `artifacts/benchmark_contracts/`.
5. Run synthesis methods against the repaired contract and report those results separately.

This is not a way to relabel old failures as solves. A repaired-contract result must be described as a result on the repaired ArchXBench contract.

## Current Repaired Contracts

Repaired root:

`artifacts/benchmark_contracts/archxbench_repaired/`

Generator:

`scripts/prepare_repaired_archxbench_contracts.py`

Use it with:

```powershell
python scripts\prepare_repaired_archxbench_contracts.py
$env:ARCHXBENCH_ROOT=(Resolve-Path artifacts\benchmark_contracts\archxbench_repaired).Path
```

The runner supports this via `ARCHXBENCH_ROOT`; the default remains the original benchmark root.

## `multich_conv2d`

Original contract issue:

- Python reference uses all-ones kernels and zero bias.
- Testbench drove `kernel = 0` and `bias = 0`, so the executable test did not match the reference/golden.
- Testbench opened `outputs/dut_output.json` only after all inputs were sent, which can drop valid streaming outputs emitted during input ingestion.
- Testbench had fragile JSON comma handling and no expected output-count check.
- Testbench emits no native PASS/FAIL tokens in the original benchmark, so post-simulation golden comparison is mandatory.

Repair:

- Drive all-ones kernels and zero bias, matching the Python reference.
- Open `dut_output.json` before streaming begins.
- Record every `valid_out` sample until exactly `COUT*(H-K+1)*(W-K+1)` outputs have been written.
- Emit valid JSON with deterministic comma handling.
- Add an output-count PASS/FAIL display for infrastructure sanity.

Sanity check:

- A hardcoded oracle DUT that emits the official golden sequence compiles/runs and reports `30752/30752`.

Repaired-contract run:

- Artifacts: `artifacts/raw_runs/repaired_contracts_multich_conv2d_20260705/`
- Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`
- C2g, seeds `42,123,456`: 3/3 clean solves, all `30752/30752` golden.
- C4i, seeds `42,123,456`: 3/3 clean solves, all `30752/30752` golden.
- C4tl, seeds `42,123,456`: 3/3 clean solves, all `30752/30752` golden.
- Interpretation: repairing the executable contract unlocks `multich_conv2d` for all three methods. This is a benchmark-contract result, not a C4-specific method win.

## `quantized_matmul`

Original contract issue:

- Testbench reads `tb_float.mem`, but the benchmark data bundle provides `tb_data.mem`.
- Testbench emits packed FP32 bit-pattern integers.
- Golden JSON stores floating-point numeric values.
- The generic golden comparator compares numeric JSON values, so packed FP32 integers and floats are not comparable.
- The design spec did not explicitly say that internal quantization follows signed no-saturation Python semantics. The official stimulus has negative `B_q` values; many generated RTLs incorrectly clamped quantized values to unsigned `0..255`.
- The runner incorrectly skipped golden comparison when a file-output testbench emitted no native PASS/FAIL tokens. `tb_qgemm.v` prints `[TB] Simulation done.` and relies on JSON comparison.

Repair:

- Generate `tb_float.mem` from `inputs/stimuli.json`.
- Regenerate `tb_params.mem` from the same stimuli.
- Normalize `outputs/golden_output.json` to flattened FP32 bit-pattern integers.
- Document signed two's-complement INT8, no-clamp quantization semantics.
- Fix the runner so file-output designs run golden comparison even with zero native PASS/FAIL tokens.
- Append repaired-contract notes to `design-specs.txt`.

Sanity check:

- A dummy all-zero `qgemm` compiles/runs and reports a normal golden mismatch: `0/64`.

Initial repaired-contract run:

- Artifacts: `artifacts/raw_runs/repaired_contracts_20260705/`
- Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`
- C2g, seeds `42,123,456`: 0/3 clean solves, all `0/0`.
- C4i, seeds `42,123,456`: 0/3 clean solves, all `0/0`.
- C4tl, seeds `42,123,456`: 0/3 clean solves, all `0/0`.
- Interpretation: this exposed the remaining signed-quantization spec issue and the runner PASS-token bug.

Runner-fix repaired-contract run:

- Artifacts: `artifacts/raw_runs/repaired_contracts_qgemm_runnerfix_pilot_20260705/`
- Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`
- C2g, seeds `42,123,456`: 3/3 clean solves, all `64/64` golden.
- C4i, seeds `42,123,456`: 3/3 clean solves, all `64/64` golden.
- The initial C4tl attempt was 0/3 because reference decomposition failed before
  repair. The later acceptance-repaired run solves C4tl 3/3.
- Final result: C2g/C4i/C4tl each solve 3/3. This is a repaired-contract result,
  not an original ArchXBench solve or an exclusive C4 win.

## `conv_3d`

Original contract issue:

- Python reference uses a 3x3x3 all-ones kernel.
- Testbench drives `kernel = 0`.
- Testbench writes an output every input cycle instead of only valid convolution outputs.
- Output width is too small for max `27 * 255 = 6885`.

Repair:

- Drive an all-ones kernel in the testbench.
- Write `dut_output.json` only when `valid_out` is true.
- Expect exactly `(D-K1+1)*(H-K2+1)*(W-K3+1)` outputs.
- Use sufficient output width.
- Append repaired-contract notes to `design-specs.txt`.

Sanity check:

- A dummy all-zero `conv3d` compiles/runs and reports a normal golden mismatch: `0/23064`.

Repaired-contract run:

- Artifacts: `artifacts/raw_runs/repaired_contracts_20260705/`
- Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`
- C2g, seeds `42,123,456`: 3/3 clean solves, all `23064/23064` golden.
- The early run produced C4i 2/3 and C4tl 0/3. The later
  `acceptance_repaired_codex_gpt55_20260716` run supplies the missing C4i trial
  and C4tl 3/3.
- Final result: C2g/C4i/C4tl each solve 3/3. The win is not method-exclusive.

## `systolic_gemm`

Original contract issue:

- The original testbench prints actual and expected matrices, but it does not emit machine-readable `[PASS]` or `[FAIL]` checks.
- Existing native-pass rows are therefore not reliable evidence of correctness.
- The expected values are present in the original testbench text, so this is repairable without inventing a new oracle.

Repair:

- Preserve the two original test cases: `A x A` for values `1..16` and `A x I` for values `0..15`.
- Convert the expected matrices already printed by the original testbench into 32 exact 64-bit result checks.
- Remove the testbench-local `include` directive; the runner supplies the generated DUT as `systolic_matrix_mult.v`.
- Append repaired-contract notes to `design-specs.txt`.

Sanity check:

- `scripts/validate_repaired_systolic_contract.py` confirms that the loader selects repaired `tb.v`.
- A hardcoded oracle DUT compiles/runs and passes all 32 exact output checks.
- Validation artifacts: `artifacts/contract_validation/systolic_20260716/`.

Repaired-contract run:

- The earlier `repaired_contracts_20260705` systolic rows are superseded: the repair generator wrote `testbench.v`, while the loader selected the unchanged display-only `tb.v`.
- Corrected artifacts: `artifacts/raw_runs/repaired_contracts_systolic_codex_gpt55_20260716/`
- Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`
- C2g, seeds `42,123,456`: 3/3 clean solves.
- C4i, seeds `42,123,456`: 3/3 clean solves.
- C4tl, seeds `42,123,456`: 3/3 clean solves.
- Every saved RTL artifact independently replays at `33/33` runner tokens: 32 assertion PASS lines plus one PASS token in the summary line.
- Interpretation: once the intended checker is executable and actually selected, all three methods solve the repaired `systolic_gemm` contract. This does not convert the original display-only rows into original-contract solves.

## FIR Family

Original contract issue:

- L4 FIR directories contain two executable contracts: stale file-output testbenches and large embedded-golden `tb_selfcheck.v` files.
- The stale L4 file-output testbenches use outdated parameters and JSON plumbing, while the specs contain repaired coefficient/parameter text.
- L6 `fp_band_pass_fir` and `fp_high_pass_fir` load coefficients through `dut.coeffs[j]`, which assumes a hidden internal DUT memory name that is not part of the module interface.
- L6 `fp_low_pass_fir` has inconsistent filenames (`stimuli_fp.json`, `lowpass_out_fp.json`) and does not expose the coefficient oracle in the testbench.
- The generic runner previously treated L4 self-checking FIR directories as file-output golden tests because `inputs/outputs` folders were present.

Repair:

- L4 `band_pass_fir`, `high_pass_fir`, and `low_pass_fir`: create repaired fixtures that remove the stale file-output testbench and keep only `tb_selfcheck.v`.
- L6 `fp_band_pass_fir` and `fp_high_pass_fir`: remove hidden `dut.coeffs` writes; require coefficients to be hard-coded from the public coefficient list.
- L6 `fp_band_pass_fir` and `fp_high_pass_fir`: repair file-output JSON comma handling so entries are separated according to actual `valid_out` writes.
- L6 `fp_low_pass_fir`: copy into the repaired root for audit completeness, but keep it held out because the coefficient oracle is still not explicit.
- Runner: self-checking `tb_selfcheck.v` directories no longer trigger file-output golden comparison just because stale `inputs/outputs` folders exist.
- Runner: 32-bit hex JSON words are compared as IEEE-754 floats with the benchmark's `+/-1.0` tolerance.

Validation:

- Script: `scripts/validate_repaired_fp_fir_contracts.py`
- Artifacts: `artifacts/contract_validation/fp_fir_20260707/`
- Oracle validation: `fp_band_pass_fir` 1000/1000 and `fp_high_pass_fir` 1000/1000 through the repaired executable testbenches.

Corrected Level-4 Q1.15 FIR result:

- Final artifacts include
  `artifacts/raw_runs/acceptance_repaired_codex_gpt55_20260716/`.
- Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`
- C2g: `band_pass_fir` 3/3, `high_pass_fir` 2/3, `low_pass_fir` 2/3.
- C4i and C4tl: 0/3 on all three designs.
- Interpretation: the corrected fixtures unlock monolithic solves but add no
  full-row decomposed result. They remain separate from the nine-row repaired
  table and from original-contract results.

Repaired L6 FP FIR run:

- Artifacts: `artifacts/raw_runs/repaired_fp_fir_c2g_pilot_20260707/`
- Artifacts: `artifacts/raw_runs/repaired_fp_fir_c2g_seeds_20260707/`
- Artifacts: `artifacts/raw_runs/repaired_fp_fir_c4_pilot_20260707/`
- Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`
- C2g, seeds `42,123,456`: `fp_band_pass_fir` 3/3 solved, all `1000/1000`; `fp_high_pass_fir` 3/3 solved, all `1000/1000`.
- Final acceptance-repaired results on trials `42,123,456` are:
  `fp_band_pass_fir` C2g 3/3, C4i 1/3, C4tl 2/3;
  `fp_high_pass_fir` 3/3, 1/3, 1/3; and
  `fp_low_pass_fir` 3/3, 1/3, 2/3.
- The low-pass repaired oracle was recovered from official upstream history and
  independently validated; the released row remains held.
- Interpretation: C2g fully solves all three repaired rows; decomposed methods
  add partial, not full-row, coverage.

## `newton_raphson_polynomial`

Original contract issue:

- The released self-checking testbench performs 100 checks: 50 root-comparison checks and 50 polynomial residual checks.
- Three residual checks are unsatisfiable together with the root-comparison requirement:
  - case 6 has no real root but still requires a low residual;
  - case 13 is the constant polynomial `p(x)=1`;
  - case 35's real-Newton reference does not land near a residual-zero point within the fixed-point tolerance.
- The effective original-checker ceiling is therefore `97/100`, not `100/100`.

Repair:

- Preserve all 50 root-comparison checks.
- Preserve the 47 satisfiable polynomial residual checks.
- Convert only residual checks 6, 13, and 35 into explicit `SKIP_REPAIRED_CONTRACT` messages with no `[PASS]` or `[FAIL]` token.
- Append repaired-contract notes to `design-specs.txt`.

Validation:

- Script: `scripts/validate_repaired_newton_contract.py`
- Artifacts: `artifacts/contract_validation/newton_20260707/`
- Oracle validation: `97/97` checks pass, 3 repaired-contract skips are emitted, and no failures occur.

Repaired-contract run:

- Corrected C2g artifacts: `artifacts/raw_runs/repaired_newton_codex_gpt55_20260716/`
- C4i/C4tl artifacts include
  `artifacts/raw_runs/acceptance_repaired_codex_gpt55_20260716/`.
- Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`
- C2g, seeds `42,123,456`: 3/3 solved, all `97/97`; every saved winner independently replays at `97/97`.
- C4i, trials `42,123,456`: 2/3 solved.
- C4tl, trials `42,123,456`: 2/3 solved.
- Interpretation: the repaired contract makes the intended task executable, but C2g is strongest. This is not a C4i/C4tl method win.

## `harris_corner_detection`

The released testbench instantiates a 256x256 image although the released public
interface and files contain 128x128 samples, and its plus-or-minus-one comparator
accepts every binary 0/1 mismatch. The copied acceptance-repaired fixture restores
the released dimensions, exact output cardinality, and exact comparison.

Final trials `42,123,456`: C2g 3/3, C4i 0/3, C4tl 0/3. Harris is therefore a
repaired-contract, monolithic-only result; legacy folders labelled `original` or
`main_claims` do not change that classification.

## `fft_streaming_64pt`

Current status:

- A repaired-contract fixture is copied under `artifacts/benchmark_contracts/archxbench_repaired/level-6/fft_streaming_64pt/` only as a hold/audit record.
- It is not a runnable repaired-contract claim.

Reason:

- The released golden file uses a dict with `real_out` and `imag_out` arrays.
- The testbench writes a list of objects with `real` and `imag` fields.
- The comparator is a copied scalar-filter comparator and cannot compare this FFT structure.
- The input path is also ambiguous: stimuli are JSON floats / FP32 hex words, while the testbench reads decimal integer pairs into 16-bit signed ports.

Decision:

- Do not run more original-contract seeds.
- Do not create a positive repaired-contract row unless both input encoding and output schema are specified and an oracle DUT validates the repaired checker.

## Paper Use

This can strengthen the paper only if framed honestly:

- Main paper: hard RTL synthesis on original ArchXBench, with golden verification.
- Benchmark audit: identifies contract defects in specific hard rows.
- Repaired-contract experiments: test whether synthesis methods solve the intended task once the executable contract is coherent.

Do not mix repaired-contract results into original ArchXBench solve-rate tables.

## Inventory Rule

- Original ArchXBench matrix: `artifacts/inventories/run_matrix_l3_l6.csv`
- Repaired-contract matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`

`scripts/build_run_matrix.py` excludes `repaired_contracts_*` runs by construction.
