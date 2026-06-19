@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
title FEDDA Launcher
echo.
echo IMPORTANT: This launcher window will stay open at the end with a pause.
echo All real output is in the titled service windows.
echo Do not close this until you see the final pause.
echo.

set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"

:: Keep all ML caches inside install folder (never write to %USERPROFILE%\.cache)
set "HF_HOME=%BASE_DIR%\cache\huggingface"
set "TORCH_HOME=%BASE_DIR%\cache\torch"
set "INSIGHTFACE_ROOT=%BASE_DIR%\cache\insightface"
set "PIP_CACHE_DIR=%BASE_DIR%\cache\pip"
set "YOLO_CONFIG_DIR=%BASE_DIR%\cache\ultralytics"
set "ULTRALYTICS_SETTINGS=%BASE_DIR%\cache\ultralytics\settings.json"

:: Helps with VRAM fragmentation on Flux / heavy models (reduces OOMs on 24GB cards)
set "PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True"

:: ============================================================================
:: SERVICE DISPATCH - background services, output goes to logs/
:: ============================================================================
if "%1"==":svc_ollama" (
    if not exist "%BASE_DIR%\logs" mkdir "%BASE_DIR%\logs"
    call :launch_ollama > "%BASE_DIR%\logs\ollama.log" 2>&1
    exit
)
if "%1"==":svc_comfy" (
    call :launch_comfy
    exit
)
if "%1"==":svc_backend" (
    if not exist "%BASE_DIR%\logs" mkdir "%BASE_DIR%\logs"
    :: Launch backend in this visible console window. Errors will show here.
    call :launch_backend
    exit
)

:: ============================================================================
:: ENTRY POINT: Detect environment and launch
:: ============================================================================
call :detect_env
if errorlevel 1 goto :missing_python

echo.
echo ============================================================================
echo   FEDDA LAUNCHER  (%MODE% mode)
echo ============================================================================
echo.

echo [1/4] Auto-update disabled (updates are distributed manually)
echo.

:: ============================================================================
:: SSL CERTIFICATE FIX (prevents CivitAI / HF "certificate verify failed" errors)
:: This makes every Python process in this session use a reliable CA bundle.
:: The installer already ran the full repair; this is the runtime safety net.
:: ============================================================================
set "SSL_CERT_FILE=%PY_EMBED_DIR%\cacert.pem"
set "REQUESTS_CA_BUNDLE=%PY_EMBED_DIR%\cacert.pem"
set "CURL_CA_BUNDLE=%PY_EMBED_DIR%\cacert.pem"

:: Optional: if the bundle is missing or tiny, run the repair script once
if not exist "%PY_EMBED_DIR%\cacert.pem" (
    echo [SSL] No CA bundle found - running one-time repair...
    if exist "%BASE_DIR%\scripts\fix_embedded_ssl.ps1" (
        powershell -ExecutionPolicy Bypass -File "%BASE_DIR%\scripts\fix_embedded_ssl.ps1" -RootPath "%BASE_DIR%"
    )
) else (
    for /f "delims=" %%A in ('powershell -NoProfile -Command "try { (Get-Item '%PY_EMBED_DIR%\cacert.pem' -ErrorAction Stop).Length } catch { 0 }"') do set "CERTSIZE=%%A"
    if defined CERTSIZE (
        if !CERTSIZE! LSS 100000 (
            echo [SSL] CA bundle looks incomplete - repairing...
            if exist "%BASE_DIR%\scripts\fix_embedded_ssl.ps1" (
                powershell -ExecutionPolicy Bypass -File "%BASE_DIR%\scripts\fix_embedded_ssl.ps1" -RootPath "%BASE_DIR%"
            )
        )
    )
)

:: ============================================================================
:: MAIN LAUNCHER: Start services
:: ============================================================================

call :cleanup_stale_services

:: 2. Start Ollama
if "%MODE%"=="portable" (
    if exist "%BASE_DIR%\ollama_embeded\ollama.exe" (
        echo [2/4] Starting Ollama...
        start /B "" cmd /c ""%~f0" :svc_ollama"
        timeout /t 2 /nobreak >nul
    ) else (
        where ollama >nul 2>nul
        if not errorlevel 1 (
            echo [2/4] Starting system Ollama...
            start /B "" cmd /c ""%~f0" :svc_ollama"
            timeout /t 2 /nobreak >nul
        ) else (
            echo [2/4] Ollama not found - Ollama Models page will show offline
        )
    )
) else (
    where ollama >nul 2>nul
    if not errorlevel 1 (
        echo [2/4] Starting Ollama...
        start /B "" cmd /c ""%~f0" :svc_ollama"
        timeout /t 2 /nobreak >nul
    ) else (
        echo [2/4] Ollama not found - Ollama Models page will show offline
    )
)


:: 3. Start ComfyUI
echo [3/4] Starting ComfyUI (Port 8199)...
call :is_port_listening 8199
if errorlevel 1 (
    echo     ComfyUI already running.
) else (
    start "FEDDA ComfyUI Console" cmd /k ""%~f0" :svc_comfy"
    echo     ComfyUI is starting in its own "FEDDA ComfyUI Console" window.
    echo     It can take 30-120 seconds to load all custom nodes on first start.
)

:: 4. Start FastAPI Backend

echo [4/4] Starting Backend (Port 8000)...
call :is_port_listening 8000
if errorlevel 1 (
    echo     Backend already running.
) else (
    echo     Opening visible Backend Console window - watch for Uvicorn running on http://0.0.0.0:8000
    start "FEDDA Backend Console" cmd /k ""%~f0" :svc_backend"
)

:: Start Frontend
echo [UI] Starting FEDDA UI (Port 5173)...
echo     Opening FEDDA Hub v21...
echo.
echo   Logs:  %BASE_DIR%\logs\
echo   Close this window to stop all services.
echo.
echo Starting frontend in separate window...
pushd "%BASE_DIR%\frontend"
if not exist "node_modules" (
    echo [INFO] node_modules missing, running npm install...
    call npm install
)
start "FEDDA Frontend" cmd /k "cd /d ""%BASE_DIR%\frontend"" && set ""PATH=%BASE_DIR%\frontend\node_modules\.bin;%PATH%"" && call npm run dev"
popd

echo.
echo Main launcher done. All services are in their windows.
echo Close this window anytime (services keep running in their consoles).
echo.
echo Press any key to close this launcher window...
pause >nul
cmd /k "echo This prompt is here to keep the window open. Type exit to close."

:: ============================================================================
:: SUBROUTINE: CHECK IF TCP PORT IS LISTENING
:: Returns errorlevel 1 when listening, 0 when not listening.
:: ============================================================================
:is_port_listening
@setlocal
@set "CHECK_PORT=%~1"
@for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /R /C:":%CHECK_PORT% .*LISTENING"') do (
    @endlocal
    @exit /b 1
)
@endlocal
@exit /b 0

:: ============================================================================
:: SUBROUTINE: CLEAN UP STALE FEDDA SERVICE PROCESSES
:: ============================================================================
:cleanup_stale_services
if not exist "%BASE_DIR%\logs" mkdir "%BASE_DIR%\logs"
echo     Cleaning stale FEDDA service processes...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$base = [IO.Path]::GetFullPath('%BASE_DIR%');" ^
  "$procs = Get-CimInstance Win32_Process | Where-Object {" ^
  "  $_.CommandLine -and (" ^
  "    $_.CommandLine -like ('*' + $base + '\\python_embeded\\python.exe* -u server.py*') -or " ^
  "    $_.CommandLine -like ('*' + $base + '\\python_embedded\\python.exe* -u server.py*') -or " ^
  "    $_.CommandLine -like ('*' + $base + '\\python_embeded\\python.exe* main.py*') -or " ^
  "    $_.CommandLine -like ('*' + $base + '\\python_embedded\\python.exe* main.py*') -or " ^
  "    $_.CommandLine -like ('*' + $base + '\\frontend\\*vite*')" ^
  "  )" ^
  "};" ^
  "foreach ($p in $procs) { try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } catch {} }" >nul 2>&1
timeout /t 1 /nobreak >nul
exit /b

:: ============================================================================
:: SUBROUTINE: DETECT ENVIRONMENT (Portable vs Lite)
:: ============================================================================
:detect_env
set "MODE="
set "PYTHON="
set "PY_EMBED_DIR="
if exist "%BASE_DIR%\python_embeded\python.exe" (
    set "MODE=portable"
    set "PYTHON=%BASE_DIR%\python_embeded\python.exe"
    set "PY_EMBED_DIR=%BASE_DIR%\python_embeded"
    set "PATH=%BASE_DIR%\python_embeded;%BASE_DIR%\python_embeded\Scripts;%BASE_DIR%\git\cmd;%BASE_DIR%\node_embeded;%PATH%"
    set "COMFY_EXTRA_FLAGS=--windows-standalone-build --force-upcast-attention"
) else if exist "%BASE_DIR%\python_embedded\python.exe" (
    set "MODE=portable"
    set "PYTHON=%BASE_DIR%\python_embedded\python.exe"
    set "PY_EMBED_DIR=%BASE_DIR%\python_embedded"
    set "PATH=%BASE_DIR%\python_embedded;%BASE_DIR%\python_embedded\Scripts;%BASE_DIR%\git\cmd;%BASE_DIR%\node_embeded;%PATH%"
    set "COMFY_EXTRA_FLAGS=--windows-standalone-build --force-upcast-attention"
) else if exist "%BASE_DIR%\venv\Scripts\python.exe" (
    set "MODE=lite"
    set "PYTHON=%BASE_DIR%\venv\Scripts\python.exe"
    set "PY_EMBED_DIR=%BASE_DIR%\venv"
    set "COMFY_EXTRA_FLAGS="
) else (
    exit /b 1
)
exit /b 0

:: ============================================================================
:: SUBROUTINE: MISSING PYTHON MESSAGE
:: ============================================================================
:missing_python
echo.
echo [ERROR] No Python environment found!
echo        FEDDA is not installed yet, or Python install failed.
echo.
echo        Expected one of:
echo          %BASE_DIR%\python_embeded\python.exe
echo          %BASE_DIR%\python_embedded\python.exe
echo          %BASE_DIR%\venv\Scripts\python.exe
echo.
if exist "%BASE_DIR%\INSTALL-LITE.bat" (
    echo        Run INSTALL-LITE.bat first, then RUN.bat.
) else if exist "%BASE_DIR%\INSTALL.bat" (
    echo        Run INSTALL.bat first, then RUN.bat.
) else if exist "%BASE_DIR%\scripts\install.bat" (
    echo        Run scripts\install.bat first, then RUN.bat.
) else (
    echo        Installer files are missing. Re-run the one-click FEDDA installer.
)
echo.
pause
exit /b 1

:: ============================================================================
:: SUBROUTINE: OLLAMA
:: ============================================================================
:launch_ollama
set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"
set "OLLAMA_HOST=127.0.0.1:11434"

echo [%date% %time%] Starting Ollama...
if exist "%BASE_DIR%\ollama_embeded\ollama.exe" (
    set "OLLAMA_MODELS=%BASE_DIR%\ollama_embeded\models"
    "%BASE_DIR%\ollama_embeded\ollama.exe" serve
) else (
    ollama serve
)
if %errorlevel% neq 0 (
    echo [ERROR] Ollama crashed with error code %errorlevel%
)
exit /b

:: ============================================================================
:: SUBROUTINE: COMFYUI
:: ============================================================================
:launch_comfy
set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"
set "COMFYUI_DIR=%BASE_DIR%\ComfyUI"

:: Detect Python (call detect_env subroutine)
call :detect_env
if errorlevel 1 goto :missing_python

set COMFYUI_OFFLINE=1
set TORIO_USE_FFMPEG=0
set PYTHONUNBUFFERED=1
set PYTHONIOENCODING=utf-8
set PYTHONPATH=%COMFYUI_DIR%;%PYTHONPATH%

echo [%date% %time%] Clearing port 8199...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":8199"') do (taskkill /F /PID %%a >nul 2>&1)
timeout /t 1 /nobreak >nul

cd /d "%COMFYUI_DIR%"
if not exist "%BASE_DIR%\logs" mkdir "%BASE_DIR%\logs"
set "COMFY_LOG=%BASE_DIR%\logs\comfyui_latest.log"
echo [%date% %time%] Starting ComfyUI...
echo [%date% %time%] Live output in this window. Full log also written to: %COMFY_LOG%
echo [%date% %time%] (Close this window only after shutting down FEDDA)
(
  "%PYTHON%" -W ignore::FutureWarning -s -u main.py %COMFY_EXTRA_FLAGS% --port 8199 --listen 127.0.0.1 --reserve-vram 4 --disable-cuda-malloc --enable-cors-header * --preview-method auto --disable-auto-launch --enable-manager --enable-manager-legacy-ui
) 2>&1 | powershell -NoProfile -Command "$input | Tee-Object -FilePath '%COMFY_LOG%' -Append | Out-Host"

if %errorlevel% neq 0 (
    echo [%date% %time%] [ERROR] ComfyUI exited with code %errorlevel%
)
exit /b


:: ============================================================================
:: SUBROUTINE: BACKEND
:: ============================================================================
:launch_backend
set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"
set "BACKEND_DIR=%BASE_DIR%\backend"

:: Detect Python (call detect_env subroutine)
call :detect_env
if errorlevel 1 goto :missing_python
set "PYTHONPATH=%BACKEND_DIR%;%PYTHONPATH%"

echo [%date% %time%] Clearing port 8000...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":8000"') do (taskkill /F /PID %%a >nul 2>&1)
timeout /t 1 /nobreak >nul

cd /d "%BACKEND_DIR%"
echo [%date% %time%] Checking backend Python dependencies...
"%PYTHON%" -c "import uvicorn, fastapi, requests, pydantic" >nul 2>&1
if %errorlevel% neq 0 (
    echo [%date% %time%] Installing missing backend dependencies...
    "%PYTHON%" -m pip install uvicorn fastapi requests python-multipart pydantic
)
echo [%date% %time%] Starting Backend...
"%PYTHON%" -u server.py

if %errorlevel% neq 0 (
    echo [%date% %time%] [ERROR] Backend crashed with error code %errorlevel%
)
exit /b
