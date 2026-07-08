# Reproducibility

## Environment

Required local tools:

- Python
- Icarus Verilog: `iverilog`
- VVP runtime: `vvp`

## Rebuild Inventory

```powershell
python scripts\build_artifact_index.py
python scripts\build_run_matrix.py
```

## Inspect Results

```powershell
Import-Csv artifacts\inventories\artifact_index.csv
Import-Csv artifacts\inventories\run_matrix_l3_l6.csv
```

## Backfill Golden Scores

Only run this when intentionally rechecking saved RTL:

```powershell
python scripts\backfill_golden.py artifacts\curated
python scripts\build_artifact_index.py
```

## Claim Validation

A paper row is valid only if:

- it appears in `docs/RESULTS.md` or `docs/PAPER_TABLES.md`
- it is backed by repo-local evidence under `artifacts/`
- it is labeled with the correct evidence class: artifact-backed, trusted score-only, repaired-contract, held/excluded, or historical log/metrics-only

Artifact-backed rows should have generated RTL indexed in `artifacts/inventories/artifact_index.csv`. Trusted score-only rows can support result tables but must not be described as artifact-backed until generated RTL is present in the repo.
