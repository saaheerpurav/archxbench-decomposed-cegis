# Repaired contract notes

- The original file-output FIR testbench uses stale interface parameters and JSON output plumbing.
- The benchmark directory already contains `tb_selfcheck.v`, an embedded-golden self-checking contract generated from the shipped stimuli and golden outputs.
- This repaired fixture removes the stale file-output testbench and makes `tb_selfcheck.v` the only executable contract.
- The design spec explicitly lists the required coefficient set, parameters, and Q15 normalization (`accumulator >>> 15`).
- Independent causal convolution reproduces all 1000 released golden samples exactly with `>>>15`; the stale `>>>20` text reproduces only a small minority.
- The original source benchmark is unchanged.
