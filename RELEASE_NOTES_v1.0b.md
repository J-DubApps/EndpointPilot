# EndpointPilot v1.0b Release Notes

**Release Date:** July 27, 2025  
**Version:** 1.0b (Beta)  
**Target Environment:** Enterprise Windows Endpoint Management

---

## Executive Summary

EndpointPilot v1.0b introduces a comprehensive PowerShell-based Windows endpoint configuration solution designed to replace traditional logon scripts with modern, resilient automation. This beta release delivers a production-ready framework that operates autonomously via scheduled tasks, ensuring configuration consistency across hybrid and remote work environments regardless of network connectivity or VPN status.

Built specifically for Microsoft Intune and NinjaOne managed Windows endpoints, EndpointPilot provides IT administrators with a JSON-driven, modular approach to endpoint configuration that scales from small deployments to enterprise-wide implementations.

## What's New in Version 1.0b

### Core PowerShell Framework
- **Modular Architecture**: Complete implementation of the ENDPOINT-PILOT.PS1 → MAIN.PS1 → Helper Scripts workflow
- **PowerShell Compatibility**: Full support for both PowerShell 5.1 (Windows PowerShell) and PowerShell 7+ (Core)
- **Architecture Detection**: Automatic x64/ARM64 detection with x86 blocking for modern endpoint support
- **JSON Schema Validation**: Comprehensive schemas for all configuration and directive files

### JsonEditorTool GUI Application
- **WPF/.NET Interface**: User-friendly graphical editor for managing JSON configuration files
- **Schema Validation**: Real-time validation against EndpointPilot JSON schemas
- **Multi-Configuration Support**: Edit FILE-OPS, REG-OPS, DRIVE-OPS, and ROAM-OPS configurations
- **Enterprise Deployment**: Designed for IT administrator workflow integration

### Operational Components
- **File Operations**: Complete file copy, move, and deletion functionality with permissions handling
- **Registry Operations**: Registry key and value management with safety validations
- **Drive Mapping**: Network drive configuration and management (framework ready)
- **Roaming Profile Support**: Profile folder synchronization capabilities (framework ready)

### Installation and Deployment
- **Dual Installation Modes**: User-mode and administrative installation scripts
- **GitHub Integration**: Download capability from repository releases
- **Scheduled Task Automation**: Automatic scheduled task creation and management
- **Temporary Staging**: Secure staging in %WINDIR%\Temp\EPilotTmp during installation

### System Agent Framework
- **Service Architecture**: Foundation for future Windows Service implementation
- **SYSTEM-OPS Schema**: Complete JSON schema for system-level operations
- **Privilege Escalation Path**: Framework for MSI installations and system registry operations

## System Requirements

### Minimum Requirements
- **Operating System**: Windows 10 Enterprise (Build 1903+) or Windows 11 Enterprise
- **PowerShell**: PowerShell 5.1 or higher
- **Architecture**: x64 or ARM64 (x86 not supported)
- **Permissions**: Standard user with scheduled task creation privileges
- **Storage**: 50MB free space in %LOCALAPPDATA%

### Recommended Configuration
- **Operating System**: Windows 11 Enterprise with latest updates
- **PowerShell**: PowerShell 7.4+ (Core)
- **Memory**: 4GB+ RAM
- **Management Platform**: Microsoft Intune or NinjaOne
- **Network**: Internet connectivity for initial deployment (offline operation supported)

### Enterprise Prerequisites
- Active Directory or Azure AD domain join
- Group Policy or Intune management capability
- PowerShell execution policy allowing signed scripts (recommended)

## Installation Guide

### User-Mode Installation (Standard)
```powershell
# Download and run the user installation script
.\Install-EndpointPilot.ps1

# Files installed to: %LOCALAPPDATA%\EndpointPilot
# Scheduled task: "EndpointPilot User Configuration"
```

### Administrative Installation (System-Wide)
```powershell
# Run as Administrator
.\Install-EndpointPilotAdmin.ps1

# Files installed to: %PROGRAMDATA%\EndpointPilot
# JsonEditorTool installed to: %PROGRAMDATA%\EndpointPilot\JsonEditorTool
```

### File Locations
- **User Mode**: `%LOCALAPPDATA%\EndpointPilot`
- **System Mode**: `%PROGRAMDATA%\EndpointPilot`
- **Configuration Files**: Same directory as PowerShell scripts
- **Log Files**: `%LOCALAPPDATA%\EndpointPilot\Logs` or `%PROGRAMDATA%\EndpointPilot\Logs`

## Configuration Schema and Examples

### CONFIG.json (Global Configuration)
```json
{
  "ClientName": "YourOrganization",
  "RefreshIntervalMinutes": 60,
  "LogRetentionDays": 30,
  "EnableDetailedLogging": true,
  "SkipFileOps": false,
  "SkipRegOps": false,
  "SkipDriveOps": false,
  "SkipRoamOps": false,
  "NetworkRoamFolder": "\\\\server\\share\\profiles"
}
```

### FILE-OPS.json (File Operations)
```json
[
  {
    "operation": "copy",
    "srcfilename": "company-wallpaper.jpg",
    "sourcePath": "\\\\server\\share\\resources",
    "destinationPath": "%USERPROFILE%\\Pictures",
    "destfilename": "wallpaper.jpg",
    "overwrite": true,
    "requiredGroup": "Domain Users"
  }
]
```

### REG-OPS.json (Registry Operations)
```json
[
  {
    "operation": "set",
    "keyPath": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes",
    "valueName": "PersonalizeColors",
    "valueData": "1",
    "valueType": "DWORD",
    "requiredGroup": "Domain Users"
  }
]
```

## Core Components Overview

### PowerShell Scripts
- **ENDPOINT-PILOT.PS1**: Entry point with architecture detection and PowerShell version handling
- **MAIN.PS1**: Primary orchestrator that loads modules and coordinates helper script execution
- **MGMT-Functions.psm1**: Core utility module with functions for group membership, registry access, and validation
- **MGMT-SHARED.ps1**: Shared variables, logging functions, and common configuration loading

### Helper Scripts
- **MGMT-FileOps.ps1**: File operation processing with copy, move, and delete capabilities
- **MGMT-RegOps.ps1**: Registry operation handling (framework implemented)
- **MGMT-DriveOps.ps1**: Network drive mapping operations (framework implemented)
- **MGMT-RoamOps.ps1**: Roaming profile synchronization (framework implemented)

### JSON Schema Files
- **CONFIG.schema.json**: Global configuration validation
- **FILE-OPS.schema.json**: File operation directive validation
- **REG-OPS.schema.json**: Registry operation directive validation
- **DRIVE-OPS.schema.json**: Drive mapping directive validation
- **SYSTEM-OPS.schema.json**: Future system operation validation

## Known Issues and Limitations

### Current Beta Limitations
- **User-Mode Only**: Currently operates under user privileges; System Agent for elevated operations in development
- **Placeholder Functionality**: Registry, Drive, and Roaming Profile operations have framework but limited implementation
- **Manual Installation**: No automated Intune .intunewin or NinjaOne packages yet (manual deployment required)
- **Limited Rollback**: No automatic rollback mechanism for failed operations

### Technical Considerations
- **PowerShell Version Compatibility**: Some advanced features require PowerShell 7+ for optimal performance
- **Network Dependencies**: Initial installation requires internet connectivity for GitHub downloads
- **Scheduled Task Permissions**: Users need rights to create scheduled tasks for user-mode deployment
- **Large Deployments**: Performance testing recommended for organizations with 1000+ endpoints

### Security Considerations
- **JSON File Security**: Configuration files stored in user-accessible locations in user-mode
- **Script Signing**: Digital signature validation not implemented in v1.0b
- **Credential Storage**: No built-in secure credential management (relies on Windows credential store)

## Migration from Traditional Logon Scripts

### Planning Your Migration
1. **Inventory Current Scripts**: Document existing logon script functionality
2. **Map to Operations**: Translate script actions to JSON operations (file, registry, drive mapping)
3. **Test User Groups**: Deploy to pilot groups using AD group-based targeting
4. **Gradual Rollout**: Replace logon scripts incrementally by function area

### Migration Benefits
- **Reliability**: Executes regardless of network connectivity status
- **Performance**: Runs on schedule rather than at every logon
- **Visibility**: Comprehensive logging and error reporting
- **Maintainability**: JSON configuration is easier to manage than script code
- **Scalability**: Better performance with large user populations

## Enterprise Deployment Scenarios

### Microsoft Intune Deployment
```powershell
# Package EndpointPilot for Intune deployment
# Create .intunewin package (manual process in v1.0b)
# Deploy as Win32 app with detection rules
# Configure assignment groups and requirements
```

### NinjaOne Deployment
- Package as NinjaOne application
- Configure deployment conditions and groups  
- Set up monitoring and reporting dashboards
- Implement automated updates via NinjaOne policies

### Group Policy Deployment (Alternative)
- Deploy via GPO startup scripts for initial installation
- Use GPO file copy for configuration file distribution
- Leverage existing AD group memberships for targeting

## Future Roadmap

### System Agent (Next Release)
- Windows Service implementation for SYSTEM-level operations
- MSI installation support
- System registry and service configuration
- Enhanced security with proper service account management

### Enhanced Installation
- Automated Intune .intunewin package generation
- NinjaOne native package support
- Automatic update mechanism for deployed instances
- Improved rollback and recovery capabilities

### Advanced Features
- PowerShell DSC integration
- Enhanced logging with centralized collection
- Web-based configuration management portal
- Multi-tenant support for MSP environments

## Support and Feedback

### Documentation
- **GitHub Repository**: [EndpointPilot Repository](https://github.com/your-org/EndpointPilot)
- **JSON Schema Documentation**: Included in repository `/schemas/` directory
- **PowerShell Module Help**: Use `Get-Help` cmdlets for function documentation

### Community Support
- **GitHub Issues**: Report bugs and feature requests via GitHub Issues
- **Community Discussions**: GitHub Discussions for implementation questions
- **Sample Configurations**: Available in repository `/examples/` directory

### Enterprise Support
- **Professional Services**: Available for large-scale implementations
- **Custom Development**: Tailored solutions for specific organizational needs
- **Training Services**: Administrator training and best practices workshops

## License and Legal

EndpointPilot v1.0b is released under the BSD-3-Clause License. See the LICENSE file in the repository for complete terms and conditions.

## Acknowledgments

This release represents significant community feedback and testing from early adopters in enterprise environments. Special thanks to the PowerShell community for best practices guidance and the Microsoft Intune team for deployment pattern recommendations.

---

**Note**: This is a beta release intended for testing and evaluation in non-production environments. While stable, we recommend thorough testing before deploying to production endpoints. Please report any issues via the GitHub repository issue tracker.

**Next Release Target**: System Agent implementation (Q4 2025)