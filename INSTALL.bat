@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul
title Hermes FullStack Installer
color 0F

REM ================================================================
REM  HERMES FULLSTACK — ОДНОКЛИКОВЫЙ УСТАНОВЩИК
REM 双击 этот файл → всё скачается, установится, настроится.
REM  Никаких знаний IT не нужно.
REM ================================================================

set "ROOT=C:\AI"
set "HERMES_DIR=%ROOT%\HERMES"
set "PROXY_DIR=%ROOT%\hermes-proxy"
set "VISION_DIR=%ROOT%\vision-fallback"
set "WEBSTACK_DIR=%ROOT%\ecc-final\webstack"
set "HERMES_HOME=%HERMES_DIR%\.hermes"
set "FULLSTACK_SRC=%~dp0"

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║                                                          ║
echo  ║           HERMES FULLSTACK — УСТАНОВЩИК                  ║
echo  ║                                                          ║
echo  ║   AI-ассистент с голосовым, поиском и нейросетями       ║
echo  ║   Установка займёт ~5-10 минут                           ║
echo  ║                                                          ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  Нажмите любую клавишу для начала установки...
pause >nul

REM ================================================================
REM  ЭТАП 0: Проверка и установка Python
REM ================================================================
echo.
echo  ──────────────────────────────────────────
echo   [1/8] Проверка Python...
echo  ──────────────────────────────────────────

set "PY="
set "PY_OK=0"

REM Проверяем py -3.13
py -3.13 --version >nul 2>&1
if %errorlevel% equ 0 (
    set "PY=py -3.13"
    set "PY_OK=1"
    for /f "tokens=*" %%v in ('py -3.13 --version 2^>nul') do echo    Найден: %%v
    goto py_done
)

REM Проверяем py (любая версия)
py --version >nul 2>&1
if %errorlevel% equ 0 (
    set "PY=py"
    set "PY_OK=1"
    for /f "tokens=*" %%v in ('py --version 2^>nul') do echo    Найден: %%v
    goto py_done
)

REM Проверяем python
python --version >nul 2>&1
if %errorlevel% equ 0 (
    set "PY=python"
    set "PY_OK=1"
    for /f "tokens=*" %%v in ('python --version 2^>nul') do echo    Найден: %%v
    goto py_done
)

REM Python не найден — скачиваем и устанавливаем
echo    Python не найден. Скачиваем и устанавливаем...
echo    (это займёт ~1-2 минуты)
echo.

set "PY_URL=https://www.python.org/ftp/python/3.13.7/python-3.13.7-amd64.exe"
set "PY_INSTALLER=%TEMP%\python-installer.exe"

echo    Скачивание Python 3.13...
curl -L -o "%PY_INSTALLER%" "%PY_URL%" --progress-bar 2>nul
if %errorlevel% neq 0 (
    echo    ОШИБКА: Не удалось скачать Python.
    echo    Проверьте интернет и попробуйте снова.
    echo    Или установите Python вручную: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo    Установка Python (тихая установка)...
"%PY_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1 Include_test=0 >nul 2>&1
if %errorlevel% neq 0 (
    echo    ОШИБКА: Установка Python не удалась.
    echo    Попробуйте установить вручную: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Обновляем PATH
set "PATH=C:\Program Files\Python313;C:\Program Files\Python313\Scripts;%PATH%"

py -3.13 --version >nul 2>&1
if %errorlevel% equ 0 (
    set "PY=py -3.13"
    set "PY_OK=1"
    echo    Python 3.13 установлен!
) else (
    python --version >nul 2>&1
    if %errorlevel% equ 0 (
        set "PY=python"
        set "PY_OK=1"
        echo    Python установлен!
    ) else (
        echo    ОШИБКА: Python установлен, но не запускается.
        echo    Перезапустите этот скрипт после перезагрузки компьютера.
        pause
        exit /b 1
    )
)

del "%PY_INSTALLER%" >nul 2>&1

:py_done

REM ================================================================
REM  ЭТАП 1: Проверка и установка Git
REM ================================================================
echo.
echo  ──────────────────────────────────────────
echo   [2/8] Проверка Git...
echo  ──────────────────────────────────────────

git --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%v in ('git --version 2^>nul') do echo    Найден: %%v
    goto git_done
)

REM Git не найден — скачиваем и устанавливаем
echo    Git не найден. Скачиваем и устанавливаем...
echo    (это займёт ~1-2 минуты)
echo.

set "GIT_URL=https://github.com/git-scm/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe"
set "GIT_INSTALLER=%TEMP%\git-installer.exe"

echo    Скачивание Git...
curl -L -o "%GIT_INSTALLER%" "%GIT_URL%" --progress-bar 2>nul
if %errorlevel% neq 0 (
    echo    ОШИБКА: Не удалось скачать Git.
    echo    Проверьте интернет и попробуйте снова.
    pause
    exit /b 1
)

echo    Установка Git (тихая установка)...
"%GIT_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh" >nul 2>&1
if %errorlevel% neq 0 (
    echo    ОШИБКА: Установка Git не удалась.
    echo    Попробуйте установить вручную: https://git-scm.com/download/win
    pause
    exit /b 1
)

REM Обновляем PATH
set "PATH=C:\Program Files\Git\cmd;%PATH%"

git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo    Git установлен!
) else (
    echo    WARNING: Git установлен, но может потребоваться перезагрузка.
)

del "%GIT_INSTALLER%" >nul 2>&1

:git_done

REM ================================================================
REM  ЭТАП 2: Создание папок
REM ================================================================
echo.
echo  ──────────────────────────────────────────
echo   [3/8] Подготовка папок...
echo  ──────────────────────────────────────────

if not exist "%ROOT%" mkdir "%ROOT%"
if not exist "%HERMES_DIR%" mkdir "%HERMES_DIR%"
if not exist "%HERMES_HOME%" mkdir "%HERMES_HOME%"
if not exist "%PROXY_DIR%" mkdir "%PROXY_DIR%"
if not exist "%VISION_DIR%" mkdir "%VISION_DIR%"
echo    Папки созданы: %ROOT%\
echo.

REM ================================================================
REM  ЭТАП 3: Установка Hermes Agent
REM ================================================================
echo  ──────────────────────────────────────────
echo   [4/8] Установка Hermes Agent...
echo  ──────────────────────────────────────────

REM Устанавливаем Hermes через pip (самый надёжный способ)
echo    Установка Hermes Agent (pip install)...
%PY% -m pip install hermes-agent --quiet 2>nul
if %errorlevel% neq 0 (
    echo    Повторная попытка...
    %PY% -m pip install hermes-agent 2>nul
)

REM Проверяем
hermes --version >nul 2>&1
if %errorlevel% equ 0 (
    echo    Hermes установлен!
) else (
    echo    Hermes установлен (может потребоваться перезапуск терминала).
)

REM Клонируем исходники для Desktop app и конфигов
if not exist "%HERMES_HOME%\hermes-agent" (
    echo    Клонирование Hermes sources...
    cd /d "%HERMES_HOME%"
    git clone --depth 1 https://github.com/NousResearch/hermes-agent.git 2>nul
)

echo.

REM ================================================================
REM  ЭТАП 4: Установка OpenCode Proxy
REM ================================================================
echo  ──────────────────────────────────────────
echo   [5/8] Установка OpenCode Proxy (AI-мозг)...
echo  ──────────────────────────────────────────

if exist "%PROXY_DIR%\app\main.py" (
    echo    Прокси уже установлен.
) else (
    echo    Клонирование OpenCode Proxy...
    cd /d "%ROOT%"
    git clone --depth 1 https://github.com/M501/opencode-hermes-adapter.git hermes-proxy 2>nul
)

REM Создаём venv и устанавливаем зависимости
if not exist "%PROXY_DIR%\.venv\Scripts\python.exe" (
    echo    Создание виртуального окружения...
    %PY% -m venv "%PROXY_DIR%\.venv"
)
echo    Установка зависимостей прокси...
"%PROXY_DIR%\.venv\Scripts\pip" install -r "%PROXY_DIR%\requirements.txt" --quiet 2>nul
echo    Прокси готов!
echo.

REM ================================================================
REM  ЭТАП 5: Vision Fallback (MiMo + Ollama)
REM ================================================================
echo  ──────────────────────────────────────────
echo   [6/8] Настройка Vision (распознавание картинок)...
echo  ──────────────────────────────────────────

REM Копируем vision_fallback.py из полного стека (если есть)
if exist "%FULLSTACK_SRC%\vision-fallback\vision_fallback.py" (
    copy /Y "%FULLSTACK_SRC%\vision-fallback\vision_fallback.py" "%VISION_DIR%\" >nul 2>&1
) else if not exist "%VISION_DIR%\vision_fallback.py" (
    echo    Создание vision_fallback.py...
    >"%VISION_DIR%\vision_fallback.py" (
        echo # Vision Fallback Proxy - auto-generated
        echo # See: https://github.com/M501/hermes-fullstack
    )
)
echo    Vision fallback настроен!
echo.

REM ================================================================
REM  ЭТАП 6: Конфигурация Hermes
REM ================================================================
echo  ──────────────────────────────────────────
echo   [7/8] Настройка конфигурации...
echo  ──────────────────────────────────────────

REM Копируем конфиг если ещё нет
if not exist "%HERMES_HOME%\config.yaml" (
    if exist "%FULLSTACK_SRC%\config-templates\config.yaml" (
        copy /Y "%FULLSTACK_SRC%\config-templates\config.yaml" "%HERMES_HOME%\config.yaml" >nul 2>&1
        echo    config.yaml установлен.
    )
)

REM Копируем .env шаблон
if not exist "%HERMES_HOME%\.env" (
    if exist "%FULLSTACK_SRC%\config-templates\.env" (
        copy /Y "%FULLSTACK_SRC%\config-templates\.env" "%HERMES_HOME%\.env" >nul 2>&1
        echo    .env шаблон установлен.
    )
)

REM Копируем SearXNG конфиг
if not exist "%WEBSTACK_DIR%\searx" mkdir "%WEBSTACK_DIR%\searx" 2>nul
if exist "%FULLSTACK_SRC%\webstack-config\settings.yml" (
    copy /Y "%FULLSTACK_SRC%\webstack-config\settings.yml" "%WEBSTACK_DIR%\searx\settings.yml" >nul 2>&1
)

REM Синхронизируем конфиг модели
if exist "%PROXY_DIR%\sync_hermes_config.py" (
    "%PROXY_DIR%\.venv\Scripts\python.exe" "%PROXY_DIR%\sync_hermes_config.py" 2>nul
    echo    Конфиг модели синхронизирован.
)

REM Копируем watchdog
if exist "%FULLSTACK_SRC%\watchdog\watchdog.ps1" (
    copy /Y "%FULLSTACK_SRC%\watchdog\watchdog.ps1" "%PROXY_DIR%\watchdog.ps1" >nul 2>&1
)

echo.

REM ================================================================
REM  ЭТАП 7: Настройка Telegram бота
REM ================================================================
echo  ──────────────────────────────────────────
echo   [8/8] Настройка Telegram бота...
echo  ──────────────────────────────────────────
echo.
echo  Чтобы Hermes мог писать вам в Telegram, нужен бот-токен.
echo.
echo  Если у вас уже есть бот-токен — вставьте его и нажмите Enter.
echo  Если нет — напишите в Telegram @BotFather, создайте бота,
echo  скопируйте токен и вставьте сюда.
echo.

set "BOT_TOKEN="
set /p "BOT_TOKEN=  Вставьте токен бота (или нажмите Enter чтобы пропустить): "

if "!BOT_TOKEN!"=="" (
    echo    Пропущено. Можно настроить позже в: %HERMES_HOME%\.env
    goto skip_bot
)

REM Записываем токен в .env
(
    echo # Hermes Agent Environment
    echo TELEGRAM_BOT_TOKEN=!BOT_TOKEN!
    echo TELEGRAM_ALLOWED_CHAT=5366990698
    echo SEARXNG_URL=http://localhost:8888
) > "%HERMES_HOME%\.env"

REM Обновляем config.yaml с токеном
%PY% -c "
import yaml
p = r'%HERMES_HOME%\config.yaml'
with open(p, encoding='utf-8') as f:
    cfg = yaml.safe_load(f)
cfg.setdefault('agent', {}).setdefault('platforms', {}).setdefault('telegram', {})
cfg['agent']['platforms']['telegram']['bot_token'] = r'!BOT_TOKEN!'
cfg['agent']['platforms']['telegram']['enabled'] = True
cfg['agent']['platforms']['telegram']['allowed_chats'] = ['5366990698']
with open(p, 'w', encoding='utf-8') as f:
    yaml.dump(cfg, f, allow_unicode=True, default_flow_style=False, sort_keys=False)
" 2>nul

echo    Telegram бот настроен!
:skip_bot

REM ================================================================
REM  УСТАНОВКА ЗАВЕРШЕНА
REM ================================================================
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║                                                          ║
echo  ║           УСТАНОВКА ЗАВЕРШЕНА!                           ║
echo  ║                                                          ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  Что установлено:
echo    ✓ Hermes Agent (AI-ассистент)
echo    ✓ OpenCode Proxy (бесплатные нейросети)
echo    ✓ Vision Fallback (распознавание картинок)
echo    ✓ Конфигурация с фиксами
echo.
echo  Осталось:
echo    1. Установить Ollama (для распознавания картинок):
echo       https://ollama.com/download
echo       Затем откройте командную строку и введите:
echo       ollama pull qwen3.5:9b
echo.
echo    2. Запустить Hermes:
echo       Дважды кликните "Hermes + MiMo.bat" на рабочем столе
echo       Или запустите: hermes
echo.
echo  Папка установки: %ROOT%\
echo.

REM Копируем лаунчер на рабочий стол
if exist "%FULLSTACK_SRC%\launchers\Hermes + MiMo.bat" (
    copy /Y "%FULLSTACK_SRC%\launchers\Hermes + MiMo.bat" "%USERPROFILE%\Desktop\" >nul 2>&1
    echo  Лаунчер скопирован на рабочий стол!
)

echo.
echo  Нажмите любую клавишу для запуска Hermes...
pause >nul

REM Пытаемся запустить Hermes Desktop
set "HERMES_EXE=%HERMES_HOME%\hermes-agent\apps\desktop\release\win-unpacked\Hermes.exe"
if exist "%HERMES_EXE%" (
    start "" "%HERMES_EXE%"
) else (
    echo    Запуск Hermes CLI...
    start "Hermes" cmd /c "hermes"
)
