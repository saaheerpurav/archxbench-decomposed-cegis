# Repaired contract notes

- Original `tb_qgemm.v` read `tb_float.mem`, but the benchmark only shipped `tb_data.mem`.
- This fixture regenerates `tb_float.mem` from `inputs/stimuli.json`.
- The DUT interface emits packed FP32 bits, so `golden_output.json` is normalized to FP32 bit-pattern integers.
- The original source benchmark is unchanged.
