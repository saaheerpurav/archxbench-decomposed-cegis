# Recovered fp_high_pass_fir contract

This copied fixture does not modify the original benchmark or the live main
repaired-contract root.

The published 31-tap coefficient list is not the golden oracle. Direct causal
convolution with that list has maximum error greater than 0.29. The official
upstream history at commit `c087e0418cb227e721b597f600bd608d3bf6babc`
retains a full-precision output file named `golden_output_fp.json`. The model
`scipy.signal.firwin(101, 5000, pass_zero=False, fs=50000)` reproduces that 1,000-sample oracle to maximum absolute
error `4.9960036108132044e-16`. The first 101 transient
samples establish the impulse response and samples 101--999 form an 899-sample
holdout.

The shipped +/-1.0 comparator is rejected: the largest released output
magnitude is only `0.29412517`, so an all-zero
DUT passes it. This fixture requires finite FP32 values, exact output length,
and absolute tolerance `1e-6`.

Upstream directory:
https://github.com/sureshpurini/ArchXBench/tree/c087e0418cb227e721b597f600bd608d3bf6babc/level-6/fp_high_pass_fir
