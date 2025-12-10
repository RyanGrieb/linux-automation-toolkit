#!/bin/bash

# Wrapper script for launching applications from .xprofile
# Adds delays to ensure X11 is ready and handles timing properly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPEN_MINIMIZE="$SCRIPT_DIR/open-minimize.sh"
LOG_DIR="/tmp/open-minimize-logs"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Wait for X11 to be fully ready
sleep 2

# Launch Firefox
"$OPEN_MINIMIZE" --name "Firefox" --command "firefox" --timeout 30 > "$LOG_DIR/firefox.log" 2>&1 &

# Launch Thunderbird
"$OPEN_MINIMIZE" --name "Mozilla Thunderbird" --command "thunderbird" --timeout 30 > "$LOG_DIR/thunderbird.log" 2>&1 &

# Launch Discord
#"$OPEN_MINIMIZE" --name "Discord" --command "discord" --min-size 250000 --timeout 30 > "$LOG_DIR/discord.log" 2>&1 &

# Wait a bit before launching TickTick to avoid overwhelming the system at startup
#sleep 3

# Launch TickTick with extended timeout and longer recheck delay for startup conditions
# TickTick takes longer to initialize and may show the window after "main-dom-ready" event (~3-5 seconds)
"$OPEN_MINIMIZE" --name "TickTick" --command "ticktick" --timeout 40 --watch-time 5 > "$LOG_DIR/ticktick.log" 2>&1 &