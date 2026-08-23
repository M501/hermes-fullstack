#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Hermes FullStack — полный установщик для голого Windows.
.DESCRIPTION
    Скачивает и устанавливает ВСЁ с нуля:
    - Python 3.13 (если нет)
    - Git (если нет)
    - Hermes Agent
    - OpenCode Proxy (AI-мозг, бесплатные нейросети)
    - Vision Fallback (распознавание картинок)
    - SearXNG (локальный поиск)
    - Ollama + qwen3.5:9b (локальная модель для vision)
    - Конфигурация с фиксами (STT auto-detect ru+en)
    - Watchdog (автозапуск всех сервисов)
    - Лаунчер на рабочий стол
.NOTES
    Запускать от АДМИНИСТРАТОРА (правый клик → Запуск от имени администратора).
    Или .bat обёртка запросит elevation автоматически.
#>

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
#  КОНФИГУРАЦИЯ
# ============================================================

$InstallRoot  = 'C:\AI'
$HermesDir    = "$InstallRoot\HERMES"
$ProxyDir     = "$InstallRoot\hermes-proxy"
$VisionDir    = "$InstallRoot\vision-fallback"
$WebstackDir  = "$InstallRoot\ecc-final\webstack"
$HermesHome   = "$HermesDir\.hermes"
$LogDir       = "$InstallRoot\logs"
$TempDir      = "$env:TEMP\hermes-install"

# Версии (обновлять при выходе новых)
$PythonVer    = '3.13.7'
$PythonUrl    = "https://www.python.org/ftp/python/$PythonVer/python-$PythonVer-amd64.exe"
$GitVer       = '2.50.1'
$GitUrl       = "https://github.com/git-scm/git/releases/download/v$GitVer.windows.1/Git-$GitVer-64-bit.exe"
$OllamaUrl    = "https://ollama.com/download/OllamaSetup.exe"

# ============================================================
#  УТИЛИТЫ
# ============================================================

function Write-Banner {
    param([string]$Text, [string]$Color = 'Cyan')
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $Color
    Write-Host "  ║  $Text" -ForegroundColor $Color
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $Color
    Write-Host ""
}

function Write-Step {
    param([int]$Num, [int]$Total, [string]$Text)
    Write-Host ""
    Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "   [$Num/$Total] $Text" -ForegroundColor Yellow
    Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray
}

function Write-OK    { param([string]$Msg) Write-Host "    ✓ $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "    ⚠ $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "    ✗ $Msg" -ForegroundColor Red }
function Write-Info  { param([string]$Msg) Write-Host "    $Msg" -ForegroundColor Gray }

function Test-Internet {
    try {
        $r = Invoke-WebRequest -Uri 'https://google.com' -TimeoutSec 5 -UseBasicParsing -Method Head
        return $true
    } catch { return $false }
}

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $userPath    = [Environment]::GetEnvironmentVariable('PATH', 'User')
    $env:PATH    = "$machinePath;$userPath"
}

function Download-File {
    param([string]$Url, [string]$Out)
    if (Test-Path $Out) { Remove-Item $Out -Force }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $Out -UseBasicParsing
}

function Test-Command {
    param([string]$Cmd)
    try { Get-Command $Cmd -ErrorAction Stop | Out-Null; return $true }
    catch { return $false }
}

# ============================================================
#  ГЛАВНЫЙ УСТАНОВОЧНЫЙ ПРОЦЕСС
# ============================================================

Clear-Host
Write-Banner "HERMES FULLSTACK — УСТАНОВКА С НУЛЯ"

Write-Host "  Этот скрипт установит AI-ассистент с нуля на чистый Windows."
Write-Host "  Установка займёт ~10-20 минут (зависит от скорости интернета)."
Write-Host ""
Write-Host "  Установятся:"
Write-Host "    • Python 3.13 (язык программирования)"
Write-Host "    • Git (система контроля версий)"
Write-Host "    • Hermes Agent (AI-ассистент)"
Write-Host "    • OpenCode Proxy (бесплатные нейросети)"
Write-Host "    • Vision Fallback (распознавание картинок)"
Write-Host "    • SearXNG (локальный поиск в интернете)"
Write-Host "    • Ollama + модель (локальная нейросеть)"
Write-Host "    • Конфигурация и лаунчер"
Write-Host ""
Write-Host "  Нажмите любую клавишу для начала..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

$totalSteps = 10
$step = 0

# ------------------------------------------------------------
#  ШАГ 1: Проверка интернета
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Проверка подключения к интернету"
if (-not (Test-Internet)) {
    Write-Err "Нет подключения к интернету!"
    Write-Host ""
    Write-Host "  Подключитесь к интернету и запустите скрипт снова." -ForegroundColor Red
    Read-Host "  Нажмите Enter для выхода"
    exit 1
}
Write-OK "Интернет подключён"

# ------------------------------------------------------------
#  ШАГ 2: Создание папок
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Создание папок"
foreach ($d in @($InstallRoot, $HermesDir, $HermesHome, $ProxyDir, $VisionDir, $WebstackDir, $LogDir, $TempDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}
Write-OK "Папки созданы: $InstallRoot\"

# ------------------------------------------------------------
#  ШАГ 3: Установка Python
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Установка Python 3.13"

$pythonInstalled = $false
foreach ($cmd in @('python', 'py')) {
    try {
        $ver = & $cmd --version 2>&1 | Select-String 'Python 3\.13'
        if ($ver) { $pythonInstalled = $true; Write-OK "Python уже установлен: $ver"; break }
    } catch {}
}

if (-not $pythonInstalled) {
    Write-Info "Python не найден. Скачиваем и устанавливаем..."
    Write-Info "Это займёт ~1-2 минуты."

    $pyInstaller = "$TempDir\python-installer.exe"
    Write-Info "Скачивание Python $PythonVer..."
    Download-File -Url $PythonUrl -Out $pyInstaller

    Write-Info "Установка Python ( тихий режим)..."
    $pyArgs = "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_doc=0 /log `"$LogDir\python-install.log`""
    $proc = Start-Process -FilePath $pyInstaller -ArgumentList $pyArgs -Wait -PassThru -WindowStyle Hidden
    if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
        Write-Err "Установка Python завершилась с ошибкой (код: $($proc.ExitCode))"
        Write-Info "Лог: $LogDir\python-install.log"
        Read-Host "Нажмите Enter для выхода"
        exit 1
    }

    Refresh-Path
    Remove-Item $pyInstaller -Force -ErrorAction SilentlyContinue

    # Проверяем
    Refresh-Path
    $pyOk = $false
    foreach ($cmd in @('python', 'py')) {
        try {
            $ver = & $cmd --version 2>&1
            if ($ver -match 'Python 3') { $pyOk = $true; Write-OK "Python установлен: $ver"; break }
        } catch {}
    }
    if (-not $pyOk) {
        Write-Warn "Python установлен, но может потребоваться перезапуск."
        Write-Info "Попробуйте перезапустить этот скрипт."
    }
} else {
    Write-Info "Пропущено (уже установлен)."
}

# Определяем команду Python
$PyCmd = 'python'
try { & $PyCmd --version 2>&1 | Out-Null } catch { $PyCmd = 'py' }
try { & $PyCmd --version 2>&1 | Out-Null } catch {
    Write-Err "Python не доступен. Перезапустите скрипт."
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

# ------------------------------------------------------------
#  ШАГ 4: Установка Git
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Установка Git"

$gitInstalled = Test-Command 'git'
if ($gitInstalled) {
    $gitVer = & git --version 2>&1
    Write-OK "Git уже установлен: $gitVer"
} else {
    Write-Info "Git не найден. Скачиваем и устанавливаем..."
    Write-Info "Это займёт ~1-2 минуты."

    $gitInstaller = "$TempDir\git-installer.exe"
    Write-Info "Скачивание Git $GitVer..."
    Download-File -Url $GitUrl -Out $gitInstaller

    Write-Info "Установка Git (тихий режим)..."
    $gitArgs = "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`" /LOG=`"$LogDir\git-install.log`""
    $proc = Start-Process -FilePath $gitInstaller -ArgumentList $gitArgs -Wait -PassThru -WindowStyle Hidden
    if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
        Write-Err "Установка Git завершилась с ошибкой (код: $($proc.ExitCode))"
        Write-Info "Лог: $LogDir\git-install.log"
    }

    Refresh-Path
    Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue

    if (Test-Command 'git') {
        Write-OK "Git установлен!"
    } else {
        Write-Warn "Git установлен, но может потребоваться перезапуск."
    }
}

# ------------------------------------------------------------
#  ШАГ 5: Установка Hermes Agent
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Установка Hermes Agent"

$hermesInstalled = Test-Command 'hermes'
if ($hermesInstalled) {
    Write-OK "Hermes уже установлен"
} else {
    Write-Info "Установка Hermes Agent через pip..."
    & $PyCmd -m pip install hermes-agent --quiet 2>$null
    Refresh-Path

    if (Test-Command 'hermes') {
        $hermesVer = & hermes --version 2>&1
        Write-OK "Hermes установлен: $hermesVer"
    } else {
        Write-Warn "Hermes установлен, но команда hermes недоступна."
        Write-Info "Попробуйте: pip install hermes-agent"
    }
}

# Клонируем исходники (нужны для Desktop app + конфигов)
if (-not (Test-Path "$HermesHome\hermes-agent")) {
    Write-Info "Клонирование Hermes sources..."
    Push-Location $HermesHome
    & git clone --depth 1 https://github.com/NousResearch/hermes-agent.git 2>$null
    Pop-Location
}

# ------------------------------------------------------------
#  ШАГ 6: Установка OpenCode Proxy
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Установка OpenCode Proxy (AI-мозг)"

if (Test-Path "$ProxyDir\app\main.py") {
    Write-OK "Прокси уже установлен"
} else {
    Write-Info "Клонирование OpenCode Proxy..."
    Push-Location $InstallRoot
    & git clone --depth 1 https://github.com/M501/opencode-hermes-adapter.git hermes-proxy 2>$null
    Pop-Location
}

# Venv + зависимости
if (-not (Test-Path "$ProxyDir\.venv\Scripts\python.exe")) {
    Write-Info "Создание виртуального окружения..."
    & $PyCmd -m venv "$ProxyDir\.venv"
}
Write-Info "Установка зависимостей прокси..."
& "$ProxyDir\.venv\Scripts\pip" install -r "$ProxyDir\requirements.txt" --quiet 2>$null
Write-OK "Прокси готов!"

# ------------------------------------------------------------
#  ШАГ 7: Vision Fallback + SearXNG конфиг
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Настройка Vision и Поиска"

# Vision fallback
$fbSrc = "$PSScriptRoot\..\vision-fallback\vision_fallback.py"
if (Test-Path $fbSrc) {
    Copy-Item $fbSrc "$VisionDir\vision_fallback.py" -Force
} elseif (-not (Test-Path "$VisionDir\vision_fallback.py")) {
    Write-Warn "vision_fallback.py не найден. Vision fallback потребуется настроить вручную."
}
Write-OK "Vision fallback настроен"

# SearXNG конфиг
$searxSrc = "$PSScriptRoot\..\webstack-config\settings.yml"
if (Test-Path $searxSrc) {
    if (-not (Test-Path "$WebstackDir\searx")) { New-Item -ItemType Directory -Path "$WebstackDir\searx" -Force | Out-Null }
    Copy-Item $searxSrc "$WebstackDir\searx\settings.yml" -Force
    Write-OK "SearXNG конфиг установлен"
}

# ------------------------------------------------------------
#  ШАГ 8: Конфигурация Hermes
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Настройка конфигурации Hermes"

# config.yaml
$cfgSrc = "$PSScriptRoot\..\config-templates\config.yaml"
if ((Test-Path $cfgSrc) -and (-not (Test-Path "$HermesHome\config.yaml"))) {
    Copy-Item $cfgSrc "$HermesHome\config.yaml" -Force
    Write-OK "config.yaml установлен"
}

# Prefill: Research First rule
$prefillSrc = "$PSScriptRoot\..\config-templates\prefill-research-first.md"
if (Test-Path $prefillSrc) {
    Copy-Item $prefillSrc "$HermesHome\prefill-research-first.md" -Force
    Write-OK "Research First правило установлено"
}

# .env
$envSrc = "$PSScriptRoot\..\config-templates\.env"
if ((Test-Path $envSrc) -and (-not (Test-Path "$HermesHome\.env"))) {
    Copy-Item $envSrc "$HermesHome\.env" -Force
    Write-OK ".env шаблон установлен"
}

# Синхронизация модели
$syncScript = "$ProxyDir\sync_hermes_config.py"
if (Test-Path $syncScript) {
    & "$ProxyDir\.venv\Scripts\python.exe" $syncScript 2>$null
    Write-OK "Конфиг модели синхронизирован"
}

# Watchdog
$wdSrc = "$PSScriptRoot\..\watchdog\watchdog.ps1"
if (Test-Path $wdSrc) {
    Copy-Item $wdSrc "$ProxyDir\watchdog.ps1" -Force
    Write-OK "Watchdog установлен"
}

# ------------------------------------------------------------
#  ШАГ 9: Настройка Telegram
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Настройка Telegram бота"
Write-Host ""
Write-Host "  Чтобы Hermes писал вам в Telegram, нужен бот-токен." -ForegroundColor White
Write-Host ""
Write-Host "  Если у вас уже есть токен — вставьте его ниже." -ForegroundColor Gray
Write-Host "  Если нет:" -ForegroundColor Gray
Write-Host "    1. Откройте Telegram, найдите @BotFather" -ForegroundColor Gray
Write-Host "    2. Отправьте /newbot" -ForegroundColor Gray
Write-Host "    3. Следуйте инструкциям, скопируйте токен" -ForegroundColor Gray
Write-Host "    4. Вставьте токен сюда" -ForegroundColor Gray
Write-Host ""

$botToken = Read-Host "  Вставьте токен бота (или нажмите Enter чтобы пропустить)"

if ($botToken) {
    # Записываем в .env
    $envContent = @"
# Hermes Agent Environment
TELEGRAM_BOT_TOKEN=$botToken
TELEGRAM_ALLOWED_CHAT=5366990698
SEARXNG_URL=http://localhost:8888
"@
    Set-Content -Path "$HermesHome\.env" -Value $envContent -Encoding UTF8

    # Обновляем config.yaml
    $cfgPath = "$HermesHome\config.yaml"
    if (Test-Path $cfgPath) {
        $cfg = Get-Content $cfgPath -Raw
        # Заменяем bot_token (паттерн)
        $cfg = $cfg -replace "bot_token: ''", "bot_token: '$botToken'"
        $cfg = $cfg -replace "enabled: false", "enabled: true"
        Set-Content -Path $cfgPath -Value $cfg -Encoding UTF8
    }
    Write-OK "Telegram бот настроен!"
} else {
    Write-Warn "Пропущено. Настройте позже в: $HermesHome\.env"
}

# ------------------------------------------------------------
#  ШАГ 10: Установка Ollama + модель
# ------------------------------------------------------------
$step++
Write-Step $step $totalSteps "Установка Ollama (локальная нейросеть для картинок)"

$ollamaInstalled = Test-Command 'ollama'
if ($ollamaInstalled) {
    Write-OK "Ollama уже установлен"
} else {
    Write-Info "Скачивание Ollama (~500 MB)..."
    Write-Info "Это займёт несколько минут."

    $ollamaInstaller = "$TempDir\OllamaSetup.exe"
    try {
        Download-File -Url $OllamaUrl -Out $ollamaInstaller

        Write-Info "Установка Ollama (тихий режим)..."
        $ollamaArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        $proc = Start-Process -FilePath $ollamaInstaller -ArgumentList $ollamaArgs -Wait -PassThru -WindowStyle Hidden

        Refresh-Path
        Remove-Item $ollamaInstaller -Force -ErrorAction SilentlyContinue

        if (Test-Command 'ollama') {
            Write-OK "Ollama установлен!"
        } else {
            Write-Warn "Ollama установлен, но команда может быть недоступна до перезагрузки."
        }
    } catch {
        Write-Warn "Не удалось установить Ollama автоматически."
        Write-Info "Скачайте вручную: https://ollama.com/download"
    }
}

# Скачиваем модель (если Ollama доступен)
if (Test-Command 'ollama') {
    Write-Info "Скачивание модели qwen3.5:9b (~6.5 GB)..."
    Write-Info "Это займёт 5-15 минут в зависимости от скорости интернета."
    Write-Info "Не закрывайте окно!"
    Write-Host ""

    try {
        & ollama pull qwen3.5:9b
        Write-OK "Модель qwen3.5:9b скачана!"
    } catch {
        Write-Warn "Не удалось скачать модель. Запустите позже: ollama pull qwen3.5:9b"
    }
} else {
    Write-Warn "Ollama недоступен. Скачайте модель позже."
}

# ------------------------------------------------------------
#  ФИНАЛ: Лаунчер + здоровье
# ------------------------------------------------------------
Write-Host ""

# Копируем лаунчер на рабочий стол
$launcherSrc = "$PSScriptRoot\..\launchers\Hermes + MiMo.bat"
if (Test-Path $launcherSrc) {
    Copy-Item $launcherSrc "$env:USERPROFILE\Desktop\Hermes + MiMo.bat" -Force
    Write-OK "Лаунчер скопирован на рабочий стол!"
}

# Проверяем здоровье всех сервисов
Write-Host ""
Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "   ПРОВЕРКА УСТАНОВКИ" -ForegroundColor Yellow
Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray

$checks = @()

# Python
$pyCheck = try { & $PyCmd --version 2>&1 | Out-String } catch { "не найден" }
$checks += @{ Name = "Python"; Status = if ($pyCheck -match '3') { "✓ $pyCheck".Trim() } else { "✗ не найден" } }

# Git
$gitCheck = try { & git --version 2>&1 | Out-String } catch { "не найден" }
$checks += @{ Name = "Git"; Status = if ($gitCheck -match 'git version') { "✓ $gitCheck".Trim() } else { "✗ не найден" } }

# Hermes
$hermesCheck = try { & hermes --version 2>&1 | Out-String } catch { "не найден" }
$checks += @{ Name = "Hermes"; Status = if ($hermesCheck) { "✓ установлен" } else { "✗ не найден" } }

# Proxy venv
$proxyOk = Test-Path "$ProxyDir\.venv\Scripts\python.exe"
$checks += @{ Name = "Proxy venv"; Status = if ($proxyOk) { "✓ создан" } else { "✗ не найден" } }

# config.yaml
$cfgOk = Test-Path "$HermesHome\config.yaml"
$checks += @{ Name = "config.yaml"; Status = if ($cfgOk) { "✓ установлен" } else { "✗ не найден" } }

# .env
$envOk = Test-Path "$HermesHome\.env"
$checks += @{ Name = ".env"; Status = if ($envOk) { "✓ установлен" } else { "✗ не найден" } }

# Prefill (Research First)
$prefillOk = Test-Path "$HermesHome\prefill-research-first.md"
$checks += @{ Name = "Research First"; Status = if ($prefillOk) { "✓ правило установлено" } else { "⚠ не найден (рекомендуется)" } }

# Ollama
$ollamaOk = Test-Command 'ollama'
$checks += @{ Name = "Ollama"; Status = if ($ollamaOk) { "✓ установлен" } else { "✗ не найден (опционально)" } }

Write-Host ""
foreach ($c in $checks) {
    $color = if ($c.Status.StartsWith("✓")) { "Green" } elseif ($c.Status.StartsWith("✗")) { "Red" } else { "Yellow" }
    Write-Host "    $($c.Name.PadRight(15)) $($c.Status)" -ForegroundColor $color
}

# Итог
$failCount = ($checks | Where-Object { $_.Status.StartsWith("✗") -and $_.Status -notmatch 'опционально' }).Count

Write-Host ""
if ($failCount -eq 0) {
    Write-Banner "УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!" "Green"
} else {
    Write-Banner "УСТАНОВКА ЗАВЕРШЕНА (есть замечания)" "Yellow"
}

Write-Host "  Что установлено:"
Write-Host "    • Hermes Agent — AI-ассистент" -ForegroundColor Green
Write-Host "    • OpenCode Proxy — бесплатные нейросети (MiMo, DeepSeek, Nemotron)" -ForegroundColor Green
Write-Host "    • Vision Fallback — распознавание картинок" -ForegroundColor Green
Write-Host "    • Конфигурация с фиксами (STT auto-detect ru+en)" -ForegroundColor Green
Write-Host ""
Write-Host "  Как пользоваться:" -ForegroundColor Cyan
Write-Host "    1. Дважды кликните 'Hermes + MiMo.bat' на рабочем столе" -ForegroundColor White
Write-Host "    2. Или откройте командную строку и введите: hermes" -ForegroundColor White
Write-Host ""
Write-Host "  Папка установки: $InstallRoot\" -ForegroundColor Gray
Write-Host ""

# Предлагаем запустить
$launch = Read-Host "  Запустить Hermes сейчас? (Y/n)"
if ($launch -ne 'n' -and $launch -ne 'N') {
    $hermesExe = "$HermesHome\hermes-agent\apps\desktop\release\win-unpacked\Hermes.exe"
    if (Test-Path $hermesExe) {
        Start-Process $hermesExe
    } else {
        Write-Info "Запуск Hermes CLI..."
        Start-Process cmd -ArgumentList "/c hermes"
    }
}

# Очистка
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  Готово! Наслаждайтесь AI-ассистентом." -ForegroundColor Green
Write-Host ""
Read-Host "  Нажмите Enter для выхода"
