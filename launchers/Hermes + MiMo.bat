@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
REM ============================================================
REM  HERMES + MIMO V2.5 FREE — Full Stack Launcher
REM  Starts: Proxy(:9224) + SearXNG(:8888) + Vision(:9225) + Ollama
REM  Then syncs config + launches Hermes Desktop.
REM  Works from Desktop shortcut OR from launchers/ directory.
REM ============================================================

REM --- Resolve PROXY_DIR (works from Desktop or launchers/) ---
set "PROXY_DIR=%~dp0"
if "%PROXY_DIR:~-1%"=="\" set "PROXY_DIR=%PROXY_DIR:~0,-1%"
if exist "%PROXY_DIR%\..\config.json" (
    for %%I in ("%PROXY_DIR%\..\") do set "PROXY_DIR=%%~fI"
    goto have_dir
)
if exist "%PROXY_DIR%\config.json" goto have_dir
set "PROXY_DIR=C:\AI\hermes-proxy"
:have_dir

REM --- Resolve other dirs ---
set "INSTALL_DIR=C:\AI"
set "WEBSTACK_DIR=%INSTALL_DIR%\ecc-final\webstack"
set "VISION_DIR=%INSTALL_DIR%\vision-fallback"
set "OLLAMA_EXE=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
set "HERMES_HOME=%INSTALL_DIR%\HERMES\.hermes"

title Hermes + MiMo V2.5 Free Proxy (port 9224)
echo ==============================================
echo  HERMES + MIMO V2.5 FREE — FULL STACK
echo  Ports:  Proxy(:9224) SearXNG(:8888)
echo          Vision(:9225) Ollama(:11434)
echo  Proxy:  %PROXY_DIR%
echo ==============================================
echo.

echo [1/6] Stopping full Hermes stack...
REM Kill Hermes Desktop
taskkill /F /IM Hermes.exe /T >nul 2>&1
taskkill /F /IM hermes.exe /T >nul 2>&1
taskkill /F /IM hermes-agent.exe /T >nul 2>&1
REM Kill proxy on :9224
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :9224 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>&1
REM Kill vision fallback on :9225
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :9225 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>&1
REM Kill Ollama
taskkill /F /IM ollama.exe /T >nul 2>&1
timeout /t 2 /nobreak >nul
echo     Done.
echo.

echo [2/6] Starting proxy on port 9224...
set "PROXY_PY=%PROXY_DIR%\.venv\Scripts\python.exe"
if not exist "%PROXY_PY%" (
    echo     ERROR: %PROXY_PY% not found!
    echo     Run: py -3.13 -m venv "%PROXY_DIR%\.venv" ^&^& "%PROXY_DIR%\.venv\Scripts\pip" install -r "%PROXY_DIR%\requirements.txt"
    pause
    exit /b 1
)
cd /d "%PROXY_DIR%"
start /b "" "%PROXY_PY%" -m uvicorn app.main:app --host 127.0.0.1 --port 9224
echo     Proxy starting...
echo.

echo [3/6] Starting SearXNG on port 8888...
cd /d "%WEBSTACK_DIR%"
if exist "%WEBSTACK_DIR%\start_searx.bat" (
    start /b cmd /c ""%WEBSTACK_DIR%\start_searx.bat""
    echo     SearXNG starting...
) else (
    echo     WARNING: SearXNG not found at %WEBSTACK_DIR%
    echo     Search will use public instances (may hit captchas).
)
echo.

echo [4/6] Starting vision fallback on port 9225...
if exist "%VISION_DIR%\vision_fallback.py" (
    cd /d "%VISION_DIR%"
    start /b "" "%PROXY_PY%" "%VISION_DIR%\vision_fallback.py"
    echo     Vision fallback starting...
) else (
    echo     WARNING: vision_fallback.py not found at %VISION_DIR%
)
echo.

echo [5/6] Starting Ollama (local LLM for vision fallback)...
if exist "%OLLAMA_EXE%" (
    start /b "" "%OLLAMA_EXE%" serve
    echo     Ollama starting...
) else (
    echo     WARNING: Ollama not found - local vision fallback unavailable
)
echo.

echo [6/6] Syncing Hermes config + starting Hermes Desktop...
cd /d "%PROXY_DIR%"
if exist "%PROXY_PY%" (
    "%PROXY_PY%" "%PROXY_DIR%\sync_hermes_config.py" 2>nul
)
echo.

REM Wait for proxy health
echo     Waiting for proxy health...
set /a c=0
:wait_proxy
timeout /t 1 /nobreak >nul
curl -s -o nul http://127.0.0.1:9224/openapi.json
if %errorlevel% equ 0 goto proxy_ok
set /a c+=1
echo     !c! sec...
if !c! geq 30 (
    echo     WARNING: proxy not responding after 30s, continuing anyway...
    goto proxy_ok
)
goto wait_proxy
:proxy_ok
echo     Proxy ready!
for /f "tokens=*" %%A in ('"%PROXY_PY%" "%PROXY_DIR%\get_model_ctx.py" 2>nul') do echo     Model: %%A
echo.

REM Wait for SearXNG
set /a c=0
:wait_searx
timeout /t 1 /nobreak >nul
curl -s -o nul "http://127.0.0.1:8888/search?q=health&format=json"
if %errorlevel% equ 0 goto searx_ok
set /a c+=1
if !c! geq 15 (
    echo     WARNING: SearXNG not responding after 15s
    goto searx_ok
)
goto wait_searx
:searx_ok
echo     SearXNG ready!
echo.

REM Launch Hermes Desktop
set "HERMES_EXE=%HERMES_HOME%\hermes-agent\apps\desktop\release\win-unpacked\Hermes.exe"
if exist "%HERMES_EXE%" (
    start "" "%HERMES_EXE%"
    echo     Hermes Desktop: launching...
) else (
    echo     Hermes Desktop not found, starting CLI instead...
    start "Hermes" cmd /c "hermes"
)
echo.

echo ==============================================
echo  ALL SERVICES RUNNING:
echo  Proxy:     http://127.0.0.1:9224/v1
for /f "tokens=*" %%A in ('"%PROXY_PY%" "%PROXY_DIR%\get_model_ctx.py" 2>nul') do echo  Model:     %%A
echo  SearXNG:   http://127.0.0.1:8888
echo  Vision:    http://127.0.0.1:9225
echo  Ollama:    http://127.0.0.1:11434
echo ==============================================
pause
