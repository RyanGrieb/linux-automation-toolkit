# Open & Minimize Scripts

Generic and specific scripts to launch applications and automatically minimize their windows. Useful for starting background apps (email, notifications, task managers) without cluttering your workspace.

For the best results for running the scripts on startup, use `~/.xprofile`

## Overview

This directory contains scripts that launch applications and minimize their windows, allowing you to start important background applications without them taking up screen space.

## Files

### open-minimize.sh

Generic, parameterized script that launches any application and waits for its window to appear, then minimizes it.

#### Usage

```bash
./open-minimize.sh [OPTIONS]
```

#### Options

- `-n, --name NAME` - Window name pattern to search for (required)
- `-c, --command CMD` - Command to launch the application (required)
- `-i, --interval SECS` - Check interval in seconds (default: 1)
- `-t, --timeout SECS` - Maximum wait time in seconds (default: 30)
- `-a, --args ARGS` - Arguments to pass to the command
- `-v, --verbose` - Show debug output
- `-h, --help` - Show help message

#### How It Works

1. Launches the specified command in the background
2. Searches for a window with a matching name pattern
3. Once found, minimizes the window immediately
4. Exits successfully (or warns if window not found within timeout)

#### Examples

**Basic usage - Thunderbird:**

```bash
./open-minimize.sh -n "Mozilla Thunderbird" -c thunderbird
```

**With custom timeout - Slack:**

```bash
./open-minimize.sh -n "Slack" -c slack -t 20
```

**With arguments - Custom Python app:**

```bash
./open-minimize.sh -n "MyApp" -c "python3" -a "/path/to/app.py" -t 60
```

**Verbose debugging:**

```bash
./open-minimize.sh -n "Firefox" -c firefox -v
```

---

### thunderbird.sh

Specialized wrapper that launches Thunderbird (email client) and minimizes its window.

#### Usage

```bash
./thunderbird.sh
```

#### What It Does

1. Launches Thunderbird in the background
2. Waits up to 30 seconds for the Thunderbird window to appear
3. Minimizes the window when found
4. Exits successfully or warns if window not found

#### Configuration

To customize behavior, edit the script or use it as a template:

```bash
# Adjust these variables in the script
CHECK_INTERVAL=1       # How often to check for the window (seconds)
TIMEOUT=30             # Maximum time to wait (seconds)
```

#### Requirements

- `thunderbird` - Email client installed and in PATH
- `xdotool` - For window management

#### Installation

**Ubuntu/Debian:**

```bash
sudo apt install thunderbird xdotool
```

**Fedora/RHEL:**

```bash
sudo dnf install thunderbird xdotool
```

**Arch:**

```bash
sudo pacman -S thunderbird xdotool
```

#### Example

Automatically start Thunderbird minimized every morning:

```bash
# Add to cron
0 8 * * * /home/ryan/Scripts/OpenMinimize/thunderbird.sh
```

Or add to your shell startup:

```bash
# Add to ~/.bashrc or ~/.bash_profile
[[ -f ~/Scripts/OpenMinimize/thunderbird.sh ]] && ~/Scripts/OpenMinimize/thunderbird.sh &
```

---

### ticktick.sh

Specialized wrapper that launches TickTick (task management app) and minimizes its window.

#### Usage

```bash
./ticktick.sh
```

#### What It Does

1. Launches TickTick using the configured command
2. Waits up to 20 seconds for the TickTick window to appear
3. Minimizes the window when found
4. Exits successfully or warns if window not found

#### Configuration

Edit `ticktick.sh` to set your TickTick command. Common options:

**If TickTick is installed as a binary:**

```bash
--command "ticktick"
```

**If TickTick is a web app (Electron):**

```bash
--command "/opt/TickTick/ticktick"
```

**If TickTick is a Python client:**

```bash
--command "python3" -a "/path/to/ticktick_client.py"
```

**If using a container or custom launcher:**

```bash
--command "docker run ticktick-image"
```

#### Finding Your TickTick Command

1. **Check installed applications:**

   ```bash
   which ticktick           # If installed as binary
   ls /opt/TickTick         # Common installation location
   ```

2. **Search for TickTick executable:**

   ```bash
   find ~ -name "*ticktick*" -type f 2>/dev/null
   ```

3. **Check your applications menu:**

   - Right-click the TickTick launcher
   - View properties or "edit" to see the command

4. **Test the command directly:**
   ```bash
   /path/to/ticktick &      # Launch directly
   ps aux | grep ticktick   # See if it's running
   ```

#### Requirements

- TickTick application installed and accessible
- `xdotool` - For window management

#### Example

Start TickTick minimized on login:

```bash
# Add to ~/.bashrc or ~/.bash_profile
[[ -f ~/Scripts/OpenMinimize/ticktick.sh ]] && ~/Scripts/OpenMinimize/ticktick.sh &
```

Or schedule with cron:

```bash
# Start TickTick at 9 AM every weekday
0 9 * * 1-5 /home/ryan/Scripts/OpenMinimize/ticktick.sh
```

---

## Creating Custom Wrappers

To create a wrapper for any application, copy one of the specialized scripts and modify the `open-minimize.sh` call:

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPEN_MINIMIZE="$SCRIPT_DIR/open-minimize.sh"

"$OPEN_MINIMIZE" \
    --name "YourApp Window Title" \
    --command "your-app-command" \
    --timeout 30
```

Tips:

1. Get the exact window title by running the app and checking `xdotool search --name "pattern"`
2. Test your command from the terminal first
3. Use `--verbose` flag when debugging

---

## Troubleshooting

### "xdotool not installed"

Install it:

```bash
sudo apt install xdotool      # Debian/Ubuntu
sudo dnf install xdotool      # Fedora/RHEL
sudo pacman -S xdotool        # Arch
```

### Window not minimizing

1. **Wrong window title:**

   ```bash
   # List all open windows
   xdotool search --class ""

   # Or watch for the app's window
   watch -n 0.5 'xdotool search --name "pattern" | head'
   ```

2. **Window title includes version or extra text:**

   - Use just a part of the title: `--name "Thunderbird"` instead of the full title
   - xdotool searches for pattern matches, not exact titles

3. **App takes longer to start:**

   - Increase timeout: `--timeout 60`
   - Or increase check interval: `--interval 2`

4. **Timeout reached but app is running:**
   ```bash
   # Debug mode shows what's happening
   ./open-minimize.sh -n "YourApp" -c "your-command" -v
   ```

### Application command not found

```bash
# Check if the app is in PATH
which app-name

# If not, use full path
./open-minimize.sh -n "AppName" -c "/usr/bin/app-name"

# Or find it
find / -name "app-name" 2>/dev/null
```

### Multiple windows with same title

xdotool finds the first matching window. If multiple instances run, it will minimize the first one found. To be more specific:

```bash
# Use class name instead of window title
xdotool search --class "thunderbird"

# Then use in script
./open-minimize.sh -c thunderbird  # xdotool has class-based options too
```

---

## Advanced Usage

### Chaining multiple apps

```bash
#!/bin/bash
SCRIPTS_DIR="/home/ryan/Scripts/OpenMinimize"

# Start multiple apps minimized
"$SCRIPTS_DIR/thunderbird.sh" &
sleep 2
"$SCRIPTS_DIR/ticktick.sh" &
sleep 2
# Add more as needed
```

### Systemd user service

Create a service to run on login:

```bash
# ~/.config/systemd/user/start-apps-minimized.service
[Unit]
Description=Start background apps minimized
After=graphical-session-started.target

[Service]
Type=oneshot
ExecStart=/home/ryan/Scripts/OpenMinimize/thunderbird.sh
ExecStart=/home/ryan/Scripts/OpenMinimize/ticktick.sh
RemainAfterExit=yes

[Install]
WantedBy=graphical-session.target
```

Enable with:

```bash
systemctl --user enable start-apps-minimized.service
systemctl --user start start-apps-minimized.service
```

---

## Best Practices

1. **Test thoroughly**: Always test the exact window name and command before automating
2. **Use timeouts wisely**: Short timeouts are fine for fast-launching apps; slower apps need more time
3. **Validate commands**: Ensure apps work from the command line before using in scripts
4. **Handle failures gracefully**: The scripts warn but don't exit with error, allowing startup chains to continue
5. **Use verbose mode for debugging**: `--verbose` flag helps diagnose issues

---

## License

These scripts are provided as-is for personal use.
