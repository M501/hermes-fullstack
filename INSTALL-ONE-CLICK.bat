@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul
title Hermes FullStack — Быстрая установка
color 0B

REM ================================================================
REM  HERMES FULLSTACK — ОДИН ФАЙЛ. ОДИН КЛИК. ВСЁ ГОТОВО.
REM
REM  Этот файл — всё что нужно.
REM  Скачайте, дважды кликните, и через 5-10 минут у вас будет
REM  AI-ассистент с голосовым управлением, нейросетями и поиском.
REM
REM  Требования: Windows 10/11, интернет
REM ================================================================

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║                                                          ║
echo  ║         HERMES FULLSTACK — УСТАНОВКА ОДНИМ КЛИКОМ       ║
echo  ║                                                          ║
echo  ║   AI-ассистент с голосовым, нейросетями и поиском       ║
echo  ║   Установка займёт ~5-10 минут                           ║
echo  ║                                                          ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

REM --- Проверяем интернет ---
echo    Проверка подключения к интернету...
curl -s -o nul https://google.com
if %errorlevel% neq 0 (
    echo.
    echo    ОШИБКА: Нет подключения к интернету.
    echo    Подключитесь к интернету и попробуйте снова.
    echo.
    pause
    exit /b 1
)
echo    Интернет есть!
echo.

REM --- Создаём временную папку ---
set "STAGE=%TEMP%\hermes-fullstack"
if exist "%STAGE%" rmdir /s /q "%STAGE%" 2>nul
mkdir "%STAGE%" 2>nul

REM --- Скачиваем полный установщик ---
echo    Скачивание установщика (~50 KB)...
echo.

REM Пробуем GitHub Release (zip)
set "ZIP_URL=https://github.com/M501/hermes-fullstack/archive/refs/heads/main.zip"
set "ZIP_FILE=%STAGE%\fullstack.zip"

curl -L -o "%ZIP_FILE%" "%ZIP_URL%" --progress-bar 2>nul
if %errorlevel% neq 0 (
    echo.
    echo    ОШИБКА: Не удалось скачать установщик.
    echo    Проверьте, что у вас есть доступ к github.com
    echo.
    pause
    exit /b 1
)

REM Распаковываем
echo    Распаковка...
powershell -NoProfile -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%STAGE%' -Force" 2>nul
if %errorlevel% neq 0 (
    echo    ОШИБКА: Не удалось распаковать архив.
    pause
    exit /b 1
)

REM Находим распакованную папку
set "SRC="
for /d %%D in ("%STAGE%\hermes-fullstack-*") do set "SRC=%%D"
if "!SRC!"=="" (
    echo    ОШИБКА: Архив повреждён.
    pause
    exit /b 1
)

REM --- Запускаем полный установщик ---
echo.
echo    Запуск установщика...
echo.
call "!SRC!\setup.bat"

REM --- Очистка ---
rmdir /s /q "%STAGE%" 2>nul
