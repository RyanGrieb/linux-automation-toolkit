#!/bin/bash

# laptop-status.sh - System health overview (2-4 lines)
# Add to ~/.bashrc: [[ -f ~/Scripts/laptop-status.sh ]] && ~/Scripts/laptop-status.sh

# Debug mode: ./laptop-status.sh --debug
DEBUG=false
[[ "$1" == "--debug" ]] && DEBUG=true

log() {
    [[ "$DEBUG" == "true" ]] && echo "[DEBUG] $*" >&2
}

# Only exit if sourced AND non-interactive
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ $- != *i* ]]; then
    log "Sourced in non-interactive shell, exiting"
    return 0 2>/dev/null || exit 0
fi
# Colors
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'

# Battery
log "=== Battery ==="
device=$(upower -e 2>/dev/null | grep battery | head -1)
if [[ -n "$device" ]]; then
    percent=$(upower -i "$device" 2>/dev/null | awk '/percentage:/ {print $2}' | tr -d '%')
    health=$(upower -i "$device" 2>/dev/null | awk '/capacity:/ {print int($2)}' | head -1)
    if [[ -n "$percent" ]]; then
        color=$GREEN; (( percent < 20 )) && color=$RED; (( percent < 50 )) && color=$YELLOW
        echo -e "${color}🔋 Battery: ${percent}%${NC} (Health: ${health}%)"
    fi
fi

# SMART + Disk (Permission needed: 'echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/smartctl" | sudo tee /etc/sudoers.d/smartctl')
log "=== SMART ==="
smart_status="${YELLOW}SMART: N/A${NC}"
if command -v smartctl &>/dev/null; then
    # Hardcode your device and SAT flag based on debug output
    smart_output=$(smartctl -d sat -H /dev/sda 2>&1 || smartctl -H /dev/sda 2>&1)
    log "Raw output: $smart_output"
    
    # Check for actual health status, not command failures
    if echo "$smart_output" | grep -qi "self-assessment test result: PASSED"; then
        smart_status="${GREEN}SMART: OK${NC}"
    elif echo "$smart_output" | grep -qi "self-assessment test result: FAILED"; then
        smart_status="${RED}SMART: FAIL${NC}"
    else
        log "No valid SMART status found (likely permission issue)"
    fi
fi

# Disk usage
root_usage=$(df / 2>/dev/null | awk 'NR==2 {print $5}')
echo -e "💾 $smart_status  root: ${root_usage} used"

# Failed services
failed_count=$(systemctl list-units --failed --no-legend --no-pager 2>/dev/null | grep -c '.' || true)
(( failed_count > 0 )) && echo -e "${RED}⚠ Failed: ${failed_count} service(s)${NC}"

# CPU temp
log "=== CPU Temp ==="
temp=$(sensors 2>/dev/null | awk '/Package id 0/ {print $4}' | tr -d '+°C')
if [[ -z "$temp" && -f /sys/class/thermal/thermal_zone0/temp ]]; then
    temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
fi
log "Temp value: $temp"

if [[ -n "$temp" ]]; then
    temp_int=${temp%%.*}
    color=$GREEN; (( temp_int > 85 )) && color=$RED; (( temp_int > 75 )) && color=$YELLOW
    echo -e "${color}🌡 CPU: ${temp}°C${NC}"
else
    echo -e "${YELLOW}🌡 CPU: N/A${NC}"
fi

log "Script complete"