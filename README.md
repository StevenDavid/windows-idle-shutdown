# Windows Idle Shutdown Task

This project contains a Windows Task Scheduler task that automatically shuts down your computer after 30 minutes of user inactivity.

## Files

- **Check-IdleAndShutdown.ps1** - PowerShell script that checks idle time and initiates shutdown
- **IdleShutdownTask.xml** - Task Scheduler task definition
- **Install-Task.ps1** - Installation script (optional)
- **Uninstall-Task.ps1** - Uninstall script (optional)

## Installation

### Method 1: Manual Installation

1. **Copy the PowerShell script to a permanent location:**
   ```powershell
   # Create the Scripts directory if it doesn't exist
   New-Item -ItemType Directory -Path "C:\Scripts" -Force
   
   # Copy the script
   Copy-Item "Check-IdleAndShutdown.ps1" -Destination "C:\Scripts\"
   ```

2. **Import the task into Task Scheduler:**
   
   Open PowerShell as Administrator and run:
   ```powershell
   Register-ScheduledTask -Xml (Get-Content "IdleShutdownTask.xml" | Out-String) -TaskName "Idle Shutdown Monitor"
   ```

   Or use Task Scheduler GUI:
   - Open Task Scheduler (taskschd.msc)
   - Click "Import Task..." in the Actions pane
   - Browse to and select `IdleShutdownTask.xml`
   - Click OK

### Method 2: Using Installation Script

Run the installation script as Administrator:
```powershell
.\Install-Task.ps1
```

## How It Works

1. The task runs every 5 minutes
2. Each time it runs, it checks how long the user has been idle (no keyboard/mouse input)
3. If idle time exceeds 30 minutes (1800 seconds), it initiates a system shutdown
4. All checks are logged to `C:\Scripts\idle-check.log`

## Configuration

### Change Idle Threshold

Edit `Check-IdleAndShutdown.ps1` and modify this line:
```powershell
$idleThresholdSeconds = 1800  # Change to desired seconds
```

### Change Check Frequency

Edit `IdleShutdownTask.xml` and modify the interval:
```xml
<Interval>PT5M</Interval>  <!-- PT5M = 5 minutes, PT10M = 10 minutes, etc. -->
```

### Change Script Location

If you want to use a different location than `C:\Scripts`:
1. Update the path in `IdleShutdownTask.xml` in the `<Arguments>` section
2. Copy the script to your chosen location

## Uninstallation

### Manual Uninstall

Open PowerShell as Administrator:
```powershell
Unregister-ScheduledTask -TaskName "Idle Shutdown Monitor" -Confirm:$false
```

Or use Task Scheduler GUI:
- Open Task Scheduler
- Find "Idle Shutdown Monitor"
- Right-click and select Delete

### Using Uninstall Script

Run as Administrator:
```powershell
.\Uninstall-Task.ps1
```

## Testing

To test without actually shutting down:

1. Edit `Check-IdleAndShutdown.ps1`
2. Comment out the `Stop-Computer` line:
   ```powershell
   # Stop-Computer -Force
   ```
3. Add a test message:
   ```powershell
   Add-Content -Path $logPath -Value "$timestamp - TEST MODE: Would shutdown now"
   ```
4. Check the log file at `C:\Scripts\idle-check.log` to verify it's working

## Troubleshooting

- **Task doesn't run**: Ensure the task is enabled in Task Scheduler and running with highest privileges
- **Script errors**: Check the log file at `C:\Scripts\idle-check.log`
- **Permissions**: The task must run as SYSTEM or with Administrator privileges to shutdown the computer
- **Execution Policy**: The task uses `-ExecutionPolicy Bypass` to avoid script execution restrictions

## Security Notes

- The script runs with elevated privileges (required for shutdown)
- The `-Force` parameter on `Stop-Computer` will close applications without prompting
- Remove `-Force` if you want users to be able to save work before shutdown
- Review the log file regularly to ensure the task is working as expected

