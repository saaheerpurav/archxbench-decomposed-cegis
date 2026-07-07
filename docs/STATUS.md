# Current Status

Date: 2026-07-07

This file is only an entry point. Do not treat it as an independent result source.

Canonical files:

- Clean claim and diagnostic tables: [RESULTS.md](RESULTS.md)
- Run queue and unresolved gaps: [RUNS_LEFT.md](RUNS_LEFT.md)
- Paper-readiness audit and baseline gap map: [PAPER_AUDIT.md](PAPER_AUDIT.md)
- Benchmark caveats: [BENCHMARK_CAVEATS.md](BENCHMARK_CAVEATS.md)
- Repaired benchmark-contract track: [EXECUTABLE_CONTRACT_REPAIR.md](EXECUTABLE_CONTRACT_REPAIR.md)
- File-output golden audit: [FILE_OUTPUT_GOLDEN_AUDIT.md](FILE_OUTPUT_GOLDEN_AUDIT.md)
- Artifact policy: [ARTIFACTS.md](ARTIFACTS.md)

## Current Bottom Line

The repo has clean evidence that verifier-grounded decomposed/CEGIS-style RTL synthesis solves hard ArchXBench designs across L3-L6, including robust L4 C4tl rows and clean L5/L6 golden-verified rows.

The current evidence does not support claiming that C4i/C4tl dominates C2g everywhere. C2g is strong on several L5/L6 designs. The paper must frame method value carefully: decomposition helps on specific hard rows and gives a structured verifier-grounded synthesis pipeline, while C2g is a serious baseline.

## Primary Goal

The only strategic goal is AAAI-27 acceptance. Do not optimize for extra benchmark rows, method branding, or cosmetic completeness if it weakens the paper. Time is not a constraint, but every run, repair, and claim must make the submission stronger, cleaner, and easier for reviewers to trust.

Benchmark repair is allowed only as a principled executable-contract audit. Do not patch a benchmark to make one method look good. Repaired-contract rows must stay separate from original ArchXBench rows and must be framed as benchmark-validity evidence unless the repair is minimal, general, and clearly justified.

## Rules

- Use only repo-local artifacts under `artifacts/`.
- A row is a paper claim only if it appears in [RESULTS.md](RESULTS.md).
- File-output designs require strict golden verification.
- Native simulator PASS without golden verification is diagnostic only.
- Do not use outside folders, old local notes, or collaborator machine paths as evidence unless copied into this repo.
- Historical log/metrics-only rows are allowed only when recorded in `artifacts/inventories/log_metric_only_results.csv`; they are not artifact-backed claims.
- Keep repaired-contract experiments separate from original ArchXBench claim tables.
- Avoid one-off design hacks. If a new method is introduced, it must be general enough to test on multiple weak rows.
- Do not push automatically.

## Matrix Ownership

Do not hand-edit generated matrices except as a last-resort audit note. Add or fix the underlying artifact/result files, then regenerate.

| File | Owns | How to update |
|---|---|---|
| `artifacts/inventories/run_matrix_l3_l6.csv` | Original ArchXBench L3-L6 results only | add/fix repo-local `result.json` rows under `artifacts/raw_runs/` or `artifacts/curated/`, then run `python scripts\build_run_matrix.py` |
| `artifacts/inventories/repaired_contract_run_matrix.csv` | Repaired-contract experiments only | add/fix runs under `artifacts/raw_runs/repaired_contracts*`, then run `python scripts\build_repaired_contract_matrix.py` |
| `artifacts/inventories/log_metric_only_results.csv` | Historical log/metrics-only rows without generated RTL/result artifacts | edit this file directly only when preserving a historical non-claim row |
| `artifacts/inventories/artifact_index.csv` and `.json` | Flat artifact inventory for all repo-local result rows | run `python scripts\build_artifact_index.py` |

Original and repaired-contract results must never be merged into the same paper table without an explicit label.

## Inventory Commands

```powershell
python scripts\build_artifact_index.py
python scripts\build_run_matrix.py
python scripts\build_repaired_contract_matrix.py
```

Primary inventory files:

- `artifacts/inventories/artifact_index.csv`
- `artifacts/inventories/artifact_index.json`
- `artifacts/inventories/run_matrix_l3_l6.csv`
- `artifacts/inventories/repaired_contract_run_matrix.csv`
