# Artifacts

All evidence lives under `artifacts/`.

## Layout

```text
artifacts/
  curated/
    main_claims/
    golden_verified_secondary/
    diagnostics/
  raw_runs/
  metrics/
  inventories/
```

## Curated Folders

| Folder | Meaning |
|---|---|
| `artifacts/curated/main_claims/` | Artifacts for rows claimed in `docs/RESULTS.md` |
| `artifacts/curated/golden_verified_secondary/` | Clean golden-verified rows that are not current main claims |
| `artifacts/curated/diagnostics/` | Failures, stale native-pass/golden-fail rows, and rows without golden evidence |

## Raw Runs

`artifacts/raw_runs/` contains original run directories for auditability. Raw rows are not claims by themselves.

## Metrics

`artifacts/metrics/` contains aggregate JSON metrics from broad sweeps.

## Inventory

Use these files for programmatic lookup:

- `artifacts/inventories/artifact_index.csv`
- `artifacts/inventories/artifact_index.json`

Regenerate them with:

```powershell
python scripts\build_artifact_index.py
```

## Claim Rule

A paper claim needs both:

1. a row in `docs/RESULTS.md`
2. a repo-local artifact path under `artifacts/curated/main_claims/`
