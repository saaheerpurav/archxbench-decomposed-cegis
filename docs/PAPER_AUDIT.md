# Paper Audit

Last synchronized: 2026-07-17

This audit is acceptance-oriented. The paper-facing numerical source is
[`PAPER_TABLES.md`](PAPER_TABLES.md); the detailed evidence source is
[`RESULTS.md`](RESULTS.md).

## Bottom Line

The submission has a credible result story, but it is not a universal C4 win.

- The strongest method evidence is the matched L3 comparison: C4i fully solves
  five of six reported designs where C1 fully solves none and C2g fully solves
  none. C4tl fully solves four and partially solves one.
- The strongest hard-design robustness evidence is L4 FFT/IFFT: fixed-order C4i
  is 0/3, randomized-order C4i improves to 2/3 and 1/3, while C4tl is 3/3 on
  both and 5/5 with the two extra trials.
- C2g is a serious baseline. It fully solves every reported L4 design and every
  reported L5 design, and it fully solves all nine repaired-contract designs.
- The reported L6 subset contains only two AES designs, and every Codex condition
  solves both 3/3. This is capability evidence, not evidence of method separation
  or full L6 coverage.
- Repaired-contract results are valuable benchmark-audit evidence, but must remain
  visibly separate from original-contract ArchXBench results.

## Original-Contract Coverage

The main matrix reports 16 of the 28 released L3--L6 designs.

| Level | Reported / released | Interpretation |
|---|---:|---|
| L3 | 6/6 | complete level coverage |
| L4 | 4/7 | FFT/IFFT and two FP pipelines |
| L5 | 4/6 | `conv1d`, `conv2d`, DCT/IDCT, and unsharp mask |
| L6 | 2/9 | AES encryption and decryption only |

`harris_corner_detection` is not an original-contract result. It belongs only to
the repaired-contract table.

## Result Checks

The synchronized tables satisfy these invariants:

- Original table: 16 designs; trials `42,123,456`, except the documented five
  pass@5 trials for C1 `fp_adder`/`fp_multiplier` and five C2g trials for
  `fp_adder`.
- Extra trials `789,1024` are used only as C4tl robustness evidence on the four
  reported L4 rows.
- Repaired table: nine designs. C2g is 3/3 on all nine; C4i and C4tl each have
  four full and four partial design-level outcomes.
- Corrected Q1.15 L4 FIR is a separate three-row table and is not merged with
  either the original or repaired main matrix.
- Sonnet results and the module-order ablation are separate validation tables,
  not additions to the Codex main matrix.
- Figure 3 separately summarizes absolute full, partial, and unsolved counts for
  16 evaluated original-contract rows and nine validated repaired-contract rows.

## Claims That Are Supported

- Verifier-grounded modular synthesis solves difficult designs from L3 through
  L6 under executable golden checks.
- Decomposition/localization provides a large, matched advantage on the reported
  L3 set.
- Repair order matters on FFT/IFFT, and the topological-localization condition is
  substantially more reliable than either fixed or randomized iterative order.
- Golden verification and executable-contract auditing expose benchmark defects
  that native PASS signals alone can hide.
- The results generalize to a second model on the selected FFT/IFFT and AES C2g
  rows; Sonnet C4tl does not solve AES because reference decomposition validation
  fails.

## Claims To Avoid

- Do not claim that C4i or C4tl dominates C2g globally.
- Do not imply that all released L4--L6 designs were evaluated.
- Do not present the two reported L6 designs as representative of all nine L6
  designs without stating the `2/9` coverage.
- Do not present repaired contracts as original ArchXBench solves.
- Do not call trial identifiers controlled model seeds. The API did not expose
  seed control (`model_seed_controlled: false`).
- Do not include no-reference experiments in the paper. They add clutter without
  strengthening the main claim.

## Deferred C4tl Protocol Check

One scientific-consistency issue remains deferred by the user: the central L4
C4tl artifacts use reference-isolated candidate scoring, while the current runner
implements candidate scoring by replacing one module in the all-candidate
composition. These are related but not identical localization protocols.

Until the deferred validation is run, the paper and artifact documentation must
describe the protocol used by the cited artifacts and must not imply that the
current runner has reproduced those L4 numbers under its present implementation.
No result in the synchronized tables is being changed solely because this check
is deferred.

## Submission Checklist

1. Later run the deferred C4tl protocol-consistency validation and standardize the
   implementation, prose, and released evidence on one definition.
2. Preserve the verified six-page layout and rerun the final visual, font,
   reference, and numerical audit after any subsequent paper change.

No other experiment is currently required for the paper's existing claims.
