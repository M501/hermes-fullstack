# watchdog.ps1 - Hermes FullStack Supervisor (portable)
# Supervises: Proxy(:9224) + Vision(:9225) + SearXNG(:8888) + Ollama(:11434)
# Auto-start + auto-restart on death. Logs preserved.
# Started: at Windows logon + every 5 min via Task Scheduler.
# Safe to run repeatedly: single-instance guard.
# NOTE: keep this file ASCII-only (Windows PowerShell 5.1 misreads UTF-8-no-BOM).

$ErrorActionPreference = 'SilentlyContinue'

# --- Configurable paths (edit for your machine) ---
$installDir  = 'C:\AI'
$proxyDir    = "$installDir\hermes-proxy"
$visionDir   = "$installDir\vision-fallback"
$webstackDir = "$installDir\ecc-final\webstack"
$python      = "$proxyDir\.venv\Scripts\python.exe"
$ollamaExe   = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"

# --- Ports ---
$port     = 9224
$fbPort   = 9225
$searxPort = 8888
$ollamaPort = 11434

# --- Health check URLs ---
$url       = "http://127.0.0.1:$port/openapi.json"
$fbHealth  = "http://127.0.0.1:$fbPort/healthz"
$searxUrl  = "http://127.0.0.1:$searxPort/search?q=health&format=json"
$ollamaUrl = "http://127.0.0.1:$ollamaPort/api/tags"

# --- Log ---
$logDir   = "$proxyDir\logs"
$watchLog = "$proxyDir\watchdog.log"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

# ---- state ----
$script:lastProxyPid = $null
$script:lastProxyStart = $null
$script:healthFails = 0
$script:fbHealthFails = 0
$script:restartTimes = @()
$script:cbCooldownUntil = $null

function Log($msg) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" | Out-File -FilePath $watchLog -Append -Encoding utf8
}

function Get-ListenerPid([int]$targetPort) {
    $lines = netstat -ano | Select-String ":$targetPort\s+.*LISTENING"
    foreach ($line in $lines) {
        $parts = @($line.Line -split '\s+' | Where-Object { $_ })
        if ($parts.Count -ge 5 -and $parts[4] -match '^\d+$') {
            return [int]$parts[4]
        }
    }
    return $null
}

function Get-ProcInfo([int]$targetPid) {
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$targetPid" -ErrorAction SilentlyContinue
    if (-not $p) { return $null }
    return @{ Pid = $p.ProcessId; StartTime = $p.CreationDate; Cmd = $p.CommandLine }
}

function Test-IsOurProxy($info) {
    if (-not $info) { return $false }
    return ($info.Cmd -like '*uvicorn*app.main:app*')
}

function Test-Healthy {
    try {
        $r = Invoke-WebRequest -Uri $url -TimeoutSec 3 -UseBasicParsing
        return $true
    } catch {
        if ($_.Exception.Response) { return $true }
        return $false
    }
}

function Test-CircuitBreaker {
    if ($script:cbCooldownUntil -and (Get-Date) -lt $script:cbCooldownUntil) {
        return $false
    }
    $window = @($script:restartTimes | Where-Object { (Get-Date) - $_ -lt 300 })
    if ($window.Count -ge 3) {
        $script:cbCooldownUntil = (Get-Date).AddMinutes(5)
        Log "CIRCUIT BREAKER: 3 restarts in 5 min - cooling down 5 min"
        return $false
    }
    return $true
}

function Kill-Process([int]$targetPid, [string]$reason) {
    $info = Get-ProcInfo $targetPid
    $stamp = if ($info) { $info.StartTime } else { 'unknown' }
    Log "KILL pid=$targetPid reason=$reason start=$stamp"
    Stop-Process -Id $targetPid -Force -ErrorAction SilentlyContinue
}

function Start-Proxy {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Log "starting proxy on :$port"
    $p = Start-Process -FilePath $python -ArgumentList '-m','uvicorn','app.main:app','--host','127.0.0.1','--port',"$port" `
        -WorkingDirectory $proxyDir -WindowStyle Hidden `
        -RedirectStandardOutput "$logDir\proxy_$stamp.out.log" `
        -RedirectStandardError  "$logDir\proxy_$stamp.err.log" -PassThru
    Start-Sleep -Seconds 8
    if (Test-Healthy) {
        $info = Get-ProcInfo $p.Id
        $script:lastProxyPid = $p.Id
        $script:lastProxyStart = if ($info) { $info.StartTime } else { $null }
        $script:restartTimes += (Get-Date)
        Log "proxy UP (pid $($p.Id))"
    } else {
        Log "proxy NOT healthy after start (pid $($p.Id))"
    }
}

function Cleanup-StrayProxies {
    $listenerPid = Get-ListenerPid $port
    if ($listenerPid) { return }
    $proxies = Get-CimInstance Win32_Process -Filter "Name='python.exe'" |
        Where-Object { $_.CommandLine -like '*uvicorn*app.main:app*' }
    foreach ($p in $proxies) {
        Kill-Process $p.ProcessId 'stray-uvicorn-no-listener'
    }
}

# ---- Vision fallback ----
function Test-FbHealthy {
    try {
        Invoke-WebRequest -Uri $fbHealth -TimeoutSec 3 -UseBasicParsing | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Start-Fallback {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Log "starting vision fallback on :$fbPort"
    $p = Start-Process -FilePath $python -ArgumentList "$visionDir\vision_fallback.py" `
        -WorkingDirectory $visionDir -WindowStyle Hidden `
        -RedirectStandardOutput "$logDir\fallback_$stamp.out.log" `
        -RedirectStandardError  "$logDir\fallback_$stamp.err.log" -PassThru
    Start-Sleep -Seconds 4
    if (Test-FbHealthy) {
        Log "vision fallback UP (pid $($p.Id))"
    } else {
        Log "vision fallback NOT healthy after start (pid $($p.Id))"
    }
}

function Cleanup-Fallback {
    $listenerPid = Get-ListenerPid $fbPort
    if ($listenerPid) { return }
    $procs = Get-CimInstance Win32_Process -Filter "Name='python.exe'" |
        Where-Object { $_.CommandLine -like '*vision_fallback.py*' }
    foreach ($p in $procs) {
        Log "killing stray vision fallback pid $($p.ProcessId)"
        Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

# ---- SearXNG ----
function Test-SearxHealthy {
    try {
        $r = Invoke-WebRequest -Uri $searxUrl -TimeoutSec 12 -UseBasicParsing
        return $true
    } catch {
        return $false
    }
}

function Start-Searx {
    Log "starting searxng"
    $bat = "$webstackDir\start_searx.bat"
    if (Test-Path $bat) {
        Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "`"$bat`"" `
            -WorkingDirectory $webstackDir -WindowStyle Hidden
        Start-Sleep -Seconds 10
        if (Test-SearxHealthy) { Log "searxng UP" } else { Log "searxng NOT healthy after start" }
    } else {
        Log "searxng bat not found at $bat"
    }
}

# ---- Ollama ----
function Test-OllamaUp {
    try {
        Invoke-WebRequest -Uri $ollamaUrl -TimeoutSec 3 -UseBasicParsing | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Start-Ollama {
    Log "starting ollama serve"
    if (Test-Path $ollamaExe) {
        Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Hidden
        Start-Sleep -Seconds 8
        if (Test-OllamaUp) { Log "ollama UP" } else { Log "ollama NOT up after start" }
    } else {
        Log "ollama not found at $ollamaExe"
    }
}

# ---- single-instance guard ----
$others = Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" |
    Where-Object { $_.CommandLine -like '*watchdog.ps1*' -and $_.ProcessId -ne $PID }
foreach ($o in $others) {
    $age = (Get-Date) - $o.CreationDate
    if ($age.TotalSeconds -gt 30) {
        Log "stopping previous watchdog pid $($o.ProcessId) (age $([int]$age.TotalSeconds)s)"
        Stop-Process -Id $o.ProcessId -Force -ErrorAction SilentlyContinue
    } else {
        Log "another watchdog pid $($o.ProcessId) is young (age $([int]$age.TotalSeconds)s) - I will exit"
        exit 0
    }
}

Log "watchdog started (pid $PID)"

# ---- startup: all services ----
$listenerPid = Get-ListenerPid $port
if ($listenerPid) {
    $info = Get-ProcInfo $listenerPid
    if (Test-IsOurProxy $info) { Log "proxy already healthy (pid $listenerPid)" }
    else { Log "WRONG_OWNER on :$port pid=$listenerPid - not touching" }
} else {
    if (Test-CircuitBreaker) { Cleanup-StrayProxies; Start-Proxy }
    else { Log "proxy start skipped: circuit breaker active" }
}

$fbListen = Get-ListenerPid $fbPort
if ($fbListen) { Log "vision fallback already up (pid $fbListen)" }
elseif (Test-CircuitBreaker) { Cleanup-Fallback; Start-Fallback }

if (-not (Test-OllamaUp)) { Start-Ollama }
if (-not (Test-SearxHealthy)) { Start-Searx }

$i = 0
while ($true) {
    Start-Sleep -Seconds 15
    $i++

    # --- Proxy supervision ---
    $listenerPid = Get-ListenerPid $port
    if (-not $listenerPid) {
        if (Test-CircuitBreaker) {
            $script:healthFails = 0
            Log "proxy DOWN (no listener) - restarting"
            Cleanup-StrayProxies
            Start-Proxy
        } else {
            Log "proxy DOWN but circuit breaker active - waiting"
        }
    } else {
        $info = Get-ProcInfo $listenerPid
        if (-not (Test-IsOurProxy $info)) {
            Log "WRONG_OWNER on :$port pid=$listenerPid - not touching"
        } elseif (Test-Healthy) {
            if ($script:healthFails -gt 0) { Log "proxy healthy again - healthFails reset" }
            $script:healthFails = 0
        } else {
            $script:healthFails++
            Log "PORT_UP_HEALTH_DOWN pid=$listenerPid fail=$($script:healthFails)"
            if ($script:healthFails -ge 3) {
                if (Test-CircuitBreaker) {
                    Log "proxy HUNG x3 - restarting"
                    Kill-Process $listenerPid 'hung-unhealthy'
                    Start-Sleep -Seconds 3
                    Start-Proxy
                }
            }
        }
    }

    # --- Vision fallback supervision (every loop ~15s) ---
    $fbListen = Get-ListenerPid $fbPort
    if (-not $fbListen) {
        if (Test-CircuitBreaker) {
            $script:fbHealthFails = 0
            Log "vision fallback DOWN - restarting"
            Cleanup-Fallback
            Start-Fallback
        }
    } elseif (-not (Test-FbHealthy)) {
        $script:fbHealthFails++
        if ($script:fbHealthFails -ge 3) {
            if (Test-CircuitBreaker) {
                Log "vision fallback HUNG x3 - restarting"
                Stop-Process -Id $fbListen -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Start-Fallback
                $script:fbHealthFails = 0
            }
        }
    } else {
        $script:fbHealthFails = 0
    }

    # --- SearXNG + Ollama check every ~60s ---
    if ($i % 4 -eq 0) {
        if (-not (Test-SearxHealthy)) {
            $sListeners = Get-NetTCPConnection -LocalPort $searxPort -State Listen -ErrorAction SilentlyContinue
            foreach ($l in $sListeners) {
                Log "killing stale searx holder pid $($l.OwningProcess)"
                Stop-Process -Id $l.OwningProcess -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 2
            Start-Searx
        }
        if (-not (Test-OllamaUp)) { Start-Ollama }
    }
}
