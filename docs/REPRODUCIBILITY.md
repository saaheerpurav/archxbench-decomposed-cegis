# Reproducibility

## Environment

Required local tools:

- Python
- Icarus Verilog: `iverilog`
- VVP runtime: `vvp`

## Rebuild Inventory

```powershell
python scripts\build_artifact_index.py
```

## Inspect Results

```powershell
Import-Csv artifacts\inventories\artifact_index.csv
```

## Backfill Golden Scores

Only run this when intentionally rechecking saved RTL:

```powershell
python scripts\backfill_golden.py artifacts\curated
python scripts\build_artifact_index.py
```

## Claim Validation

A claim is valid only if:

- it appears in `docs/RESULTS.md`
- it has artifacts under `artifacts/curated/main_claims/`
- it is indexed in `artifacts/inventories/artifact_index.csv`
