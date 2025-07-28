# EndpointPilot Development Container Guide

## Overview

EndpointPilot uses dual development containers to support both cross-platform development and native Windows testing. This guide covers setup, usage, and platform-specific considerations.

## Our CI/CD and PS Script Testing Approach for EndpointPilot

**We have three different .devcontainer configurations** that serve different purposes:

1. **Main devcontainer.json + docker-compose.yml**: General development with database support
   - Multi-service setup with SQL Server
   - Useful for testing database interactions
   - Ideal for complex development scenarios and CI/CD pipeline testing

2. **Linux subfolder (.devcontainer/linux/)**: Cross-platform PowerShell development on macOS/Linux
   - PowerShell Core development with mocked Windows cmdlets
   - Fast unit testing and syntax validation
   - Primary development environment for Mac users

3. **Windows subfolder (.devcontainer/windows/)**: Native Windows testing (when on Windows host)
   - Full Windows API, registry, and Active Directory access
   - Integration testing with real Windows components
   - Required for testing Windows-specific features

### Development Workflow
- I use the Linux container on my Mac for the most development
- I switch to Windows container when testing Windows-specific features (requires Windows host or VM)
- And I use the main compose setup when you need database functionality

This gives EndpointPilot devs maximum flexibility in both macOS and Windows development environments.

## Container Architecture

### Linux Container (`.devcontainer/Linux/`)
- **Base**: Ubuntu 22.04 with PowerShell Core 7.4
- **Purpose**: Cross-platform development, syntax validation, and mocked Windows testing
- **Key Features**:
  - Windows cmdlet mocking via `EndpointPilotMocks` module
  - Docker-in-Docker support
  - GitHub CLI and Azure CLI pre-installed
  - SSH key mounting from host

### Windows Container (`.devcontainer/Windows/`)  
- **Base**: Windows Server Core LTSC 2022
- **Purpose**: Native Windows testing with full registry, service, and AD access
- **Key Features**:
  - Both PowerShell 5.1 and PowerShell 7
  - Full Windows API access
  - Registry and service management
  - Active Directory cmdlets (when domain-joined)

## Quick Start

### Switching Between Containers

Use the provided script to switch environments:

```powershell
# Switch to Linux container
.\Switch-DevContainer.ps1 -Platform Linux

# Switch to Windows container  
.\Switch-DevContainer.ps1 -Platform Windows
```

This opens VS Code with the selected container configuration.

### Manual Setup

1. **Install Prerequisites**:
   - Docker Desktop
   - VS Code with Dev Containers extension
   - Git

2. **Open Container**:
   - Open VS Code in project root
   - `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
   - Select desired platform configuration

## Platform-Specific Development

### Linux Container Development

**When to Use:**
- PowerShell syntax validation
- Cross-platform compatibility testing
- Initial development and debugging
- CI/CD pipeline development

**Available Tools:**
```bash
# Test syntax across all PS files
Test-EndpointPilotLinux -Type Syntax

# Run unit tests with mocked Windows cmdlets
Test-EndpointPilotLinux -Type Unit

# Check for Windows-specific incompatibilities
Test-EndpointPilotLinux -Type Compatibility
```

**Mocked Windows Cmdlets:**
- `Get-ItemProperty` → Returns mock registry values
- `Get-WmiObject` → Returns mock system information
- `Get-ADComputer` → Returns mock AD objects

### Windows Container Development

**When to Use:**
- Registry operation testing
- Service management validation
- Active Directory integration testing
- Full integration testing

**Available Tools:**
```powershell
# Test specific Windows components
Test-EndpointPilotWindows -Component Registry
Test-EndpointPilotWindows -Component Services
Test-EndpointPilotWindows -Component AD

# Test registry operations safely
Test-RegistryOperation -Path "HKCU:\Test" -Name "TestValue" -Value "TestData"
```

## Development Workflow

### Recommended Development Flow

1. **Start in Linux Container**:
   - Develop core PowerShell logic
   - Validate syntax and basic functionality
   - Run unit tests with mocked dependencies

2. **Test in Windows Container**:
   - Validate Windows-specific operations
   - Test registry and service interactions
   - Run integration tests

3. **Deploy to Real Environment**:
   - Test on actual Windows 10/11 Enterprise
   - Validate with real AD environment
   - Performance testing

### Container-Specific Considerations

#### Linux Container Limitations
- No real registry access
- No Windows services
- No native AD connectivity
- File system differences (case-sensitive, different paths)

#### Windows Container Limitations  
- Larger resource footprint
- Slower startup times
- Limited networking in some environments
- Requires Hyper-V isolation

## File Structure

### Container-Specific Directories
```
.devcontainer/
├── Linux/
│   ├── devcontainer.json      # Linux container config
│   ├── Dockerfile             # Ubuntu + PowerShell setup
│   ├── setup.sh               # Linux-specific setup
│   └── tests/                 # Linux test configs
└── Windows/
    ├── devcontainer.json      # Windows container config
    ├── Dockerfile             # Windows Server setup
    ├── setup.ps1              # Windows-specific setup
    └── tests/                 # Windows test configs
```

### Shared Development Files
- PowerShell scripts work in both containers
- JSON configuration files are platform-agnostic
- Test files use conditional logic for platform differences

## Troubleshooting

### Common Issues

**Linux Container:**
```bash
# If mocks aren't working
Import-Module EndpointPilotMocks -Force

# If PowerShell profile doesn't load
. ~/.config/powershell/Microsoft.PowerShell_profile.ps1
```

**Windows Container:**
```powershell
# If modules fail to install
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# If registry tests fail
Test-Path "HKCU:\Software" # Verify registry access
```

**Both Containers:**
```powershell
# Verify Pester installation
Get-Module -ListAvailable Pester

# Check PowerShell version compatibility
$PSVersionTable
```

### Performance Optimization

**Linux Container:**
- Use volume mounts for persistent data
- Leverage Docker layer caching
- Use `.dockerignore` to exclude unnecessary files

**Windows Container:**
- Allocate sufficient RAM (minimum 4GB)
- Use SSD storage for better I/O
- Consider Windows container isolation modes

## Best Practices

### Code Development
- Write platform-agnostic PowerShell when possible
- Use `$IsWindows`, `$IsLinux` variables for platform detection
- Test critical paths in both environments
- Leverage container-specific helper functions

### Testing Strategy
- Unit tests → Linux container (fast, mocked)
- Integration tests → Windows container (slower, real)
- End-to-end tests → Real Windows environment

### Container Management
- Rebuild containers after significant changes
- Use volume mounts for persistent development data
- Keep container images updated for security

## Next Steps

- See [TESTING-STRATEGY.md](TESTING-STRATEGY.md) for comprehensive testing approach
- See [CROSS-PLATFORM-DEVELOPMENT.md](CROSS-PLATFORM-DEVELOPMENT.md) for platform compatibility details
- Review container-specific PowerShell profiles for available helper functions