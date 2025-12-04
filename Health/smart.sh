#!/bin/bash

# Disk SMART Health Check Script for Linux Mint

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Root privileges required.${NC}"
    echo -e "${YELLOW}Usage: sudo $0${NC}"
    exit 1
fi

# Install smartmontools if missing
if ! command -v smartctl &> /dev/null; then
    echo -e "${YELLOW}smartctl not found. Installing smartmontools...${NC}"
    apt update && apt install -y smartmontools
    if [ $? -ne 0 ]; then
        echo -e "${RED}Installation failed. Run: sudo apt install smartmontools${NC}"
        exit 1
    fi
fi

echo -e "${CYAN}=== Disk SMART Health Check ===${NC}"
echo

# Find all disk drives (exclude non-SMART devices like SD cards, loop devices)
disks=$(lsblk -d -n -o NAME,TYPE,RO | grep '^[shvn][dav]' | grep -v '^loop' | awk '$3=="0" {print "/dev/"$1}')

if [ -z "$disks" ]; then
    echo -e "${YELLOW}No SMART-capable disks detected.${NC}"
    echo "Common devices checked: SATA, NVMe, Virtual drives"
    echo "Excluded: SD cards (mmcblk), loop devices, RAM disks"
    exit 0
fi

echo -e "${GREEN}Found $(echo $disks | wc -w) disk(s) to analyze...${NC}"
echo

issues=0
warnings=0

# Process each disk
for disk in $disks; do
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  Disk: $disk${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Get disk info
    info=$(smartctl -i "$disk" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Note: Cannot access $disk (may not support SMART)${NC}"
        continue  # Don't count as critical issue
    fi
    
    # Basic information
    model=$(echo "$info" | grep -E "Device Model|Model Number" | cut -d: -f2 | xargs)
    serial=$(echo "$info" | grep "Serial Number" | cut -d: -f2 | xargs)
    capacity=$(echo "$info" | grep "User Capacity" | cut -d: -f2 | xargs | cut -d'[' -f1)
    
    [ -n "$model" ] && echo "Model: $model"
    [ -n "$serial" ] && echo "Serial: $serial"
    [ -n "$capacity" ] && echo "Capacity: $capacity"
    
    # Check SMART support
    if ! echo "$info" | grep -q "SMART support is:.*Available"; then
        echo -e "${YELLOW}⚠ SMART not available on this device${NC}"
        continue
    fi
    
    # Enable SMART if disabled
    if ! echo "$info" | grep -q "SMART support is:.*Enabled"; then
        echo -e "${YELLOW}→ Enabling SMART...${NC}"
        smartctl -s on "$disk" > /dev/null 2>&1
        sleep 1
    fi
    
    # Health status
    health=$(smartctl -H "$disk" 2>/dev/null | grep "SMART overall-health" | cut -d: -f2 | xargs)
    if [[ "$health" == "PASSED" ]]; then
        echo -e "Health Status: ${GREEN}✓ PASSED${NC}"
    elif [[ -n "$health" ]]; then
        echo -e "Health Status: ${RED}✗ FAILED${NC}"
        issues=$((issues + 1))
    else
        echo -e "${YELLOW}⚠ Health status unavailable${NC}"
    fi
    
    # Get SMART attributes
    attrs=$(smartctl -A "$disk" 2>/dev/null)
    
    # Check disk type and process accordingly
    if [[ $disk =~ nvme ]]; then
        # NVMe drive processing
        temp=$(echo "$attrs" | grep "Temperature:" | awk '{print $2}')
        if [ -n "$temp" ]; then
            if [ "$temp" -ge 70 ]; then
                echo -e "Temperature: ${RED}${temp}°C ⚠ High${NC}"
                issues=$((issues + 1))
            elif [ "$temp" -ge 60 ]; then
                echo -e "Temperature: ${YELLOW}${temp}°C ⚠ Warm${NC}"
                warnings=$((warnings + 1))
            else
                echo -e "Temperature: ${GREEN}${temp}°C${NC}"
            fi
        fi
        
        # Endurance
        percent_used=$(echo "$attrs" | grep "Percentage Used" | awk '{print $3}')
        if [ -n "$percent_used" ]; then
            if [ "$percent_used" -ge 95 ]; then
                echo -e "Endurance Used: ${RED}${percent_used}% ⚠${NC}"
                issues=$((issues + 1))
            elif [ "$percent_used" -ge 80 ]; then
                echo -e "Endurance Used: ${YELLOW}${percent_used}% ⚠${NC}"
                warnings=$((warnings + 1))
            else
                echo -e "Endurance Used: ${GREEN}${percent_used}%${NC}"
            fi
        fi
        
        # Critical warning
        crit_warn=$(echo "$attrs" | grep "Critical Warning" | awk '{print $3}')
        if [ -n "$crit_warn" ] && [ "$crit_warn" != "0x00" ]; then
            echo -e "${RED}✗ Critical Warning: $crit_warn${NC}"
            issues=$((issues + 1))
        fi
        
        # Available spare
        spare=$(echo "$attrs" | grep "Available Spare" | head -1 | awk '{print $3}')
        spare_thresh=$(echo "$attrs" | grep "Available Spare Threshold" | awk '{print $4}')
        if [ -n "$spare" ] && [ -n "$spare_thresh" ]; then
            if [ "$spare" -lt "$spare_thresh" ]; then
                echo -e "${RED}✗ Available Spare: ${spare}% (below threshold: ${spare_thresh}%)${NC}"
                issues=$((issues + 1))
            else
                echo -e "Available Spare: ${GREEN}${spare}%${NC}"
            fi
        fi
        
    else
        # SATA drive processing
        temp=$(echo "$attrs" | grep "Temperature_Celsius" | awk '{print $10}')
        if [ -n "$temp" ]; then
            if [ "$temp" -ge 50 ]; then
                echo -e "Temperature: ${RED}${temp}°C ⚠ High${NC}"
                issues=$((issues + 1))
            elif [ "$temp" -ge 45 ]; then
                echo -e "Temperature: ${YELLOW}${temp}°C ⚠ Warm${NC}"
                warnings=$((warnings + 1))
            else
                echo -e "Temperature: ${GREEN}${temp}°C${NC}"
            fi
        fi
        
        # Process key attributes
        echo
        echo -e "${CYAN}Critical Attributes:${NC}"
        
        # Function to check attribute
        check_attr() {
            local id=$1
            local name=$2
            local line=$(echo "$attrs" | awk -v id="$id" '$1 == id')
            local value=$(echo "$line" | awk '{print $10}')
            
            [ -z "$value" ] && return
            
            case $id in
                5|197|198|10)  # Attributes that should be zero
                    if [ "$value" -gt 0 ]; then
                        echo -e "  ${RED}✗ $name: $value${NC}"
                        issues=$((issues + 1))
                    else
                        echo -e "  ${GREEN}✓ $name: $value${NC}"
                    fi
                    ;;
                *)
                    echo "  $name: $value"
                    ;;
            esac
        }
        
        check_attr "5" "Reallocated Sectors"
        check_attr "197" "Current Pending Sectors"
        check_attr "198" "Uncorrectable Errors"
        check_attr "10" "Spin Retry Count"
        
        # Power on hours
        hours_line=$(echo "$attrs" | awk '$1 == 9')
        if [ -n "$hours_line" ]; then
            hours=$(echo "$hours_line" | awk '{print $10}')
            days=$((hours / 24))
            years=$((days / 365))
            remaining=$((days % 365))
            echo "  Power On Time: ${years}y ${remaining}d"
        fi
        
        # Power cycles
        cycles=$(echo "$attrs" | awk '$1 == 12 {print $10}')
        [ -n "$cycles" ] && echo "  Power Cycles: $cycles"
    fi
    
    # Self-test log
    echo
    last_test=$(smartctl -l selftest "$disk" 2>/dev/null | grep "# 1" | head -1)
    if echo "$last_test" | grep -q "Completed without error" 2>/dev/null; then
        echo -e "${GREEN}✓ Last self-test: PASSED${NC}"
    elif [ -n "$last_test" ]; then
        echo -e "${YELLOW}⚠ Last self-test: $(echo "$last_test" | cut -d' ' -f5- | xargs)${NC}"
        warnings=$((warnings + 1))
    else
        echo -e "${YELLOW}⚠ No self-test history${NC}"
        warnings=$((warnings + 1))
    fi
    
    echo
done

# --- Summary ---
echo -e "${CYAN}=== Summary Report ===${NC}"
echo

if [ $issues -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✓ All disks are healthy!${NC}"
elif [ $issues -eq 0 ]; then
    echo -e "${YELLOW}⚠ Found $warnings warning(s) (no critical issues)${NC}"
else
    echo -e "${RED}✗ Found $issues critical issue(s) requiring immediate attention${NC}"
    [ $warnings -gt 0 ] && echo -e "${YELLOW}⚠ And $warnings warning(s)${NC}"
fi

echo
echo -e "${CYAN}--- Additional Commands ---${NC}"
echo -e "Detailed info:   ${BLUE}sudo smartctl -a /dev/sdX${NC}"
echo -e "Short self-test: ${BLUE}sudo smartctl -t short /dev/sdX${NC}"
echo -e "Long self-test:  ${BLUE}sudo smartctl -t long /dev/sdX${NC}"
echo -e "View test log:   ${BLUE}sudo smartctl -l selftest /dev/sdX${NC}"
echo

exit 0