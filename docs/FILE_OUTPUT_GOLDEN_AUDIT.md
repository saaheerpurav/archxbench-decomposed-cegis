# File-Output Golden Audit

Date: 2026-07-05

This audit checks which ArchXBench designs write JSON outputs and therefore require post-simulation golden comparison.

Generated inventory:

`artifacts/inventories/file_output_contract_audit.csv`

Rebuild command:

```powershell
python scripts\audit_file_output_contracts.py
```

## Result

ArchXBench has 19 designs with JSON golden/reference files in the repo-local benchmark tree.

Most have native PASS/FAIL tokens in the official testbench. Three original benchmark designs are post-simulation-golden-only:

| Level | Design | Meaning |
|---|---|---|
| L6 | `conv_3d` | testbench writes `dut_output.json` but emits no native PASS/FAIL |
| L6 | `multich_conv2d` | testbench writes `dut_output.json` but emits no native PASS/FAIL |
| L6 | `quantized_matmul` | testbench writes `dut_output.json` but emits no native PASS/FAIL |

For these designs, `total_tests == 0` from native log parsing is not evidence of failure by itself. The runner must execute golden comparison whenever a benchmark data directory exists.

## Runner Status

The runner now does this correctly:

- `_golden_verify_final` runs for file-output designs even when native PASS/FAIL count is zero.
- C2g and C4i/C4tl repaired-contract qgemm runs use this fixed behavior.
- `quantized_matmul` repaired-contract runner-fixed rows are therefore valid: C2g 3/3 and C4i 3/3 golden verified.

## Paper Rule

Do not count native simulator completion as a solve for file-output designs.

A file-output row is solved only when:

`golden_correct == golden_total` and `golden_total > 0`

Rows without golden verification remain diagnostics, even if they have native PASS-like output.
