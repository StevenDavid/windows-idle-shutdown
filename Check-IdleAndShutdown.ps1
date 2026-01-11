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
Add-Content -Path $logPath -Value "$timestamp - Idle time: $idleTimeSeconds seconds"

# Check if idle time exceeds threshold
if ($idleTimeSeconds -ge $idleThresholdSeconds) {
    Add-Content -Path $logPath -Value "$timestamp - Idle threshold exceeded. Initiating shutdown..."
    
    # Shutdown the computer
    # Use -Force to close applications without prompting
    # Remove -Force if you want to allow users to cancel
    Stop-Computer -Force
} else {
    $remainingSeconds = $idleThresholdSeconds - $idleTimeSeconds
    Add-Content -Path $logPath -Value "$timestamp - Still active. $remainingSeconds seconds until shutdown threshold."
}

