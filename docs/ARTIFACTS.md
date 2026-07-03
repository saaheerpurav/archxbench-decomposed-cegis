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

`artifacts/metrics/` contains aggregate JSON metrics from broad sweeps. The dedicated C2g metric files are:

- `metrics_c2g_gpt55.json`
- `metrics_c2g_gpt4o.json`
- `metrics_c2g_o4mini.json`

Older level-specific C2g metric files are preserved for auditability.

## Model Label Normalization

All GPT-5.5-family runs are normalized to `gpt-5.5` in repo-local artifacts and inventories. The repo-local artifacts are the canonical evidence, regardless of which collaborator or machine generated the run.

## Inventory

Use these files for programmatic lookup:

- `artifacts/inventories/artifact_index.csv`
- `artifacts/inventories/artifact_index.json`
- `artifacts/inventories/run_matrix_l3_l6.csv`

Regenerate the artifact index with:

```powershell
python scripts\build_artifact_index.py
```

Regenerate the L3-L6 run matrix with:

```powershell
python scripts\build_run_matrix.py
```

The run matrix is the easiest way to inspect which GPT-5.5 `C1`, `C2g`, `C4i`, and `C4tl` runs exist for every official L3-L6 design. It reports strict clean solves, not paper claims.

## Claim Rule

A paper claim needs both:

1. a row in `docs/RESULTS.md`
2. a repo-local artifact path under `artifacts/curated/main_claims/`
