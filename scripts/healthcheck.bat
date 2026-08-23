@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
REM ============================================================
REM  Hermes FullStack — Health Check
REM  Verifies all services are running correctly.
REM ============================================================

echo =============================================
echo  HERMES FULLSTACK — HEALTH CHECK
echo =============================================
echo.

set "PASS=0"
set "FAIL=0"

REM --- Proxy :9224 ---
echo [1/5] OpenCode Proxy (:9224)...
curl -s -o nul -w "%%{http_code}" http://127.0.0.1:9224/openapi.json >nul 2>&1
if %errorlevel% equ 0 (
    echo     ✓ Running
    set /a PASS+=1
) else (
    echo     ✗ NOT running — start proxy first
    set /a FAIL+=1
)
echo.

REM --- Vision :9225 ---
echo [2/5] Vision Fallback (:9225)...
curl -s -o nul -w "%%{http_code}" http://127.0.0.1:9225/healthz >nul 2>&1
if %errorlevel% equ 0 (
    echo     ✓ Running
    set /a PASS+=1
) else (
    echo     ✗ NOT running
    set /a FAIL+=1
)
echo.

REM --- SearXNG :8888 ---
echo [3/5] SearXNG (:8888)...
curl -s -o nul -w "%%{http_code}" "http://127.0.0.1:8888/search?q=test&format=json" >nul 2>&1
if %errorlevel% equ 0 (
    echo     ✓ Running
    set /a PASS+=1
) else (
    echo     ✗ NOT running — run: scripts\setup-searxng.bat
    set /a FAIL+=1
)
echo.

REM --- Ollama :11434 ---
echo [4/5] Ollama (:11434)...
curl -s -o nul -w "%%{http_code}" http://127.0.0.1:11434/api/tags >nul 2>&1
if %errorlevel% equ 0 (
    echo     ✓ Running
    set /a PASS+=1
) else (
    echo     ✗ NOT running — install Ollama + ollama pull qwen3.5:9b
    set /a FAIL+=1
)
echo.

REM --- Hermes ---
echo [5/5] Hermes Agent...
where hermes >nul 2>&1
if %errorlevel% equ 0 (
    echo     ✓ Installed (hermes in PATH)
    set /a PASS+=1
) else (
    echo     ✗ Not in PATH — install: pip install hermes-agent
    set /a FAIL+=1)
echo.

REM --- Model info ---
echo =============================================
echo  Model: (from proxy)
set "PROXY_PY=C:\AI\hermes-proxy\.venv\Scripts\python.exe"
set "GET_MODEL=C:\AI\hermes-proxy\get_model_ctx.py"
if exist "%PROXY_PY%" (
    for /f "tokens=*" %%A in ('"%PROXY_PY%" "%GET_MODEL%" 2>nul') do echo  %%A
) else (
echo  (proxy not installed yet)
)

echo.
echo  Results: %PASS% passed, %FAIL% failed
if %FAIL%==0 (
    echo  ✓ ALL SERVICES HEALTHY
) else (
    echo  ✗ Some services need attention
)
echo =============================================
pause
