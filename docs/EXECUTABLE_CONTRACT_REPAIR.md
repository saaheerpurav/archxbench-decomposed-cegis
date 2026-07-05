# Executable Contract Repair

Date: 2026-07-05

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
- C4tl, seeds `42,123,456`: 0/3 clean solves; reference decomposition failed before repair.
- Interpretation: once the executable contract and runner are correct, `quantized_matmul` is solvable by C2g and C4i. This is not a C4tl win.

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
- C4i, seeds `42,123,456`: 2/3 clean solves, seeds `42,123`; seed `456` failed decomposition compile validation.
- C4tl, seeds `42,123,456`: 0/3 clean solves.
- Interpretation: repairing the executable contract unlocks `conv_3d`, but the win is not specific to C4tl. C2g is strongest on this repaired contract.

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
