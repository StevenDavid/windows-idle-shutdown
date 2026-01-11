# Test-IdleDetection.ps1
# This script helps you test the idle detection without actually shutting down

Write-Host "Idle Time Detection Test" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will monitor your idle time for 60 seconds." -ForegroundColor Yellow
Write-Host "Try moving your mouse or typing to see the idle time reset." -ForegroundColor Yellow
Write-Host ""

# Add Windows API signature to get last input time
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

$startTime = Get-Date
$duration = 60  # Run for 60 seconds

Write-Host "Starting monitoring... (Press Ctrl+C to stop)" -ForegroundColor Green
Write-Host ""

while ((Get-Date) -lt $startTime.AddSeconds($duration)) {
    # Get idle time
    $idleTimeMs = [IdleTimeChecker]::GetIdleTime()
    $idleTimeSeconds = [math]::Floor($idleTimeMs / 1000)
    $idleMinutes = [math]::Floor($idleTimeSeconds / 60)
    $idleSecondsRemainder = $idleTimeSeconds % 60
    
    # Get current time
    $currentTime = Get-Date -Format "HH:mm:ss"
    
    # Display with color coding
    if ($idleTimeSeconds -lt 5) {
        $color = "Green"
        $status = "ACTIVE"
    } elseif ($idleTimeSeconds -lt 30) {
        $color = "Yellow"
        $status = "IDLE"
    } else {
        $color = "Red"
        $status = "VERY IDLE"
    }
    
    # Clear the line and write new status
    Write-Host "`r[$currentTime] Idle: $idleMinutes min $idleSecondsRemainder sec ($idleTimeSeconds total seconds) - $status" -ForegroundColor $color -NoNewline
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host ""
Write-Host "Test complete!" -ForegroundColor Green
Write-Host ""
Write-Host "If the idle time was resetting when you moved your mouse/keyboard, the detection is working correctly." -ForegroundColor Cyan
Write-Host "If it showed high idle times even when you were active, there's a problem." -ForegroundColor Cyan

