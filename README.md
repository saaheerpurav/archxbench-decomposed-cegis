# ArchXBench CEGIS

This repository is the only source of truth for the ArchXBench CEGIS paper work.

Start with [docs/STATUS.md](docs/STATUS.md). It defines the current paper state, clean claims, secondary evidence, diagnostics, and run queue.

Supporting files:

- [docs/RESULTS.md](docs/RESULTS.md): clean result tables only
- [docs/RUNS_LEFT.md](docs/RUNS_LEFT.md): exact run queue
- [docs/ARTIFACTS.md](docs/ARTIFACTS.md): artifact layout and inventory rules
- [docs/METHODS.md](docs/METHODS.md): method definitions
- [docs/BENCHMARK_CAVEATS.md](docs/BENCHMARK_CAVEATS.md): checker and benchmark caveats
- [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md): local commands

Repository rules:

- All evidence lives under `artifacts/`.
- A paper claim must appear in `docs/RESULTS.md`.
- A paper claim must have repo-local artifacts indexed in `artifacts/inventories/artifact_index.csv`.
- Raw runs are audit data. Curated folders define which rows are clean, secondary, or diagnostic.
