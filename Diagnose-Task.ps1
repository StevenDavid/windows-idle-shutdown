# Diagnose-Task.ps1
# Diagnostic script to check if the Idle Shutdown Monitor is configured correctly

#Requires -RunAsAdministrator

Write-Host "Idle Shutdown Monitor - Diagnostic Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$taskName = "Idle Shutdown Monitor"
$scriptPath = "C:\Scripts\Check-IdleAndShutdown.ps1"
$logPath = "C:\Scripts\idle-check.log"

# Check if task exists
Write-Host "1. Checking if task exists..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "   ✓ Task found" -ForegroundColor Green
} else {
    Write-Host "   ✗ Task NOT found" -ForegroundColor Red
    Write-Host "   Run Install-Task.ps1 to install the task" -ForegroundColor Yellow
    exit 1
}

# Check task principal (who it runs as)
Write-Host ""
Write-Host "2. Checking task security context..." -ForegroundColor Yellow
$principal = $task.Principal
$currentUser = "$env:USERDOMAIN\$env:USERNAME"

Write-Host "   Task runs as: $($principal.UserId)" -ForegroundColor Cyan
Write-Host "   Current user: $currentUser" -ForegroundColor Cyan

if ($principal.UserId -eq "S-1-5-18" -or $principal.UserId -like "*SYSTEM*") {
    Write-Host "   ✗ PROBLEM: Task is running as SYSTEM" -ForegroundColor Red
    Write-Host "   This prevents it from detecting user input!" -ForegroundColor Red
    Write-Host "   Solution: Run Install-Task.ps1 to reinstall with correct user" -ForegroundColor Yellow
} elseif ($principal.UserId -like "*$env:USERNAME*" -or $principal.GroupId -eq "S-1-5-32-544") {
    Write-Host "   ✓ Task runs as user (correct)" -ForegroundColor Green
} else {
    Write-Host "   ⚠ Warning: Task runs as different user" -ForegroundColor Yellow
}

# Check run level
if ($principal.RunLevel -eq "Highest") {
    Write-Host "   ✓ Runs with highest privileges (correct)" -ForegroundColor Green
} else {
    Write-Host "   ✗ Does NOT run with highest privileges" -ForegroundColor Red
}

# Check if script exists
Write-Host ""
Write-Host "3. Checking if script file exists..." -ForegroundColor Yellow
if (Test-Path $scriptPath) {
    Write-Host "   ✓ Script found at $scriptPath" -ForegroundColor Green
} else {
    Write-Host "   ✗ Script NOT found at $scriptPath" -ForegroundColor Red
}

# Check log file
Write-Host ""
Write-Host "4. Checking log file..." -ForegroundColor Yellow
if (Test-Path $logPath) {
    Write-Host "   ✓ Log file exists" -ForegroundColor Green
    $logContent = Get-Content $logPath -Tail 5
    Write-Host "   Last 5 log entries:" -ForegroundColor Cyan
    foreach ($line in $logContent) {
        Write-Host "   $line" -ForegroundColor Gray
    }
} else {
    Write-Host "   ⚠ Log file not found (task may not have run yet)" -ForegroundColor Yellow
}

# Check task state
Write-Host ""
Write-Host "5. Checking task state..." -ForegroundColor Yellow
if ($task.State -eq "Ready") {
    Write-Host "   ✓ Task is enabled and ready" -ForegroundColor Green
} else {
    Write-Host "   ✗ Task state: $($task.State)" -ForegroundColor Red
}

# Test idle detection
Write-Host ""
Write-Host "6. Testing idle detection..." -ForegroundColor Yellow
try {
    Add-Type @'
using System;
using System.Runtime.InteropServices;

public class IdleTimeChecker {
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();

    public static uint GetIdleTime() {
        LASTINPUTINFO lastInputInfo = new LASTINPUTINFO();
        lastInputInfo.cbSize = (uint)Marshal.SizeOf(lastInputInfo);
        
        if (GetLastInputInfo(ref lastInputInfo)) {
            uint currentTickCount = GetTickCount();
            uint idleTime = currentTickCount - lastInputInfo.dwTime;
            return idleTime;
        }
        return 0;
    }
}
'@
    
    $idleMs = [IdleTimeChecker]::GetIdleTime()
    $idleSec = [math]::Floor($idleMs / 1000)
    
    if ($idleSec -ge 0 -and $idleSec -lt 3600) {
        Write-Host "   ✓ Idle detection working: $idleSec seconds idle" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Idle detection returned invalid value: $idleSec seconds" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Error testing idle detection: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Diagnosis complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "If you see any red ✗ marks above, fix those issues." -ForegroundColor Yellow
Write-Host "The most common issue is the task running as SYSTEM instead of your user account." -ForegroundColor Yellow

