# ============================================================
#  NutriPal - Unified Service Startup Script
# ============================================================
#
#  Starts all 3 services:
#    1. Node.js Backend API      (port 4000)
#    2. Python AI Planner        (port 8000)
#    3. Python Pose Corrector    (port 8001)
#
#  Usage:
#    .\START_ALL_SERVICES.ps1                 # Start all
#    .\START_ALL_SERVICES.ps1 -SkipAI         # Skip AI planner
#    .\START_ALL_SERVICES.ps1 -SkipPose       # Skip pose corrector
#    .\START_ALL_SERVICES.ps1 -BackendOnly    # Only Node.js backend
#
# ============================================================

param(
    [switch]$SkipAI,
    [switch]$SkipPose,
    [switch]$BackendOnly
)

$ErrorActionPreference = "Continue"
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$BACKEND_DIR = Join-Path $ROOT "backend"
$AI_DIR = Join-Path $BACKEND_DIR "ai-planner"
$POSE_DIR = Join-Path $BACKEND_DIR "pose-corrector"

# Detect Python paths
$AI_PYTHON = Join-Path $BACKEND_DIR "venv-ai\Scripts\python.exe"
$POSE_PYTHON = Join-Path $BACKEND_DIR "venv-pose\Scripts\python.exe"

if (-not (Test-Path $AI_PYTHON) -or -not (Test-Path $POSE_PYTHON)) {
    Write-Host "Warning: Isolated virtual environments not found. Falling back to system Python." -ForegroundColor Yellow
    $SYS_PYTHON = if (Get-Command python -ErrorAction SilentlyContinue) { "python" }
                  elseif (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" }
                  elseif (Get-Command py -ErrorAction SilentlyContinue) { "py" }
                  else { $null }
    if (-not (Test-Path $AI_PYTHON)) { $AI_PYTHON = $SYS_PYTHON }
    if (-not (Test-Path $POSE_PYTHON)) { $POSE_PYTHON = $SYS_PYTHON }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  NutriPal - Starting Services" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$env:PYTHONIOENCODING = "utf-8"
$jobs = @()

# -- 1. Node.js Backend --
Write-Host "[1/3] Starting Node.js Backend (port 4000)..." -ForegroundColor Green
$backendJob = Start-Process -FilePath "node" -ArgumentList "src/server.js" -WorkingDirectory $BACKEND_DIR -PassThru -NoNewWindow
$jobs += $backendJob
Write-Host "  PID: $($backendJob.Id)" -ForegroundColor DarkGray
Start-Sleep -Seconds 2

# -- 2. AI Planner (Python) --
if (-not $BackendOnly -and -not $SkipAI) {
    if ($AI_PYTHON) {
        $aiServer = Join-Path $AI_DIR "api_server.py"
        if (Test-Path $aiServer) {
            Write-Host "[2/3] Starting AI Planner (port 8000)..." -ForegroundColor Yellow
            $aiJob = Start-Process -FilePath $AI_PYTHON -ArgumentList "api_server.py" -WorkingDirectory $AI_DIR -PassThru -NoNewWindow
            $jobs += $aiJob
            Write-Host "  PID: $($aiJob.Id)" -ForegroundColor DarkGray
        } else {
            Write-Host "[2/3] SKIPPED - ai-planner/api_server.py not found" -ForegroundColor DarkYellow
        }
    } else {
        Write-Host "[2/3] SKIPPED - Python not found in PATH" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "[2/3] SKIPPED - AI Planner (flag)" -ForegroundColor DarkGray
}

# -- 3. Pose Corrector (Python) --
if (-not $BackendOnly -and -not $SkipPose) {
    if ($POSE_PYTHON) {
        $poseServer = Join-Path $POSE_DIR "pose_corrector_api.py"
        if (Test-Path $poseServer) {
            Write-Host "[3/3] Starting Pose Corrector (port 8001)..." -ForegroundColor Magenta
            $poseJob = Start-Process -FilePath $POSE_PYTHON -ArgumentList "pose_corrector_api.py" -WorkingDirectory $POSE_DIR -PassThru -NoNewWindow
            $jobs += $poseJob
            Write-Host "  PID: $($poseJob.Id)" -ForegroundColor DarkGray
        } else {
            Write-Host "[3/3] SKIPPED - pose-corrector/pose_corrector_api.py not found" -ForegroundColor DarkYellow
        }
    } else {
        Write-Host "[3/3] SKIPPED - Python not found in PATH" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "[3/3] SKIPPED - Pose Corrector (flag)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Services Running" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Backend API:     http://localhost:4000" -ForegroundColor White
Write-Host "  API Docs:        http://localhost:4000/api/v1" -ForegroundColor White
if (-not $BackendOnly -and -not $SkipAI) {
    Write-Host "  AI Planner:      http://localhost:8000" -ForegroundColor White
    Write-Host "  AI Planner Docs: http://localhost:8000/docs" -ForegroundColor White
}
if (-not $BackendOnly -and -not $SkipPose) {
    Write-Host "  Pose Corrector:  http://localhost:8001" -ForegroundColor White
    Write-Host "  Pose WS:        ws://localhost:8001/ws/pose-analysis" -ForegroundColor White
}
Write-Host ""
Write-Host "  Press Ctrl+C to stop all services" -ForegroundColor DarkGray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Wait for any process to exit
try {
    while ($true) {
        foreach ($job in $jobs) {
            if ($job.HasExited) {
                Write-Host "Process $($job.Id) exited with code $($job.ExitCode)" -ForegroundColor Red
            }
        }
        Start-Sleep -Seconds 5
    }
} finally {
    Write-Host "`nStopping all services..." -ForegroundColor Yellow
    foreach ($job in $jobs) {
        if (-not $job.HasExited) {
            Stop-Process -Id $job.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  Stopped PID $($job.Id)" -ForegroundColor DarkGray
        }
    }
    Write-Host "All services stopped." -ForegroundColor Green
}
