# Current Status

Date: 2026-07-03

This file is the entry point for a fresh agent. Use this repo only. Do not use outside notes, local paths, old run folders, or memory from another machine.

## Paper Center

The paper is about decomposition-guided CEGIS for hard RTL synthesis on ArchXBench.

Current clean mechanism evidence:

- C4i solves selected L3 designs on matched GPT-5.5 seeds.
- C4tl solves four L4 core designs across five seeds.
- C2g is the monolithic golden-feedback baseline.
- File-output L5/L6 rows require full golden comparison before they can become claims.

## Clean Main Claims

Use only these as current paper claims:

- C4i solves `gauss_siedel` and `gradient_descent` on seeds `42,123,456`; matched C2g does not solve them.
- C4i solves `fp_multiplier`, `fp_adder`, `newton_raphson_sqrt`, and `harris_corner_detection` on seeds `42,123,456`; these are solved rows, not exclusive wins.
- C4tl solves L4 `fp_mult_pipeline`, `fp_adder_pipeline`, `fft_16pt_iterative`, and `ifft_16pt_iterative` on seeds `42,123,456,789,1024`.
- `newton_raphson_polynomial` is a clean negative result.

The exact tables are in [RESULTS.md](RESULTS.md).

## Clean Secondary Evidence

These rows are golden-verified but are not current main claims because they are one-seed or baseline context:

- `conv1d` C4i seed `42`: `16/16`
- `conv1d` C4tl seed `42`: `16/16`
- `harris_corner_detection` C2g seed `42`: `16384/16384`
- `aes_encryption` C4i seed `42`: `8/8`

These live under `artifacts/curated/golden_verified_secondary/`.

## Diagnostics

Rows under `artifacts/curated/diagnostics/` are not claims. This includes:

- native-pass but golden-fail L5/L6 rows
- imported rows without golden fields
- negative debug attempts

Do not promote a diagnostic row unless it gets copied to a clean curated folder and appears in [RESULTS.md](RESULTS.md).

## Not Solved As Clean Claims

Do not claim these as solved:

- `dct_idct_8pt_pipelined`
- FIR-family designs
- `conv_3d`
- `quantized_matmul`
- `systolic_gemm`
- native-pass L5/L6 rows with incomplete or failing golden comparison

## Run Queue

No runs are required for the current claims. See [RUNS_LEFT.md](RUNS_LEFT.md) before starting any new run.

## Artifact Policy

All artifacts are under `artifacts/`.

Current inventory:

- `artifacts/inventories/artifact_index.csv`
- `artifacts/inventories/artifact_index.json`

Regenerate the inventory with:

```powershell
python scripts\build_artifact_index.py
```
