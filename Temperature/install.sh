#!/bin/bash

# Temperature Script Installer
# Installs systemd services/timers and configures paths automatically

set -e

# Get the absolute path of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_SCRIPT="$SCRIPT_DIR/temperature.sh"

# Source files
SERVICE_FILE="temperature.service"
LOGIN_SERVICE_FILE="temperature-login.service"
TIMER_FILE="temperature.timer"
LOGIN_TIMER_FILE="temperature-login.timer"

# Destination
SYSTEMD_DIR="$HOME/.config/systemd/user"

echo "Temperature Script Installer"
echo "============================"
echo

# 1. Dependency Check
if ! command -v sct &> /dev/null; then
    echo "❌ Error: 'sct' is not installed."
    echo "   Please install it first (e.g., sudo pacman -S sct, or sudo apt install sct)"
    exit 1
fi

# 2. Script Existence Check
if [ ! -f "$TEMP_SCRIPT" ]; then
    echo "❌ Error: temperature.sh not found at $TEMP_SCRIPT"
    exit 1
fi

# 3. Make executable
chmod +x "$TEMP_SCRIPT"
echo "✓ Made temperature.sh executable"

# 4. Create directory
mkdir -p "$SYSTEMD_DIR"

# 5. Install and Patch Files
# We copy the files, then use 'sed' to update the ExecStart path to the REAL location
# This makes the script work no matter where you saved the folder.

echo "Installing configuration files..."

install_unit() {
    local filename=$1
    local source_path="$SCRIPT_DIR/$filename"
    local dest_path="$SYSTEMD_DIR/$filename"

    if [ ! -f "$source_path" ]; then
        echo "❌ Error: Source file $filename missing!"
        exit 1
    fi

    cp "$source_path" "$dest_path"
    
    # If it's a service file, update the ExecStart path to match current location
    if [[ "$filename" == *".service" ]]; then
        # Replaces any ExecStart line with the absolute path to temperature.sh
        sed -i "s|^ExecStart=.*|ExecStart=$TEMP_SCRIPT|g" "$dest_path"
        echo "  - Installed and configured path for $filename"
    else
        echo "  - Installed $filename"
    fi
}

install_unit "$SERVICE_FILE"
install_unit "$LOGIN_SERVICE_FILE"
install_unit "$TIMER_FILE"
install_unit "$LOGIN_TIMER_FILE"

# 6. Systemd Reload & Start
echo
echo "Configuring Systemd..."
systemctl --user daemon-reload

# Explicitly disable the SERVICE units so they are only triggered by TIMERS
# (This prevents the 'double start' issue)
systemctl --user disable "$SERVICE_FILE" 2>/dev/null || true
systemctl --user disable "$LOGIN_SERVICE_FILE" 2>/dev/null || true

# Enable and restart the TIMERS
systemctl --user enable "$TIMER_FILE"
systemctl --user restart "$TIMER_FILE"
echo "✓ Enabled minute timer"

systemctl --user enable "$LOGIN_TIMER_FILE"
systemctl --user restart "$LOGIN_TIMER_FILE"
echo "✓ Enabled login timer"

# 7. Initial Run
echo
echo "Running script now to verify operation..."
"$TEMP_SCRIPT"

echo
echo "Installation complete!"
echo "-----------------------------------------------------"
echo "Status Check:"
echo "   Minutely Timer: $(systemctl --user is-active temperature.timer)"
echo "   Login Timer:    $(systemctl --user is-active temperature-login.timer)"
echo "-----------------------------------------------------"