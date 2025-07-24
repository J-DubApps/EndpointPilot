# EndpointPilot Installation Scripts Documentation

## Overview

This document provides comprehensive documentation for the EndpointPilot installation scripts, covering both the System Agent and JsonEditorTool installation processes.

## System Agent Installation Scripts

### Install-SystemAgent.ps1

**Purpose**: Automates the build, installation, and configuration of the EndpointPilot System Agent Windows Service.

#### Synopsis
```powershell
.\Install-SystemAgent.ps1 [-BuildConfiguration <String>] [-Force] [-SkipBuild]
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| BuildConfiguration | String | Release | Build configuration (Release or Debug) |
| Force | Switch | False | Force installation even if service exists |
| SkipBuild | Switch | False | Skip the build process (use existing binaries) |
| RuntimeIdentifier | String | win-x64 | Target architecture (win-x64 or win-arm64) |
| UsePreBuilt | Switch | False | Use pre-built binaries from SystemAgent/bin folder |

#### Installation Process

1. **Prerequisites Check**
   - Verifies Administrator privileges
   - Checks for .NET 8 SDK/Runtime
   - Validates SystemAgent project exists

2. **Build Process** (unless -SkipBuild)
   - Auto-detects ARM64 architecture and switches build target
   - Cleans previous build artifacts
   - Builds SystemAgent project for specified architecture (x64 or ARM64)
   - Verifies build output

3. **Directory Setup**
   - Creates `%PROGRAMDATA%\EndpointPilot\SystemAgent` for service binaries
   - Creates `%PROGRAMDATA%\EndpointPilot` for configuration files
   - Copies service binaries to SystemAgent subdirectory
   - Copies configuration files (CONFIG.json, SYSTEM-OPS.json, MAIN.PS1) to main directory
   - Sets secure ACLs (SYSTEM and Administrators only)

4. **Service Installation**
   - Creates Windows Service named "EndpointPilot System Agent"
   - Sets service to start automatically
   - Configures service recovery options
   - Starts the service

5. **Post-Installation**
   - Performs health check
   - Displays service status
   - Shows log file location

#### Usage Examples

```powershell
# Standard installation
.\Install-SystemAgent.ps1

# Debug build installation
.\Install-SystemAgent.ps1 -BuildConfiguration Debug

# Force reinstall
.\Install-SystemAgent.ps1 -Force

# Install without rebuilding
.\Install-SystemAgent.ps1 -SkipBuild

# Install for ARM64 architecture
.\Install-SystemAgent.ps1 -RuntimeIdentifier win-arm64

# Auto-detected ARM64 build (will detect automatically)
.\Install-SystemAgent.ps1  # On ARM64 system, automatically uses win-arm64

# Use pre-built binaries (no compilation needed)
.\Install-SystemAgent.ps1 -UsePreBuilt

# Use pre-built ARM64 binaries specifically
.\Install-SystemAgent.ps1 -UsePreBuilt -RuntimeIdentifier win-arm64
```

#### Security Features

- **Elevated Execution**: Requires Administrator privileges
- **Secure ACLs**: Installation directory restricted to SYSTEM and Administrators
- **Service Account**: Runs as LocalSystem for required privileges
- **Path Validation**: Validates all paths before operations

#### Error Handling

- Comprehensive error checking at each step
- Detailed error messages for troubleshooting
- Automatic rollback on critical failures
- Logging of all operations

#### Output

The script provides colored console output:
- 🟢 Green: Success messages
- 🟡 Yellow: Warnings
- 🔴 Red: Errors
- 🔵 Cyan: Information

### Uninstall-SystemAgent.ps1

**Purpose**: Cleanly removes the EndpointPilot System Agent Windows Service and optionally removes all associated files.

#### Synopsis
```powershell
.\Uninstall-SystemAgent.ps1 [-RemoveFiles] [-Force]
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| RemoveFiles | Switch | False | Remove all System Agent files after uninstall |
| Force | Switch | False | Force removal without confirmation prompts |

#### Uninstallation Process

1. **Prerequisites Check**
   - Verifies Administrator privileges
   - Checks if service exists

2. **Service Removal**
   - Stops the service if running
   - Deletes the Windows Service
   - Verifies service removal

3. **Optional File Cleanup** (if -RemoveFiles)
   - Prompts for confirmation (unless -Force)
   - Removes SystemAgent directory
   - Preserves user configuration files by default

4. **Verification**
   - Confirms service no longer exists
   - Reports cleanup status

#### Usage Examples

```powershell
# Remove service only (preserve files)
.\Uninstall-SystemAgent.ps1

# Complete removal including files
.\Uninstall-SystemAgent.ps1 -RemoveFiles

# Force complete removal without prompts
.\Uninstall-SystemAgent.ps1 -RemoveFiles -Force
```

#### Safety Features

- **Confirmation Prompts**: Asks before destructive operations
- **Preserve User Data**: Keeps configuration files by default
- **Service State Check**: Ensures clean service shutdown
- **Error Recovery**: Continues with remaining steps on non-critical errors

## Common Installation Scenarios

### Fresh Installation
```powershell
# Complete installation from source
.\Install-SystemAgent.ps1
```

### Development Installation
```powershell
# Install debug build for testing
.\Install-SystemAgent.ps1 -BuildConfiguration Debug
```

### Upgrade Installation
```powershell
# Stop service, upgrade, restart
.\Uninstall-SystemAgent.ps1
.\Install-SystemAgent.ps1
```

### Complete Reinstallation
```powershell
# Remove everything and reinstall
.\Uninstall-SystemAgent.ps1 -RemoveFiles -Force
.\Install-SystemAgent.ps1
```

## Troubleshooting Installation Issues

### Build Failures

#### .NET SDK Not Found
**Error**: "NET SDK not found"
**Solution**: Install .NET 8 SDK from https://dotnet.microsoft.com/download

#### Build Errors
**Error**: "Build failed with errors"
**Solution**: 
- Check `dotnet --version` shows 8.0 or higher
- Ensure all NuGet packages are restored
- Review build output for specific errors

### Installation Failures

#### Access Denied
**Error**: "Access is denied"
**Solution**: Run PowerShell as Administrator

#### Service Already Exists
**Error**: "Service 'EndpointPilot System Agent' already exists"
**Solution**: Use `-Force` parameter or uninstall first

#### Directory Access Issues
**Error**: "Cannot create directory"
**Solution**: 
- Check %PROGRAMDATA% permissions
- Ensure no files are locked by other processes

### Service Start Failures

#### Service Fails to Start
**Error**: "Service did not start successfully"
**Solution**:
- Check Windows Event Log
- Review `%PROGRAMDATA%\EndpointPilot\Agent.log`
- Verify .NET 8 Runtime is installed
- Ensure CONFIG.json exists and is valid

## Log Files and Diagnostics

### Installation Logs
- Console output shows all installation steps
- Errors are highlighted in red
- Warnings in yellow

### Service Logs
- **Location**: `%PROGRAMDATA%\EndpointPilot\Agent.log`
- **Event Log**: Windows Application Log
- **Source**: "EndpointPilot System Agent"

### Diagnostic Commands
```powershell
# Check service status
Get-Service "EndpointPilot System Agent"

# View recent service events
Get-EventLog -LogName Application -Source "EndpointPilot System Agent" -Newest 10

# Check installation directory
Get-ChildItem "%PROGRAMDATA%\EndpointPilot\SystemAgent"

# Verify service executable
sc.exe qc "EndpointPilot System Agent"
```

## Best Practices

### Installation
1. Always run prerequisite checks before installation
2. Use Release builds for production
3. Test in non-production environment first
4. Document any custom configurations

### Uninstallation
1. Stop dependent services first
2. Backup configuration files before removal
3. Use -RemoveFiles only when completely removing EndpointPilot
4. Verify service removal before file cleanup

### Maintenance
1. Keep installation scripts with the project
2. Document any modifications to scripts
3. Test scripts after SystemAgent code changes
4. Maintain version compatibility

## Integration with Deployment Tools

### Intune Deployment
```powershell
# Silent installation for Intune
powershell.exe -ExecutionPolicy Bypass -File Install-SystemAgent.ps1 -Force
```

### SCCM/ConfigMgr
- Use script parameters for silent installation
- Check exit codes for success/failure
- Monitor via Windows Event Log

### NinjaOne/RMM Tools
- Deploy scripts as scheduled tasks
- Use -Force for unattended installation
- Parse output for monitoring

## JsonEditorTool Installation Scripts

### Install-JsonEditorTool.ps1

**Purpose**: Automates the build, installation, and configuration of the EndpointPilot JsonEditorTool WPF application.

#### Synopsis
```powershell
.\Install-JsonEditorTool.ps1 [-BuildConfiguration <String>] [-InstallLocation <String>] [-RuntimeIdentifier <String>] [-UsePreBuilt] [-Force] [-CreateDesktopShortcut]
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| BuildConfiguration | String | Release | Build configuration (Release or Debug) |
| InstallLocation | String | ProgramData | Installation location (ProgramData or Desktop) |
| RuntimeIdentifier | String | win-x64 | Target architecture (win-x64 or win-arm64) |
| UsePreBuilt | Switch | False | Use pre-built binaries from JsonEditorTool/bin folder |
| Force | Switch | False | Force reinstallation even if application exists |
| CreateDesktopShortcut | Switch | False | Create a desktop shortcut for the application |

#### Installation Process

1. **Prerequisites Check**
   - Verifies Administrator privileges
   - Checks for .NET 9 Runtime (recommended)
   - Auto-detects ARM64 architecture if needed

2. **Build Process** (unless -UsePreBuilt)
   - Builds JsonEditorTool WPF application
   - Supports both x64 and ARM64 architectures
   - Verifies build output and dependencies

3. **Installation Setup**
   - **ProgramData**: Installs to `%PROGRAMDATA%\EndpointPilot\JsonEditorTool`
   - **Desktop**: Installs to `%USERPROFILE%\Desktop\EndpointPilot-JsonEditorTool`
   - Sets appropriate file permissions
   - Copies all application dependencies

4. **Post-Installation**
   - Creates desktop shortcut (if requested)
   - Performs installation validation
   - Displays usage instructions

#### Usage Examples

```powershell
# Standard installation to ProgramData
.\Install-JsonEditorTool.ps1

# Install to Desktop with shortcut using pre-built binaries
.\Install-JsonEditorTool.ps1 -UsePreBuilt -InstallLocation Desktop -CreateDesktopShortcut

# Install ARM64 version with force reinstall
.\Install-JsonEditorTool.ps1 -RuntimeIdentifier win-arm64 -Force
```

### Build-JsonEditorTool.ps1

**Purpose**: Builds pre-compiled binaries for both x64 and ARM64 architectures.

#### Synopsis
```powershell
.\Build-JsonEditorTool.ps1 [-BuildConfiguration <String>] [-Architecture <String>] [-OutputToLegacy]
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| BuildConfiguration | String | Release | Build configuration (Release or Debug) |
| Architecture | String | both | Target architecture (win-x64, win-arm64, or both) |
| OutputToLegacy | Switch | False | Also copy to existing publish/publish-arm64 folders |

#### Usage Examples

```powershell
# Build both architectures
.\Build-JsonEditorTool.ps1

# Build only ARM64 with legacy output
.\Build-JsonEditorTool.ps1 -Architecture win-arm64 -OutputToLegacy
```

## JsonEditorTool Features

The JsonEditorTool provides a graphical interface for managing EndpointPilot JSON configuration files:

### Supported Configuration Files
- **CONFIG.json** - General EndpointPilot settings
- **FILE-OPS.json** - File operations (copy, move, create, delete)
- **REG-OPS.json** - Registry operations and modifications
- **DRIVE-OPS.json** - Network drive mappings
- **ROAM-OPS.json** - Roaming profile configurations
- **SYSTEM-OPS.json** - System-level operations for System Agent

### Key Features
- **Visual JSON Editing** with schema validation
- **Material Design UI** for intuitive user experience
- **Real-time Validation** against EndpointPilot schemas
- **Automatic Backups** before saving changes
- **Cross-Architecture Support** (x64 and ARM64)

## Version History

### Current Version Features
- Full System Agent installation automation
- Secure ACL configuration
- Health check validation
- Clean uninstallation process

### Future Enhancements
- MSI package generation
- Update detection and automation
- Configuration migration support
- ARM64 platform support