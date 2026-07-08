# ArchXBench CEGIS

This repository is the only source of truth for the ArchXBench CEGIS paper work.

Working paper title:

**Autonomous Synthesis of Hard RTL Designs via Iterative Repair and Modular Decomposition**

Start with [docs/STATUS.md](docs/STATUS.md). It defines the current paper state, clean claims, secondary evidence, diagnostics, and run queue.

Supporting files:

- [docs/RESULTS.md](docs/RESULTS.md): clean result tables only
- [docs/PAPER_TABLES.md](docs/PAPER_TABLES.md): consolidated paper-facing table source
- [docs/RUNS_LEFT.md](docs/RUNS_LEFT.md): exact run queue
- [docs/ARTIFACTS.md](docs/ARTIFACTS.md): artifact layout and inventory rules
- [docs/METHODS.md](docs/METHODS.md): method definitions
- [docs/BENCHMARK_CAVEATS.md](docs/BENCHMARK_CAVEATS.md): checker and benchmark caveats
- [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md): local commands

Repository rules:

- All evidence lives under `artifacts/`.
- A paper claim must appear in `docs/RESULTS.md`.
- Trusted score-only rows are valid experimental results; missing generated RTL is artifact collection debt, not invalid evidence.
- Artifact-backed rows must be indexed in `artifacts/inventories/artifact_index.csv`.
- Raw runs are audit data. Curated folders define which rows are clean, secondary, or diagnostic.
