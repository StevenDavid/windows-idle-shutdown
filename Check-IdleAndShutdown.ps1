# Check-IdleAndShutdown.ps1
# This script checks if the user has been idle for 30 minutes and shuts down the computer if so

# Define idle threshold in seconds (30 minutes = 1800 seconds)
$idleThresholdSeconds = 1800

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

# Get idle time in milliseconds
$idleTimeMs = [IdleTimeChecker]::GetIdleTime()
$idleTimeSeconds = [math]::Floor($idleTimeMs / 1000)

# Log the current idle time
$logPath = "$PSScriptRoot\idle-check.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Sanity check: if idle time is negative or unreasonably large, something is wrong
if ($idleTimeSeconds -lt 0 -or $idleTimeSeconds -gt 86400) {
    # More than 24 hours or negative - likely a calculation error
    Add-Content -Path $logPath -Value "$timestamp - ERROR: Invalid idle time detected: $idleTimeSeconds seconds (raw: $idleTimeMs ms)"
    Add-Content -Path $logPath -Value "$timestamp - This usually means the script cannot access user session input."
    Add-Content -Path $logPath -Value "$timestamp - Ensure the task runs as the logged-in user, not SYSTEM."
    exit 1
}

# Additional check: if idle time is exactly 0 and raw ms is very large, dwTime was likely 0
if ($idleTimeSeconds -eq 0 -and $idleTimeMs -gt 4000000000) {
    Add-Content -Path $logPath -Value "$timestamp - ERROR: GetLastInputInfo returned dwTime=0 (raw idle: $idleTimeMs ms)"
    Add-Content -Path $logPath -Value "$timestamp - The script is likely running as SYSTEM and cannot access user input."
    Add-Content -Path $logPath -Value "$timestamp - Change the scheduled task to run as the logged-in user with highest privileges."
    exit 1
}

# Convert to minutes for easier reading
$idleMinutes = [math]::Floor($idleTimeSeconds / 60)
$thresholdMinutes = [math]::Floor($idleThresholdSeconds / 60)

Add-Content -Path $logPath -Value "$timestamp - Idle time: $idleTimeSeconds seconds ($idleMinutes minutes) | Threshold: $idleThresholdSeconds seconds ($thresholdMinutes minutes)"

# Check if idle time exceeds threshold
if ($idleTimeSeconds -ge $idleThresholdSeconds) {
    Add-Content -Path $logPath -Value "$timestamp - WARNING: Idle threshold exceeded! Idle: $idleMinutes min >= Threshold: $thresholdMinutes min"
    Add-Content -Path $logPath -Value "$timestamp - Initiating shutdown in 10 seconds..."

    # Give a 10 second warning before shutdown (allows time to move mouse to cancel if needed)
    Start-Sleep -Seconds 10

    # Re-check idle time after the 10 second delay
    $recheckIdleMs = [IdleTimeChecker]::GetIdleTime()
    $recheckIdleSeconds = [math]::Floor($recheckIdleMs / 1000)

    if ($recheckIdleSeconds -ge $idleThresholdSeconds) {
        Add-Content -Path $logPath -Value "$timestamp - Recheck confirmed idle. Shutting down now..."
        # Shutdown the computer
        Stop-Computer -Force
    } else {
        Add-Content -Path $logPath -Value "$timestamp - User became active during countdown. Shutdown cancelled."
    }
} else {
    $remainingSeconds = $idleThresholdSeconds - $idleTimeSeconds
    $remainingMinutes = [math]::Floor($remainingSeconds / 60)
    Add-Content -Path $logPath -Value "$timestamp - Still active. $remainingMinutes minutes ($remainingSeconds seconds) until shutdown threshold."
}

