# NetBox Integration Guide

This guide explains how to use the inventory tool's output with NetBox for CMDB population and ongoing monitoring.

## Overview

The NetBox Inventory Tool generates structured data in multiple formats:
- **JSON**: Complete system inventory for comprehensive import
- **CSV**: Health data for monitoring and alerting
- **Mappings**: Device relationships and configurations

## Data Structure

### Device Information
```json
{
  "device": {
    "hostname": "server01",
    "manufacturer": "ASRockRack", 
    "model": "W480D4U",
    "serial": "ABC123456"
  },
  "hardware": {
    "cpu": {...},
    "memory": {...}
  }
}
Health Data (CSV)
csvdevice,model,serial,health_status,power_hours,temperature,reallocated_sectors
/dev/sda,Samsung_SSD_850,S3PTNF0JB64511M,PASSED,66248,38,0
NetBox Import Methods
Method 1: Manual Device Creation

Create Device Type (if not exists)

Manufacturer: Extract from hardware.manufacturer
Model: Use hardware.model
Height: 1U (or appropriate)


Create Device

Name: Use metadata.hostname
Device Type: From step 1
Serial: From device.serial


Add Interfaces

Extract from network.interfaces
Include MAC addresses and IP assignments



Method 2: API Import Script
python#!/usr/bin/env python3
import json
import requests

def import_device(inventory_file, netbox_url, token):
    with open(inventory_file, 'r') as f:
        data = json.load(f)
    
    headers = {
        'Authorization': f'Token {token}',
        'Content-Type': 'application/json'
    }
    
    # Create device
    device_data = {
        'name': data['metadata']['hostname'],
        'device_type': get_or_create_device_type(data),
        'serial': data['device'].get('serial', ''),
        'status': 'active'
    }
    
    response = requests.post(
        f'{netbox_url}/api/dcim/devices/',
        headers=headers,
        json=device_data
    )
    
    return response.json()

# Usage
import_device('inventory_server01.json', 'https://netbox.example.com', 'your-token')
Method 3: CSV Import for Health Monitoring

Import Health Data
bash# Upload health_summary.smart_health_csv to NetBox custom fields
# Or use for external monitoring integration

Create Custom Fields

power_on_hours: Integer field
temperature: Integer field
health_status: Choice field (PASSED/FAILED)
reallocated_sectors: Integer field



Automation Workflows
Daily Health Monitoring
bash#!/bin/bash
# Run inventory and extract health data
./scripts/netbox_inventory.sh
cat output/inventory_*.json | jq -r '.health_summary.smart_health_csv' > /tmp/health.csv

# Process health alerts
while IFS=, read -r device model serial health hours temp sectors; do
    if [ "$health" != "PASSED" ] || [ "$sectors" -gt 0 ]; then
        echo "ALERT: $device health issue - $health, $sectors reallocated sectors"
        # Send to monitoring system
    fi
done < /tmp/health.csv
Weekly Device Updates
bash#!/bin/bash
# Collect inventory
./scripts/netbox_inventory.sh

# Update NetBox via API
python3 scripts/netbox_import.py output/inventory_$(hostname)_*.json
Field Mappings
Device Fields
Inventory FieldNetBox FieldNotesmetadata.hostnamenamePrimary identifierdevice.manufacturermanufacturerCreate if missingdevice.modeldevice_type.modelCreate device typedevice.serialserialHardware serialhardware.cpu.modelCustom fieldCPU detailshardware.memory.totalCustom fieldRAM capacity
Interface Fields
Inventory FieldNetBox FieldNotesnetwork.interfaces[].namenameInterface namenetwork.interfaces[].macmac_addressMAC addressnetwork.interfaces[].ipv4IP assignmentVia IPAM
Storage Fields
Inventory FieldNetBox FieldNotesstorage.mappings.device_to_labelCustom fieldDrive mappinghealth_summary.smart_health_csvCustom fieldsHealth metrics
Best Practices
1. Device Lifecycle Management

Use inventory data to track hardware changes
Monitor drive health for proactive replacement
Track power-on hours for warranty planning

2. Monitoring Integration

Export health CSV to monitoring systems
Set alerts for SMART failures
Track temperature trends

3. Capacity Planning

Use unmounted drive data for expansion planning
Monitor filesystem usage trends
Track storage pool utilization

4. Documentation

Update device documentation with inventory data
Maintain configuration baselines
Track hardware refresh cycles

Example Workflows
New Server Setup

Run inventory tool on new server
Import device data to NetBox
Configure monitoring based on health data
Document storage configuration

Health Monitoring

Daily inventory collection
Compare health metrics to baselines
Alert on changes (new bad sectors, high temps)
Update NetBox custom fields

Capacity Management

Weekly storage analysis
Identify unmounted drives
Plan expansion based on usage trends
Update NetBox device notes

Troubleshooting
Common Issues

Missing SMART data: Install smartmontools
Permission errors: Ensure sudo access for hardware queries
Network interface detection: Check for multiple NICs
Storage mapping confusion: Use label_to_device mappings

Validation
bash# Verify JSON structure
cat output/inventory_*.json | jq '.metadata'

# Check health data format
cat output/inventory_*.json | jq -r '.health_summary.smart_health_csv' | head -5

# Validate device mappings
cat output/inventory_*.json | jq '.storage.mappings.label_to_device'
Support
For integration assistance:

Check existing GitHub issues
Review example output in examples/
Test with sample data before production import