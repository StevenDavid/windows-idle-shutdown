# Quick Start Guide

## Installation (3 steps)

### Step 1: Copy files to your Windows machine
Transfer all the files from this repository to your Windows computer.

### Step 2: Install the task
Open PowerShell **as Administrator** and run:

```powershell
cd path\to\windows-idle
.\Install-Task.ps1
```

### Step 3: Verify it's working
```powershell
.\Test-IdleDetection.ps1
```

Move your mouse - the idle time should reset to 0 seconds.

**Done!** The task will now check every 5 minutes and shutdown after 30 minutes of inactivity.

---

## What Gets Installed

- **Script**: `C:\Scripts\Check-IdleAndShutdown.ps1`
- **Log file**: `C:\Scripts\idle-check.log`
- **Scheduled Task**: "Idle Shutdown Monitor" (runs every 5 minutes)

---

## If Computer Shuts Down While You're Active

This means the task is running as SYSTEM instead of your user account.

**Fix it:**
```powershell
.\Diagnose-Task.ps1    # Check what's wrong
.\Install-Task.ps1     # Reinstall with correct settings
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for details.

---

## Customization

### Change idle timeout (default: 30 minutes)

Edit `C:\Scripts\Check-IdleAndShutdown.ps1`, line 5:
```powershell
$idleThresholdSeconds = 1800  # 1800 = 30 minutes
```

Examples:
- 15 minutes: `900`
- 1 hour: `3600`
- 2 hours: `7200`

### Change check frequency (default: 5 minutes)

When running `Install-Task.ps1`, it sets the task to check every 5 minutes.

To change this, edit `Install-Task.ps1`, line 51:
```powershell
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
```

Change `-Minutes 5` to your desired interval.

---

## Uninstall

```powershell
.\Uninstall-Task.ps1
```

---

## Files Included

| File | Purpose |
|------|---------|
| `Check-IdleAndShutdown.ps1` | Main script that checks idle time |
| `Install-Task.ps1` | Automated installation |
| `Uninstall-Task.ps1` | Automated uninstallation |
| `Test-IdleDetection.ps1` | Test if idle detection works |
| `Diagnose-Task.ps1` | Diagnose configuration issues |
| `IdleShutdownTask.xml` | Task definition (for reference) |
| `README.md` | Full documentation |
| `TROUBLESHOOTING.md` | Detailed troubleshooting guide |
| `QUICK-START.md` | This file |

---

## How It Works

1. Task runs every 5 minutes
2. Checks how long since last keyboard/mouse input
3. If idle ≥ 30 minutes:
   - Waits 10 seconds
   - Rechecks idle time
   - If still idle, shuts down
4. All activity logged to `C:\Scripts\idle-check.log`

---

## Common Questions

**Q: Will it shut down if I'm watching a video?**  
A: Yes, if you don't move the mouse or press keys for 30 minutes. Move your mouse occasionally to prevent shutdown.

**Q: Can I cancel the shutdown?**  
A: Yes! You have a 10-second window after the threshold is reached. Just move your mouse during that time.

**Q: Does it work with multiple users?**  
A: The task must be installed separately for each user who wants this feature.

**Q: What if my computer is off when the task should run?**  
A: The task will run when the computer is next turned on and you're logged in.

**Q: Can I test without actually shutting down?**  
A: Yes! Edit `C:\Scripts\Check-IdleAndShutdown.ps1` and comment out line 85:
```powershell
# Stop-Computer -Force
```

---

## Support

If you encounter issues:

1. Run `.\Diagnose-Task.ps1` to identify the problem
2. Check `C:\Scripts\idle-check.log` for error messages
3. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions

