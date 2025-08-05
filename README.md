# NetBox Inventory Tool

A comprehensive system inventory collection tool for NetBox CMDB integration.

## Features
- Hardware information collection (CPU, memory, storage)
- SMART drive health monitoring
- Network interface enumeration
- Block device and filesystem mapping
- JSON output for NetBox API integration

## Usage
```bash
./scripts/netbox_inventory.sh [format]
Supported formats: json (default), yaml, csv
Output

Structured data files for NetBox import
Raw system data preservation
Health and status reports

Requirements

Linux system with bash
sudo access for hardware queries
Optional: smartmontools, lm-sensors

