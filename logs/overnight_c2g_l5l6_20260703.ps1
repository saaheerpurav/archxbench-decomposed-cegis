$env:USE_CODEX_CLI='1'
$env:CODEX_REASONING_EFFORT='low'
$env:CODEX_CLI_TIMEOUT='300'
python -m cegis.tdes.fpga.autonomous.run_aaai --designs conv1d harris_corner_detection aes_encryption fft_streaming_64pt conv2d unsharp_mask --conditions C2g --models gpt-5.5 --seeds 123 456 42 --output artifacts/raw_runs/overnight_c2g_l5l6_20260703 --parallel 2 *> logs/overnight_c2g_l5l6_20260703.log
