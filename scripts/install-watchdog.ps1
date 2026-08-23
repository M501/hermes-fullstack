# install-watchdog.ps1 — Register watchdog as a scheduled task
# Run once with admin privileges: powershell -ExecutionPolicy Bypass -File install-watchdog.ps1

$taskName = "HermesFullStack-Watchdog"
$watchdogPath = "C:\AI\hermes-proxy\watchdog.ps1"

if (-not (Test-Path $watchdogPath)) {
    Write-Host "ERROR: watchdog.ps1 not found at $watchdogPath"
    Write-Host "Run setup.bat first."
    pause
    exit 1
}

# Remove old task if exists
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Create trigger: at logon + every 5 minutes
$triggerAtLogon = New-ScheduledTaskTrigger -AtLogon
$triggerRepeat = New-ScheduledTaskTrigger -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 5) `
    -RepetitionDuration (New-TimeSpan -Days 9999)

# Action: run watchdog.ps1
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watchdogPath`""

# Settings: run whether user is logged on or not, don't stop on idle
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false `
    -ExecutionTimeLimit (New-TimeSpan -Days 9999)

# Register
Register-ScheduledTask `
    -TaskName $taskName `
    -Trigger @($triggerAtLogon, $triggerRepeat) `
    -Action $action `
    -Settings $settings `
    -Description "Hermes FullStack: auto-start + supervise Proxy(:9224) + Vision(:9225) + SearXNG(:8888) + Ollama(:11434)" `
    -Force

Write-Host ""
Write-Host "Watchdog registered: $taskName"
Write-Host "  Triggers: at logon + every 5 minutes"
Write-Host "  Script: $watchdogPath"
Write-Host ""
Write-Host "To test now: Start-ScheduledTask -TaskName '$taskName'"
Write-Host "To remove:   Unregister-ScheduledTask -TaskName '$taskName'"
pause
