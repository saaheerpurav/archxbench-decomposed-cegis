# Runs Left

This is the only run queue.

## Required For Current Claims

None.

The current claims in [RESULTS.md](RESULTS.md) already have repo-local artifacts.

## Clean Optional Expansion

Only one optional expansion is currently straightforward:

| Design | Method | Missing seeds | Requirement |
|---|---|---|---|
| `conv1d` | C4i | `123,456` | must end with complete golden score |
| `conv1d` | C4tl | `123,456` | must end with complete golden score |

Reason: C4i and C4tl seed `42` are already golden-verified at `16/16`.

## Do Not Blind-Run

Do not run these just to fill a table. They need a method or checker decision first:

| Design | Current status |
|---|---|
| `aes_encryption` | C4i seed `42` is golden-clean; C4tl seed `42` fails golden |
| `aes_decryption` | current C4i/C4tl rows are not golden-clean |
| `fft_streaming_64pt` | C2g seed `42` is golden-clean; C4i/C4tl seed `42` fail golden |
| `conv2d` | current C4i/C4tl rows fail or partially match golden |
| `unsharp_mask` | current C4i/C4tl rows partially match golden |
| `harris_corner_detection` C4tl | current C4tl seed `42` fails golden; C4i is already clean on `42,123,456` |
| `systolic_gemm` | no reliable golden evidence in repo |
| `conv_3d` | diagnostic rows fail |
| `quantized_matmul` | diagnostic rows fail |
| `dct_idct_8pt_pipelined` | diagnostic rows fail |
| FIR-family designs | benchmark/spec-contract caveat unresolved |
