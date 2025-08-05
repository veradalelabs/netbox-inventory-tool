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
    "smart_data": $(echo -e "$SMART_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$SMART_OUTPUT\"")
  },,
  "network": {
    "interfaces": $(echo "$IP_ADDR_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$IP_ADDR_OUTPUT\""),
    "routes": $(echo "$IP_ROUTE_OUTPUT" | jq -Rs . 2>/dev/null || echo "\"$IP_ROUTE_OUTPUT\"")
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
