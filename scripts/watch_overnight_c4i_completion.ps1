param(
    [string]$RepoRoot = (Resolve-Path ".").Path,
    [string]$OutputDir = "artifacts/raw_runs/overnight_c4i_completion_20260704",
    [string]$LogFile = "logs/overnight_c4i_completion_20260704.watchdog.log",
    [int]$SleepSeconds = 300
)

$ErrorActionPreference = "Continue"
Set-Location $RepoRoot

$fullOutput = Join-Path $RepoRoot $OutputDir
$fullLog = Join-Path $RepoRoot $LogFile
New-Item -ItemType Directory -Force -Path (Split-Path $fullLog), $fullOutput | Out-Null

$env:USE_CODEX_CLI = "1"
$env:CODEX_REASONING_EFFORT = "low"
$env:CODEX_CLI_TIMEOUT = "300"

$plans = @(
    @{
        Name = "c4i-l4-l5-l6-completion"
        Designs = @(
            "fft_16pt_iterative",
            "fp_adder_pipeline",
            "fp_mult_pipeline",
            "ifft_16pt_iterative",
            "conv2d",
            "unsharp_mask",
            "fft_streaming_64pt"
        )
        Seeds = @(123, 456)
    }
)

function Write-WatchLog {
    param([string]$Message)
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $fullLog -Value "[$stamp] $Message"
}

function Test-RunnerAlive {
    $needle = [IO.Path]::GetFileName($fullOutput)
    $procs = Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -and
        ($_.CommandLine -like "*run_aaai*") -and
        ($_.CommandLine -like "*$needle*")
    }
    return (($procs | Measure-Object).Count -gt 0)
}

function Get-MissingForPlan {
    param($Plan)
    $missing = @()
    foreach ($design in $Plan.Designs) {
        foreach ($seed in $Plan.Seeds) {
            $result = Join-Path $fullOutput "$design/C4i/$seed/result.json"
            if (-not (Test-Path $result)) {
                $missing += [pscustomobject]@{ Design = $design; Seed = $seed }
            }
        }
    }
    return $missing
}

function Invoke-RunForMissing {
    param($Plan, $Missing)
    $designs = $Missing | Select-Object -ExpandProperty Design -Unique
    $seeds = $Missing | Select-Object -ExpandProperty Seed -Unique
    if (($designs | Measure-Object).Count -eq 0 -or ($seeds | Measure-Object).Count -eq 0) {
        return
    }

    Write-WatchLog "Restarting $($Plan.Name): designs=$($designs -join ',') seeds=$($seeds -join ',')"
    python -m cegis.tdes.fpga.autonomous.run_aaai `
        --designs $designs `
        --conditions C4i `
        --models gpt-5.5 `
        --seeds $seeds `
        --output $OutputDir `
        --parallel 2 *>> $fullLog
}

Write-WatchLog "watchdog started for $OutputDir"

while ($true) {
    $runnerAlive = Test-RunnerAlive
    $allMissing = @()
    foreach ($plan in $plans) {
        $missing = @(Get-MissingForPlan -Plan $plan)
        $allMissing += $missing
    }

    $resultCount = (Get-ChildItem -Path $fullOutput -Recurse -Filter result.json -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-WatchLog "heartbeat runner_alive=$runnerAlive result_json_count=$resultCount missing_planned=$($allMissing.Count)"

    if ($allMissing.Count -eq 0) {
        Write-WatchLog "all planned result.json files present; rebuilding inventories"
        python scripts\build_artifact_index.py *>> $fullLog
        python scripts\build_run_matrix.py *>> $fullLog
        Write-WatchLog "watchdog complete"
        break
    }

    if (-not $runnerAlive) {
        foreach ($plan in $plans) {
            $missing = @(Get-MissingForPlan -Plan $plan)
            if ($missing.Count -gt 0) {
                Invoke-RunForMissing -Plan $plan -Missing $missing
            }
        }
    }

    Start-Sleep -Seconds $SleepSeconds
}
