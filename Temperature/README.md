# Screen Temperature Adjuster

A lightweight, automated screen temperature manager for Linux that adjusts your display's color temperature based on the time of day. Similar to f.lux or Night Shift, it reduces blue light in the evening to help reduce eye strain and improve sleep quality.

## Features

- **Time-based Automation**: Automatically changes color temperature throughout the day.
  - **Early Morning (06:00 - 09:00)**: 3000K (Warm)
  - **Morning (09:00 - 12:00)**: 5000K (Daylight)
  - **Midday (12:00 - 16:00)**: 6500K (Cool/Standard)
  - **Afternoon (16:00 - 19:00)**: 5000K (Daylight)
  - **Evening (19:00 - 21:00)**: 3000K (Warm)
  - **Night (21:00 - 06:00)**: 2000K (Very Warm)
- **Manual Control**: Easily set a specific temperature or reset to default.
- **Pause/Resume**: Temporarily disable automation (e.g., for color-sensitive work) for a configurable duration.
- **Systemd Integration**: Runs automatically in the background using user-level systemd timers.
- **Low Overhead**: Minimal resource usage.

## Requirements

- **Linux** (Tested on distributions using X11/Xorg)
- **sct** (Screen Color Temperature)
  - Arch Linux: `sudo pacman -S sct`
  - Debian/Ubuntu: `sudo apt install sct`

## Installation

1. **Clone or Download** this repository/directory.
2. **Run the Installer**:
   ```bash
   ./install.sh
   ```
   The installer will:
   - Check for `sct` dependency.
   - Install systemd service and timer units to `~/.config/systemd/user/`.
   - Update paths to point to the location of the `temperature.sh` script.
   - Enable and start the background timers.

## Usage

The script normally runs automatically in the background, but you can use `temperature.sh` for manual control.

### Basic Commands

```bash
# Set a specific temperature (e.g., 4000K)
./temperature.sh 4000

# Reset to default (6500K) and pause automation temporarily
./temperature.sh --reset
# OR
./temperature.sh -r

# Resume automation immediately
./temperature.sh --resume
```

### Automation Pause (Reset)

When you run `temperature.sh --reset`, the screen sets to 6500K, and automation is paused for a "grace period" (default: 2 hours). This is useful if you need to do color-accurate work or watch a movie without the tint.

- **Check status**: Run the script manually `time ./temperature.sh`? No, just wait for the next minute tick or check logs. The script checks for the active reset state before applying changes.

## Configuration

You can customize behavior by modifying environment variables in `temperature.sh` or exporting them before running commands (though editing the script is more persistent).

| Variable | Default | Description |
|----------|---------|-------------|
| `SCREEN_TEMP_GRACE_PERIOD` | 7200 | Time in seconds to pause automation after a reset (2 hours). |
| `SCREEN_TEMP_LOG_FILE` | `/tmp/temperature.log` | Path to the log file. |

## Uninstallation

To remove the services, timers, and logs:

```bash
./uninstall.sh
```

This will:
- Stop and disable the systemd units.
- Remove the unit files.
- Reset the screen temperature to 6500K.
- Remove temporary state and log files.
