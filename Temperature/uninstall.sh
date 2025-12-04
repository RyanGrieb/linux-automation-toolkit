#!/bin/bash

# Temperature Script Uninstaller
# This script removes systemd services, timers, and crontab entries

# Define the systemd user directory
SYSTEMD_DIR="$HOME/.config/systemd/user"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_SCRIPT="$SCRIPT_DIR/temperature.sh"

echo "Temperature Script Uninstaller"
echo "=============================="
echo

# 1. Reset the screen temperature to default immediately
if [ -x "$TEMP_SCRIPT" ]; then
    echo "Resetting screen temperature..."
    # We ignore the output to keep it clean, or you can let it show
    "$TEMP_SCRIPT" --reset 
else
    echo "⚠ Warning: temperature.sh not found, skipping screen reset."
fi

# Helper function to remove a unit
remove_unit() {
    UNIT=$1
    FILE="$SYSTEMD_DIR/$UNIT"

    echo "Processing $UNIT..."
    
    # Always try to stop and disable, ignore errors if already stopped/disabled
    systemctl --user stop "$UNIT" 2>/dev/null || true
    systemctl --user disable "$UNIT" 2>/dev/null || true

    # Check if the file actually exists before trying to remove it
    if [ -f "$FILE" ]; then
        rm -f "$FILE"
        echo "✓ Removed file: $FILE"
    else
        echo "⚠ File not found (already removed): $FILE"
    fi
}

echo
echo "--- Removing Systemd Units ---"

# Remove Timers first
remove_unit "temperature.timer"
remove_unit "temperature-login.timer"

# Remove Services second
remove_unit "temperature.service"
remove_unit "temperature-login.service"

# Reload systemd to recognize files are gone
systemctl --user daemon-reload

# Remove state file and log file
echo
echo "--- Cleaning up Cache & Logs ---"
STATE_FILE="$HOME/.cache/.screen-temp-reset"
LOG_FILE="/tmp/temperature.log"

if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
    echo "✓ Removed state file: $STATE_FILE"
fi

if [ -f "$LOG_FILE" ]; then
    rm -f "$LOG_FILE"
    echo "✓ Removed log file: $LOG_FILE"
fi

echo
echo "Uninstallation complete!"