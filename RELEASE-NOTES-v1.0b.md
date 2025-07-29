# EndpointPilot v1.0b Release Notes

**Release Date:** September 01, 2025  
**Release Type:** Beta Release  
**Target Audience:** IT Administrators, Security Teams, Technical Decision Makers

---

## Overview

EndpointPilot v1.0b represents the first public beta release of a PowerShell-based Windows endpoint configuration solution, written by Julian West. This release introduces a modern alternative to traditional logon scripts, designed specifically for hybrid and remote work environments where network connectivity to domain controllers cannot be guaranteed.  

This beta release delivers a test-ready framework capable of demonstrating resilient automation of Windows PC Endpoint configuration management.  Once production-ready, EndpointPilot can ensure configuration consistency across hybrid and remote work environments -- regardless of network connectivity or VPN status.

Built specifically for Microsoft Intune and NinjaOne managed Windows endpoints, EndpointPilot provides IT administrators with a JSON-driven, modular approach to endpoint configuration that scales from small deployments to enterprise-wide implementations.  The author is aiming for a simple "better than a logon script" approach, ensuring consistent endpoint configuration regardless of VPN status or network availability.

## What's New in Version 1.0b

### Core PowerShell Framework
- **Modular Architecture**: Separate helper scripts for different operation types, with standardized error handling.  Complete implementation of the ENDPOINT-PILOT.PS1 → MAIN.PS1 → Helper Scripts workflow
- **JSON-Driven Configuration Management**: Complete configuration system using directive files (FILE-OPS.json, REG-OPS.json, DRIVE-OPS.json, ROAM-OPS.json)
- **PowerShell Compatibility**: Full support for both PowerShell 5.1 (Windows PowerShell) and PowerShell 7+ (Core)
- **Multi-Architecture Support**: Native support for both x64 and ARM64 Windows systems, with automatic x64/ARM64 detection with x86 blocking for modern endpoint support
- **JSON Schema Validation**: Comprehensive schemas for all configuration and directive files

### JsonEditorTool GUI Application

- **Comprehensive JSON Editor**: WPF-based .NET application for user-friendly managing of all EndpointPilot configuration files.  Edit FILE-OPS, REG-OPS, DRIVE-OPS, and ROAM-OPS configurations.
- **Schema Validation**: Real-time validation against JSON schemas to prevent configuration errors
- **Multi-Platform Binaries**: Pre-compiled binaries available for both x64 and ARM64 architectures
- **Material Design UI**: Modern, intuitive interface built with Material Design for WPF
- **Integrated Help System**: Context-sensitive help and tooltips for all configuration options

### Operational Components
- **File Operations**: Complete file copy, move, and deletion functionality with permissions handling
- **Registry Operations**: Registry key and value management with safety validations
- **Drive Mapping**: Network drive configuration and management (framework ready)
- **Roaming Profile Support**: Profile folder synchronization capabilities (framework ready)

### System Agent Framework (Preview)

- **System-Level Operations**: C# Windows Service foundation for elevated operations (planned for future releases)
- **SYSTEM-OPS Schema**: Complete JSON schema definition for system-level operations
- **Service Architecture**: Built on .NET 8+ Worker Service pattern for reliability and performance
- **Privilege Escalation Path**: Framework for secure elevation (under development)

### Installation and Deployment

- **Dual Installation Modes**: User-mode and administrative installation scripts
- **GitHub Integration**: Download capability from repository releases
- **Intune/NinjaOne Ready**: Prepared for enterprise deployment through Microsoft Intune (.intunewin) and NinjaOne packaging
- **Network Share Support**: Optional network-based configuration file synchronization (for Active Directory environments)

## System Requirements

### Minimum Requirements

- **Operating System**: Windows 10 Enterprise (Build 1903+) or Windows 11 Enterprise 
- **PowerShell**: PowerShell 5.1 or higher (PowerShell 7+ recommended)
- **Memory**: 8GB+ RAM
- **User Privileges**: Scheduled task creation rights (for non System Agent implementations)
- **Network**: Internet connectivity for initial deployment from Intune or NinjaOne, or LAN connectivity in AD evnironments (offline operation supported)
- **Disk Space**: 50MB for core components, additional 100MB for JsonEditorTool on Sysadmin machines.

### Enterprise Prerequisites
- Active Directory or Azure AD domain join
- Group Policy or Intune management capability
- PowerShell execution policy allowing signed scripts (recommended)

## Installation Guide

### Quick Start Installation

1. **Download the latest release** from the GitHub repository releases page
2. **Extract the package** to a temporary directory (e.g., `%WINDIR%\Temp\EPilotTmp`)
3. **Run the installer** appropriate for your environment:
   - **User Mode**: `.\deploy\Install-EndpointPilot.ps1`
   - **Administrative Mode**: `.\deploy\Install-EndpointPilotAdmin.ps1`
4. **Configure JSON files** using the JsonEditorTool or by editing files directly

### File Locations

#### User Mode Installation
- **Core Files**: `%LOCALAPPDATA%\EndpointPilot` (`C:\Users\[Username]\AppData\Local\EndpointPilot`)
- **Log Files**: `%LOCALAPPDATA%\EndpointPilot\logs`
- **Configuration**: `%LOCALAPPDATA%\EndpointPilot\*.json`

#### System Mode Installation (Future)
- **Core Files**: `%PROGRAMDATA%\EndpointPilot` (`C:\ProgramData\EndpointPilot`)
- **JsonEditorTool**: `%PROGRAMDATA%\EndpointPilot\JsonEditorTool`
- **System Agent**: `%PROGRAMDATA%\EndpointPilot\SystemAgent`

### JsonEditorTool Installation

The JsonEditorTool requires separate installation and can be deployed system-wide:

```powershell
.\deploy\Install-JsonEditorTool.ps1 -Force
```

Pre-compiled binaries are available for both x64 and ARM64 architectures in the `JsonEditorTool/publish/` and `JsonEditorTool/publish-arm64/` directories.

## Configuration Schema and Examples

### Primary Configuration Files

#### CONFIG.json
Global configuration settings controlling EndpointPilot behavior:

```json
{
  "OrgName": "Your Organization",
  "Refresh_Interval": 900,
  "NetworkScriptRootPath": "\\\\server\\share\\EPilot\\",
  "NetworkScriptRootEnabled": true,
  "HttpsScriptRootEnabled": false,
  "HttpsScriptRootPath": "https://server/share/EPilot/",
  "CopyLogFileToNetwork": false,
  "RoamFiles": false,
  "NetworkLogFile": "\\\\server\\share\\logs\\EPilot_RunLogs",
  "NetworkRoamFolder": "\\\\server\\share\\RoamingFiles",
  "SkipFileOps": false,
  "SkipDriveOps": false,
  "SkipRegOps": false,
  "SkipRoamOps": false
}
```

#### FILE-OPS.json
File system operations including copy, move, and delete operations:

```json
[
  {
    "id": 1,
    "srcfilename": "example.txt",
    "dstfilename": "example.txt",
    "sourcePath": "C:\\source\\path",
    "destinationPath": "C:\\destination\\path",
    "overwrite": true,
    "copyonce": false,
    "existCheckLocation": "",
    "existCheck": false,
    "deleteFile": false,
    "targeting_type": "none",
    "target": "all",
    "_comment1": "File copy operation example",
    "_comment2": ""
  }
]
```

#### REG-OPS.json
Registry operations for managing Windows registry entries:

```json
[
  {
    "id": 1,
    "action": "create",
    "path": "HKCU\\Software\\Example",
    "name": "ExampleValue",
    "value": "ExampleData",
    "type": "String",
    "targeting_type": "none",
    "target": "all",
    "_comment1": "Registry value creation example",
    "_comment2": ""
  }
]
```

#### DRIVE-OPS.json
Network drive mapping and management operations:

```json
[
  {
    "id": 1,
    "action": "map",
    "driveletter": "H:",
    "uncpath": "\\\\server\\share",
    "persistent": true,
    "targeting_type": "none",
    "target": "all",
    "_comment1": "Network drive mapping example",
    "_comment2": ""
  }
]
```

## Core Components Overview

### PowerShell Scripts

#### ENDPOINT-PILOT.PS1
Entry point script that handles PowerShell version detection and architecture validation before launching the main orchestrator.

#### MAIN.PS1
Primary orchestrator that:
- Loads the MGMT-Functions module
- Processes CONFIG.json settings
- Calls appropriate helper scripts based on configuration
- Manages execution flow and error handling

#### Utility Modules and Scripts
- **MGMT-Functions.psm1**: Core utility functions including InGroup (user group membership checking), registry access, and Test-Path validation etc
- **MGMT-SHARED.ps1**: Shared variables, logging functions (WriteLog), and common configuration loading

#### Helper Scripts
- **MGMT-FileOps.ps1**: Processes FILE-OPS.json directives
- **MGMT-RegOps.ps1**: Handles REG-OPS.json operations (placeholder in v1.0b)
- **MGMT-DriveOps.ps1**: Manages DRIVE-OPS.json operations (placeholder in v1.0b)
- **MGMT-RoamOps.ps1**: Processes roaming file operations
- **MGMT-SchedTsk.ps1**: Manages scheduled task creation and maintenance
- **MGMT-Telemetry.ps1**: Handles logging and telemetry data

#### Utility Modules
- **MGMT-Functions.psm1**: Core utility functions including InGroup, Get-Permission, Test-Path validation
- **MGMT-SHARED.ps1**: Shared variables, logging functions (WriteLog), and common configurations

### JSON Schema Files & Validation

All configuration files include comprehensive JSON schema validation:
- **CONFIG.schema.json**: Validates global configuration structure
- **FILE-OPS.schema.json**: Ensures file operation syntax correctness
- **REG-OPS.schema.json**: Validates registry operation definitions
- **DRIVE-OPS.schema.json**: Confirms drive mapping configuration
- **SYSTEM-OPS.schema.json**: Future system operations validation (preview)

Schema validation can be performed using the included `Validate-JsonSchema.ps1` script or through the JsonEditorTool interface.

### Advanced Configuration

#### SYSTEM-OPS.json (Preview)
System-level operations schema for future System Agent implementation:

```json
[
  {
    "id": "Install-Software-Example",
    "operation": "install_msi",
    "comment": "Install example software package",
    "msi_path": "\\\\server\\software\\Example.msi",
    "install_args": "/quiet /norestart",
    "success_codes": [0, 3010],
    "targeting": {
      "type": "group",
      "target": "IT-Administrators"
    }
  }
]
```

## Known Issues and Limitations

### Current Beta Limitations

1. **User-Mode Operation Only**: This beta release operates exclusively in user context as of July 2025 dev sprint cycle.  System-level operations requiring elevated privileges are not yet supported, but a preview for SYSTEM operations (via agent) is included with this release.

2. **Helper Script Placeholders**: MGMT-RegOps.ps1 and MGMT-DriveOps.ps1 are currently placeholder implementations. Full functionality will be available in the release version.

3. **Operating System Restrictions**: Currently limited to Windows 10/11 Enterprise editions. Windows 10/11 Pro compatibility is under evaluation for future releases.

4. **Scheduled Task Dependencies**: Users must have rights to create scheduled tasks until the System Agent solution is implemented.

5. **32-bit Architecture**: x86/32-bit systems are explicitly not supported and will generate blocking errors.

### Technical Considerations

1. **JSON File Security**: Configuration files are stored in user-accessible locations (%LOCALAPPDATA%). Production deployments may need to consider file system ACL restrictions, to comply with any internal security.  Currently a Windows endpoint with proper managed BitLocker encryption of the system (we only support Enterprise edition of Windows -- for this reason) is generally secure; however, we must allow JSON files to be visible to users in our current framework design.

2. **Network Dependency**: While EndpointPilot operates offline, initial configuration synchronization may require network access to UNC paths or HTTPS endpoints.

3. **PowerShell Execution Policy**: Ensure appropriate PowerShell execution policies are configured (RemoteSigned or Unrestricted recommended).

4. **Group Policy Interactions**: EndpointPilot may interact with existing Group Policy settings. Test thoroughly in isolated environments before production deployment.

### Performance Notes

1. **Resource Usage**: EndpointPilot is designed for minimal resource consumption, but complex file operations may impact system performance during execution.

2. **Logging Overhead**: Comprehensive logging is enabled by default. Consider log rotation strategies for long-running deployments.

3. **JSON Parsing**: Large JSON configuration files may impact startup time. Keep directive files focused and concise.

## Migration and Upgrade Path

### From Traditional Logon Scripts

1. **Inventory Current Logon Scripts**: Document existing logon script functionality and dependencies
2. **Map to EndpointPilot Operations**: Convert file copies, registry changes, and drive mappings to JSON directives
3. **Test in Isolated Environment**: Deploy EndpointPilot alongside existing logon scripts initially
4. **Gradual Migration**: Phase out logon scripts as EndpointPilot configurations are validated
5. **Monitor and Adjust**: Use EndpointPilot logging to verify successful operations

### Configuration Migration Tools

The JsonEditorTool includes import capabilities for migrating from:
- Existing batch file operations
- PowerShell script configurations
- Manual registry export files

### Rollback Considerations

- Maintain existing logon scripts during initial deployment
- Document configuration changes for manual rollback if needed
- Use version control for JSON configuration files
- Test rollback procedures in development environments

## Testing and Validation

### Validation Tools

1. **JSON Schema Validation**: Use `Validate-JsonSchema.ps1` or JsonEditorTool for configuration validation
2. **Test Mode Execution**: Run with `-TestSharedVarModule` parameter for dry-run testing
3. **Integration Tests**: Pester test framework support included for automated testing
4. **Manual Verification**: Built-in logging provides detailed operation tracking

### Recommended Testing Approach

1. **Development Environment**: Test all configurations in isolated development systems
2. **Pilot Group**: Deploy to limited user group for real-world validation
3. **Staged Rollout**: Gradually expand deployment based on pilot results
4. **Monitoring**: Implement log aggregation for enterprise-scale monitoring

## Enterprise Deployment

### Microsoft Intune Integration

EndpointPilot v1.0b is prepared for Intune deployment through:
- **.intunewin package creation**: Automated packaging scripts included
- **Detection rules**: PowerShell-based detection for installed components
- **Assignment targeting**: Support for user and device-based assignments
- **Reporting integration**: Log data compatible with Intune reporting systems

### NinjaOne Integration

NinjaOne deployment preparation includes:
- **Package structure**: Compatible with NinjaOne application deployment
- **Custom fields**: Version tracking and configuration status reporting
- **Script categories**: Integration with NinjaOne script management
- **Monitoring integration**: Status reporting through NinjaOne APIs

### Network Share Deployment

Traditional network share deployment supports:
- **UNC path configuration**: Direct file serving from network shares
- **Version management**: Centralized update distribution
- **Offline operation**: Local caching for network-independent operation
- **Hybrid scenarios**: Combination of network and local configuration sources

## Support and Documentation

### Getting Started Resources

- **Installation Guide**: `/docs/README.md`
- **Configuration Examples**: Example JSON files included in repository
- **JsonEditorTool Documentation**: Built-in help system and tooltips
- **Schema Reference**: Complete JSON schema documentation in `/PlanningDocs/`

### Community and Feedback

- **GitHub Repository**: [https://github.com/J-DubApps/EndpointPilot](https://github.com/J-DubApps/EndpointPilot)
- **Issue Tracking**: GitHub Issues for bug reports and feature requests
- **Contributing Guidelines**: See CONTRIBUTING.md for development participation
- **Code of Conduct**: Community guidelines available in CODE_OF_CONDUCT.md

### Professional Support

EndpointPilot v1.0b is provided under the BSD-3-Clause license. While community support is available through GitHub, professional consulting and enterprise support services may be available through the project maintainers.

## Future Roadmap

### Planned for v1.1 Release

- **System Agent Implementation**: Complete C# Windows Service for elevated operations
- **MGMT-RegOps and MGMT-DriveOps**: Full implementation of registry and drive mapping operations
- **Enhanced Error Handling**: Improved error recovery and reporting mechanisms
- **Update Mechanism**: Automated update system for deployed instances

### Long-Term Objectives

- **Windows Pro Support**: Expand OS compatibility beyond Enterprise editions (likely will involve some measure of security introduced to JSON directive files, or future database support)
- **PowerShell DSC Integration**: Optional DSC compliance reporting
- **Cloud Configuration**: Direct integration with cloud-based configuration sources

## Security Considerations

### Current Security Model

- **User Context Operation**: All operations execute within user privilege boundaries
- **File System Security**: Configuration files inherit user profile ACLs
- **Network Communication**: Optional HTTPS support for configuration retrieval (coming in 1.1)
- **Script Signing**: Prepared for code signing in production environments

### Future Security Enhancements

- **System Agent ACLs**: Strict file system permissions for system-level operations
- **Certificate-Based Authentication**: PKI integration for enterprise environments
- **Audit Logging**: Enhanced logging for security compliance requirements
- **Privilege Escalation Controls**: Granular control over elevated operations

## Technical Specifications

### Supported File Formats

- **JSON Configuration**: All directive files use standardized JSON format
- **PowerShell Scripts**: Compatible with PowerShell 5.1+ syntax
- **Log Files**: Plain text with standardized timestamp format
- **Schema Files**: JSON Schema Draft 7 specification compliance

### Network Protocols

- **SMB/CIFS**: Network share access for configuration and logging
- **HTTPS**: Secure configuration retrieval (planned for v1.1)
- **Local File System**: Primary configuration storage and caching

### Integration APIs

- **PowerShell Module**: MGMT-Functions.psm1 provides programmatic access
- **JSON Schema**: Machine-readable configuration validation
- **Exit Codes**: Standardized return codes for automation integration
- **Event Logging**: Windows Event Log integration for enterprise monitoring

---

## License and Legal

EndpointPilot v1.0b is released under the BSD-3-Clause License. See the LICENSE file in the repository for complete terms and conditions.

## Acknowledgments

This release represents significant community feedback and testing from early adopters in enterprise environments. Special thanks to the PowerShell community for best practices guidance and the Microsoft Intune team for deployment pattern recommendations.

---

## Version Information

**Version**: 1.0b  
**Build Date**: September 01, 2025  
**Git Commit**: Latest commit hash at release time  
**License**: BSD-3-Clause  
**Supported Platforms**: Windows 10/11 Enterprise (x64, ARM64)

---

**Important Notice**: This is a beta release intended for testing and evaluation purposes in non-production environments. While stableand functional, we recommend thorough testing before deploying EndpointPilot v1.0b to production endpoints. Please report any issues via the GitHub repository issue tracker.

For the latest updates, documentation, and support resources, visit the official EndpointPilot repository at [https://github.com/J-DubApps/EndpointPilot](https://github.com/J-DubApps/EndpointPilot).


**Next Release Target**: System Agent implementation (Q4 2025)
