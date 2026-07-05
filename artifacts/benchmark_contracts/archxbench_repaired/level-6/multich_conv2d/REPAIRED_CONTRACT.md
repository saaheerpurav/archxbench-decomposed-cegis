# Repaired contract notes

- Original testbench drove `kernel = 0`, while the Python reference uses all-ones kernels.
- Original testbench opened `dut_output.json` only after all inputs were sent, which can drop streaming outputs.
- Original testbench had fragile JSON comma handling and no expected output-count check.
- This fixture collects outputs from the start of simulation and writes exactly `COUT*(H-K+1)*(W-K+1)` outputs.
- The original source benchmark is unchanged.
