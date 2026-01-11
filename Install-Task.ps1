# Install-Task.ps1
# Installation script for the Idle Shutdown Monitor task
# Must be run as Administrator

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "Installing Idle Shutdown Monitor..." -ForegroundColor Cyan

# Define paths
$scriptSource = Join-Path $PSScriptRoot "Check-IdleAndShutdown.ps1"
$scriptDestination = "C:\Scripts"
$scriptPath = Join-Path $scriptDestination "Check-IdleAndShutdown.ps1"
$taskXmlPath = Join-Path $PSScriptRoot "IdleShutdownTask.xml"
$taskName = "Idle Shutdown Monitor"

# Check if source files exist
if (-not (Test-Path $scriptSource)) {
    Write-Host "ERROR: Check-IdleAndShutdown.ps1 not found in current directory!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $taskXmlPath)) {
    Write-Host "ERROR: IdleShutdownTask.xml not found in current directory!" -ForegroundColor Red
    exit 1
}

# Create Scripts directory if it doesn't exist
Write-Host "Creating C:\Scripts directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $scriptDestination -Force | Out-Null

# Copy the PowerShell script
Write-Host "Copying PowerShell script to $scriptPath..." -ForegroundColor Yellow
Copy-Item $scriptSource -Destination $scriptPath -Force

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Task '$taskName' already exists. Removing old task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Register the scheduled task
Write-Host "Registering scheduled task..." -ForegroundColor Yellow

# Create the task action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$scriptPath`""

# Create the trigger (every 5 minutes, indefinitely)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
$trigger.Repetition.Interval = "PT5M"  # Repeat every 5 minutes
$trigger.Repetition.Duration = ""      # Empty string means indefinitely

# Create the principal (run as current user with highest privileges)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest

# Create the settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Minutes 1)

# Register the task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

Write-Host "`nInstallation complete!" -ForegroundColor Green
Write-Host "`nTask Details:" -ForegroundColor Cyan
Write-Host "  - Task Name: $taskName"
Write-Host "  - Script Location: $scriptPath"
Write-Host "  - Log File: C:\Scripts\idle-check.log"
Write-Host "  - Check Frequency: Every 5 minutes"
Write-Host "  - Idle Threshold: 30 minutes"
Write-Host "`nThe task will check for idle time every 5 minutes." -ForegroundColor Yellow
Write-Host "If the user has been idle for 30 minutes, the computer will shutdown." -ForegroundColor Yellow
Write-Host "`nTo view the task, open Task Scheduler (taskschd.msc)" -ForegroundColor Cyan
Write-Host "To uninstall, run: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false" -ForegroundColor Cyan

