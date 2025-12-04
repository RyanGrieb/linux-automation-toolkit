#!/usr/bin/env bash
set -euo pipefail

# Configuration
SERVICE_NAME="auto-shutdown"
SCRIPT_NAME="auto-shutdown.sh"
USER_SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$USER_SERVICE_DIR/${SERVICE_NAME}.service"

# Get absolute path of the shutdown script
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SETUP_DIR}/${SCRIPT_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check script exists and is executable
if [[ ! -f "$SCRIPT_PATH" ]]; then
    error "Script not found at $SCRIPT_PATH. Ensure install.sh is in the same directory as $SCRIPT_NAME."
fi

if [[ ! -x "$SCRIPT_PATH" ]]; then
    warn "Script is not executable. Setting executable bit..."
    chmod +x "$SCRIPT_PATH"
    log "Made script executable."
fi

# Check dependencies
log "Checking dependencies..."
missing_deps=false
for cmd in systemd-inhibit xprintidle on_ac_power xdotool; do
    if ! command -v "$cmd" &> /dev/null; then
        warn "Command '$cmd' not found. Please install it."
        missing_deps=true
    fi
done
if [[ "${missing_deps}" == "true" ]]; then
    error "Please install missing dependencies and run again."
fi

# Don't run as root
if [[ $EUID -eq 0 ]]; then
    error "Run this as your regular user, not root/sudo"
fi

# Create systemd user directory
log "Creating systemd user directory..."
mkdir -p "$USER_SERVICE_DIR"

# Create service file with WRAPPED execution
log "Creating systemd service file..."
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Auto-shutdown on battery idle
# Remove graphical dependency; run earlier
After=default.target
# Tell systemd we can delay shutdown for 30 minutes
JobTimeoutSec=1800

[Service]
Type=simple
# Inhibit sleep, idle, and shutdown; use 'block' mode for stronger prevention
ExecStart=/usr/bin/systemd-inhibit --what=handle-lid-switch:sleep:idle:shutdown --why="Auto-shutdown timer" --mode=block $SCRIPT_PATH
# Keep trying if we fail
Restart=on-failure
RestartSec=30

[Install]
WantedBy=default.target
EOF
log "✓ Service file created at $SERVICE_FILE"

# Reload and start service
log "Reloading systemd user daemon..."
systemctl --user daemon-reload

log "Stopping any old service instance..."
systemctl --user stop "${SERVICE_NAME}.service" 2>/dev/null || true

log "Enabling service to start on login..."
systemctl --user enable "${SERVICE_NAME}.service"

log "Starting service now..."
systemctl --user start "${SERVICE_NAME}.service"

# Give it a moment to start
sleep 3

# Verify
if systemctl --user is-active --quiet "${SERVICE_NAME}.service"; then
    log "✓ Service is running"
else
    error "Service failed to start. Run 'systemctl --user status ${SERVICE_NAME}.service' for details"
fi

# Check inhibitor using process instead of formatted output
sleep 5
if systemctl --user is-active --quiet "${SERVICE_NAME}.service" && \
   pgrep -f "systemd-inhibit.*${SCRIPT_NAME}" > /dev/null; then
    log "✓ Sleep inhibitor is active. System won't suspend for up to 30 minutes on battery"
else
    warn "Inhibitor check inconclusive. Service is running but lock not visible in formatted output."
    warn "This is normal. Verify with: COLUMNS=200 systemd-inhibit --list"
    warn "Or check process directly: pgrep -fa 'systemd-inhibit.*${SCRIPT_NAME}'"
fi

# Done
echo
log "Installation complete!"
echo
echo "→ Monitor logs: journalctl --user -u ${SERVICE_NAME}.service -f"
echo "→ Check status: systemctl --user status ${SERVICE_NAME}.service"
echo "→ View inhibitor: systemctl --user show ${SERVICE_NAME}.service"
echo "→ Disable: systemctl --user disable --now ${SERVICE_NAME}.service"
echo
echo "The service will auto-start on your next login. The inhibitor is active."
echo ""
echo "To test: Close the lid, unplug AC, and wait 30 minutes of true idle time. The laptop will shutdown cleanly."
echo ""
echo "If you experience issues, check for other programs generating input events with: xinput test-xi2 --root"