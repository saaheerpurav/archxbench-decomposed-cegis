# Repaired contract notes

- Original `tb_qgemm.v` read `tb_float.mem`, but the benchmark only shipped `tb_data.mem`.
- This fixture regenerates `tb_float.mem` from `inputs/stimuli.json`.
- The DUT interface emits packed FP32 bits, so `golden_output.json` is normalized to FP32 bit-pattern integers.
- Internal quantization follows the Python reference exactly: signed two's-complement INT8 values, no unsigned clamp to `0..255`.
- For the official stimulus, `B_q = round(B_fp / scale_B) + zp_B` includes negative values.
- The original source benchmark is unchanged.
