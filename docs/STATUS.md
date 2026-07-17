# Current Status

Last synchronized: 2026-07-17

This file is an entry point, not an independent numerical source.

## Current Bottom Line

The paper has a defensible original-contract result matrix covering all six L3
designs, four of seven L4 designs, four of six L5 designs, and two of nine L6
designs. The strongest matched method result is at L3; the strongest robustness
and mechanism result is C4tl on L4 FFT/IFFT. C2g remains a strong baseline and
fully solves every reported L4 and L5 row.

Repaired-contract results are complete for nine designs and are reported in a
separate table. `harris_corner_detection` and `systolic_gemm` are repaired-contract
results, not original-contract solves.

No run is active. One C4tl implementation/evidence consistency check is deferred;
see [`RUNS_LEFT.md`](RUNS_LEFT.md). No-reference experiments are not planned.

## Authoritative Files

- Paper draft: [../paper/aspdac2027/main.tex](../paper/aspdac2027/main.tex)
- Detailed results and evidence policy: [RESULTS.md](RESULTS.md)
- Paper-facing numbers and Figure 3 data: [PAPER_TABLES.md](PAPER_TABLES.md)
- Acceptance-oriented claim audit: [PAPER_AUDIT.md](PAPER_AUDIT.md)
- Remaining run/protocol work: [RUNS_LEFT.md](RUNS_LEFT.md)
- Benchmark caveats: [BENCHMARK_CAVEATS.md](BENCHMARK_CAVEATS.md)
- Repaired-contract methodology: [EXECUTABLE_CONTRACT_REPAIR.md](EXECUTABLE_CONTRACT_REPAIR.md)
- Artifact policy: [ARTIFACTS.md](ARTIFACTS.md)

Historical drafts and notes are not numerical sources. If they disagree with the
four synchronized result/status files above, the synchronized files control.

## Non-Negotiable Reporting Rules

- Separate original, repaired, and corrected executable contracts.
- Report the original matrix's actual level coverage: `6/6`, `4/7`, `4/6`, `2/9`.
- Use absolute full/partial design counts for Figure 3, not percentages over the
  shown subset.
- Treat `42,123,456` as trial identifiers, not controlled API seeds.
- Require golden verification and saved, replayable RTL for central claims.
- Do not imply C4 dominance over C2g globally.
- Do not add no-reference results or rerun solved cells solely for artifact
  completeness.
- Do not push automatically.

## Generated Inventory Ownership

- `artifacts/inventories/run_matrix_l3_l6.csv`: original-contract results.
- `artifacts/inventories/repaired_contract_run_matrix.csv`: repaired-contract
  results.
- `artifacts/inventories/log_metric_only_results.csv`: explicitly historical
  log/metric-only rows.
- `artifacts/inventories/artifact_index.csv` and `.json`: flat artifact inventory.

Fix source artifacts first and regenerate inventories; do not hand-edit generated
matrices to force agreement with the paper.
