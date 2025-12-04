# Auto-Shutdown

Automatically shuts down your Linux laptop when it's been idle for 30 minutes while running on battery power. Useful for preventing unnecessary battery drain when you've stepped away from your machine.

## Features

- **Battery-aware**: Only triggers shutdown when running on battery power; AC-powered systems are unaffected
- **Idle detection**: Uses X11 to detect keyboard/mouse inactivity
- **Systemd integration**: Runs as a user systemd service that auto-starts on login
- **Sleep inhibitor**: Prevents the system from suspending via `systemd-inhibit`, allowing the auto-shutdown logic to execute properly even when the lid is closed
- **Logging**: Detailed timestamped logs for debugging and monitoring
- **Smart power transitions**: Resets idle timer when transitioning from AC to battery

## Requirements

This script requires the following utilities:

- `xprintidle` - Detects X11 idle time
- `on_ac_power` - Checks if system is on AC power
- `xdotool` - Simulates mouse movement for idle timer reset
- `systemd-inhibit` - Prevents system suspension
- Systemd user services enabled

### Installation of Dependencies

**Ubuntu/Linux Mint/Debian:**

```bash
sudo apt update
sudo apt install xprintidle xdotool powermgmt-base
```
