#!/bin/bash

STATE_FILE="$HOME/.cache/.screen-temp-reset"
GRACE_PERIOD="${SCREEN_TEMP_GRACE_PERIOD:-7200}" # 2 hours default (in seconds)
LOG_FILE="${SCREEN_TEMP_LOG_FILE:-/tmp/temperature.log}"
LOG_ENABLED=true

# Ensure cache directory exists
mkdir -p "$(dirname "$STATE_FILE")"

# --- Logging Function ---
log() {
    if [ "$LOG_ENABLED" = true ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
    fi
}

# --- Find sct command ---
find_sct() {
    local sct_path=$(which sct 2>/dev/null)
    if [ -n "$sct_path" ]; then
        echo "$sct_path"
        log "Found sct at: $sct_path"
        return 0
    fi
    
    # Check common locations
    for loc in /usr/bin/sct /usr/local/bin/sct /bin/sct; do
        if [ -f "$loc" ]; then
            log "Found sct at alternative location: $loc"
            echo "$loc"
            return 0
        fi
    done
    
    log "ERROR: sct command not found anywhere"
    return 1
}

SCT_CMD=$(find_sct) || { echo "Error: sct command not found. Please install it."; exit 1; }

# Function to reset screen temperature
reset_screen_temperature() {
    log "Reset function called"
    echo "Resetting screen temperature to default (6500K)..."
    
    if "$SCT_CMD" 6500; then
        date +%s > "$STATE_FILE"
        log "Reset successful, created state file: $STATE_FILE"
        echo "Automation paused for $((GRACE_PERIOD / 60)) minutes. To resume earlier, run: $0 --resume"
    else
        log "ERROR: Failed to execute sct 6500"
        echo "Error: Failed to reset screen temperature"
        exit 1
    fi
    exit 0
}

# Function to resume automation
resume_screen_temperature() {
    log "Resume function called"
    if [ -f "$STATE_FILE" ]; then
        rm -f "$STATE_FILE"
        log "State file removed, automation resumed"
        echo "Screen temperature automation resumed."
    else
        log "Resume called but no state file found"
        echo "Automation was not paused. No action taken."
    fi
    exit 0
}

# Function to check if reset is active
check_reset_active() {
    if [ -f "$STATE_FILE" ]; then
        local reset_time=$(cat "$STATE_FILE")
        local current_time=$(date +%s)
        local elapsed=$((current_time - reset_time))
        
        if [ $elapsed -lt $GRACE_PERIOD ]; then
            local remaining_mins=$(( (GRACE_PERIOD - elapsed) / 60 ))
            echo "Reset is active. Skipping automatic adjustment (${remaining_mins} minutes remaining)."
            log "Reset active, ${remaining_mins} minutes remaining"
            return 0 # Active
        else
            # Grace period expired, clean up
            rm -f "$STATE_FILE"
            log "Grace period expired, removed state file"
            return 1 # Not active
        fi
    fi
    return 1 # Not active
}

# Function to adjust temperature
adjust_screen_temperature() {
    log "Auto-adjust function called"
    
    # Check if reset is active before adjusting
    if check_reset_active; then
        return 0
    fi

    local hour=$(date +"%H")
    log "Current hour: $hour"

    local temp=""
    local period=""

    if [ "$hour" -ge 6 ] && [ "$hour" -lt 9 ]; then
        temp=3000
        period="early morning"
    elif [ "$hour" -ge 9 ] && [ "$hour" -lt 12 ]; then
        temp=5000
        period="morning"
    elif [ "$hour" -ge 12 ] && [ "$hour" -lt 16 ]; then
        temp=6500
        period="midday"
    elif [ "$hour" -ge 16 ] && [ "$hour" -lt 19 ]; then
        temp=5000
        period="afternoon"
    elif [ "$hour" -ge 19 ] && [ "$hour" -lt 21 ]; then
        temp=3000
        period="evening"
    else
        temp=2000
        period="night"
    fi
    
    echo "Setting screen temperature to ${temp}K (warm) for ${period}..."
    log "Setting temperature to ${temp}K for ${period}"
    
    if "$SCT_CMD" "$temp"; then
        log "Temperature set successfully"
    else
        log "ERROR: Failed to set temperature"
        echo "Error: Failed to set screen temperature"
        exit 1
    fi
}

# Function to set a specific temperature
set_temperature() {
    local temp="$1"
    log "Manual temperature set called: ${temp}K"
    
    # Validate temperature is a number
    if ! [[ "$temp" =~ ^[0-9]+$ ]]; then
        echo "Error: Temperature must be a number (e.g., 4000)"
        log "Invalid temperature format: $temp"
        exit 1
    fi
    
    # Validate reasonable range
    if [ "$temp" -lt 1000 ] || [ "$temp" -gt 10000 ]; then
        echo "Error: Temperature must be between 1000K and 10000K"
        log "Temperature out of range: $temp"
        exit 1
    fi
    
    echo "Setting screen temperature to ${temp}K..."
    log "Executing: $SCT_CMD $temp"
    
    if "$SCT_CMD" "$temp"; then
        log "Manual temperature set successful"
        echo "Temperature set to ${temp}K successfully"
    else
        log "ERROR: Manual temperature set failed"
        echo "Error: Failed to set temperature to ${temp}K"
        exit 1
    fi
}

# --- Parse Arguments ---
# Check for log flag before processing other args
for arg in "$@"; do
    if [ "$arg" = "-l" ] || [ "$arg" = "--log" ]; then
        LOG_ENABLED=true
        log "=== Script started with logging enabled ==="
        log "Arguments: $*"
        log "User: $USER, Display: $DISPLAY, Home: $HOME"
        break
    fi
done

# Main argument handling
case "$1" in
    -r|--reset)
        reset_screen_temperature
        ;;
    --resume)
        resume_screen_temperature
        ;;
    -h|--help)
        echo "Usage: $0 [TEMPERATURE|-r|--reset|--resume|--log]"
        echo "  TEMPERATURE    Set a specific temperature (e.g., 4000)"
        echo "  -r, --reset    Reset to 6500K and pause automation"
        echo "  --resume       Resume automation immediately"
        echo "  -l, --log      Enable debug logging to $LOG_FILE"
        exit 0
        ;;
    -l|--log)
        # Log flag handled above, just run auto-adjust
        adjust_screen_temperature
        ;;
    "")
        adjust_screen_temperature
        ;;
    *)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            set_temperature "$1"
        else
            echo "Error: Unknown option '$1'"
            echo "Usage: $0 [TEMPERATURE|-r|--reset|--resume|--log]"
            exit 1
        fi
        ;;
esac