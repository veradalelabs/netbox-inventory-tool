# NetBox System Inventory Tool

A comprehensive system inventory collection tool designed for NetBox CMDB integration. Automatically discovers and documents hardware, storage, network interfaces, and health status across Linux systems.

## Features

### System Information
- Hardware specifications (CPU, memory, motherboard)
- Operating system and kernel details
- System uptime and load information
- PCI device enumeration

### Enhanced Storage Analysis
- Block device discovery with filesystem mapping
- Storage label-to-device mapping
- SMART health monitoring for all drives
- Unmounted drive detection
- BTRFS/ext4/XFS filesystem health checks

### Network Discovery
- Network interface enumeration with MAC addresses
- IP address and routing information
- Docker network detection

### Health Monitoring
- Drive health status in CSV format
- Filesystem error detection
- Unmounted storage identification
- Temperature and reallocated sector monitoring

## Quick Start

```bash
# Clone the repository
git clone https://github.com/veradalelabs/netbox-inventory-tool.git
cd netbox-inventory-tool

# Make the script executable
chmod +x scripts/netbox_inventory.sh

# Run inventory collection
./scripts/netbox_inventory.sh

# View results
ls -la output/
cat output/inventory_$(hostname)_*.json | jq .
Output Formats

JSON: Complete system inventory (default)
CSV: Health data for easy import
Log files: Collection process details

Requirements
Required

Linux system with bash 4.0+
Basic system commands (lscpu, free, df, lsblk, etc.)

Optional (Enhanced Features)

smartmontools - For drive health monitoring
jq - For JSON formatting and querying
sudo access - For hardware queries and SMART data

Installation on Common Distributions
bash# Arch Linux
sudo pacman -S smartmontools jq

# Ubuntu/Debian
sudo apt install smartmontools jq

# RHEL/CentOS
sudo yum install smartmontools jq
Sample Output
System Overview
json{
  "metadata": {
    "hostname": "server01",
    "collection_time": "2025-08-04T22:36:39-07:00",
    "script_version": "2.0.0"
  },
  "hardware": {
    "cpu": "Intel(R) Xeon(R) W-1270 CPU @ 3.40GHz",
    "memory": "64GB"
  }
}
Health Summary (CSV Format)
csvdevice,model,serial,health_status,power_hours,temperature,reallocated_sectors
/dev/sda,Samsung_SSD_850_EVO,S3PTNF0JB64511M,PASSED,66248,38,0
/dev/sdb,ST18000NM000J,ZR5FNVPL,PASSED,5919,43,0
NetBox Integration
The tool generates structured data perfect for NetBox import:

Device Information: Hardware specs for device creation
Interface Data: Network interfaces with MAC addresses
Storage Inventory: Drive details and health status
Health Monitoring: CSV data for ongoing monitoring

See docs/NETBOX_INTEGRATION.md for detailed import instructions.
Project Structure
netbox-inventory-tool/
├── scripts/           # Main inventory script
├── docs/             # Documentation and guides
├── examples/         # Sample outputs
├── output/           # Generated inventory files
└── README.md         # This file
Contributing

Fork the repository
Create a feature branch: git checkout -b feature/new-feature
Make your changes and test thoroughly
Update documentation as needed
Submit a pull request

License
MIT License - see LICENSE file for details
Support

🐛 Issues: Report bugs via GitHub Issues
📖 Documentation: Check the docs/ folder
💬 Discussions: Use GitHub Discussions for questions

Changelog
v2.0.0 (Latest)

Enhanced storage analysis with device mapping
SMART health monitoring
CSV output for easy import
Comprehensive block device discovery
Filesystem health checks

v1.0.0

Basic system inventory collection
JSON output format
Initial NetBox compatibility

