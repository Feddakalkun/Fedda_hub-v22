@echo off
setlocal EnableDelayedExpansion
title FEDDA Installer

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%\..") do set "BASE_DIR=%%~fI"
cd /d "%BASE_DIR%"

echo.
echo ============================================================================
echo   FEDDAKALKUN INSTALLER
echo ============================================================================
echo.
echo   Scanning your system...
echo.

:: ============================================================================
:: SYSTEM SCAN
:: ============================================================================

:: GPU Check - nvidia-smi -L gives clean output on all driver versions
set "GPU_OK=0"
set "GPU_NAME=Not detected"
for /f "tokens=1,* delims=:" %%a in ('nvidia-smi -L 2^>^&1 ^| findstr /i "^GPU"') do (
    if "!GPU_OK!"=="0" (
        set "GPU_OK=1"
        :: %%b = " NVIDIA GeForce RTX 3090 (UUID: ...)"
        :: Extract name before the UUID parenthesis
        set "_gpu=%%b"
        for /f "tokens=1 delims=(" %%n in ("%%b") do (
            :: Trim leading space
            for /f "tokens=*" %%t in ("%%n") do set "GPU_NAME=%%t"
        )
    )
)
if "!GPU_OK!"=="1" (
    echo   GPU:      !GPU_NAME!
) else (
    echo   GPU:      No NVIDIA GPU found
)

:: Check for system Python + parse version
set "HAS_PYTHON=0"
set "PY_VERSION="
set "PY_MINOR=0"
set "PY_VERSION_OK=0"
set "PY_VERSION_WARN=0"
where python >nul 2>nul
if %errorlevel% equ 0 (
    set "HAS_PYTHON=1"
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do set "PY_VERSION=%%v"
    :: Parse minor version - "Python 3.10.11" -> extract 10
    for /f "tokens=2 delims=." %%m in ('python --version 2^>^&1') do set "PY_MINOR=%%m"
    if !PY_MINOR! GEQ 10 set "PY_VERSION_OK=1"
    if !PY_MINOR! EQU 10 set "PY_VERSION_WARN=1"
)

:: Check for system Git
set "HAS_GIT=0"
set "GIT_VERSION="
where git >nul 2>nul
if %errorlevel% equ 0 (
    set "HAS_GIT=1"
    for /f "tokens=*" %%v in ('git --version 2^>^&1') do set "GIT_VERSION=%%v"
)

:: Check for system Node
set "HAS_NODE=0"
set "NODE_VERSION="
where node >nul 2>nul
if %errorlevel% equ 0 (
    set "HAS_NODE=1"
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do set "NODE_VERSION=%%v"
)

:: Check for system npm
set "HAS_NPM=0"
set "NPM_VERSION="
where npm >nul 2>nul
if %errorlevel% equ 0 (
    set "HAS_NPM=1"
    for /f "tokens=*" %%v in ('npm --version 2^>^&1') do set "NPM_VERSION=%%v"
)

:: Check for system Ollama
set "HAS_OLLAMA=0"
where ollama >nul 2>nul
if %errorlevel% equ 0 (
    set "HAS_OLLAMA=1"
)

echo.
echo   System Tools Found:
if "%HAS_PYTHON%"=="1" (
    echo     Python:   %PY_VERSION%  [embedded 3.11.9 will be used if needed]
) else (
    echo     Python:   not installed  [embedded 3.11.9 will be downloaded]
)
if "%HAS_GIT%"=="1" (
    echo     Git:      %GIT_VERSION%
) else (
    echo     Git:      not installed
)
if "%HAS_NODE%"=="1" (
    echo     Node.js:  %NODE_VERSION%
) else (
    echo     Node.js:  not installed
)
if "%HAS_NPM%"=="1" (
    echo     npm:      v%NPM_VERSION%
) else (
    echo     npm:      not installed
)
if "%HAS_OLLAMA%"=="1" (
    echo     Ollama:   installed
) else (
    echo     Ollama:   not installed
)

echo   Main install uses embedded Python + system Git/Node/npm where available.

:: ============================================================================
:: CHECK IF ALREADY INSTALLED
:: ============================================================================
if exist "%BASE_DIR%\python_embeded\python.exe" (
    echo.
    echo   [NOTE] Install already detected (python_embeded found^).
    echo          Run UPDATE.bat from the install root to update, or delete python_embeded to reinstall.
    echo.
    if not "%FEDDA_UNATTENDED%"=="1" pause
    exit /b 0
)
if exist "%BASE_DIR%\venv\Scripts\python.exe" (
    echo.
    echo   [NOTE] Install already detected (venv found^).
    echo          Run UPDATE.bat from the install root to update, or delete venv to reinstall.
    echo.
    if not "%FEDDA_UNATTENDED%"=="1" pause
    exit /b 0
)

:: ============================================================================
:: NVIDIA CHECK
:: ============================================================================
if "%GPU_OK%"=="0" (
    echo.
    echo   ============================================================
    echo   ERROR: No NVIDIA GPU detected!
    echo   FEDDAKALKUN requires an NVIDIA GPU with CUDA support.
    echo   AMD and Intel GPUs are not supported.
    echo   ============================================================
    echo.
    if not "%FEDDA_UNATTENDED%"=="1" pause
    exit /b 1
)

:: Single main install
:: Uses embedded Python + system Git/Node

:: ============================================================================
:: MAIN INSTALL
:: ============================================================================
for %%I in ("%~dp0\..") do set "BASE_DIR=%%~fI"
set "SCRIPT_DIR=%~dp0"
if "!SCRIPT_DIR:~-1!"=="\" set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
cd /d "!BASE_DIR!"

echo.
echo   Starting Main Install...
echo.

if "%FEDDA_UNATTENDED%"=="1" (
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\install.ps1" -Unattended
) else (
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\install.ps1"
)

if %errorlevel% neq 0 (
    echo.
    echo   [ERROR] Installation failed! Check logs\install_fast_log.txt
    echo.
    if not "%FEDDA_UNATTENDED%"=="1" pause
    exit /b %errorlevel%
)

goto :done

:: ============================================================================
:: DONE
:: ============================================================================
:done
echo.
echo ============================================================================
echo   INSTALLATION COMPLETE!
echo ============================================================================
echo.
echo   To start FEDDA, run:  RUN.bat from the install root
echo.
echo   Log files saved to: %BASE_DIR%\logs\
echo     - install_report.txt      Quick summary of what was installed
echo     - install_full_log.txt    Full transcript of every command
echo     - install_log.txt         Step-by-step progress log
echo.
if exist "%BASE_DIR%\logs\install_report.txt" (
    echo   --- INSTALL REPORT ---
    type "%BASE_DIR%\logs\install_report.txt"
    echo   --- END REPORT ---
    echo.
)
if not "%FEDDA_UNATTENDED%"=="1" pause

