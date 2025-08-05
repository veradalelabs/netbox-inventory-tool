Perfect! Now let's create:
Step 3: Create Examples and Changelog
First, let's create docs/EXAMPLES.md:
markdown# NetBox Inventory Tool - Examples

This document provides real-world examples of the inventory tool's output and common use cases.

## Sample System: Media Server

### Basic Command
```bash
./scripts/netbox_inventory.sh
Complete JSON Output (Excerpt)
json{
  "metadata": {
    "hostname": "tyrannosaurusplex",
    "collection_time": "2025-08-04T22:36:39-07:00",
    "script_version": "2.0.0",
    "format_version": "1.0"
  },
  "system": {
    "hostnamectl": "Static hostname: tyrannosaurusplex\nOperating System: Arch Linux\nKernel: Linux 6.15.9-arch1-1\nArchitecture: x86-64\nHardware Vendor: ASRockRack\nHardware Model: W480D4U"
  },
  "hardware": {
    "cpu": "Intel(R) Xeon(R) W-1270 CPU @ 3.40GHz\n16 cores, 5.0GHz max",
    "memory": "62Gi total, 60Gi available",
    "pci": "NVIDIA Quadro P1000, Intel I210 Gigabit Ethernet..."
  },
  "storage": {
    "mappings": {
      "label_to_device": "18_0:/dev/sdf\n18_1:/dev/sde\n18_2:/dev/sdh...",
      "mount_status": "/dev/sda:mounted:/cache\n/dev/sde:unmounted:-..."
    },
    "health_summary": {
      "smart_health_csv": "device,model,serial,health_status,power_hours,temperature,reallocated_sectors\n/dev/sda,Samsung_SSD_850_EVO_500GB,S3PTNF0JB64511M,PASSED,66248,38,0\n/dev/sdb,ST18000NM000J-2TV103,ZR5FNVPL,PASSED,5919,43,0...",
      "unmounted_drives_csv": "/dev/sde,btrfs,18_1,16.4T\n"
    }
  },
  "network": {
    "interfaces": "enp6s0: 192.168.1.7/24, Docker networks..."
  }
}
Use Case Examples
1. New Server Documentation
Scenario: Setting up a new server in NetBox
bash# Collect inventory
./scripts/netbox_inventory.sh

# Extract key info for NetBox
cat output/inventory_*.json | jq '{
  hostname: .metadata.hostname,
  manufacturer: .system.hostnamectl | split("\n") | map(select(test("Hardware Vendor"))) | .[0] | split(":")[1] | ltrimstr(" "),
  model: .system.hostnamectl | split("\n") | map(select(test("Hardware Model"))) | .[0] | split(":")[1] | ltrimstr(" "),
  cpu_info: .hardware.cpu | split("\n")[0],
  memory: .hardware.memory | split("\n")[0],
  interface_count: (.network.interfaces | split("\n") | length)
}'
Output:
json{
  "hostname": "tyrannosaurusplex",
  "manufacturer": "ASRockRack", 
  "model": "W480D4U",
  "cpu_info": "Intel(R) Xeon(R) W-1270 CPU @ 3.40GHz",
  "memory": "62Gi total, 2.2Gi used, 60Gi available",
  "interface_count": 8
}
2. Storage Health Monitoring
Scenario: Daily health checks for drive monitoring
bash# Extract health data
cat output/inventory_*.json | jq -r '.storage.health_summary.smart_health_csv' > daily_health.csv

# Check for issues
awk -F, 'NR>1 && ($4!="PASSED" || $7>0) {print "ALERT: " $1 " - Status:" $4 " Sectors:" $7}' daily_health.csv
Sample Alert Output:
# No alerts (all drives healthy)
3. Capacity Planning
Scenario: Identifying expansion opportunities
bash# Find unmounted storage
cat output/inventory_*.json | jq -r '.storage.health_summary.unmounted_drives_csv'

# Calculate potential capacity
cat output/inventory_*.json | jq -r '.storage.health_summary.unmounted_drives_csv' | \
awk -F, 'NR>1 {print "Available: " $4 " on " $1 " (" $3 ")"}'
Output:
Available: 16.4T on /dev/sde (18_1)
4. Network Discovery
Scenario: Documenting network interfaces for NetBox
bash# Extract interface details
cat output/inventory_*.json | jq '.network.interfaces' | \
grep -E "(enp|eth)" | grep "inet " | \
awk '{print $2 ": " $5}' | sed 's/addr://'
Output:
enp6s0: 192.168.1.7/24
5. Docker Environment Detection
Scenario: Documenting containerized services
bash# Detect Docker usage
cat output/inventory_*.json | jq '.network.interfaces' | \
grep -c "docker\|br-" && echo "Docker detected" || echo "No Docker"

# Count container networks
cat output/inventory_*.json | jq '.network.interfaces' | \
grep -c "veth" | awk '{print "Active containers: " $1}'
Output:
Docker detected
Active containers: 4
Parsing Examples
Extract Hardware Summary
bashcat output/inventory_*.json | jq '{
  system: {
    hostname: .metadata.hostname,
    os: (.system.hostnamectl | split("\n") | map(select(test("Operating System"))) | .[0] | split(":")[1] | ltrimstr(" ")),
    kernel: (.system.hostnamectl | split("\n") | map(select(test("Kernel"))) | .[0] | split(":")[1] | ltrimstr(" "))
  },
  hardware: {
    cpu_cores: (.hardware.cpu | split("\n") | map(select(test("CPU\\(s\\):"))) | .[0] | split(":")[1] | ltrimstr(" ") | tonumber),
    memory_gb: (.hardware.memory | split("\n")[0] | split(" ")[1] | rtrimstr("Gi") | tonumber),
    storage_drives: (.storage.health_summary.smart_health_csv | split("\n") | length - 2)
  }
}'
Health Status Summary
bashcat output/inventory_*.json | jq -r '.storage.health_summary.smart_health_csv' | \
awk -F, '
NR==1 {print $0}
NR>1 {
  total++
  if($4=="PASSED") passed++
  if($7=="0") good_sectors++
  temp_sum += ($6 != "N/A" ? $6 : 0)
  temp_count += ($6 != "N/A" ? 1 : 0)
}
END {
  print "Total drives: " total
  print "Healthy drives: " passed "/" total
  print "Drives with good sectors: " good_sectors "/" total
  if(temp_count > 0) print "Average temperature: " int(temp_sum/temp_count) "°C"
}'
Storage Mapping Table
bashecho "Device,Label,Filesystem,Mount Status"
cat output/inventory_*.json | jq -r '
.storage.mappings.device_to_label,
.storage.mappings.mount_status
' | paste -d, - - | \
awk -F, '{
  device=$1; label=$2; fs=$3
  mount_device=$4; mount_status=$5; mount_point=$6
  if(device == mount_device) {
    print device "," label "," fs "," mount_status ":" mount_point
  }
}'
Integration Scripts
Simple NetBox Device Creator
python#!/usr/bin/env python3
import json
import sys

def extract_device_info(inventory_file):
    with open(inventory_file, 'r') as f:
        data = json.load(f)
    
    # Extract manufacturer from hostnamectl
    hostnamectl = data['system']['hostnamectl']
    lines = hostnamectl.split('\n')
    
    manufacturer = next((line.split(':', 1)[1].strip() 
                        for line in lines if 'Hardware Vendor' in line), 'Unknown')
    model = next((line.split(':', 1)[1].strip() 
                 for line in lines if 'Hardware Model' in line), 'Unknown')
    
    return {
        'name': data['metadata']['hostname'],
        'manufacturer': manufacturer,
        'model': model,
        'serial': data.get('device', {}).get('serial', ''),
        'cpu': data['hardware']['cpu'].split('\n')[0],
        'memory': data['hardware']['memory'].split('\n')[0]
    }

if __name__ == '__main__':
    device_info = extract_device_info(sys.argv[1])
    print(json.dumps(device_info, indent=2))
Usage:
bashpython3 extract_device.py output/inventory_tyrannosaurusplex_*.json
Health Alert Script
bash#!/bin/bash
# health_monitor.sh - Check for storage issues

INVENTORY_FILE="$1"
ALERT_EMAIL="admin@example.com"

# Extract health data
jq -r '.storage.health_summary.smart_health_csv' "$INVENTORY_FILE" | \
while IFS=, read -r device model serial health hours temp sectors; do
    # Skip header
    [[ "$device" == "device" ]] && continue
    
    # Check for issues
    if [[ "$health" != "PASSED" ]]; then
        echo "CRITICAL: $device health status: $health"
        # mail -s "Storage Alert: $device" "$ALERT_EMAIL" <<< "Drive $device failed health check"
    fi
    
    if [[ "$sectors" -gt 0 ]]; then
        echo "WARNING: $device has $sectors reallocated sectors"
    fi
    
    if [[ "$temp" != "N/A" && "$temp" -gt 50 ]]; then
        echo "WARNING: $device temperature high: ${temp}°C"
    fi
done
Common Queries
Find All Network Interfaces
bashcat output/inventory_*.json | jq -r '.network.interfaces' | \
grep -E '^[0-9]+:' | awk '{print $2}' | sed 's/:$//'
Get Storage Summary
bashcat output/inventory_*.json | jq -r '
"Total Storage Devices: " + (.storage.health_summary.smart_health_csv | split("\n") | length - 2 | tostring),
"Mounted Filesystems: " + (.storage.mappings.mount_status | split("\n") | map(select(test(":mounted:"))) | length | tostring),
"Unmounted Drives: " + (.storage.health_summary.unmounted_drives_csv | split("\n") | length - 2 | tostring)
'
Extract All Hardware Details
bashcat output/inventory_*.json | jq '{
  hostname: .metadata.hostname,
  collection_time: .metadata.collection_time,
  cpu_model: (.hardware.cpu | split("\n")[1] | split(":")[1] | ltrimstr(" ")),
  total_memory: (.hardware.memory | split("\n")[0] | split(" ")[1]),
  network_interfaces: [.network.interfaces | split("\n")[] | select(test("^[0-9]+:")) | split(":")[1] | ltrimstr(" ")],
  storage_health: (.storage.health_summary.smart_health_csv | split("\n")[1:] | map(select(length > 0) | split(",")) | map({device: .[0], model: .[1], health: .[3]}))
}'