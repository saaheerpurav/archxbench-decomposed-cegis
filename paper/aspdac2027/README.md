# ASP-DAC 2027 Paper Draft

This folder contains the LaTeX draft for:

**Autonomous Synthesis of Hard RTL Designs via Iterative Repair and Modular Decomposition**

## Format

ASP-DAC 2027 requires:

- ACM Primary Article Template.
- LaTeX users should use `sample-sigconf.tex`.
- Initial submissions must be double-blind.
- Main manuscript limit is 6 pages, including abstract, figures, and tables.
- References are excluded from the 6-page limit.

The current draft uses:

```tex
\documentclass[sigconf,anonymous]{acmart}
```

## Build

MiKTeX is installed locally on this machine.

The current PDF build is:

- `main.pdf`
- 6 total PDF pages in ACM `sigconf` anonymous format

The command used locally is:

```powershell
$bin="$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64"
$env:PATH="$bin;$env:PATH"
pdflatex -interaction=nonstopmode main.tex
bibtex main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

If LaTeX is installed locally:

```powershell
latexmk -pdf main.tex
```

or:

```powershell
pdflatex main
bibtex main
pdflatex main
pdflatex main
```

## Source of Results

The paper tables are derived from repo-local docs and inventories:

- `docs/PAPER_TABLES.md`
- `docs/RESULTS.md`
- `artifacts/inventories/run_matrix_l3_l6.csv`
- `artifacts/inventories/repaired_contract_run_matrix.csv`

Original-contract and repaired-contract results must remain separate.
