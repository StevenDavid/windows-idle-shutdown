# Troubleshooting: Computer Shuts Down Even When Active

## The Problem

If your computer is shutting down even when you're actively using it, the most common cause is that the scheduled task is running as **SYSTEM** instead of your user account.

When the task runs as SYSTEM, the `GetLastInputInfo()` Windows API call returns `dwTime=0` because SYSTEM doesn't have access to user session input information. This causes the script to calculate an extremely large idle time, triggering an immediate shutdown.

## The Solution

The task **MUST** run as your logged-in user account (with elevated privileges) to detect your keyboard and mouse input.

### Quick Fix

1. **Run the diagnostic script** to confirm the issue:
   ```powershell
   .\Diagnose-Task.ps1
   ```
   
   Look for this line:
   ```
   ✗ PROBLEM: Task is running as SYSTEM
   ```

2. **Reinstall the task** with the correct user:
   ```powershell
   .\Install-Task.ps1
   ```
   
   This will automatically configure the task to run as your user account.

3. **Verify the fix**:
   ```powershell
   .\Test-IdleDetection.ps1
   ```
   
   The idle time should reset to 0 when you move your mouse.

### Manual Fix

If you prefer to fix it manually:

1. Open Task Scheduler (taskschd.msc)
2. Find "Idle Shutdown Monitor"
3. Right-click → Delete
4. Run this PowerShell command as Administrator:
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"C:\Scripts\Check-IdleAndShutdown.ps1`""
   $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
   $trigger.Repetition.Interval = "PT5M"
   $trigger.Repetition.Duration = ""
   $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
   $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd
   Register-ScheduledTask -TaskName "Idle Shutdown Monitor" -Action $action -Trigger $trigger -Principal $principal -Settings $settings
   ```

## How to Verify It's Fixed

### Method 1: Check Task Scheduler

1. Open Task Scheduler (taskschd.msc)
2. Find "Idle Shutdown Monitor"
3. Right-click → Properties
4. On the "General" tab, under "Security options":
   - Should show your username (e.g., `DOMAIN\YourName`)
   - Should NOT show "SYSTEM" or "NT AUTHORITY\SYSTEM"
   - "Run only when user is logged on" should be selected
   - "Run with highest privileges" should be checked

### Method 2: Run the Test Script

```powershell
.\Test-IdleDetection.ps1
```

Watch the idle time counter. When you move your mouse or type, it should immediately reset to 0 seconds.

If it stays at a high number or shows thousands of seconds even when you're active, the task is still running as SYSTEM.

### Method 3: Check the Log File

Look at `C:\Scripts\idle-check.log`. If you see these error messages:

```
ERROR: GetLastInputInfo returned dwTime=0
The script is likely running as SYSTEM and cannot access user input.
```

Then the task is still running as SYSTEM and needs to be fixed.

## Why This Happens

The Windows API function `GetLastInputInfo()` retrieves the time of the last input event (keyboard or mouse) from the user session. However:

- When running as **SYSTEM**: The function can't access user session data, returns `dwTime=0`
- When running as **your user**: The function works correctly and returns the actual last input time

This is a Windows security feature - SYSTEM account is isolated from user sessions.

## Prevention

Always use the `Install-Task.ps1` script to install the task. It automatically configures the correct user context.

If you manually create the task or import the XML file, make sure to:
1. Set the user to your account (not SYSTEM)
2. Enable "Run with highest privileges"
3. Select "Run only when user is logged on"

## Still Having Issues?

Run the diagnostic script for a full system check:

```powershell
.\Diagnose-Task.ps1
```

This will check:
- ✓ Task exists
- ✓ Task runs as correct user
- ✓ Task has elevated privileges
- ✓ Script file exists
- ✓ Log file status
- ✓ Idle detection is working

Any issues will be marked with a red ✗ and include instructions on how to fix them.

