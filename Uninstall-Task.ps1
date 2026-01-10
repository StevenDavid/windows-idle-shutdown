# Uninstall-Task.ps1
# Uninstallation script for the Idle Shutdown Monitor task
# Must be run as Administrator

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "Uninstalling Idle Shutdown Monitor..." -ForegroundColor Cyan

$taskName = "Idle Shutdown Monitor"
$scriptPath = "C:\Scripts\Check-IdleAndShutdown.ps1"
$logPath = "C:\Scripts\idle-check.log"

# Check if task exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Removing scheduled task '$taskName'..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Task removed successfully." -ForegroundColor Green
} else {
    Write-Host "Task '$taskName' not found. Nothing to remove." -ForegroundColor Yellow
}

# Ask if user wants to remove the script files
$removeFiles = Read-Host "`nDo you want to remove the script and log files from C:\Scripts? (Y/N)"
if ($removeFiles -eq 'Y' -or $removeFiles -eq 'y') {
    if (Test-Path $scriptPath) {
        Write-Host "Removing $scriptPath..." -ForegroundColor Yellow
        Remove-Item $scriptPath -Force
    }
    
    if (Test-Path $logPath) {
        Write-Host "Removing $logPath..." -ForegroundColor Yellow
        Remove-Item $logPath -Force
    }
    
    # Check if Scripts directory is empty and remove if so
    $scriptsDir = "C:\Scripts"
    if (Test-Path $scriptsDir) {
        $items = Get-ChildItem $scriptsDir
        if ($items.Count -eq 0) {
            Write-Host "Removing empty directory $scriptsDir..." -ForegroundColor Yellow
            Remove-Item $scriptsDir -Force
        }
    }
    
    Write-Host "Files removed successfully." -ForegroundColor Green
}

Write-Host "`nUninstallation complete!" -ForegroundColor Green

