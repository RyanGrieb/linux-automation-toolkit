# Health Monitoring Scripts

Collection of bash scripts for monitoring Linux laptop/system health, including battery status, SMART disk health, USB device status, and temperature monitoring.

## Scripts

### laptop-status.sh

Quick system health overview (2-4 lines) showing battery, disk, SMART status, CPU temperature, and failed services.

#### Features

- **Battery monitoring**: Shows current battery percentage and health capacity
- **Disk health**: Displays root partition usage and SMART disk status
- **Temperature monitoring**: Shows CPU package temperature
- **Service status**: Alerts if systemd services have failed
- **Color-coded output**: Green (OK), yellow (warning), red (critical)
- **Non-intrusive**: Lightweight, quick execution

#### Usage

**One-time check:**

```bash
./laptop-status.sh
```

**Auto-run on shell startup:**
Add to `~/.bashrc`:

```bash
[[ -f ~/Scripts/laptop-status.sh ]] && ~/Scripts/laptop-status.sh
```

**Debug mode:**

```bash
./laptop-status.sh --debug
```

#### Requirements

- `upower` - Battery information (usually pre-installed)
- `smartctl` - Disk SMART monitoring (from `smartmontools`)
- `sensors` - CPU temperature (from `lm-sensors`)
- `systemctl` - Service status (standard on systemd systems)

#### Setup

**Ubuntu/Debian:**

```bash
sudo apt install smartmontools lm-sensors
sudo sensors-detect  # Interactive setup for temperature monitoring
```

**Fedora/RHEL:**

```bash
sudo dnf install smartmontools lm_sensors
sudo sensors-detect
```

**Arch:**

```bash
sudo pacman -S smartmontools lm_sensors
sudo sensors-detect
```

#### SMART Monitoring Permissions

By default, `smartctl` requires root. To run without `sudo`, add:

```bash
echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/smartctl" | sudo tee /etc/sudoers.d/smartctl
```

#### SMART Device Detection

If SMART monitoring shows "N/A", your device may need the `-d sat` flag. Run in debug mode to see the raw output:

```bash
./laptop-status.sh --debug
```

Check which flag your drive needs:

```bash
sudo smartctl -H /dev/sda                # Try without flag
sudo smartctl -d sat -H /dev/sda         # Try with SAT flag
sudo smartctl -d scsi -H /dev/sda        # Try SCSI flag
```

Hardcode the working flag in the script around line 25.

#### Output Examples

**Healthy system:**

```
🔋 Battery: 87% (Health: 98%)
💾 SMART: OK  root: 42% used
🌡 CPU: 52°C
```

**System with warnings:**

```
🔋 Battery: 18% (Health: 72%)
💾 SMART: OK  root: 89% used
⚠ Failed: 1 service(s)
🌡 CPU: 78°C
```

**Critical conditions:**

```
🔋 Battery: 5% (Health: 45%)
💾 SMART: FAIL  root: 95% used
⚠ Failed: 2 service(s)
🌡 CPU: 92°C
```

#### Troubleshooting

**Battery shows N/A:**

```bash
upower -e          # List battery devices
upower -i <device> # Check specific device
```

**SMART shows FAIL:**
Run full SMART diagnostics:

```bash
sudo smartctl -d sat -a /dev/sda 2>&1 | less
```

**Temperature shows N/A:**
Ensure `sensors` is configured:

```bash
sudo sensors-detect --auto
sensors                # Test output
```

---

### check_usb_health.sh

Comprehensive USB health diagnostic showing kernel errors, connected devices, port status, and device information.

#### Features

- **Kernel error tracking**: Shows recent USB-related kernel messages with error count
- **Device listing**: Displays all connected USB devices with vendor/product info
- **Port status**: Shows USB port power status from sysfs
- **Detailed summary**: Device enumeration and error status using `usb-devices`
- **Threshold alerting**: Warns if error count exceeds configurable threshold

#### Usage

```bash
./check_usb_health.sh
```

To monitor continuously:

```bash
watch -n 10 ./check_usb_health.sh
```

To redirect to file:

```bash
./check_usb_health.sh > usb-health-report.txt
```

#### Requirements

- Standard Linux utilities (dmesg, grep, awk)
- `lsusb` - List USB devices (from `usbutils`)
- `usb-devices` - Detailed device info (optional, from `usbutils`)

#### Setup

**Ubuntu/Debian:**

```bash
sudo apt install usbutils
```

#### Configuration

Adjust the error threshold in the script (line 6):

```bash
# Threshold for "bad" messages before we warn
ERROR_THRESHOLD=5
```

Lower values produce more warnings; higher values only warn on serious issues.

#### Output Sections

1. **Recent USB kernel messages** - Last 20 USB-related dmesg entries
2. **Error count** - Number of error/fail/reset messages detected
3. **Connected devices** - Output from `lsusb`
4. **Device details** - Structured summary from `usb-devices`
5. **Port status** - USB port power states from sysfs

#### Example Output

```
=== USB Health Check (Wed Dec  3 14:30:45 PST 2025) ===

1) Recent USB-related kernel messages:
[1234.567] usb 1-1: new high-speed USB device number 5 using xhci_hcd
[1234.789] usb-storage 1-1:1.0: USB Mass Storage device detected

Found 2 USB error-like messages since boot.
✅ USB error count is within normal range.

2) Attached USB devices (lsusb):
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 005: ID 0951:1666 Kingston Technology Data Traveler

3) usb-devices summary:
...
```

#### Troubleshooting

**Too many errors reported:**

- Check kernel logs for actual issues: `dmesg | grep -i usb | tail -50`
- Some systems report benign USB messages; adjust `ERROR_THRESHOLD` accordingly
- Look for patterns in error timestamps to identify problematic devices

**Port status shows "suspended":**

- This is normal for unused USB ports
- Disconnected devices may show as suspended

**usb-devices not installed:**

- Script will skip section 3 gracefully
- Install `usbutils` for detailed output

---

### smart.sh

Wrapper for SMART disk monitoring with enhanced output and diagnostics.

#### Features

- Status check with color-coded output
- Full SMART attribute reporting
- Error log viewing
- Disk information summary
- Support for multiple drives
- Permission handling for non-root users

#### Usage

```bash
./smart.sh              # Show SMART status of all drives
./smart.sh --full       # Full SMART attribute dump
./smart.sh --errors     # Show only error log
```

#### Requirements

- `smartctl` - SMART monitoring utility

#### Setup

Same as laptop-status.sh; see SMART Monitoring Permissions section above.

#### Example Output

```
=== SMART Status for /dev/sda ===
Model: Samsung SSD 970 EVO Plus 500GB
Capacity: 465.76 GB
Status: PASSED ✅

Temperature: 42°C
Power-on hours: 3,250
Reallocated sectors: 0
```

---

## Best Practices

1. **Regular monitoring**: Run `laptop-status.sh` at startup to catch issues early
2. **USB health checks**: Run `check_usb_health.sh` when experiencing device issues
3. **SMART monitoring**: Monitor SMART status weekly; failing drives often show warning signs before complete failure
4. **Temperature tracking**: Watch CPU temps, especially under load; excessive heat indicates cooling problems
5. **Battery health**: Track battery health percentage over time; degradation below 80% may warrant replacement

## Combined Health Check

Create a daily health report:

```bash
#!/bin/bash
echo "=== System Health Report ($(date)) ===" >> ~/system-health.log
echo >> ~/system-health.log
~/Scripts/laptop-status.sh >> ~/system-health.log
echo >> ~/system-health.log
~/Scripts/Health/check_usb_health.sh >> ~/system-health.log
echo >> ~/system-health.log
```

Schedule with cron:

```bash
# Daily at 8 AM
0 8 * * * ~/Scripts/Health/daily-health-check.sh
```

## Troubleshooting Common Issues

### "Permission denied" errors

Most scripts require elevated privileges for certain operations. Use:

```bash
sudo ./script-name.sh
```

Or configure passwordless sudo for specific commands (see individual script sections).

### Scripts show "N/A" for sensors

Install and configure `lm-sensors`:

```bash
sudo sensors-detect --auto
sudo systemctl restart kmod@lm_sensors  # or restart manually
```

### No battery information

Verify UPower is running:

```bash
systemctl --user status upower
upower -e
```

### Kernel messages not updating

Kernel ringbuffer may be small or cleared. Messages older than ringbuffer size won't appear.
