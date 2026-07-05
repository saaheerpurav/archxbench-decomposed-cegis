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

## `quantized_matmul`

Original contract issue:

- Testbench reads `tb_float.mem`, but the benchmark data bundle provides `tb_data.mem`.
- Testbench emits packed FP32 bit-pattern integers.
- Golden JSON stores floating-point numeric values.
- The generic golden comparator compares numeric JSON values, so packed FP32 integers and floats are not comparable.

Repair:

- Generate `tb_float.mem` from `inputs/stimuli.json`.
- Regenerate `tb_params.mem` from the same stimuli.
- Normalize `outputs/golden_output.json` to flattened FP32 bit-pattern integers.
- Append repaired-contract notes to `design-specs.txt`.

Sanity check:

- A dummy all-zero `qgemm` compiles/runs and reports a normal golden mismatch: `0/64`.

Repaired-contract run:

- Artifacts: `artifacts/raw_runs/repaired_contracts_20260705/`
- Matrix: `artifacts/inventories/repaired_contract_run_matrix.csv`
- C2g, seeds `42,123,456`: 0/3 clean solves, all `0/0`.
- C4i, seeds `42,123,456`: 0/3 clean solves, all `0/0`.
- C4tl, seeds `42,123,456`: 0/3 clean solves, all `0/0`.
- Interpretation: the file-format contract is executable now, but the design remains unsolved by current methods.

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
