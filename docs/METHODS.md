# Methods

## C1

Single-shot baseline. The model receives the design task and emits RTL without iterative repair.

## C2g

Monolithic golden-feedback CEGIS baseline. The model receives full-design checker feedback and repairs the whole design.

## C4i

Decomposition-guided CEGIS. The model decomposes the design into modules, solves modules, integrates them, and repairs using checker feedback.

## C4tl

C4i with testbench-localization feedback. It keeps the decomposition structure and adds localized failure information from simulation output.

## C4a And C4m

Diagnostic variants. They are not current main methods unless a row is promoted into `docs/RESULTS.md`.
