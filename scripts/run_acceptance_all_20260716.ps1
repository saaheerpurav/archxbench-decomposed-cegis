$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

. "C:\Users\saahe\Desktop\Programming\Stuff\College\Research\tools\oss-cad-suite\environment.ps1"

$env:USE_CODEX_CLI = "1"
$env:CODEX_REASONING_EFFORT = "low"
$env:CODEX_CLI_TIMEOUT = "1800"

python -u scripts\run_acceptance_queue.py `
    --queue repaired `
    --benchmark-root artifacts\benchmark_contracts\archxbench_repaired `
    --output artifacts\raw_runs\acceptance_repaired_codex_gpt55_20260716 `
    --parallel 3 `
    --model gpt-5.5
if ($LASTEXITCODE -ne 0) {
    throw "Repaired acceptance queue failed with exit code $LASTEXITCODE"
}

python -u scripts\run_acceptance_queue.py `
    --queue original `
    --benchmark-root cegis\tdes\fpga\benchmarks\archxbench `
    --output artifacts\raw_runs\acceptance_original_codex_gpt55_20260716 `
    --parallel 3 `
    --model gpt-5.5
if ($LASTEXITCODE -ne 0) {
    throw "Original acceptance queue failed with exit code $LASTEXITCODE"
}

python scripts\strict_replay_results.py `
    artifacts\raw_runs\acceptance_repaired_codex_gpt55_20260716 `
    --benchmark-root artifacts\benchmark_contracts\archxbench_repaired `
    --claimed-solved-only
if ($LASTEXITCODE -ne 0) {
    throw "Strict replay of repaired acceptance queue failed with exit code $LASTEXITCODE"
}

python scripts\strict_replay_results.py `
    artifacts\raw_runs\acceptance_original_codex_gpt55_20260716 `
    --benchmark-root cegis\tdes\fpga\benchmarks\archxbench `
    --claimed-solved-only
if ($LASTEXITCODE -ne 0) {
    throw "Strict replay of original acceptance queue failed with exit code $LASTEXITCODE"
}

python scripts\build_run_matrix.py
python scripts\build_repaired_contract_matrix.py
python scripts\build_noref_ablation_matrix.py
python scripts\build_artifact_index.py

Write-Output "ACCEPTANCE_QUEUE_COMPLETE"
