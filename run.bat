@echo off
setlocal EnableDelayedExpansion
title FEDDA Hub v22

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "PYTHON=%ROOT%\python_embeded\python.exe"
set "COMFY_MAIN=%ROOT%\ComfyUI\main.py"
set "BACKEND=%ROOT%\backend\server.py"
set "FRONTEND=%ROOT%\frontend"

echo.
echo ============================================================
echo   FEDDA Hub v22
echo ============================================================
echo.

if not exist "%PYTHON%" (
    echo [ERROR] python_embeded not found. Run the installer first.
    echo.
    pause
    exit /b 1
)
if not exist "%COMFY_MAIN%" (
    echo [ERROR] ComfyUI not found. Run the installer first.
    echo.
    pause
    exit /b 1
)
if not exist "%FRONTEND%\node_modules" (
    echo [ERROR] Frontend dependencies missing. Run the installer first.
    echo.
    pause
    exit /b 1
)

echo [1/3] Starting ComfyUI on port 8199...
start "FEDDA - ComfyUI" /MIN "%PYTHON%" -s "%COMFY_MAIN%" --windows-standalone-build --port 8199

echo [2/3] Starting backend on port 8000...
start "FEDDA - Backend" /MIN "%PYTHON%" "%BACKEND%"

echo [3/3] Starting frontend (browser opens automatically)...
echo.
echo       To stop: close this window, then close the two minimized windows.
echo.
cd /d "%FRONTEND%"
npm run dev
