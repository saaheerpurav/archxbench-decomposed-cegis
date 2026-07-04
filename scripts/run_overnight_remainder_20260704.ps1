param(
    [string]$RepoRoot = (Resolve-Path ".").Path,
    [string]$LogFile = "logs/overnight_remainder_20260704.log",
    [int]$SleepSeconds = 300,
    [int]$MaxAttemptsPerBatch = 2
)

$ErrorActionPreference = "Continue"
Set-Location $RepoRoot

$fullLog = Join-Path $RepoRoot $LogFile
New-Item -ItemType Directory -Force -Path (Split-Path $fullLog) | Out-Null

$env:USE_CODEX_CLI = "1"
$env:CODEX_REASONING_EFFORT = "low"
$env:CODEX_CLI_TIMEOUT = "300"

function Write-RunLog {
    param([string]$Message)
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $fullLog -Value "[$stamp] $Message"
}

function Get-ResultCount {
    param([string]$OutputDir)
    $path = Join-Path $RepoRoot $OutputDir
    return (Get-ChildItem -Path $path -Recurse -Filter result.json -ErrorAction SilentlyContinue | Measure-Object).Count
}

function Test-RunAaaiAliveForOutput {
    param([string]$OutputDir)
    $needle = [IO.Path]::GetFileName($OutputDir)
    $procs = Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -and
        ($_.CommandLine -like "*run_aaai*") -and
        ($_.CommandLine -like "*$needle*")
    }
    return (($procs | Measure-Object).Count -gt 0)
}

function Wait-ForCurrentC4iBatch {
    $currentOutput = "artifacts/raw_runs/overnight_c4i_completion_20260704"
    Write-RunLog "waiting for active C4i completion batch to finish"

    while ($true) {
        $count = Get-ResultCount -OutputDir $currentOutput
        $alive = Test-RunAaaiAliveForOutput -OutputDir $currentOutput
        Write-RunLog "active C4i batch status: runner_alive=$alive result_json_count=$count expected=14"

        if (($count -ge 14) -and (-not $alive)) {
            Write-RunLog "active C4i completion batch finished"
            break
        }

        Start-Sleep -Seconds $SleepSeconds
    }
}

function Get-MissingCells {
    param($Batch)

    $fullOutput = Join-Path $RepoRoot $Batch.OutputDir
    $missing = @()
    foreach ($design in $Batch.Designs) {
        foreach ($seed in $Batch.Seeds) {
            $result = Join-Path $fullOutput "$design/$($Batch.Condition)/$seed/result.json"
            if (-not (Test-Path $result)) {
                $missing += [pscustomobject]@{ Design = $design; Seed = $seed }
            }
        }
    }
    return $missing
}

function Invoke-Batch {
    param($Batch)

    New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot $Batch.OutputDir) | Out-Null
    Write-RunLog "starting batch $($Batch.Name): condition=$($Batch.Condition) output=$($Batch.OutputDir)"

    for ($attempt = 1; $attempt -le $MaxAttemptsPerBatch; $attempt++) {
        $missing = @(Get-MissingCells -Batch $Batch)
        Write-RunLog "batch $($Batch.Name) attempt $attempt missing=$($missing.Count)"
        if ($missing.Count -eq 0) {
            break
        }

        $designs = $missing | Select-Object -ExpandProperty Design -Unique
        $seeds = $missing | Select-Object -ExpandProperty Seed -Unique
        Write-RunLog "running $($Batch.Name): designs=$($designs -join ',') seeds=$($seeds -join ',')"

        python -m cegis.tdes.fpga.autonomous.run_aaai `
            --designs $designs `
            --conditions $Batch.Condition `
            --models gpt-5.5 `
            --seeds $seeds `
            --output $Batch.OutputDir `
            --parallel 2 *>> $fullLog
    }

    $remaining = @(Get-MissingCells -Batch $Batch)
    Write-RunLog "batch $($Batch.Name) complete/pass-through: remaining_missing=$($remaining.Count)"

    Write-RunLog "rebuilding inventories after $($Batch.Name)"
    python scripts\build_artifact_index.py *>> $fullLog
    python scripts\build_run_matrix.py *>> $fullLog
}

$batches = @(
    @{
        Name = "c2g-conditional-l5l6"
        OutputDir = "artifacts/raw_runs/overnight_c2g_conditional_20260704"
        Condition = "C2g"
        Designs = @("aes_decryption", "dct_idct_8pt_pipelined", "conv_3d", "quantized_matmul")
        Seeds = @(42, 123, 456)
    },
    @{
        Name = "c4i-conditional-l5l6"
        OutputDir = "artifacts/raw_runs/overnight_c4i_conditional_20260704"
        Condition = "C4i"
        Designs = @("aes_decryption", "dct_idct_8pt_pipelined", "conv_3d", "quantized_matmul")
        Seeds = @(123, 456)
    },
    @{
        Name = "c4tl-fairness-l5l6"
        OutputDir = "artifacts/raw_runs/overnight_c4tl_fairness_20260704"
        Condition = "C4tl"
        Designs = @(
            "harris_corner_detection",
            "aes_encryption",
            "fft_streaming_64pt",
            "aes_decryption",
            "conv2d",
            "unsharp_mask",
            "dct_idct_8pt_pipelined",
            "conv_3d",
            "quantized_matmul"
        )
        Seeds = @(123, 456)
    }
)

Write-RunLog "overnight remainder supervisor started"
Wait-ForCurrentC4iBatch

foreach ($batch in $batches) {
    Invoke-Batch -Batch $batch
}

Write-RunLog "overnight remainder supervisor complete"
