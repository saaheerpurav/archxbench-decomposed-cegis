# Current Status

Date: 2026-07-05

This file is only an entry point. Do not treat it as an independent result source.

Canonical files:

- Clean claim and diagnostic tables: [RESULTS.md](RESULTS.md)
- Run queue and unresolved gaps: [RUNS_LEFT.md](RUNS_LEFT.md)
- Paper-readiness audit and baseline gap map: [PAPER_AUDIT.md](PAPER_AUDIT.md)
- Benchmark caveats: [BENCHMARK_CAVEATS.md](BENCHMARK_CAVEATS.md)
- Repaired benchmark-contract track: [EXECUTABLE_CONTRACT_REPAIR.md](EXECUTABLE_CONTRACT_REPAIR.md)
- Artifact policy: [ARTIFACTS.md](ARTIFACTS.md)

## Current Bottom Line

The repo has clean evidence that verifier-grounded decomposed/CEGIS-style RTL synthesis solves hard ArchXBench designs across L3-L6, including robust L4 C4tl rows and clean L5/L6 golden-verified rows.

The current evidence does not support claiming that C4i/C4tl dominates C2g everywhere. C2g is strong on several L5/L6 designs. The paper must frame method value carefully: decomposition helps on specific hard rows and gives a structured verifier-grounded synthesis pipeline, while C2g is a serious baseline.

## Rules

- Use only repo-local artifacts under `artifacts/`.
- A row is a paper claim only if it appears in [RESULTS.md](RESULTS.md).
- File-output designs require strict golden verification.
- Native simulator PASS without golden verification is diagnostic only.
- Do not use outside folders, old local notes, or collaborator machine paths as evidence unless copied into this repo.
- Keep repaired-contract experiments separate from original ArchXBench claim tables.
- Do not push automatically.

## Inventory Commands

```powershell
python scripts\build_artifact_index.py
python scripts\build_run_matrix.py
```

Primary inventory files:

- `artifacts/inventories/artifact_index.csv`
- `artifacts/inventories/artifact_index.json`
- `artifacts/inventories/run_matrix_l3_l6.csv`
- `artifacts/inventories/repaired_contract_run_matrix.csv`
