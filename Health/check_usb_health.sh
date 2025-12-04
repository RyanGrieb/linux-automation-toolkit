#!/usr/bin/env bash
#
# check_usb_health.sh
# Reports USB errors, device list, and port status.

# Threshold for “bad” messages before we warn
ERROR_THRESHOLD=5

echo "=== USB Health Check ($(date)) ==="
echo

# 1) Kernel USB errors via dmesg
echo "1) Recent USB-related kernel messages:"
dmesg | grep -i usb | tail -n 20
echo

# Count critical USB error keywords
ERROR_COUNT=$(dmesg | grep -i usb | egrep -i "error|fail|reset|over-current|stall" | wc -l)
echo "Found $ERROR_COUNT USB error-like messages since boot."

if (( ERROR_COUNT > ERROR_THRESHOLD )); then
  echo "⚠️  Warning: High number of USB errors detected (> $ERROR_THRESHOLD)."
else
  echo "✅ USB error count is within normal range."
fi
echo

# 2) List all connected USB devices
echo "2) Attached USB devices (lsusb):"
lsusb
echo

# 3) Detailed device status via usb-devices (if available)
if command -v usb-devices &>/dev/null; then
  echo "3) usb-devices summary:"
  usb-devices | awk '
    BEGIN { RS=""; FS="\n" }
    /T:  Bus=/ {
      for(i=1;i<=NF;i++) {
        if ($i ~ /T:  Bus=/) print "\n" $i
        if ($i ~ /D:/)      print " " $i
        if ($i ~ /Err/)     print "   Status:" $i
      }
    }'
else
  echo "3) usb-devices not installed; skipping detailed summary."
fi
echo

# 4) USB port power/status (sysfs)
echo "4) USB port power/status:"
for PORT in /sys/bus/usb/devices/*/power/; do
  DEV=$(basename "$(dirname "$PORT")")
  STATUS_FILE="$PORT/status"
  if [[ -f "$STATUS_FILE" ]]; then
    STAT=$(cat "$STATUS_FILE")
    echo "  Port $DEV: $STAT"
  fi
done
echo

echo "=== End of USB Health Check ==="
