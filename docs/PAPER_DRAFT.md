# Autonomous Synthesis of Hard RTL Designs via Iterative Repair and Modular Decomposition

Anonymous Authors

## Abstract

Large language models can generate short programs and simple register-transfer level (RTL) circuits, but hard executable synthesis tasks remain unreliable under direct prompting. We study this gap on ArchXBench, a recent benchmark suite for complex RTL synthesis whose authors report that frontier models solve lower-level tasks but fail from Level 4 onward under zero-shot pass@5 evaluation. We present a verifier-grounded autonomous synthesis pipeline that combines iterative repair, modular decomposition, and strict executable feedback. Instead of asking a model to emit a complete RTL design once, the pipeline decomposes a design into implementation modules, validates a reference composition against the benchmark testbench, generates module implementations, and iteratively repairs failures using simulator and golden-output feedback.

On original ArchXBench contracts, our pipeline obtains clean solves across Levels 3-6, including four Level-4 designs that solve on all three main seeds and two additional robustness seeds, Level-5 image/convolution designs, and Level-6 AES encryption/decryption designs with golden verification. The results also show that decomposition is not universally superior: a strong monolithic golden-feedback baseline matches or exceeds it on several Level-5 and repaired-contract rows. We therefore frame the contribution as a verified autonomous synthesis study rather than a universal method win. A second contribution is a benchmark-contract audit. Several hard rows contain executable-contract defects or ambiguities; we repair only infrastructure/specification mismatches, keep repaired-contract results separate from original benchmark results, and show both new solves and persistent failures.

## 1. Introduction

Autonomous code agents are increasingly evaluated by their ability to solve executable tasks: generate a candidate, run a checker, inspect failures, and repair. This loop is attractive because it grounds language-model generation in objective feedback. However, the loop becomes substantially harder when the target artifact is not a short script but a structured system with concurrency, timing, bit-level encodings, and externally defined correctness contracts.

Register-transfer level hardware design is a compact but demanding setting for this problem. RTL designs are programs, but they are also circuits: their behavior depends on bit widths, signedness, clocking, reset protocols, pipeline latency, streaming handshakes, and file-output conventions. A design can compile while still being wrong on golden traces. A simulator can run while still failing to compare outputs. A benchmark can include a natural-language specification, a testbench, input files, and reference outputs that are not mutually consistent. These properties make RTL synthesis a useful testbed for studying verifier-grounded autonomous agents.

Recent RTL generation benchmarks such as VerilogEval and RTLLM established automatic evaluation for Verilog generation, but many tasks in those suites are small instructional circuits or moderate design fragments. ArchXBench was introduced to push beyond this regime. It contains a six-level suite of increasingly complex designs drawn from arithmetic, signal processing, image processing, machine learning, and cryptography. In the ArchXBench paper, the best reported zero-shot model solves 16 of 30 tasks across Levels 1-3, while all evaluated models fail from Level 4 onward. This makes ArchXBench a suitable stress test for whether autonomous synthesis agents can move beyond direct prompting.

We ask a focused question: can a verifier-grounded autonomous agent solve hard RTL designs that are not reliably solved by direct generation, while preserving an honest distinction between original benchmark results and benchmark-contract repairs?

Our answer is partially yes, with important caveats. We evaluate several conditions: a single-shot baseline (C1), a monolithic golden-feedback repair baseline (C2g), a decomposition-guided iterative repair pipeline (C4i), and a testbench-localized decomposition pipeline (C4tl). C4i and C4tl solve several rows that direct and monolithic baselines do not, especially in Level 3 and the core Level-4 evidence. C4tl solves four Level-4 designs on all main seeds and two additional robustness seeds. C4i solves Level-5 `conv1d` and `harris_corner_detection` and Level-6 AES encryption/decryption on all main seeds with golden verification. At the same time, C2g is a serious baseline and is stronger on several Level-5 and repaired-contract tasks. The paper therefore does not claim that modular decomposition dominates monolithic repair. The claim is that verifier-grounded decomposition and repair, together with strict golden verification and benchmark-contract auditing, closes important hard-task gaps and exposes the remaining ones.

This work makes three contributions:

1. We present an autonomous RTL synthesis pipeline that combines decomposition, reference-composition validation, iterative repair, and simulator/golden feedback.
2. We provide a controlled ArchXBench study across Levels 3-6, separating original benchmark evidence, baseline context, repaired-contract evidence, and held/excluded rows.
3. We document benchmark-contract failure modes in hard RTL tasks and show how principled executable-contract repair changes the interpretation of both successes and failures.

## 2. Background and Related Work

### LLMs for RTL Generation

VerilogEval introduced a benchmark and evaluation harness for Verilog code generation based on HDLBits-style tasks, enabling automatic functional checking of generated designs. RTLLM similarly proposed an open-source benchmark for natural-language-to-RTL generation and evaluated syntax, functionality, and design quality. These benchmarks established a useful foundation, but their tasks are generally smaller than the deeply pipelined or multi-module designs found in modern accelerator and signal-processing workloads.

More recent systems move toward stronger RTL-generation agents. AutoChip showed that compiler and simulator feedback can improve automated HDL generation on HDLBits-style tasks. VerilogCoder, which appeared at AAAI 2025, introduced autonomous Verilog coding agents with graph-based planning and AST-based waveform tracing, reporting strong results on VerilogEval-Human v2. MAGE and Spec2RTL-Agent further study multi-agent RTL-generation workflows. Evolutionary methods such as EvolVE and COEVO use inference-time search or co-evolutionary optimization to improve RTL correctness and, in some cases, power/performance/area (PPA) metrics on VerilogEval and RTLLM-style benchmarks.

These systems indicate a shift from single prompts toward agentic workflows, planning, feedback, and search. Our work differs in emphasis: we evaluate on ArchXBench Levels 3-6, including Level-4 and above rows where the ArchXBench paper reports that all evaluated frontier models fail under zero-shot pass@5. We also use strict simulator/golden feedback and explicitly audit benchmark contracts instead of treating every failing checker as ground truth. In short, VerilogCoder-class systems show that tool-integrated RTL agents are promising on VerilogEval-style tasks; this paper asks whether verifier-grounded decomposition and repair can solve harder ArchXBench rows and how benchmark-contract defects affect that evaluation.

### Hard RTL Benchmarks

ArchXBench was designed to expose the limits of current LLM-driven RTL synthesis on complex digital systems. It includes multi-level tasks spanning arithmetic, filters, FFTs, image processing, GEMM, AES, and other designs. The benchmark paper reports that frontier models can solve only lower levels under zero-shot pass@5 and consistently fail from Level 4 onward. This failure frontier is central to our motivation: if a method solves only tasks already solved by direct prompting, it is unlikely to constitute a strong research contribution. We therefore focus on L3-L6 accounting, with particular attention to Level 4 and above.

### Verifier-Grounded Program Synthesis

Counterexample-guided inductive synthesis (CEGIS) and related repair loops use a verifier to iteratively reject incorrect candidates and guide the next synthesis attempt. LLM-based code agents instantiate a similar pattern: generate code, run tests, inspect errors, and repair. However, applying this loop to RTL is difficult because failures may arise from syntax, simulation, timing, golden-output mismatch, file-format mismatch, or benchmark-contract ambiguity. Our pipeline treats simulator and golden feedback as first-class signals, but also audits the executable contract when the benchmark components disagree.

## 3. Problem Setting

Each ArchXBench design provides a natural-language problem description, design specification, and executable evaluation assets such as Verilog testbenches, input files, output files, and comparison scripts. A synthesis agent receives the design task and must emit Verilog RTL. A run is successful only when the generated design passes the official self-checking testbench or, for file-output designs, matches the golden output.

We distinguish three evaluation classes:

- **Original-contract results:** runs against the benchmark as released in the repository.
- **Repaired-contract results:** runs against a separately copied benchmark fixture where infrastructure or executable-contract inconsistencies are minimally repaired and oracle-validated.
- **Held/excluded rows:** tasks for which the released contract remains ambiguous or inconsistent enough that a positive solve would be misleading.

This separation is essential. If a benchmark testbench is wrong, solving it may not mean solving the intended task. Conversely, if a generated design fails because the checker cannot compare outputs correctly, treating the failure as a model failure is also misleading. Our paper reports these categories separately.

## 4. Methods

We evaluate four primary conditions. Figure 1 shows the pipeline used by the decomposed conditions.

Figure source: `docs/figures/pipeline_figure.tex`.

### C1: Single-Shot Generation

C1 is the direct baseline. The model receives the design task and emits RTL without iterative repair. This condition measures whether the task is already solved by straightforward prompting.

### C2g: Monolithic Golden-Feedback Repair

C2g is a monolithic CEGIS-style baseline. The model generates a complete design, the simulator and golden checker evaluate it, and the model receives full-design feedback for repair. The design remains a single global artifact throughout the loop. C2g is important because it is a strong and simple baseline: if monolithic repair solves a design with fewer moving parts, decomposition is not necessary for that row.

### C4i: Decomposition-Guided Iterative Repair

C4i asks the model to decompose the design into submodules with interfaces, reference implementations, and a top-level composition. Before using the decomposition for synthesis, the reference composition must pass the original system testbench. This validation gate prevents arbitrary decompositions from becoming ungrounded scaffolding. After the decomposition passes, the agent generates or repairs modules and integrates them into a complete RTL design. Failures from the system checker guide subsequent repairs.

The key idea is not merely to split a design into files. The key idea is to convert a hard monolithic synthesis problem into a structured search over module boundaries, while still requiring the composed system to satisfy the original benchmark checker.

### C4tl: Testbench-Localized Decomposition

C4tl extends C4i with more localized failure information from simulation and testbench traces. It keeps the same decomposition discipline but attempts to identify which module or interface is most implicated by the failing system behavior. This is intended to reduce repair diffusion: instead of rewriting the whole design for every failure, the agent can focus on the most likely responsible component.

### Artifact and Verification Discipline

Every run is stored under `artifacts/` with a `result.json` file. Artifact-backed rows also include generated Verilog and, where applicable, decomposition metadata. File-output designs require strict golden verification: native simulator completion alone is not a solve. For self-checking designs, the pass count reported by the official testbench is the score.

## 5. Experimental Setup

### Benchmark Scope

We evaluate ArchXBench Levels 3-6. Lower levels are not the focus because the benchmark paper already shows that current models can solve lower-level tasks. The scientific question is whether autonomous synthesis can move into the harder regime.

The L3-L6 set includes arithmetic kernels, iterative numerical methods, FFT/IFFT designs, floating-point pipelines, FIR filters, convolution/image-processing tasks, GEMM/matrix multiplication tasks, and AES encryption/decryption.

### Models and Seeds

Main paper tables use seeds `42,123,456`. Extra C4tl Level-4 seeds `789,1024` are reported as robustness evidence. The primary paper rows use the model name `gpt-5.5`, exactly as recorded in the repository `result.json` artifacts and normalized inventories. Some auxiliary historical artifacts include `gpt-4o`, `o4-mini`, and `claude-opus-4-6`, but those rows are not the primary paper comparisons unless explicitly labeled.

### Metrics

For self-checking testbenches, a run is clean if `best_passes == total_tests` with `total_tests > 0`. For file-output designs, a run is clean only if `golden_correct == golden_total` and `golden_total > 0`. We report solve counts over seeds, e.g. `3/3`.

### Evidence Classes

We explicitly label rows as artifact-backed, trusted score-only, repaired-contract, held/excluded, or historical log/metrics-only. Trusted score-only rows are valid result evidence when the logged score is accepted, but they are not described as artifact-backed until generated RTL is present in the repository.

## 6. Results on Original ArchXBench Contracts

### Main Evidence

Table 1 summarizes the central original-contract evidence with all four primary conditions. C4i solves five Level-3 designs on all three main seeds, while direct baselines are weaker or fail. C4tl also solves four of those six selected L3 rows on all three seeds, but only solves `gauss_siedel` on one seed and fails `newton_raphson_polynomial` on all three seeds. This shows that decomposition variants are not interchangeable: C4i is the stronger L3 method overall.

At Level 4, C4tl solves the four core rows `fft_16pt_iterative`, `ifft_16pt_iterative`, `fp_adder_pipeline`, and `fp_mult_pipeline` on all three main seeds, and all four remain solved on two additional robustness seeds. This is the strongest hard-level coverage evidence in the original-contract results.

At Levels 5 and 6, C4i solves `conv1d`, `harris_corner_detection`, `aes_encryption`, and `aes_decryption` on all three main seeds with golden verification. These rows demonstrate that the pipeline can produce correct designs beyond self-checking arithmetic kernels.

| Level | Design | C1 | C2g | C4i | C4tl | Evidence |
|---|---|---:|---:|---:|---:|---|
| L3 | `fp_adder` | 0/5 | 1/5 | 3/3 | 3/3 | artifact-backed/logged |
| L3 | `fp_multiplier` | 0/5 | 0/3 | 3/3 | 3/3 | artifact-backed/logged |
| L3 | `gauss_siedel` | 0/3 | 0/3 | 3/3 | 1/3 | artifact-backed |
| L3 | `gradient_descent` | 0/3 | 0/3 | 3/3 | 3/3 | artifact-backed |
| L3 | `newton_raphson_sqrt` | 0/3 | 0/3 | 3/3 | 3/3 | artifact-backed |
| L3 | `newton_raphson_polynomial` | 0/3 | 0/3 | 0/3 | 0/3 | artifact-backed diagnostic |
| L4 | `fft_16pt_iterative` | 0/3 | 3/3 | 0/3 | 3/3 main, 5/5 incl. robustness | artifact-backed/logged |
| L4 | `ifft_16pt_iterative` | 0/3 | 3/3 | 0/3 | 3/3 main, 5/5 incl. robustness | artifact-backed/logged |
| L4 | `fp_adder_pipeline` | 3/3 | 3/3 | 3/3 | 3/3 main, 5/5 incl. robustness | artifact-backed/logged |
| L4 | `fp_mult_pipeline` | 3/3 | 3/3 | 3/3 | 3/3 main, 5/5 incl. robustness | artifact-backed/logged |
| L5 | `conv1d` | 3/3 | 3/3 | 3/3 | 1/3 | mixed artifact-backed/trusted score-only |
| L5 | `harris_corner_detection` | 0/3 | 3/3 | 3/3 | 0/3 | mixed artifact-backed/trusted score-only |
| L6 | `aes_encryption` | 3/3 | 3/3 | 3/3 | 2/3 | mixed artifact-backed/trusted score-only |
| L6 | `aes_decryption` | 1/3 | 3/3 | 3/3 | 1/3 | mixed artifact-backed/trusted score-only |

### Baseline Context

The results are not a simple story of decomposition beating monolithic repair everywhere. C2g is strong. It solves L4 FFT/IFFT rows on all main seeds, solves several Level-5 rows such as `conv2d`, `dct_idct_8pt_pipelined`, and `unsharp_mask`, and matches or exceeds C4i/C4tl on several repaired-contract tasks. This matters for the paper's framing. The contribution is not a universal dominance claim; it is a verified synthesis pipeline that produces hard-level solves, identifies where decomposition helps, and records where monolithic repair is enough or better.

| Level | Design | C1 | C2g | C4i | C4tl | Evidence |
|---|---|---:|---:|---:|---:|---|
| L5 | `conv2d` | 0/3 | 3/3 | 0/3 | 0/3 | trusted score-only baseline row |
| L5 | `dct_idct_8pt_pipelined` | 0/3 | 3/3 | 0/3 | 0/3 | trusted score-only baseline row |
| L5 | `unsharp_mask` | 0/3 | 3/3 | 0/3 | 0/3 | C2g artifact-backed |
| L6 | `fft_streaming_64pt` | 0/3 | 1/5 | 0/3 | 0/3 | diagnostic only; excluded from positive tables |

### Full L3-L6 Accounting

Across all L3-L6 designs in the repository, each row is classified as a clean original-contract positive, an original-contract diagnostic, a repaired-contract row, or a held/excluded row.

| Category | Designs |
|---|---|
| Clean original-contract positive rows | `fp_adder`, `fp_multiplier`, `gauss_siedel`, `gradient_descent`, `newton_raphson_sqrt`, `fft_16pt_iterative`, `ifft_16pt_iterative`, `fp_adder_pipeline`, `fp_mult_pipeline`, `conv1d`, `conv2d`, `dct_idct_8pt_pipelined`, `harris_corner_detection`, `unsharp_mask`, `aes_encryption`, `aes_decryption` |
| Original-contract partial/negative diagnostics | `newton_raphson_polynomial`, `fft_streaming_64pt` |
| Repaired-contract rows | `conv_3d`, `multich_conv2d`, `quantized_matmul`, `fp_band_pass_fir`, `fp_high_pass_fir`, `newton_raphson_polynomial`, `systolic_gemm`, L4 FIR family |
| Held/excluded | L4 FIR family from positive tables, `fp_low_pass_fir`, `fft_streaming_64pt` |

## 7. Benchmark-Contract Audit

Hard executable benchmarks are only useful if the executable contract reflects the intended task. During evaluation, we found several cases where natural-language specifications, testbenches, file formats, and golden outputs were not mutually consistent. We therefore added a repaired-contract track. The original benchmark is not overwritten; instead, repaired fixtures live under a separate root and all repaired-contract results are reported separately.

### File-Output Contracts and Golden Verification

For file-output designs, native simulator completion is insufficient. Some original testbenches emit no PASS/FAIL tokens and rely entirely on post-simulation golden comparison. In these cases, a run that merely reaches the end of simulation is diagnostic, not a solve. The runner therefore performs golden comparison whenever the design requires file-output checking.

### Repaired-Contract Results

Table 3 reports the repaired-contract track. These rows should not be counted as original ArchXBench solves. They answer a different question: if the executable contract is made coherent in a minimal and oracle-validated way, do current synthesis agents solve the intended task?

| Design | Repaired-contract result | Interpretation |
|---|---|---|
| `conv_3d` | C2g 3/3, C4i 2/3, C4tl 0/3 | benchmark-contract repair unlocks intended task |
| `multich_conv2d` | C2g/C4i/C4tl all 3/3 | clean repaired-contract validation |
| `quantized_matmul` runner-fixed | C2g 3/3, C4i 3/3, C4tl 0/3 | file-format/runner contract mattered |
| `fp_band_pass_fir` | C2g 3/3; C4i/C4tl seed-42 pilots fail | repaired-contract C2g win |
| `fp_high_pass_fir` | C2g 3/3; C4i/C4tl seed-42 pilots fail/near-miss | repaired-contract C2g win |
| `newton_raphson_polynomial` | C2g 3/3, C4i 1/3, C4tl 1/3 on `97/97` repaired checker | original checker has three unsatisfiable residual checks |
| `systolic_gemm` | C2g/C4i/C4tl all 0/3 after checker repair | genuine capability boundary |
| L4 FIR family | C2g/C4i/C4tl seed-42 pilots all fail | negative benchmark-audit evidence |

These results show both sides of benchmark repair. For `multich_conv2d` and `quantized_matmul`, contract repair converts ambiguous or broken evaluation into meaningful solvable tasks. For `systolic_gemm`, repairing the display-only checker does not produce a win: all methods still fail. This is important because it shows that the audit is not merely a mechanism for turning failures into successes.

### Held and Excluded Rows

Some rows remain excluded or held because a principled repair would require unresolved semantic choices.

| Design/group | Status | Reason |
|---|---|---|
| L4 `band_pass_fir`, `high_pass_fir`, `low_pass_fir` | exclude from positive tables | inconsistent evaluation contracts where specification and executable testbench disagree on filter coefficients/source-of-truth behavior |
| L6 `fp_low_pass_fir` | hold | released files do not expose an explicit coefficient/cutoff oracle |
| L6 `fft_streaming_64pt` | exclude | unresolved input/output contract ambiguities, including mismatched output schema and input numeric encoding |
| L5 `systolic_gemm` | negative repaired-contract row | after converting display-only expected matrices into executable checks, all methods remain 0/3 |

## 8. Discussion

### What Decomposition Helps With

Decomposition is most useful when the design naturally factors into semantically meaningful modules and when localizing failures reduces the repair burden. The Level-4 FFT/IFFT and floating-point pipeline results support this: C4tl robustly solves all four core Level-4 rows on five seeds. C4i also gives clean Level-3 wins over C1/C2g on several numerical kernels.

The validation gate is essential. A decomposition is not accepted merely because it looks plausible. The reference composition must pass the system testbench before it is used as scaffolding. This prevents ungrounded module boundaries from becoming a source of false confidence.

### Where Decomposition Does Not Help

C4i/C4tl do not dominate C2g. In several L5 rows and repaired-contract rows, monolithic golden-feedback repair is stronger. This can happen when the design is compact enough for whole-design repair, when module boundaries introduce interface risk, or when the main difficulty is a global convention such as file format, numeric encoding, or streaming protocol. The repaired FP FIR and `conv_3d` results are clear examples: C2g is strongest after contract repair.

### Why Benchmark Audit Belongs in the Paper

For ASP-DAC, the benchmark-audit contribution is a design-automation issue: executable RTL benchmarks are increasingly used to compare LLM-aided hardware design systems, but a simulator run is only meaningful when the executable contract matches the intended hardware task. If the benchmark contract is ambiguous, a model can fail for the wrong reason or succeed on the wrong task. Our audit shows concrete failure modes: hidden testbench assumptions, output-schema mismatch, copied comparators, display-only checkers, unsatisfiable residual checks, and missing oracle information.

## 9. Limitations

First, the strongest claim is not that C4i or C4tl is universally better than C2g. The data do not support that. C2g is a strong baseline and wins or matches on several rows.

Second, several rows are score-only rather than artifact-backed. These rows are labeled as trusted score-only evidence and should not be described as artifact-backed until generated RTL is present in the repository.

Third, repaired-contract results depend on careful judgment about what counts as an infrastructure repair versus a semantic benchmark change. We mitigate this by keeping repaired fixtures separate, oracle-validating repairs when possible, and reporting repaired-contract results separately from original results.

Fourth, the evaluation is concentrated on RTL synthesis. The broader lesson concerns verifier-grounded autonomous synthesis, but the empirical results are from hardware-design tasks. Future work should test whether the same separation of decomposition, verifier feedback, and benchmark-contract auditing transfers to other executable synthesis domains.

## 10. Conclusion

We studied autonomous RTL synthesis on hard ArchXBench designs using verifier-grounded iterative repair and modular decomposition. The resulting pipeline solves hard original-contract rows across Levels 3-6, including robust Level-4 solves and golden-verified Level-5/Level-6 designs. The results also show that monolithic golden-feedback repair remains a strong baseline and that decomposition is not universally superior. A benchmark-contract audit further reveals that several hard rows require careful separation between model failures, checker failures, and ambiguous executable contracts.

The main conclusion is therefore not a simple leaderboard claim. It is that hard autonomous synthesis requires three ingredients together: structured generation, executable feedback, and trustworthy benchmark contracts. Without all three, both successes and failures can be misinterpreted.

## References

- Suresh Purini, Siddhant Garg, Mudit Gaur, Sankalp Bhat, Sohan Mupparapu, and Arun Ravindran. ArchXBench: A Complex Digital Systems Benchmark Suite for LLM Driven RTL Synthesis. MLCAD 2025; arXiv:2508.06047.
- Mingjie Liu, Nathaniel Pinckney, Brucek Khailany, and Haoxing Ren. VerilogEval: Evaluating Large Language Models for Verilog Code Generation. ICCAD 2023; arXiv:2309.07544.
- Yao Lu et al. RTLLM: An Open-Source Benchmark for Design RTL Generation with Large Language Model. arXiv:2308.05345.
- Shailja Thakur, Jason Blocklove, Hammond Pearce, Benjamin Tan, Siddharth Garg, and Ramesh Karri. AutoChip: Automating HDL Generation Using LLM Feedback. DAC 2024; arXiv:2311.04887.
- Chia-Tung Ho, Haoxing Ren, and Brucek Khailany. VerilogCoder: Autonomous Verilog Coding Agents with Graph-based Planning and Abstract Syntax Tree (AST)-based Waveform Tracing Tool. AAAI 2025; arXiv:2408.08927.
- Zhendong Mi, Renming Zheng, Haowen Zhong, Yue Sun, and Shaoyi Huang. RTLCoder: Fully Open-Source and Efficient LLM-Assisted RTL Code Generation. arXiv:2312.08617.
- Yang Zhao et al. CodeV: Empowering LLMs for Verilog Generation through Multi-Level Summarization. IEEE TCAD, 2025.
- Wei-Po Hsin, Ren-Hao Deng, Yao-Ting Hsieh, En-Ming Huang, and Shih-Hao Hung. EvolVE: Evolutionary Search for LLM-based Verilog Generation and Optimization. arXiv:2601.18067.
- Heng Ping, Peiyu Zhang, Shixuan Li, Wei Yang, Anzhe Cheng, Shukai Duan, Xiaole Zhang, and Paul Bogdan. COEVO: Co-Evolutionary Framework for Joint Functional Correctness and PPA Optimization in LLM-Based RTL Generation. arXiv:2604.15001.
- Spec2RTL-Agent: Automated Hardware Code Generation from Complex Specifications Using LLM Agent Systems. arXiv:2506.13905.

## Author Notes for Next Revision

- Convert to ASP-DAC LaTeX immediately after the prose is stable.
- Add exact citations in BibTeX.
- Compress tables for the 6-page ASP-DAC main-body limit plus one reference page.
- Move detailed repaired-contract rows to appendix if space is tight.
- Insert `docs/figures/pipeline_figure.tex` in Section 4.
- Add one qualitative example of a decomposition and one benchmark-contract bug, but keep both short.
