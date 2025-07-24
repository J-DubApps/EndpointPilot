# Pre-Built EndpointPilot System Agent Binaries

This directory contains pre-compiled binaries of the EndpointPilot System Agent for immediate deployment without requiring a build environment.

## Directory Structure

```
/SystemAgent/bin/
├── win-x64/          # Windows x64 binaries
│   ├── EndpointPilot.SystemAgent.exe
│   ├── EndpointPilot.SystemAgent.dll
│   ├── EndpointPilot.SystemAgent.deps.json
│   ├── EndpointPilot.SystemAgent.runtimeconfig.json
│   └── [other runtime files]
├── win-arm64/        # Windows ARM64 binaries  
│   ├── EndpointPilot.SystemAgent.exe
│   ├── EndpointPilot.SystemAgent.dll
│   ├── EndpointPilot.SystemAgent.deps.json
│   ├── EndpointPilot.SystemAgent.runtimeconfig.json
│   └── [other runtime files]
└── README.md         # This file
```

## Usage

### Quick Installation (Using Pre-Built Binaries)

```powershell
# Use pre-built x64 binaries (auto-detected on x64 systems)
.\Install-SystemAgent.ps1 -UsePreBuilt

# Use pre-built ARM64 binaries (auto-detected on ARM64 systems)  
.\Install-SystemAgent.ps1 -UsePreBuilt

# Force specific architecture with pre-built binaries
.\Install-SystemAgent.ps1 -UsePreBuilt -RuntimeIdentifier win-arm64
.\Install-SystemAgent.ps1 -UsePreBuilt -RuntimeIdentifier win-x64
```

### Manual Installation

1. Copy the appropriate architecture folder contents to:
   - `%PROGRAMDATA%\EndpointPilot\SystemAgent\`

2. Run the service installation:
   ```powershell
   sc.exe create "EndpointPilot System Agent" binPath="%PROGRAMDATA%\EndpointPilot\SystemAgent\EndpointPilot.SystemAgent.exe" start=auto
   ```

## Build Information

These binaries are compiled with:
- **.NET 8.0** target framework (`net8.0-windows`)
- **Release** configuration
- **Framework-dependent** deployment (requires .NET 8 Runtime)
- **Single-file** publishing enabled

## Requirements

- Windows 11 (x64 or ARM64)
- .NET 8.0 Runtime installed
- Administrator privileges for service installation

## Building Your Own

If you prefer to build from source:

```powershell
# Build both architectures
.\Install-SystemAgent.ps1 -RuntimeIdentifier win-x64
.\Install-SystemAgent.ps1 -RuntimeIdentifier win-arm64

# Or build without installing
dotnet publish SystemAgent/EndpointPilot.SystemAgent.csproj -c Release -r win-x64 --self-contained false
dotnet publish SystemAgent/EndpointPilot.SystemAgent.csproj -c Release -r win-arm64 --self-contained false
```

## Version Information

- **Built with**: .NET 8.0.x SDK
- **Last Updated**: [Update when binaries are refreshed]
- **Compatibility**: Windows 11 Enterprise/Pro x64 and ARM64

## Security Notes

- These binaries are unsigned - you may need to configure Windows Defender/antivirus exclusions
- For production use, consider code signing the binaries
- Binaries should be verified against source code before deployment

## Troubleshooting

If the pre-built binaries don't work:
1. Ensure .NET 8 Runtime is installed: `dotnet --list-runtimes`
2. Check Windows architecture: `$env:PROCESSOR_ARCHITECTURE`
3. Try building from source using the installation script
4. Check the [main documentation](../SystemAgent.md) for detailed troubleshooting

---
*These binaries are provided for convenience. Always verify compatibility with your specific environment.*