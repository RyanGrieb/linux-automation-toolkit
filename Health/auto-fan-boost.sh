#!/bin/bash

# Configuration
HIGH_TEMP_THRESHOLD=85
LOW_TEMP_THRESHOLD=75
FAN_BOOST_RPM_THRESHOLD=5000
CHECK_INTERVAL=5
FAN_BOOST_SCRIPT="$(dirname "$0")/fan-boost.sh"

DEBUG=false

# Check arguments
if [[ "$1" == "--debug" ]]; then
    DEBUG=true
    echo "🐛 Debug mode enabled"
fi

# Function to get CPU temperature (borrowed/adapted from cpu-temp.sh)
get_cpu_temp() {
    local temp
    # Try using sensors first
    temp=$(sensors 2>/dev/null | awk '/Package id 0/ {print $4}' | tr -d '+°C' | head -n1)
    
    # Fallback to sysfs if sensors fails or returns empty
    if [[ -z "$temp" && -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
    fi
    
    # Truncate decimal part if present (52.0 -> 52)
    temp=$(echo "$temp" | cut -d. -f1)

    # Ensure we got a number, otherwise default to safe low value to prevent errors
    if [[ ! "$temp" =~ ^[0-9]+$ ]]; then
        log_debug "Invalid temperature value in get_cpu_temp: $temp"
        echo "0"
    else
        echo "$temp"
    fi
}

# Function to log debug messages
log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo "DEBUG: $1" >&2
    fi
}

# Main Loop
echo "Starting Auto Fan Boost Monitor..."
echo "Thresholds: Enable > ${HIGH_TEMP_THRESHOLD}°C, Disable < ${LOW_TEMP_THRESHOLD}°C"

while true; do
    # 1. Get current state
    CURRENT_TEMP=$(get_cpu_temp)
    
    # Read fan speed
    if [[ -f "/proc/acpi/ibm/fan" ]]; then
        CURRENT_RPM=$(awk '/speed:/ {print $2}' "/proc/acpi/ibm/fan")
        CURRENT_RPM=${CURRENT_RPM:-0}
    else
        echo "Error: /proc/acpi/ibm/fan not found. Is thinkpad_acpi loaded?"
        CURRENT_RPM=0
    fi

    # 2. Logic
    log_debug "Temp: ${CURRENT_TEMP}°C, Fan: ${CURRENT_RPM} RPM"

    if [[ "$CURRENT_TEMP" -ge "$HIGH_TEMP_THRESHOLD" ]]; then
        # High Temp Condition
        if [[ "$CURRENT_RPM" -lt "$FAN_BOOST_RPM_THRESHOLD" ]]; then
            echo "🔥 Temp high ($CURRENT_TEMP°C). Engaging Fan Boost..."
            sudo "$FAN_BOOST_SCRIPT"
        else
            log_debug "Temp high ($CURRENT_TEMP°C), but fan already boosted."
        fi
        
    elif [[ "$CURRENT_TEMP" -le "$LOW_TEMP_THRESHOLD" ]]; then
        # Low Temp Condition
        if [[ "$CURRENT_RPM" -gt "$FAN_BOOST_RPM_THRESHOLD" ]]; then
            echo "❄️ Temp low ($CURRENT_TEMP°C). Disabling Fan Boost..."
            sudo "$FAN_BOOST_SCRIPT"
        else
             log_debug "Temp low ($CURRENT_TEMP°C), but fan already normal."
        fi
    fi

    sleep "$CHECK_INTERVAL"
done
