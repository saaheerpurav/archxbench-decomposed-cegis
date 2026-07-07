# Repaired contract notes

- The original file-output FIR testbench uses stale interface parameters and JSON output plumbing.
- The benchmark directory already contains `tb_selfcheck.v`, an embedded-golden self-checking contract generated from the shipped stimuli and golden outputs.
- This repaired fixture removes the stale file-output testbench and makes `tb_selfcheck.v` the only executable contract.
- The design spec explicitly lists the required coefficient set and parameters.
- The original source benchmark is unchanged.
