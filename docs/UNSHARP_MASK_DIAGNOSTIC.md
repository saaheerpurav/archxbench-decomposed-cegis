# Unsharp Mask Diagnostic

Last checked: 2026-07-06.

`unsharp_mask` now has artifact-backed C2g solves on two seeds.

## Current Artifact-Backed Result

| Method | Seeds | Result | Artifact status |
|---|---|---:|---|
| C2g | `42,456` | `2/2` solved, both `65536/65536` | result JSON and generated RTL saved |
| C4a | `42,123,456` | `0/3` solved; best `63780/65536` | generated RTL saved |
| C4i | `42,123,456` | `0/3` solved; best `63482/65536` | generated RTL saved |
| C4tl | `42,123,456` | `0/3` solved; best golden `62256/65536` | generated RTL saved |

Artifact-backed C2g solve paths:

- `artifacts/raw_runs/unsharp_c2g_artifact_rerun_20260706/unsharp_mask/C2g/42/result.json`
- `artifacts/raw_runs/unsharp_c2g_artifact_rerun_20260706/unsharp_mask/C2g/42/verilog/unsharp_mask.v`
- `artifacts/raw_runs/unsharp_c2g_artifact_rerun_20260706/unsharp_mask/C2g/456/result.json`
- `artifacts/raw_runs/unsharp_c2g_artifact_rerun_20260706/unsharp_mask/C2g/456/verilog/unsharp_mask.v`

Local replay with OSS CAD Suite confirmed both saved RTL files produce `65536/65536`, full-length `65536` DUT outputs, and zero mismatches against the shipped `golden_output.json`.

## Old Score-Only Runs

The old C2g near-miss paths remain score-only and should not be used as artifact-backed evidence:

- `artifacts/raw_runs/overnight_c2g_priority1_20260703/unsharp_mask/C2g/42/result.json`
- `artifacts/raw_runs/overnight_c2g_priority1_20260703/unsharp_mask/C2g/456/result.json`

That whole `overnight_c2g_priority1_20260703` run folder has `14` result JSON files, `0` Verilog files, and `0` `verilog/` directories.

## Saved Non-C2g Replay Findings

Replay was run with OSS CAD Suite against the official `level-5/unsharp_mask` inputs and `golden_output.json`.

| Artifact | Replayed golden score | DUT output length | Main pattern |
|---|---:|---:|---|
| `adaptive_c4a_weak_targets_20260704/unsharp_mask/C4a/42` | `63780/65536` | `65535` | many border/column mismatches plus one missing tail sample |
| same C4a artifact with an extra 512-cycle local drain | `63781/65536` | `65536` | drain fixes only the missing tail sample |
| `overnight_c4i_completion_20260704/unsharp_mask/C4i/456` | `63482/65536` | `65535` | same broad spatial mismatch pattern |
| `overnight_c4tl_fairness_20260704/unsharp_mask/C4tl/456` | `61033/65536` | `65536` | standard centered-stencil-like behavior, but far from benchmark golden |

Conclusion: saved C4a/C4i/C4tl failures are not just a no-drain testbench issue.

## Benchmark-Golden Caveat

The design spec describes a Gaussian blur followed by `original - blurred`, gain, reconstruction, and saturation with zero padding.

The shipped `golden_output.json` does not match a textbook centered 3x3 unsharp-mask reference. A direct centered 3x3 reference scores only `61033/65536`, matching the poorer C4tl behavior. A simple causal/trailing one-pixel-shifted model scores `65026/65536`, closer but still not exact.

This means C2g solved the benchmark's executable golden behavior, not necessarily the plain mathematical image-processing spec. That is acceptable as an ArchXBench executable-contract result, but the caveat should be mentioned if `unsharp_mask` is discussed qualitatively.

## Remaining Action

If `unsharp_mask` is promoted beyond a secondary result, run C2g seed `123` with artifact saving as well. Current artifact-backed C2g evidence is `2/2` clean on seeds `42,456`; old seed `123` is score-only and failed at `63736/65536`.
