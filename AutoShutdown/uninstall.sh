#!/usr/bin/env bash
set -euo pipefail

# Configuration
SERVICE_NAME="auto-shutdown"
USER_SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$USER_SERVICE_DIR/${SERVICE_NAME}.service"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Don't run as root
if [[ $EUID -eq 0 ]]; then
    error "Run this as your regular user, not root/sudo"
fi

# Check if service file exists
if [[ ! -f "$SERVICE_FILE" ]]; then
    warn "Service file not found at $SERVICE_FILE. Service may already be uninstalled."
    exit 0
fi

# Stop service if running
log "Stopping auto-shutdown service..."
systemctl --user stop "${SERVICE_NAME}.service" 2>/dev/null || warn "Service was not running"

# Disable service from starting at login
log "Disabling auto-shutdown service..."
systemctl --user disable "${SERVICE_NAME}.service" 2>/dev/null || warn "Service was not enabled"

# Remove service file
log "Removing service file..."
rm -f "$SERVICE_FILE"

# Reload systemd user daemon to apply changes
log "Reloading systemd user daemon..."
systemctl --user daemon-reload

# Final verification
echo
log "Uninstallation complete!"
echo
echo "→ Verify: systemctl --user status ${SERVICE_NAME}.service (should show 'not found')"
echo "→ Check inhibitors: systemd-inhibit --list (no auto-shutdown entry)"
echo "→ Reinstall anytime: ./setup.sh"
echo
warn "Note: The auto-shutdown.sh script itself was NOT deleted. Remove it manually if desired."