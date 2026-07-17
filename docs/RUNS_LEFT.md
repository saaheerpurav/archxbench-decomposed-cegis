# Runs Left

Last synchronized: 2026-07-17

No run is active. No additional benchmark row, no-reference condition, or artifact
recollection rerun is queued.

## Deferred Before Final Experimental Freeze

### C4tl localization-protocol consistency

The paper's central L4 artifacts and the current runner do not yet implement the
same candidate-scoring composition:

- cited central L4 artifacts: evaluate the candidate module with the other
  modules isolated by reference implementations;
- current runner: replace one reference module with its candidate inside the
  all-candidate composition.

The user has explicitly deferred this work. When resumed, run a six-cell pilot on
`fft_16pt_iterative` and `ifft_16pt_iterative`, trials `42,123,456`, using Codex
CLI GPT-5.5 with low reasoning and three concurrent cells. Save `result.json`, all
generated Verilog, transcripts, configuration, and replay-verification output.

Decision after the pilot:

- If the standardized implementation reproduces 3/3 on both rows, complete the
  two robustness trials (`789,1024`) and any remaining L4 cells needed so the
  released method and cited artifacts use one protocol.
- If it does not reproduce the result, keep the existing artifacts intact,
  investigate the protocol difference, and revise the method claim rather than
  combining incomparable runs.

This check is about method/evidence consistency, not collecting missing artifacts.

## Completed Evidence

- Original-contract matrix: 16 reported designs across L3--L6, synchronized in
  `RESULTS.md` and `PAPER_TABLES.md`.
- C4tl L3 coverage: complete on trials `42,123,456`.
- C4tl L4 robustness: complete in the existing artifact set on trials
  `42,123,456,789,1024` for FFT, IFFT, and both FP pipelines.
- Repaired-contract matrix: nine designs complete on trials `42,123,456`.
- Corrected L4 Q1.15 FIR experiment: three designs complete and reported
  separately.
- Sonnet selected-frontier validation: complete.
- C4i randomized-order FFT/IFFT ablation: complete.
- Previously score-only C2g rows selected for the paper now have saved artifacts.

Completed results are not rerun merely to recreate artifacts or normalize folder
names.

## Held Or Excluded

- no-reference condition: excluded from the paper and run queue;
- `fft_streaming_64pt`: excluded because the released executable contract remains
  ambiguous;
- `fp_low_pass_fir`: held because the released files do not expose an explicit
  coefficient/cutoff oracle;
- additional opportunistic baselines or C4 variants: not queued because they do
  not currently strengthen the acceptance story enough to justify more surface
  area.

## Execution Rules When Work Resumes

- Use Codex CLI GPT-5.5 with low reasoning; do not use Claude for the deferred
  Codex protocol run.
- Run three cells concurrently.
- Keep trials `42,123,456` as the main set; use `789,1024` only for documented
  robustness checks.
- Treat trial numbers as run identifiers, not controlled model random seeds.
- Save artifacts synchronously and replay every winning RTL artifact.
- Keep original-contract, repaired-contract, and corrected-contract inventories
  separate.
- After a batch, rebuild the artifact index and relevant run matrices before
  changing any paper number.
- Do not push unless the user explicitly requests it.
