# Repaired contract notes

- Original testbench drove `kernel = 0`, while the Python reference uses a 3x3x3 all-ones kernel.
- Original testbench wrote one output per input voxel instead of one output per valid convolution window.
- Original output width was `DATA_W+4`; this fixture uses `DATA_W+5`, enough for 27 unsigned 8-bit terms.
- The fixture writes exactly `(D-K1+1)*(H-K2+1)*(W-K3+1)` outputs and checks that count.
- The original source benchmark is unchanged.
