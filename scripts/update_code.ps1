# ============================================================================
# FEDDA Code Update - Fast, minimal, pulls latest code from GitHub
# Used by auto-update in run.bat - focused on speed
# For full maintenance (custom nodes, deps), see update_logic.ps1
# ============================================================================

param([switch]$SilentMode)

$ErrorActionPreference = "Stop"
$ScriptPath = $PSScriptRoot
$RootPath = Split-Path -Parent $ScriptPath
Set-Location $RootPath

if (-not $SilentMode) {
    Write-Host "`n===================================================" -ForegroundColor Cyan
    Write-Host "  FEDDA CODE UPDATE" -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
}

# ============================================================================
# GIT SETUP
# ============================================================================
$GitEmbedded = Join-Path $RootPath "git_embeded\cmd\git.exe"
if (Test-Path $GitEmbedded) {
    $GitExe = $GitEmbedded
    $env:PATH = "$(Split-Path $GitExe);$env:PATH"
} else {
    $GitExe = "git"
}

# Fix dubious ownership errors (local config only - never modify user's global gitconfig)
$env:GIT_CONFIG_GLOBAL = Join-Path $RootPath ".gitconfig"
& $GitExe config --file "$env:GIT_CONFIG_GLOBAL" --add safe.directory '*' 2>$null

# ============================================================================
# 1. CHECK IF GIT REPO EXISTS
# ============================================================================
if (-not (Test-Path (Join-Path $RootPath ".git"))) {
    if (-not $SilentMode) {
        Write-Host "`n  Initializing git from GitHub..." -ForegroundColor Yellow
    }
    & $GitExe init
    & $GitExe remote add origin https://github.com/Feddakalkun/Fedda_hub-v22.git
}

# ============================================================================
# 2. PULL LATEST CODE
# ============================================================================
if (-not $SilentMode) {
    Write-Host "`n  Pulling latest code from GitHub..." -ForegroundColor Yellow
    # Stash local changes to protect uncommitted work (including new files like workflows)
    $hasChanges = & $GitExe status --porcelain
    if ($hasChanges) {
        if (-not $SilentMode) { Write-Host "  Stashing local changes to protect them..." -ForegroundColor Yellow }
        & $GitExe stash push -u -m "auto-stash-before-update-$(Get-Date -Format yyyyMMddHHmmss)" 2>&1 | Out-Null
    }
}

try {
    $ErrorActionPreference = "Continue"
    & $GitExe fetch origin main 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "git fetch failed"
    }
    & $GitExe reset --hard origin/main 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "git reset failed"
    }
    & $GitExe clean -fd 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"
    
    if (-not $SilentMode) {
        Write-Host "  [OK] Code updated successfully." -ForegroundColor Green
        if ($hasChanges) { if (-not $SilentMode) { Write-Host "  (Your local changes were stashed - use git stash pop to restore)" -ForegroundColor Yellow } }
    }
} catch {
    if (-not $SilentMode) {
        Write-Host "  [WARN] Git update failed: $_" -ForegroundColor Yellow
    }
    exit 1
}

# ============================================================================
# 3. RUN FULL MAINTENANCE (nodes, deps, frontend)
# ============================================================================
$UpdateLogic = Join-Path $ScriptPath "update_logic.ps1"
if (Test-Path $UpdateLogic) {
    if (-not $SilentMode) {
        Write-Host "`n  Running full maintenance (nodes, deps, frontend)..." -ForegroundColor Yellow
    }
    & powershell -ExecutionPolicy Bypass -File "$UpdateLogic" $(if ($SilentMode) { "-SilentMode" })
} else {
    if (-not $SilentMode) {
        Write-Host "`n  [WARN] update_logic.ps1 not found - skipping node/dep maintenance." -ForegroundColor Yellow
    }
}

# ============================================================================
# DONE
# ============================================================================
if (-not $SilentMode) {
    Write-Host "`n===================================================" -ForegroundColor Green
    Write-Host "  UPDATE COMPLETE" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green
}

exit 0
