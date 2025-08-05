# Changelog

All notable changes to the NetBox Inventory Tool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-08-04

### Added
- **Enhanced Block Device Enumeration**: Comprehensive `lsblk` data collection with detailed filesystem information
- **Storage Label-to-Device Mapping**: Clear mapping between filesystem labels and physical devices
- **SMART Health Monitoring**: CSV-formatted health data for all drives including:
  - Power-on hours tracking
  - Temperature monitoring  
  - Reallocated sector detection
  - Overall health status
- **Unmounted Drive Detection**: Identification of unused storage capacity
- **Filesystem Health Checks**: Error detection for BTRFS, ext4, and XFS filesystems
- **Mount Status Tracking**: Complete mount/unmount status for all block devices
- **Structured Health Data**: CSV output format optimized for NetBox import and monitoring systems
- **Missing Label Detection**: Identifies expected storage labels that aren't found

### Enhanced
- **Storage Information Collection**: Expanded from basic `df` output to comprehensive storage analysis
- **JSON Structure**: Added dedicated `mappings` and `health_summary` sections for better organization
- **Network Discovery**: Improved detection of Docker networks and container interfaces
- **Error Handling**: More robust handling of missing commands and failed operations
- **Logging**: Enhanced logging with timestamps and operation status

### Technical Improvements
- **Modular Design**: Split storage collection into logical functions (`collect_storage_info`, `collect_label_mappings`, `collect_storage_health`)
- **CSV Format Support**: Structured CSV output alongside JSON for easy data import
- **Cross-Platform Compatibility**: Improved support across different Linux distributions
- **Performance**: Optimized data collection with reduced redundant operations

### Documentation
- **NetBox Integration Guide**: Complete guide for importing data into NetBox CMDB
- **Usage Examples**: Real-world examples and parsing scripts
- **API Integration**: Sample Python scripts for automated NetBox updates
- **Health Monitoring**: Scripts for automated health checking and alerting

### Use Cases Enabled
- **CMDB Population**: Automated device discovery and documentation in NetBox
- **Health Monitoring**: Proactive drive failure detection and alerting
- **Capacity Planning**: Identification of unused storage for expansion planning
- **Asset Management**: Complete hardware inventory with serial numbers and specifications
- **Network Documentation**: Comprehensive interface discovery including containerized environments

## [1.0.0] - 2025-08-04

### Added
- **Basic System Information Collection**:
  - Host information via `hostnamectl`
  - CPU specifications via `lscpu`
  - Memory information via `free`
  - PCI device enumeration via `lspci`
- **Storage Discovery**:
  - Filesystem usage via `df`
  - Mount information
  - Basic SMART data collection for all drives
- **Network Interface Discovery**:
  - Interface details via `ip addr`
  - Routing information via `ip route`
- **JSON Output Format**: Structured data suitable for NetBox integration
- **Error Handling**: Graceful handling of missing commands and permissions
- **Logging**: Basic operation logging with success/failure indicators
- **Project Structure**: Clean organization with separate directories for scripts, docs, examples, and output

### Technical Features
- **Cross-Platform Support**: Works on major Linux distributions
- **Minimal Dependencies**: Uses standard system commands with optional enhancements
- **Safe Execution**: Proper error handling and permission checks
- **Extensible Design**: Modular architecture for easy feature additions

## [Unreleased]

### Planned for v3.0.0
- **YAML Output Format**: Alternative to JSON for human-readable output
- **Configuration File Support**: Customizable collection parameters
- **Direct NetBox API Integration**: Automated device creation and updates
- **Historical Data Tracking**: Compare inventory changes over time
- **Custom Field Mapping**: Configurable NetBox field assignments
- **Bulk Operations**: Multi-system inventory collection
- **Container Integration**: Enhanced Docker and Kubernetes discovery
- **Cloud Platform Support**: AWS/Azure/GCP metadata integration

### Under Consideration
- **Web Interface**: Browser-based inventory collection and viewing
- **Database Storage**: Local SQLite database for historical tracking
- **Alerting Integration**: Direct integration with monitoring systems
- **Hardware Vendor APIs**: Enhanced hardware information via vendor-specific APIs
- **Automated Scheduling**: Built-in cron-like scheduling for regular collection
- **Report Generation**: PDF/HTML reports for management

---

## Development Notes

### Version Numbering
- **Major versions** (X.0.0): Breaking changes or significant architecture updates
- **Minor versions** (X.Y.0): New features, enhanced functionality
- **Patch versions** (X.Y.Z): Bug fixes, small improvements

### Release Process
1. Feature development in dedicated branches
2. Testing across multiple Linux distributions
3. Documentation updates
4. GitHub release with tagged version
5. Changelog updates

### Contributing
See [Contributing Guidelines](CONTRIBUTING.md) for development workflow and coding standards.

### Support Policy
- **Current version (2.x)**: Full support with bug fixes and security updates
- **Previous version (1.x)**: Security fixes only
- **End of life**: Announced 6 months in advance

---

## Migration Notes

### Upgrading from v1.0.0 to v2.0.0

**JSON Structure Changes**:
- Added `storage.mappings` section with device-to-label mapping
- Added `storage.health_summary` section with CSV-formatted health data
- Enhanced `network.interfaces` with Docker network detection

**New Output Files**:
- Health data now available in CSV format within JSON
- Mount status tracking for all devices
- Unmounted drive detection

**Compatibility**:
- All v1.0.0 JSON fields preserved
- New fields are additive, not breaking
- Existing NetBox import scripts should continue working
- Enhanced data provides additional integration opportunities

**Recommended Actions**:
1. Update any parsing scripts to take advantage of new structured data
2. Implement health monitoring using the new CSV format
3. Review storage mappings for capacity planning opportunities
4. Update NetBox import procedures to include health data