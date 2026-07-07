# Artifact Audit Status

Last audited: 2026-07-07.

## Summary

- Total repo-local `result.json` files: `1085`.
- Result rows with at least one saved Verilog file: `353`.
- Result rows without saved Verilog: `732`.
- The current `docs/RESULTS.md` main C4i/C4tl claim rows are artifact-backed.
- Many C1/C2g baseline and secondary rows are score-only and must be rerun before being used as artifact-backed paper evidence.

## Main Claims

All rows in the `Main Claims` table of `docs/RESULTS.md` have generated RTL artifacts for their listed seeds.

Examples:

- L3 C4i main claims have `verilog/*.v` under `artifacts/curated/main_claims/L3/...`.
- L4 C4tl main claims have `verilog/*.v` under `artifacts/curated/main_claims/L4/...`.
- L5 C4i main claims have `verilog/*.v` under `artifacts/curated/main_claims/L5/...`.
- L6 C4i main claims have `verilog/*.v` under `artifacts/curated/main_claims/L6/...` or the AES decryption encoding-fix run.

## Known Score-Only C2g Gaps

These clean C2g rows have no saved Verilog and must be rerun if used as artifact-backed evidence:

| Design | Seeds | Score | Current location |
|---|---|---:|---|
| `aes_encryption` | `42,123,456` | `8/8` | baseline/overnight C2g score-only rows |
| `aes_decryption` | `42,123,456` | `8/8` | `aes_decryption_encoding_fix_20260704` C2g score-only rows |
| `conv1d` | `42,123,456` | `16/16` | baseline/overnight C2g score-only rows |
| `conv2d` | `42,123,456` | `4096/4096` | `overnight_c2g_priority1_20260703` |
| `dct_idct_8pt_pipelined` | `42,123,456` | `16/16` | `overnight_c2g_conditional_20260704` |
| `harris_corner_detection` | `42,123,456` | `16384/16384` | baseline/overnight C2g score-only rows |
| `conv_3d` repaired contract | `42,123,456` | `23064/23064` | `repaired_contracts_20260705` C2g score-only rows |

`overnight_c2g_priority1_20260703` specifically has `14` result JSON files and no saved Verilog at all.

## Known Log/Metrics-Only Non-C2g Rows

The repository-local audit preserves historical C4i GPT-5.5 L4 FIR results from committed logs and `artifacts/inventories/log_metric_only_results.csv`, but without preserved generated RTL/result artifacts for those cells:

| Design | Seeds | Result | Current evidence |
|---|---|---:|---|
| `band_pass_fir` | `42,123,456,789,1024` | 0/5 solved; best `5/1001` | repo-local logs and log/metrics inventory only |
| `high_pass_fir` | `42,123,456,789,1024` | 2/5 solved; seeds `456,1024` scored `1001/1001` | repo-local logs and log/metrics inventory only |
| `low_pass_fir` | `42,123,456,789,1024` | 1/5 solved; seed `123` scored `1001/1001` | repo-local logs and log/metrics inventory only |

Inventory: `artifacts/inventories/log_metric_only_results.csv`.

These rows can be used to avoid forgetting that the sweep happened. They cannot be used as artifact-backed claims unless rerun with saved RTL.

## Artifact-Backed C2g Rows

Current clean C2g rows with saved Verilog:

| Design | Seeds | Score | Location |
|---|---|---:|---|
| `unsharp_mask` | `42,123,456` | `65536/65536` | `artifacts/raw_runs/unsharp_c2g_artifact_rerun_20260706/` and `artifacts/raw_runs/unsharp_c2g_seed123_artifact_rerun_20260706/` |
| `multich_conv2d` repaired contract | `42,123,456` | `30752/30752` | `artifacts/raw_runs/repaired_contracts_multich_conv2d_20260705/` |
| `quantized_matmul` repaired contract, runner-fixed | `42,123,456` | `64/64` | `artifacts/raw_runs/repaired_contracts_qgemm_runnerfix_pilot_20260705/` |
| `fp_band_pass_fir` repaired contract | `42,123,456` | `1000/1000` | `artifacts/raw_runs/repaired_fp_fir_c2g_pilot_20260707/` and `artifacts/raw_runs/repaired_fp_fir_c2g_seeds_20260707/` |
| `fp_high_pass_fir` repaired contract | `42,123,456` | `1000/1000` | `artifacts/raw_runs/repaired_fp_fir_c2g_pilot_20260707/` and `artifacts/raw_runs/repaired_fp_fir_c2g_seeds_20260707/` |
| `newton_raphson_polynomial` repaired contract | `42,123,456` | `97/97` | `artifacts/raw_runs/repaired_newton_20260707/` |

## Artifact-Backed Repaired FIR Negative Rows

These are negative repaired-contract pilots with saved Verilog. They are not paper claims.

| Design group | Conditions | Seed | Result |
|---|---|---:|---|
| L4 repaired FIR | C2g/C4i/C4tl | `42` | all nine cells fail; best score 5/1001 |

Locations:

- `artifacts/raw_runs/repaired_fir_l4_c2g_pilot_20260706/`
- `artifacts/raw_runs/repaired_fir_l4_c4i_pilot_20260706/`
- `artifacts/raw_runs/repaired_fir_l4_c4tl_pilot_20260706/`

## Rule Going Forward

A run is artifact-backed only if its cell directory contains both:

- `result.json`
- `verilog/*.v`

Score-only rows can remain in diagnostics or baseline context, but they cannot support a paper claim until rerun with saved RTL.
