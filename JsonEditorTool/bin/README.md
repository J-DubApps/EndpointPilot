# Pre-Built EndpointPilot JsonEditorTool Binaries

This directory contains pre-compiled binaries of the EndpointPilot JsonEditorTool for immediate deployment without requiring a build environment.

## Directory Structure

```
/JsonEditorTool/bin/
├── win-x64/          # Windows x64 binaries
│   ├── EndpointPilotJsonEditor.App.exe
│   ├── EndpointPilotJsonEditor.App.dll
│   ├── EndpointPilotJsonEditor.Core.dll
│   ├── MaterialDesignThemes.Wpf.dll
│   ├── Newtonsoft.Json.dll
│   └── [other runtime files]
├── win-arm64/        # Windows ARM64 binaries  
│   ├── EndpointPilotJsonEditor.App.exe
│   ├── EndpointPilotJsonEditor.App.dll
│   ├── EndpointPilotJsonEditor.Core.dll
│   ├── MaterialDesignThemes.Wpf.dll
│   ├── Newtonsoft.Json.dll
│   └── [other runtime files]
└── README.md         # This file
```

## What is JsonEditorTool?

The EndpointPilot JsonEditorTool is a WPF-based graphical application that provides an intuitive interface for creating and editing EndpointPilot JSON configuration files:

- **CONFIG.json** - General EndpointPilot settings and organization configuration
- **FILE-OPS.json** - File operations (copy, move, create, delete)
- **REG-OPS.json** - Registry operations and modifications
- **DRIVE-OPS.json** - Network drive mappings and configurations
- **ROAM-OPS.json** - Roaming profile and folder redirection settings
- **SYSTEM-OPS.json** - System-level operations (MSI installs, services)

## Usage

### Quick Installation (Using Pre-Built Binaries)

```powershell
# Install to ProgramData with auto-architecture detection
.\Install-JsonEditorTool.ps1 -UsePreBuilt

# Install to Desktop with desktop shortcut
.\Install-JsonEditorTool.ps1 -UsePreBuilt -InstallLocation Desktop -CreateDesktopShortcut

# Force specific architecture with pre-built binaries
.\Install-JsonEditorTool.ps1 -UsePreBuilt -RuntimeIdentifier win-arm64
```

### Manual Installation

1. Copy the appropriate architecture folder contents to your desired location:
   - **System-wide**: `%PROGRAMDATA%\EndpointPilot\JsonEditorTool\`
   - **User-specific**: `%USERPROFILE%\Desktop\EndpointPilot-JsonEditorTool\`

2. Run the application:
   ```powershell
   .\EndpointPilotJsonEditor.App.exe
   ```

## Features

### Visual JSON Editing
- **Schema Validation**: Real-time validation against EndpointPilot JSON schemas
- **IntelliSense**: Auto-completion and suggestions for valid values
- **Error Highlighting**: Visual indicators for syntax and validation errors
- **Backup Management**: Automatic backup creation before saving changes

### User-Friendly Interface
- **Material Design UI**: Modern, intuitive interface using Material Design
- **Tabbed Navigation**: Easy switching between different operation types
- **Form-Based Editing**: No need to manually write JSON
- **Preview Mode**: See generated JSON before saving

### File Operations Support
- **Create New**: Start with empty configuration files
- **Load Existing**: Import and edit existing JSON files
- **Save Changes**: Write back to original files with backup
- **Export**: Save configurations to different locations

## Build Information

These binaries are compiled with:
- **.NET 9.0** target framework (`net9.0-windows`)
- **Release** configuration
- **Framework-dependent** deployment (requires .NET 9 Runtime)
- **Single-file** publishing enabled for easier distribution

## Requirements

- Windows 11 (x64 or ARM64)
- .NET 9.0 Runtime installed (or .NET 8.0 with compatibility)
- Sufficient permissions to read/write JSON configuration files

## Building Your Own

If you prefer to build from source:

```powershell
# Build both architectures
.\Build-JsonEditorTool.ps1

# Build specific architecture
.\Build-JsonEditorTool.ps1 -Architecture win-arm64

# Build and install directly
.\Install-JsonEditorTool.ps1 -RuntimeIdentifier win-x64
```

## Architecture Differences

### x64 Version
- Native execution on Intel/AMD x64 processors
- Optimal performance on traditional Windows machines
- Smaller memory footprint

### ARM64 Version
- Native execution on ARM64 processors (Surface Pro X, ARM-based laptops)
- No emulation overhead through Prism
- Optimized for ARM-based Windows devices

## Integration with EndpointPilot

The JsonEditorTool is designed to work seamlessly with the broader EndpointPilot ecosystem:

1. **Configuration Management**: Edit CONFIG.json for organizational settings
2. **Operation Planning**: Design FILE-OPS, REG-OPS, and DRIVE-OPS workflows
3. **System Integration**: Configure SYSTEM-OPS for the System Agent
4. **Validation**: Ensure all JSON files meet EndpointPilot requirements before deployment

## Version Information

- **Built with**: .NET 9.0 SDK
- **UI Framework**: WPF with Material Design Themes
- **JSON Processing**: Newtonsoft.Json with Schema validation
- **Last Updated**: [Update when binaries are refreshed]
- **Compatibility**: Windows 11 Enterprise/Pro x64 and ARM64

## Security Notes

- These binaries are unsigned - you may need to configure Windows Defender/antivirus exclusions
- The application requires read/write access to EndpointPilot configuration directories
- For production use, consider code signing the binaries
- JSON files are validated against schemas to prevent malformed configurations

## Troubleshooting

### Application Won't Start
1. Ensure .NET 9 Runtime is installed: `dotnet --list-runtimes`
2. Check Windows architecture matches binary: `$env:PROCESSOR_ARCHITECTURE`
3. Verify file permissions in installation directory
4. Check Windows Event Log for application errors

### JSON Validation Errors
1. Ensure JSON files follow EndpointPilot schema requirements
2. Check for syntax errors (missing commas, brackets)
3. Verify all required fields are present
4. Use the built-in validation features to identify issues

### Performance Issues
1. Ensure you're using the correct architecture binary (ARM64 on ARM64)
2. Close other resource-intensive applications
3. Check available disk space for temporary files
4. Consider building from source with specific optimizations

## Support

For issues with the JsonEditorTool:
1. Check the [main EndpointPilot documentation](../README.md)
2. Review JSON schema files for validation requirements
3. Test with minimal JSON files to isolate issues
4. Use build-from-source option if pre-built binaries don't work

---
*These binaries are provided for convenience. The JsonEditorTool is designed to simplify EndpointPilot configuration management through a visual interface.*