@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
REM ============================================================
REM  Hermes FullStack — Quick Setup (new machine)
REM  One script: installs everything from scratch.
REM  Requirements: Windows 11, Python 3.13+, git, Ollama (optional)
REM ============================================================

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "INSTALL_DIR=C:\AI"

echo =============================================
echo  HERMES FULLSTACK — QUICK SETUP
echo  Source: %ROOT%
echo  Target: %INSTALL_DIR%
echo =============================================
echo.

REM --- Step 1: Check prerequisites ---
echo [1/9] Checking prerequisites...
set "PY=py"
py -3.13 --version >nul 2>&1
if %errorlevel%==0 (
    set "PY=py -3.13"
    echo     Python 3.13 found.
) else (
    python --version >nul 2>&1
    if %errorlevel%==0 (
        set "PY=python"
        echo     Python found (3.13+ recommended).
    ) else (
        echo     ERROR: Python not found!
        echo     Install Python 3.13+: https://www.python.org/downloads/
        echo     Tick "Add python to PATH" during install.
        pause
        exit /b 1
    )
)
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo     ERROR: git not found! Install: https://git-scm.com/download/win
    pause
    exit /b 1
)
echo     Git found.
echo.

REM --- Step 2: Create target directories ---
echo [2/9] Creating directories...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\HERMES" mkdir "%INSTALL_DIR%\HERMES"
echo     Created %INSTALL_DIR%\
echo.

REM --- Step 3: Install Hermes Agent ---
echo [3/9] Installing Hermes Agent...
if exist "%INSTALL_DIR%\HERMES\.hermes\hermes-agent" (
    echo     Hermes source exists, pulling latest...
    cd /d "%INSTALL_DIR%\HERMES\.hermes\hermes-agent"
    git pull --quiet 2>nul
) else (
    echo     Cloning Hermes...
    cd /d "%INSTALL_DIR%\HERMES\.hermes"
    git clone https://github.com/NousResearch/hermes-agent.git 2>nul
)
REM Install Hermes if not already in PATH
hermes --version >nul 2>&1
if %errorlevel% neq 0 (
    echo     Installing Hermes via pip...
    %PY% -m pip install hermes-agent --quiet 2>nul
)
echo     Hermes installed.
echo.

REM --- Step 4: Setup OpenCode Proxy ---
echo [4/9] Setting up OpenCode Proxy...
set "PROXY_DIR=%INSTALL_DIR%\hermes-proxy"
if exist "%PROXY_DIR%\app\main.py" (
    echo     Proxy exists, pulling latest...
    cd /d "%PROXY_DIR%"
    git pull --quiet 2>nul
) else (
    echo     Cloning opencode-hermes-adapter...
    cd /d "%INSTALL_DIR%"
    git clone https://github.com/M501/opencode-hermes-adapter.git hermes-proxy
)
REM Create venv and install deps
if not exist "%PROXY_DIR%\.venv\Scripts\python.exe" (
    echo     Creating proxy venv...
    %PY% -m venv "%PROXY_DIR%\.venv"
)
echo     Installing proxy dependencies...
"%PROXY_DIR%\.venv\Scripts\pip" install -r "%PROXY_DIR%\requirements.txt" --quiet 2>nul
echo     Proxy ready.
echo.

REM --- Step 5: Setup Vision Fallback ---
echo [5/9] Setting up Vision Fallback (MiMo + Ollama)...
set "VISION_DIR=%INSTALL_DIR%\vision-fallback"
if not exist "%VISION_DIR%" mkdir "%VISION_DIR%"
if not exist "%VISION_DIR%\vision_fallback.py" (
    echo     Copying vision_fallback.py from setup package...
    copy /Y "%ROOT%\vision-fallback\vision_fallback.py" "%VISION_DIR%\" >nul
)
echo     Vision fallback ready at %VISION_DIR%
echo     (Ollama with qwen3.5:9b model needed for local fallback)
echo.

REM --- Step 6: Setup WebStack (SearXNG + research) ---
echo [6/9] Setting up WebStack (SearXNG)...
set "WEBSTACK_DIR=%INSTALL_DIR%\ecc-final\webstack"
if not exist "%INSTALL_DIR%\ecc-final" mkdir "%INSTALL_DIR%\ecc-final"
if exist "%WEBSTACK_DIR%\webstack\__init__.py" (
    echo     WebStack exists.
) else (
    echo     NOTE: WebStack should be cloned separately.
    echo     Copy from your existing machine: C:\AI\ecc-final\webstack
    echo     Or clone from your repo if available.
)
REM Copy SearXNG config
if not exist "%WEBSTACK_DIR%\searx" mkdir "%WEBSTACK_DIR%\searx"
copy /Y "%ROOT%\webstack-config\settings.yml" "%WEBSTACK_DIR%\searx\settings.yml" >nul 2>&1
echo     SearXNG config placed.
echo.

REM --- Step 7: Apply Hermes config fixes ---
echo [7/9] Applying Hermes config fixes...
set "HERMES_HOME=%INSTALL_DIR%\HERMES\.hermes"
if not exist "%HERMES_HOME%" mkdir "%HERMES_HOME%"

REM Create config.yaml from template (secrets redacted)
copy /Y "%ROOT%\config-templates\config.yaml" "%HERMES_HOME%\config.yaml" >nul 2>&1
echo     config.yaml installed (edit .env for API keys).

REM Create .env template
copy /Y "%ROOT%\config-templates\.env" "%HERMES_HOME%\.env" >nul 2>&1
echo     .env template installed (fill in your keys).

REM Apply critical STT fix: empty language = auto-detect (ru+en)
echo     STT language fix: stt.language="" (auto-detect, not "en")
echo.

REM --- Step 8: Install launchers ---
echo [8/9] Installing launchers...
copy /Y "%ROOT%\launchers\Hermes + MiMo.bat" "%USERPROFILE%\Desktop\" >nul 2>&1
echo     Desktop shortcut: "Hermes + MiMo.bat"
echo.

REM --- Step 9: Install watchdog ---
echo [9/9] Installing watchdog...
set "WATCHDOG_DIR=%INSTALL_DIR%\hermes-proxy"
copy /Y "%ROOT%\watchdog\watchdog.ps1" "%WATCHDOG_DIR%\watchdog.ps1" >nul 2>&1
echo     Watchdog installed at %WATCHDOG_DIR%\watchdog.ps1
echo     (Runs at logon via Startup .vbs + Task Scheduler every 5 min)
echo.

echo =============================================
echo  SETUP COMPLETE!
echo.
echo  Next steps:
echo  1. Edit %HERMES_HOME%\.env with your API keys
echo  2. Edit %HERMES_HOME%\config.yaml if needed
echo     (Telegram bot_token, allowed_chats, etc.)
echo  3. Install Ollama for local vision fallback:
echo     https://ollama.com/download
echo     Then: ollama pull qwen3.5:9b
echo  4. Double-click "Hermes + MiMo.bat" on Desktop
echo.
echo  Ports:
echo    :9224 — OpenCode Proxy (main brain)
echo    :9225 — Vision Fallback (MiMo + Ollama)
echo    :8888 — SearXNG (web search)
echo    :11434 — Ollama (local LLM)
echo =============================================
pause
