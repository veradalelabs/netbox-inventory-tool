#!/bin/bash

# NetBox System Inventory Collection Tool
# Version: 1.0.0
# A clean, maintainable approach to system inventory

set -euo pipefail

# Configuration
SCRIPT_VERSION="1.0.0"
OUTPUT_DIR="./output"
OUTPUT_FORMAT="${1:-json}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)
OUTPUT_FILE="${OUTPUT_DIR}/inventory_${HOSTNAME}_${TIMESTAMP}"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${OUTPUT_FILE}.log"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Data collection functions
collect_system_info() {
    log "=== System Information ==="
    
    HOSTNAMECTL_OUTPUT=$(hostnamectl 2>/dev/null || echo "N/A")
    UNAME_OUTPUT=$(uname -a 2>/dev/null || echo "N/A")
    UPTIME_OUTPUT=$(uptime 2>/dev/null || echo "N/A")
}

collect_hardware_info() {
    log "=== Hardware Information ==="
    
    LSCPU_OUTPUT=$(lscpu 2>/dev/null || echo "N/A")
    MEMORY_OUTPUT=$(free -h 2>/dev/null || echo "N/A")
    LSPCI_OUTPUT=$(lspci 2>/dev/null || echo "N/A")
}

collect_storage_info() {
    log "=== Storage Information ==="
    
    # Basic storage info
    DF_OUTPUT=$(df -h 2>/dev/null || echo "N/A")
    MOUNT_OUTPUT=$(mount 2>/dev/null || echo "N/A")
    
    # Enhanced block device information
    log "Collecting block device information"
    LSBLK_BASIC=$(lsblk 2>/dev/null || echo "N/A")
    LSBLK_DETAILED=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,UUID,LABEL 2>/dev/null || echo "N/A")
    LSBLK_FILESYSTEMS=$(lsblk -f 2>/dev/null || echo "N/A")
    
    # Block device UUIDs and labels
    log "Collecting device labels and UUIDs"
    BLKID_OUTPUT=$(blkid 2>/dev/null || echo "N/A")
    
    # SMART data collection
    SMART_OUTPUT=""
    if command_exists smartctl; then
        for device in /dev/sd* /dev/nvme*; do
            if [ -b "$device" ] && [[ ! "$device" =~ [0-9]$ ]]; then
                log "Collecting SMART data for $device"
                SMART_OUTPUT+="\n=== SMART Data for $device ===\n"
                SMART_OUTPUT+="$(sudo smartctl -a "$device" 2>/dev/null || echo "Failed to read $device")\n"
            fi
        done
    fi
}

collect_network_info() {
    log "=== Network Information ==="
    
    IP_ADDR_OUTPUT=$(ip addr show 2>/dev/null || echo "N/A")
    IP_ROUTE_OUTPUT=$(ip route show 2>/dev/null || echo "N/A")
}

collect_label_mappings() {
    log "=== Storage Label Mappings ==="
    
    # Create explicit label to device mapping
    LABEL_MAPPINGS=""
    MISSING_LABELS=""
    
    # Check for any labeled devices (not just specific ones)
    if command_exists blkid; then
        # Get all labeled devices
        while read -r device label; do
            if [ -n "$device" ] && [ -n "$label" ]; then
                LABEL_MAPPINGS+="$label:$device\n"
                log "Found label $label on device $device"
            fi
        done < <(blkid -o export | awk '/^DEVNAME=/ {dev=$0; sub(/DEVNAME=/, "", dev)} /^LABEL=/ {label=$0; sub(/LABEL=/, "", label); if(dev && label) print dev, label}' 2>/dev/null || true)
        
        # If no labels found, note that
        if [ -z "$LABEL_MAPPINGS" ]; then
            MISSING_LABELS+="No labeled filesystems found\n"
            log "No filesystem labels detected on this system"
        fi
    fi
    
    # Create device to label reverse mapping
    DEVICE_MAPPINGS=""
    for device in /dev/sd* /dev/nvme*; do
        if [ -b "$device" ] && [[ ! "$device" =~ [0-9]$ ]]; then
            label=$(blkid -s LABEL -o value "$device" 2>/dev/null || echo "unlabeled")
            uuid=$(blkid -s UUID -o value "$device" 2>/dev/null || echo "no-uuid")
            fstype=$(blkid -s TYPE -o value "$device" 2>/dev/null || echo "unknown")
            
            DEVICE_MAPPINGS+="$device:${label}:${fstype}:${uuid}\n"
            log "Device $device has label '${label}' type '${fstype}'"
        fi
    done
    
    # Create mount status mapping
    MOUNT_STATUS=""
    for device in /dev/sd* /dev/nvme*; do
        if [ -b "$device" ] && [[ ! "$device" =~ [0-9]$ ]]; then
            if mount | grep -q "^$device " 2>/dev/null; then
                mountpoint=$(mount | grep "^$device " | awk '{print $3}' | head -1)
                MOUNT_STATUS+="$device:mounted:$mountpoint\n"
            else
                MOUNT_STATUS+="$device:unmounted:-\n"
            fi
        fi
    done
}

collect_storage_health() {
    log "=== Essential Storage Health ==="
    
    # Basic SMART health status for all drives
    SMART_HEALTH=""
    if command_exists smartctl; then
        SMART_HEALTH+="device,model,serial,health_status,power_hours,temperature,reallocated_sectors\n"
        
        for device in /dev/sd* /dev/nvme*; do
            if [ -b "$device" ] && [[ ! "$device" =~ [0-9]$ ]]; then
                model=$(smartctl -i "$device" 2>/dev/null | grep "Device Model:" | cut -d: -f2- | xargs | tr ' ' '_' || echo "Unknown")
                serial=$(smartctl -i "$device" 2>/dev/null | grep "Serial Number:" | cut -d: -f2- | xargs || echo "Unknown")
                health=$(smartctl -H "$device" 2>/dev/null | grep "overall-health" | cut -d: -f2- | xargs || echo "Unknown")
                power_hours=$(smartctl -A "$device" 2>/dev/null | grep "Power_On_Hours" | awk '{print $10}' || echo "N/A")
                temp=$(smartctl -A "$device" 2>/dev/null | grep "Temperature_Celsius" | awk '{print $10}' || echo "N/A")
                reallocated=$(smartctl -A "$device" 2>/dev/null | grep "Reallocated_Sector_Ct" | awk '{print $10}' || echo "N/A")
                
                SMART_HEALTH+="$device,$model,$serial,$health,$power_hours,$temp,$reallocated\n"
            fi
        done
    else
        SMART_HEALTH+="device,model,serial,health_status,power_hours,temperature,reallocated_sectors\n"
        SMART_HEALTH+="# smartctl not available - install smartmontools for drive health data\n"
    fi
    
    # Basic filesystem health (errors, read-only status) - improved error handling
    FILESYSTEM_HEALTH=""
    if mount | grep -E "^/dev" >/dev/null 2>&1; then
        while read -r device mountpoint fstype; do
            # Skip empty lines
            [ -z "$device" ] && continue
            
            if [ "$fstype" = "btrfs" ] && command_exists btrfs; then
                errors=$(btrfs device stats "$mountpoint" 2>/dev/null | grep -c -E "(read_io_errs|write_io_errs|flush_io_errs)" 2>/dev/null || echo "0")
                FILESYSTEM_HEALTH+="$device,$mountpoint,$fstype,errors:$errors\n"
            elif [ "$fstype" = "ext4" ] || [ "$fstype" = "ext3" ] || [ "$fstype" = "ext2" ]; then
                readonly_status=$(mount | grep "$device" | grep -o "ro," 2>/dev/null || echo "rw,")
                FILESYSTEM_HEALTH+="$device,$mountpoint,$fstype,status:${readonly_status%,}\n"
            elif [ "$fstype" = "xfs" ]; then
                readonly_status=$(mount | grep "$device" | grep -o "ro," 2>/dev/null || echo "rw,")
                FILESYSTEM_HEALTH+="$device,$mountpoint,$fstype,status:${readonly_status%,}\n"
            elif [ "$fstype" = "vfat" ] || [ "$fstype" = "ntfs" ]; then
                readonly_status=$(mount | grep "$device" | grep -o "ro," 2>/dev/null || echo "rw,")
                FILESYSTEM_HEALTH+="$device,$mountpoint,$fstype,status:${readonly_status%,}\n"
            else
                # Handle any other filesystem types
                FILESYSTEM_HEALTH+="$device,$mountpoint,$fstype,status:detected\n"
            fi
        done < <(mount | grep -E "^/dev" | awk '{print $1, $3, $5}' 2>/dev/null || true)
    fi
    
    # Unmounted drives summary - with better error handling
    UNMOUNTED_DRIVES=""
    for device in /dev/sd* /dev/nvme*; do
        # Check if device exists and is a block device
        if [ -b "$device" ] && [[ ! "$device" =~ [0-9]$ ]]; then
            if ! mount | grep -q "^$device " 2>/dev/null; then
                fstype=$(blkid -s TYPE -o value "$device" 2>/dev/null || echo "unknown")
                label=$(blkid -s LABEL -o value "$device" 2>/dev/null || echo "unlabeled")
                size=$(lsblk -d -o SIZE "$device" 2>/dev/null | tail -1 | xargs || echo "unknown")
                UNMOUNTED_DRIVES+="$device,$fstype,$label,$size\n"
            fi
        fi
    done
}


# JSON generation
generate_json() {
    log "Generating JSON output"
    
    cat > "${OUTPUT_FILE}.json" << JSON_EOF
{
  "metadata": {
    "hostname": "$HOSTNAME",
    "collection_time": "$(date -Iseconds)",
    "script_version": "$SCRIPT_VERSION",
    "format_version": "1.0"
  },
  "system": {
    "hostnamectl": $(echo "$HOSTNAMECTL_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$HOSTNAMECTL_OUTPUT\""),
    "uname": $(echo "$UNAME_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$UNAME_OUTPUT\""),
    "uptime": $(echo "$UPTIME_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$UPTIME_OUTPUT\"")
  },
  "hardware": {
    "cpu": $(echo "$LSCPU_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$LSCPU_OUTPUT\""),
    "memory": $(echo "$MEMORY_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$MEMORY_OUTPUT\""),
    "pci": $(echo "$LSPCI_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$LSPCI_OUTPUT\"")
  },
  "storage": {
    "filesystems": $(echo "$DF_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$DF_OUTPUT\""),
    "mounts": $(echo "$MOUNT_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$MOUNT_OUTPUT\""),
    "block_devices": {
      "basic": $(echo "$LSBLK_BASIC" | jq -Rs . 2>/dev/null || echo "\"$LSBLK_BASIC\""),
      "detailed": $(echo "$LSBLK_DETAILED" | jq -Rs . 2>/dev/null || echo "\"$LSBLK_DETAILED\""),
      "filesystems": $(echo "$LSBLK_FILESYSTEMS" | jq -Rs . 2>/dev/null || echo "\"$LSBLK_FILESYSTEMS\"")
    },
    "device_labels": $(echo "$BLKID_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$BLKID_OUTPUT\""),
    "mappings": {
      "label_to_device": $(echo -e "$LABEL_MAPPINGS" | jq -Rs . 2>/dev/null || echo "\"$LABEL_MAPPINGS\""),
      "device_to_label": $(echo -e "$DEVICE_MAPPINGS" | jq -Rs . 2>/dev/null || echo "\"$DEVICE_MAPPINGS\""),
      "mount_status": $(echo -e "$MOUNT_STATUS" | jq -Rs . 2>/dev/null || echo "\"$MOUNT_STATUS\""),
      "missing_labels": $(echo -e "$MISSING_LABELS" | jq -Rs . 2>/dev/null || echo "\"$MISSING_LABELS\"")
    },
    "smart_data": $(echo -e "$SMART_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$SMART_OUTPUT\"")
  },
  "network": {
    "interfaces": $(echo "$IP_ADDR_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$IP_ADDR_OUTPUT\""),
    "routes": $(echo "$IP_ROUTE_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$IP_ROUTE_OUTPUT\"")
  },
  "health_summary": {
      "smart_health_csv": $(echo -e "$SMART_HEALTH" | jq -Rs . 2>/dev/null || echo "\"$SMART_HEALTH\""),
      "filesystem_health_csv": $(echo -e "$FILESYSTEM_HEALTH" | jq -Rs . 2>/dev/null || echo "\"$FILESYSTEM_HEALTH\""),
      "unmounted_drives_csv": $(echo -e "$UNMOUNTED_DRIVES" | jq -Rs . 2>/dev/null || echo "\"$UNMOUNTED_DRIVES\"")
    }
}
JSON_EOF
}

# Main execution
main() {
    log "Starting NetBox inventory collection"
    log "Hostname: $HOSTNAME"
    log "Output format: $OUTPUT_FORMAT"
    
    # Collect all data
    collect_system_info
    collect_hardware_info
    collect_storage_info
    collect_network_info
    collect_label_mappings
    collect_storage_health
    
    # Generate output
    case "$OUTPUT_FORMAT" in
        "json")
            generate_json
            ;;
        *)
            log "Unsupported format: $OUTPUT_FORMAT"
            exit 1
            ;;
    esac
    
    log "Collection completed successfully"
    log "Output file: ${OUTPUT_FILE}.json"
    ls -la "${OUTPUT_FILE}".* 2>/dev/null || true
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
