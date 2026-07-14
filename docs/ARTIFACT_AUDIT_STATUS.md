# Artifact Audit Status

Last audited: 2026-07-09.

## Summary

- Total repo-local `result.json` files: `1124`.
- Result rows with at least one saved Verilog file: `392`.
- Result rows without saved Verilog: `732`.
- The current `docs/RESULTS.md` main C4i/C4tl claim rows are artifact-backed.
- Priority 1 and Priority 2 C2g artifact-collection rows were rerun on 2026-07-09 and now have generated RTL.
- C4i randomized-module-order ablation rows were run on 2026-07-13 and all six cells have generated RTL under `artifacts/raw_runs/c4i_rand_order_fft_ifft_20260713/`.
- Some remaining historical baseline and secondary rows are score-only. Treat their logged scores as trusted experimental results only when recorded in the inventory. The Priority 1 and Priority 2 C2g artifact-collection rows are no longer pending; they have saved generated RTL.

## Main Claims

All rows in the `Main Claims` table of `docs/RESULTS.md` have generated RTL artifacts for their listed seeds.

Examples:

- L3 C4i main claims have `verilog/*.v` under `artifacts/curated/main_claims/L3/...`.
- L4 C4tl main claims have `verilog/*.v` under `artifacts/curated/main_claims/L4/...`.
- L5 C4i main claims have `verilog/*.v` under `artifacts/curated/main_claims/L5/...`.
- L6 C4i main claims have `verilog/*.v` under `artifacts/curated/main_claims/L6/...` or the AES decryption encoding-fix run.

## Completed C2g Artifact Collection

These clean C2g rows previously had trusted logged scores but no saved Verilog in this repo. They were rerun on 2026-07-09 for artifact collection. Each listed cell now has `result.json` and `verilog/*.v`.

| Design | Seeds | Score | Artifact location |
|---|---|---:|---|
| `aes_encryption` | `42,123,456` | `8/8` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `aes_decryption` | `42,123,456` | `8/8` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `conv1d` | `42,123,456` | `16/16` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `conv2d` | `42,123,456` | `4096/4096` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `dct_idct_8pt_pipelined` | `42,123,456` | `16/16` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `harris_corner_detection` | `42,123,456` | `16384/16384` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `conv_3d` repaired contract | `42,123,456` | `23064/23064` | `artifacts/raw_runs/c2g_artifact_collection_20260709_repaired/` |

Historical folders such as `overnight_c2g_priority1_20260703` still have result JSONs without saved Verilog. They are superseded for artifact-backed C2g evidence by the 2026-07-09 collection roots above.

## Known Log/Metrics-Only Non-C2g Rows

The repository-local audit preserves historical C4i GPT-5.5 L4 FIR results from committed logs and `artifacts/inventories/log_metric_only_results.csv`, but without preserved generated RTL/result artifacts for those cells:

| Design | Seeds | Result | Current evidence |
|---|---|---:|---|
| `band_pass_fir` | `42,123,456,789,1024` | 0/5 solved; best `5/1001` | repo-local logs and log/metrics inventory only |
| `high_pass_fir` | `42,123,456,789,1024` | 2/5 solved; seeds `456,1024` scored `1001/1001` | repo-local logs and log/metrics inventory only |
| `low_pass_fir` | `42,123,456,789,1024` | 1/5 solved; seed `123` scored `1001/1001` | repo-local logs and log/metrics inventory only |

Inventory: `artifacts/inventories/log_metric_only_results.csv`.

These rows can be used to avoid forgetting that the sweep happened. They should not be described as artifact-backed unless rerun with saved RTL.

## Artifact-Backed C2g Rows

Current clean C2g rows with saved Verilog:

| Design | Seeds | Score | Location |
|---|---|---:|---|
| `unsharp_mask` | `42,123,456` | `65536/65536` | `artifacts/raw_runs/unsharp_c2g_artifact_rerun_20260706/` and `artifacts/raw_runs/unsharp_c2g_seed123_artifact_rerun_20260706/` |
| `conv1d` | `42,123,456` | `16/16` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `conv2d` | `42,123,456` | `4096/4096` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `dct_idct_8pt_pipelined` | `42,123,456` | `16/16` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `harris_corner_detection` | `42,123,456` | `16384/16384` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `aes_encryption` | `42,123,456` | `8/8` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `aes_decryption` | `42,123,456` | `8/8` | `artifacts/raw_runs/c2g_artifact_collection_20260709_original/` |
| `conv_3d` repaired contract | `42,123,456` | `23064/23064` | `artifacts/raw_runs/c2g_artifact_collection_20260709_repaired/` |
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

Score-only rows can support trusted result tables when the logged score is accepted, but they must not be described as artifact-backed until the corresponding Verilog is present in the repo.
