@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
REM ============================================================
REM  SearXNG Setup — download + install for Hermes WebStack
REM  Run once after main setup.bat
REM ============================================================

set "WEBSTACK_DIR=C:\AI\Hermes_PROJECTS\webstack"
set "SEARX_DIR=%WEBSTACK_DIR%\searxng-master"
set "SEARX_VENV=%WEBSTACK_DIR%\.venv-searx"

echo =============================================
echo  SearXNG Setup for Hermes WebStack
echo =============================================
echo.

REM Check Python
set "PY=py"
py -3.13 --version >nul 2>&1
if %errorlevel%==0 (
    set "PY=py -3.13"
) else (
    python --version >nul 2>&1
    if %errorlevel%==0 set "PY=python"
)

REM 1. Download SearXNG source
echo [1/3] Downloading SearXNG source...
if exist "%SEARX_DIR%\searx\webapp.py" (
    echo     Already downloaded.
) else (
    echo     Downloading from GitHub...
    cd /d "%WEBSTACK_DIR%"
    curl -sL https://codeload.github.com/searxng/searxng/tar.gz/refs/heads/master -o searxng.tar.gz
    if %errorlevel% neq 0 (
        echo     ERROR: Download failed. Check internet connection.
        pause
        exit /b 1
    )
    echo     Extracting...
    tar xzf searxng.tar.gz
    del searxng.tar.gz
    echo     Done.
)
echo.

REM 2. Create venv and install
echo [2/3] Creating SearXNG venv and installing...
if not exist "%SEARX_VENV%\Scripts\python.exe" (
    %PY% -m venv "%SEARX_VENV%"
)
"%SEARX_VENV%\Scripts\pip" install -r "%SEARX_DIR%\requirements.txt" --quiet 2>nul

REM Apply Windows patch: wrap 'import pwd' in try/except
echo     Applying Windows compatibility patch...
%PY% -c "import pathlib; p=pathlib.Path(r'%SEARX_DIR%\searx\valkeydb.py'); t=p.read_text(encoding='utf-8'); t=t.replace('import pwd', 'try:\n    import pwd\nexcept ImportError:\n    pwd = None'); p.write_text(t, encoding='utf-8')" 2>nul

echo     SearXNG installed.
echo.

REM 3. Copy config
echo [3/3] Applying SearXNG config...
if not exist "%WEBSTACK_DIR%\searx" mkdir "%WEBSTACK_DIR%\searx"
copy /Y "%~dp0..\webstack-config\settings.yml" "%WEBSTACK_DIR%\searx\settings.yml" >nul 2>&1
echo     Config placed at %WEBSTACK_DIR%\searx\settings.yml
echo.

echo =============================================
echo  SearXNG Setup Complete!
echo  Test: start_searx.bat (from %WEBSTACK_DIR%)
echo  Then: http://127.0.0.1:8888/search?q=test^&format=json
echo =============================================
pause
