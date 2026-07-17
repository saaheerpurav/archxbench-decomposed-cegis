# Repaired contract notes

- The original testbench overrides the public 128x128 design parameters with 256x256, but the shipped stimulus and golden files each contain exactly 16384 samples.
- This fixture uses the documented 128x128 dimensions and requires exactly 16384 output samples.
- Outputs are captured throughout input streaming and a bounded pipeline-drain interval; JSON commas depend on the actual output count.
- Native PASS requires exactly 16384 `valid_out` assertions. Golden scoring additionally compares all 16384 binary outputs in order.
- The original source benchmark is unchanged.
