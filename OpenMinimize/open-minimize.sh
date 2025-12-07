#!/bin/bash

################################################################################
# open-minimize.sh
# Generic script to launch an application and minimize its window
#
# Usage: ./open-minimize.sh [OPTIONS]
#
# Options:
#   -n, --name NAME              Window name pattern to search for (required)
#   -c, --command CMD            Command to launch the application (required)
#   -i, --interval SECS          Check interval in seconds (default: 1)
#   -t, --timeout SECS           Maximum wait time in seconds (default: 30)
#   -t, --timeout SECS           Maximum wait time in seconds (default: 30)
#   -r, --watch-time SECS        Seconds to keep watching/minimizing the window after first success (default: 10)
#   -m, --min-size PIXELS        Minimum window area (width * height) to consider valid (default: 100000)
#   -a, --args ARGS              Arguments to pass to the command
#   -h, --help                   Show this help message
#
# Examples:
#   ./open-minimize.sh -n "Mozilla Thunderbird" -c thunderbird
#   ./open-minimize.sh -n "Slack" -c "slack" -t 20
#   ./open-minimize.sh -n "Discord" -c "discord" -m 250000
#   ./open-minimize.sh -n "TickTick" -c "python3 /path/to/ticktick" -i 2 -t 60
################################################################################

set -euo pipefail

# Default values
WINDOW_NAME=""
COMMAND=""
COMMAND_ARGS=""
CHECK_INTERVAL=1
TIMEOUT=30
VERBOSE=true
MIN_WINDOW_SIZE=100000  # Minimum window area (width * height) to consider as a real window
WATCH_DURATION=10       # Seconds to keep watching/minimizing the window after first success

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
debug() { [[ "$VERBOSE" == "true" ]] && echo -e "${YELLOW}[DEBUG]${NC} $*"; }

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                WINDOW_NAME="$2"
                shift 2
                ;;
            -c|--command)
                COMMAND="$2"
                shift 2
                ;;
            -a|--args)
                COMMAND_ARGS="$2"
                shift 2
                ;;
            -i|--interval)
                CHECK_INTERVAL="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -r|--watch-time)
                WATCH_DURATION="$2"
                shift 2
                ;;
            -m|--min-size)
                MIN_WINDOW_SIZE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

show_help() {
    grep "^#" "$0" | grep -E "^\s*#" | sed 's/^#!//' | sed 's/^# //'
}

# Validate requirements
validate_requirements() {
    if [[ -z "$WINDOW_NAME" ]]; then
        error "Window name (-n/--name) is required"
    fi
    
    if [[ -z "$COMMAND" ]]; then
        error "Command (-c/--command) is required"
    fi
    
    if ! command -v xdotool &>/dev/null; then
        error "xdotool is required but not installed. Install with: sudo apt install xdotool"
    fi
}

# Wait for window to be fully mapped and ready
wait_for_window_ready() {
    local window_id=$1
    local max_attempts=50
    local attempt=0
    local last_width=0
    local last_height=0
    local stable_count=0
    local required_stable=2  # Window size must be stable for 2 checks
    
    while (( attempt < max_attempts )); do
        # Try to get geometry
        local geom_output
        geom_output=$(xdotool getwindowgeometry "$window_id" 2>&1)
        local geom_status=$?
        
        if [[ $geom_status -eq 0 ]]; then
            # Parse geometry output to extract dimensions
            local width height
            width=$(echo "$geom_output" | sed -n 's/.*Geometry: \([0-9]*\)x.*/\1/p')
            height=$(echo "$geom_output" | sed -n 's/.*Geometry: [0-9]*x\([0-9]*\).*/\1/p')
            
            debug "Window ready check $attempt: ${width}x${height}"
            
            # Check if window size has stabilized
            if [[ -n "$width" && -n "$height" ]]; then
                if [[ "$width" == "$last_width" && "$height" == "$last_height" && "$width" -gt 0 ]]; then
                    stable_count=$((stable_count + 1))
                    if (( stable_count >= required_stable )); then
                        debug "Window size stabilized at ${width}x${height}"
                        return 0
                    fi
                else
                    stable_count=0
                fi
                
                last_width=$width
                last_height=$height
            fi
        fi
        
        sleep 0.1
        attempt=$((attempt + 1))
    done
    
    debug "Window did not stabilize after $max_attempts checks (5 seconds)"
    return 1
}

# Launch the application
launch_application() {
    debug "Launching: $COMMAND $COMMAND_ARGS"
    
    if [[ -z "$COMMAND_ARGS" ]]; then
        $COMMAND &
    else
        $COMMAND "$COMMAND_ARGS" &
    fi
    
    disown 2>/dev/null || true
    log "Launched: $COMMAND"
}

# Wait for window to appear and minimize it
wait_and_minimize() {
    local elapsed=0
    local found_small_window=false
    local small_window_found_at=0
    local grace_period=5  # Continue searching for 5 seconds after finding a small window

    debug "Waiting for window matching: '$WINDOW_NAME' (timeout: ${TIMEOUT}s, interval: ${CHECK_INTERVAL}s)"
    debug "Minimum window size: ${MIN_WINDOW_SIZE} pixels (to ignore tray icons)"

    while true; do
        # Check if we've exceeded the timeout
        if (( elapsed >= TIMEOUT )); then
            warn "Timeout reached: Window matching '$WINDOW_NAME' not found after ${TIMEOUT}s"
            return 1
        fi

        # If we found a small window, check if grace period has expired
        if [[ "$found_small_window" == "true" ]]; then
            local grace_elapsed=$((elapsed - small_window_found_at))
            if (( grace_elapsed >= grace_period )); then
                warn "Grace period expired: Only found small window (likely tray icon), no main window appeared"
                return 1
            fi
        fi

        # Search for ALL windows matching the name
        local window_ids
        window_ids=$(xdotool search --name "$WINDOW_NAME" 2>/dev/null || true)

        if [[ -n "$window_ids" ]]; then
            # If multiple windows match, pick the largest one (real app window, not tray icon)
            local largest_window_id=0
            local largest_size=0

            while read -r wid; do
                if [[ -n "$wid" ]]; then
                    local geom
                    geom=$(xdotool getwindowgeometry "$wid" 2>&1)
                    local width height
                    width=$(echo "$geom" | sed -n 's/.*Geometry: \([0-9]*\)x.*/\1/p')
                    height=$(echo "$geom" | sed -n 's/.*Geometry: [0-9]*x\([0-9]*\).*/\1/p')

                    if [[ -n "$width" && -n "$height" ]]; then
                        local size=$((width * height))
                        debug "  Window $wid: ${width}x${height} (area: $size)"

                        if (( size > largest_size )); then
                            largest_size=$size
                            largest_window_id=$wid
                        fi
                    fi
                fi
            done <<< "$window_ids"

            if (( largest_window_id > 0 )); then
                # Check if this is a small window (likely tray icon)
                if (( largest_size < MIN_WINDOW_SIZE )); then
                    if [[ "$found_small_window" == "false" ]]; then
                        debug "Found small window (size: $largest_size), likely tray icon. Continuing to search for main window..."
                        found_small_window=true
                        small_window_found_at=$elapsed
                    else
                        debug "Still monitoring for larger window (current: $largest_size, elapsed: $((elapsed - small_window_found_at))s of ${grace_period}s grace period)"
                    fi
                else
                    # Found a window large enough to be the real application window
                    WINDOW_ID=$largest_window_id
                    debug "Selected window ID: $WINDOW_ID (size: $largest_size)"
                    log "Found window: $WINDOW_NAME (ID: $WINDOW_ID, size: $largest_size)"

                    # Wait for window to be fully mapped and ready
                    if wait_for_window_ready "$WINDOW_ID"; then
                        debug "Window is ready, attempting to minimize"

                        # Minimize the window
                        local minimize_output
                        minimize_output=$(xdotool windowminimize "$WINDOW_ID" 2>&1)
                        local minimize_status=$?

                        if [[ $minimize_status -eq 0 ]]; then
                            log "Window minimized successfully"
                            
                            # Watchdog loop: Keep ensuring it stays minimized for WATCH_DURATION seconds
                            local watch_start=$(date +%s)
                            local watch_now
                            
                            debug "Entering watchdog mode for ${WATCH_DURATION} seconds..."
                            
                            while true; do
                                watch_now=$(date +%s)
                                if (( watch_now - watch_start >= WATCH_DURATION )); then
                                    debug "Watchdog period ended."
                                    break
                                fi
                                
                                # Check window state
                                local wm_state
                                wm_state=$(xprop -id "$WINDOW_ID" _NET_WM_STATE 2>/dev/null || echo "DESTROYED")
                                
                                if [[ "$wm_state" == "DESTROYED" ]]; then
                                    warn "Window destroyed during watchdog period. Resuming search..."
                                    break # breaks the watchdog loop, falls out to... WHERE?
                                          # We need to make sure we don't return 0. 
                                          # We are currently inside `if [[ $minimize_status -eq 0 ]]; then`
                                          # If we break, we hit the end of that block.
                                          # We need a flag to say "keep searching".
                                elif [[ "$wm_state" != *"HIDDEN"* ]]; then
                                    debug "Window $WINDOW_ID is visible again! Forcing minimize..."
                                    xdotool windowminimize "$WINDOW_ID" 2>/dev/null || true
                                fi
                                
                                sleep 0.5
                            done
                            
                            # If we are here, either time expired or window destroyed.
                            # If window exists and is minimized (or we gave up watching), success?
                            if [[ -n "$WINDOW_ID" ]] && xprop -id "$WINDOW_ID" &>/dev/null; then
                                log "Watchdog completed. Window appears stable."
                                return 0
                            else
                                # Window lost, continue main search loop
                                debug "Window lost during watchdog. Continuing main search..."
                            fi
                        else
                            debug "xdotool output: $minimize_output"
                            warn "Failed to minimize window (xdotool returned $minimize_status)"
                            return 1
                        fi
                    else
                        warn "Window found but failed to become ready"
                        return 1
                    fi
                fi
            fi
        fi

        # Wait before checking again
        sleep "$CHECK_INTERVAL"
        elapsed=$((elapsed + CHECK_INTERVAL))
        debug "Elapsed: ${elapsed}s"
    done
}

# Main execution
main() {
    parse_args "$@"
    validate_requirements
    launch_application
    wait_and_minimize
}

main "$@"
