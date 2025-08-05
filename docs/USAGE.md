# Usage Guide

## Basic Usage

```bash
./scripts/netbox_inventory.sh [format]
Supported Formats

json (default) - JSON format suitable for NetBox API
More formats coming soon (yaml, csv)

Requirements
Required

Linux system with bash 4.0+
Basic system commands (lscpu, free, df, etc.)

Optional

smartmontools for drive health data
jq for cleaner JSON formatting
sudo access for hardware queries

Output
The script generates files in the output/ directory:

inventory_hostname_timestamp.json - Main inventory data
inventory_hostname_timestamp.log - Collection log

Examples
Basic system inventory
bash./scripts/netbox_inventory.sh
View generated files
bashls -la output/
cat output/inventory_*.json | jq .
