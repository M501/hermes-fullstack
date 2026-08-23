@echo off
chcp 65001 >nul 2>nul
title Hermes FullStack — Установка
color 0B

REM ================================================================
REM  HERMES FULLSTACK — УСТАНОВЩИК
REM
REM  Скачайте этот файл, дважды кликните — и через 10-20 минут
REM  у вас будет AI-ассистент с голосовым, нейросетями и поиском.
REM
REM  Требования: Windows 10/11, интернет
REM  Никаких знаний IT не нужно.
REM ================================================================

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║                                                          ║
echo  ║         HERMES FULLSTACK — УСТАНОВКА ОДНИМ КЛИКОМ       ║
echo  ║                                                          ║
echo  ║   AI-ассистент с голосовым, нейросетями и поиском       ║
echo  ║   Установка займёт ~10-20 минут                          ║
echo  ║                                                          ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

REM --- Проверяем, запущен ли от администратор ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo    Запрос прав администратора...
    echo    (появится окно "Контроль учётных записей" — нажмите "Да")
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

REM --- Находим скрипт установки ---
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%scripts\install-full.ps1" (
    set "PS_SCRIPT=%SCRIPT_DIR%scripts\install-full.ps1"
) else if exist "%SCRIPT_DIR%install-full.ps1" (
    set "PS_SCRIPT=%SCRIPT_DIR%install-full.ps1"
) else (
    REM Скачиваем с GitHub если файл запущен отдельно
    echo    Поиск скрипта установки...
    set "STAGE=%TEMP%\hermes-install"
    if not exist "%STAGE%" mkdir "%STAGE%"
    
    echo    Скачивание установщика с GitHub...
    curl -L -o "%STAGE%\fullstack.zip" "https://github.com/M501/hermes-fullstack/archive/refs/heads/main.zip" --progress-bar 2>nul
    if %errorlevel% neq 0 (
        echo.
        echo    ОШИБКА: Не удалось скачать установщик.
        echo    Проверьте подключение к интернету.
        echo.
        pause
        exit /b 1
    )
    
    echo    Распаковка...
    powershell -NoProfile -Command "Expand-Archive -Path '%STAGE%\fullstack.zip' -DestinationPath '%STAGE%' -Force" 2>nul
    
    set "SRC="
    for /d %%D in ("%STAGE%\hermes-fullstack-*") do set "SRC=%%D"
    if "!SRC!"=="" (
        echo    ОШИБКА: Архив повреждён.
        pause
        exit /b 1
    )
    set "PS_SCRIPT=!SRC!\scripts\install-full.ps1"
)

REM --- Запускаем PowerShell установщик ---
echo.
echo    Запуск установщика...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

REM --- Очистка ---
if exist "%STAGE%" rmdir /s /q "%STAGE%" 2>nul
