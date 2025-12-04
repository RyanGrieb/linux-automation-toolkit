#!/usr/bin/env bash

# --- CONFIGURATION ---
USER_HOME="$HOME"
export DISPLAY=:0
export XAUTHORITY="$USER_HOME/.Xauthority"
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

LOG_FILE="$USER_HOME/.auto-shutdown.log"
: > "$LOG_FILE"

# Settings
SHUTDOWN_THRESHOLD=1800 # 30 minutes
LOOP_INTERVAL=60        # Check every 60 seconds
MOUSE_DRIFT_TOLERANCE=10

# Temp file to track keyboard activity
KBD_ACTIVITY_FILE="/tmp/auto-shutdown-kbd-timestamp"
touch "$KBD_ACTIVITY_FILE"

# --- CLEANUP TRAP ---
# Ensure we kill the background listener when this script stops
cleanup() {
    echo "$(date): INFO: Stopping background listener..." >> "$LOG_FILE"
    kill $LISTENER_PID 2>/dev/null
    rm -f "$KBD_ACTIVITY_FILE"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# --- BACKGROUND KEYBOARD LISTENER ---
# 1. Listen to X11 Master inputs
# 2. Filter ONLY for "KeyPress" events (Ignore Motion, Release, Properties)
# 3. Touch the timestamp file when a key is pressed
echo "$(date): INFO: Starting X11 KeyPress Listener..." >> "$LOG_FILE"
(
    xinput test-xi2 --root | \
    grep --line-buffered "EVENT type.*(KeyPress)" | \
    while read line; do
        touch "$KBD_ACTIVITY_FILE"
    done
) &
LISTENER_PID=$!

# --- INITIALIZATION ---
custom_timer=0

# Get initial mouse pos
get_mouse_pos() {
    eval $(xdotool getmouselocation --shell 2>/dev/null)
    echo "$X $Y"
}
read prev_X prev_Y <<< $(get_mouse_pos)

# Get initial keyboard timestamp
last_kbd_time=$(stat -c %Y "$KBD_ACTIVITY_FILE")

echo "$(date): INFO: Event-Based Script Started (PID: $$)" >> "$LOG_FILE"

# --- MAIN LOOP ---
while true; do
    # 1. CHECK POWER
    if on_ac_power >/dev/null; then pwr_state="AC"; else pwr_state="BATTERY"; fi

    # 2. CHECK KEYBOARD (Has the timestamp file changed?)
    curr_kbd_time=$(stat -c %Y "$KBD_ACTIVITY_FILE")
    
    # 3. CHECK MOUSE (Distance moved)
    read curr_X curr_Y <<< $(get_mouse_pos)
    diff_x=$((curr_X - prev_X)); diff_x=${diff_x#-}
    diff_y=$((curr_Y - prev_Y)); diff_y=${diff_y#-}
    mouse_dist=$((diff_x + diff_y))

    # --- LOGIC ---

    if [[ "$pwr_state" == "AC" ]]; then
        custom_timer=0
        debug_msg="[AC Power] Safe"

    elif [[ "$curr_kbd_time" -ne "$last_kbd_time" ]]; then
        # The background process touched the file -> Valid KeyPress
        custom_timer=0
        debug_msg="[Activity] KeyPress Detected"
        # Update our tracking timestamp
        last_kbd_time=$curr_kbd_time

    elif [[ "$mouse_dist" -gt "$MOUSE_DRIFT_TOLERANCE" ]]; then
        # Mouse moved significantly
        custom_timer=0
        debug_msg="[Activity] Mouse Moved (${mouse_dist}px)"

    else
        # No KeyPress, No Big Mouse Move
        custom_timer=$((custom_timer + LOOP_INTERVAL))
        debug_msg="[Idle] Timer: ${custom_timer}s"
    fi

    # 4. SHUTDOWN TRIGGER
    if [[ "$pwr_state" == "BATTERY" && "$custom_timer" -ge "$SHUTDOWN_THRESHOLD" ]]; then
        echo "$(date): INFO: Threshold Reached (${custom_timer}s). Shutting down." >> "$LOG_FILE"
        systemctl poweroff >> "$LOG_FILE" 2>&1
        exit 0
    fi

    echo "$(date '+%H:%M:%S'): $debug_msg" >> "$LOG_FILE"

    prev_X=$curr_X
    prev_Y=$curr_Y

    sleep $LOOP_INTERVAL
done