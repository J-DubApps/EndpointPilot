# Cross-Platform Development Guide

## Overview

EndpointPilot is primarily a Windows-targeted solution, but cross-platform development using Linux containers enables faster development cycles, better collaboration, and comprehensive testing. This guide covers the techniques and considerations for developing Windows PowerShell solutions on non-Windows platforms.

## Platform Compatibility Architecture

### PowerShell Core Foundation
EndpointPilot leverages PowerShell Core's cross-platform capabilities while maintaining Windows PowerShell 5.1 compatibility.

**Supported Versions:**
- PowerShell 7.0+ (Cross-platform, preferred for development)
- PowerShell 5.1 (Windows PowerShell, target runtime)

### Platform Detection Strategy
```powershell
# Automatic platform detection
if ($PSVersionTable.PSVersion.Major -ge 6) {
    # PowerShell Core
    $IsWindowsPlatform = $IsWindows
    $IsLinuxPlatform = $IsLinux
    $IsMacPlatform = $IsMacOS
} else {
    # Windows PowerShell 5.1
    $IsWindowsPlatform = $true
    $IsLinuxPlatform = $false
    $IsMacPlatform = $false
}
```

## Windows API Mocking Strategy

### Registry Operations
Windows registry access is mocked on Linux to enable development and testing:

```powershell
# Real Windows implementation
function Get-RegistryValue {
    param($Path, $Name)
    try {
        $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $item.$Name
    } catch {
        return $null
    }
}

# Linux mock implementation (EndpointPilotMocks module)
function Get-ItemProperty {
    param($Path, $Name)
    Write-Warning "MOCK: Registry access - Path: $Path, Name: $Name"
    
    # Return contextual mock data based on path
    switch -Regex ($Path) {
        "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion" {
            return @{ $Name = "10.0.19041" }  # Mock Windows version
        }
        "HKCU:\\Software\\EndpointPilot" {
            return @{ $Name = "MockedUserSetting" }
        }
        default {
            return @{ $Name = "MockedValue" }
        }
    }
}
```

### WMI/CIM Mocking
Windows Management Instrumentation calls are mocked for cross-platform compatibility:

```powershell
# Real Windows implementation
function Get-SystemInfo {
    return Get-CimInstance -ClassName Win32_ComputerSystem
}

# Linux mock implementation
function Get-WmiObject {
    param($Class, $Namespace)
    Write-Warning "MOCK: WMI query - Class: $Class"
    
    switch ($Class) {
        "Win32_ComputerSystem" {
            return @{
                Name = "MOCK-COMPUTER"
                Domain = "MOCKDOMAIN.LOCAL"
                TotalPhysicalMemory = 8589934592
                Manufacturer = "MockVendor"
                Model = "MockModel"
            }
        }
        "Win32_OperatingSystem" {
            return @{
                Caption = "Microsoft Windows 11 Enterprise"
                Version = "10.0.22000"
                Architecture = "64-bit"
                BuildNumber = "22000"
            }
        }
        default {
            return @{ MockProperty = "MockValue" }
        }
    }
}
```

### Active Directory Mocking
AD cmdlets require specialized mocking for development environments:

```powershell
# Real Windows implementation (requires RSAT/AD module)
function Get-DomainInfo {
    return Get-ADDomain
}

# Linux mock implementation
function Get-ADComputer {
    param($Identity)
    Write-Warning "MOCK: AD Computer query - Identity: $Identity"
    return @{
        Name = $Identity
        DistinguishedName = "CN=$Identity,OU=Computers,DC=mock,DC=local"
        DNSHostName = "$Identity.mock.local"
        Enabled = $true
        OperatingSystem = "Windows 11 Enterprise"
    }
}

function Get-ADGroupMember {
    param($Identity)
    Write-Warning "MOCK: AD Group query - Identity: $Identity"
    return @(
        @{ Name = "MockUser1"; SamAccountName = "muser1" }
        @{ Name = "MockUser2"; SamAccountName = "muser2" }
    )
}
```

## Cross-Platform File Handling

### Path Handling
```powershell
# Cross-platform path construction
function Get-EndpointPilotPath {
    param($Subpath)
    
    if ($IsWindowsPlatform) {
        $basePath = "$env:LOCALAPPDATA\EndpointPilot"
    } else {
        # Linux/Mac development
        $basePath = "$HOME/.endpointpilot"
    }
    
    if ($Subpath) {
        return Join-Path -Path $basePath -ChildPath $Subpath
    }
    return $basePath
}
```

### File System Operations
```powershell
# Cross-platform file operations
function Set-FilePermissions {
    param($Path, $Permissions)
    
    if ($IsWindowsPlatform) {
        # Windows ACL management
        $acl = Get-Acl $Path
        # Apply Windows permissions
        Set-Acl -Path $Path -AclObject $acl
    } else {
        # Unix-style permissions for development
        Write-Warning "MOCK: Setting permissions on $Path (Linux mock)"
        # In real scenarios, could use chmod equivalent
    }
}
```

## Development Environment Configuration

### Linux Container Mocking Module
The `EndpointPilotMocks` module provides comprehensive Windows API simulation:

```powershell
# Module structure
EndpointPilotMocks/
├── EndpointPilotMocks.psm1      # Main module
├── EndpointPilotMocks.psd1      # Module manifest
├── Registry/
│   └── RegistryMocks.ps1        # Registry-specific mocks
├── WMI/
│   └── WmiMocks.ps1             # WMI/CIM mocks
└── ActiveDirectory/
    └── ADMocks.ps1              # AD cmdlet mocks
```

### Mock Data Configuration
```powershell
# Configurable mock responses
$MockConfiguration = @{
    Registry = @{
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" = @{
            ProductName = "Windows 11 Enterprise"
            CurrentVersion = "10.0"
            CurrentBuild = "22000"
        }
        "HKCU:\Software\EndpointPilot" = @{
            LastRun = (Get-Date).ToString()
            Version = "1.0.0"
        }
    }
    WMI = @{
        ComputerName = "DEV-LINUX-MOCK"
        Domain = "DEVELOPMENT.LOCAL"
        Architecture = "x64"
    }
    ActiveDirectory = @{
        Domain = "dev.local"
        Users = @("testuser1", "testuser2", "admin")
        Groups = @("Domain Users", "EndpointPilot Users")
    }
}
```

## Testing Strategies

### Unit Testing with Mocks
```powershell
Describe "Cross-Platform Unit Tests" {
    BeforeAll {
        if (-not $IsWindowsPlatform) {
            Import-Module EndpointPilotMocks -Force
        }
    }
    
    Context "Registry Operations" {
        It "Should handle registry reads cross-platform" {
            $result = Get-RegistryValue -Path "HKLM:\SOFTWARE\Test" -Name "TestValue"
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
```

### Conditional Testing
```powershell
Describe "Platform-Specific Tests" {
    Context "Windows-Only Features" -Skip:(-not $IsWindowsPlatform) {
        It "Should access real registry" {
            { Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" } | Should -Not -Throw
        }
    }
    
    Context "Cross-Platform Features" {
        It "Should work on all platforms" {
            $result = Test-JsonSchema -JsonFile "CONFIG.json"
            $result.Valid | Should -Be $true
        }
    }
}
```

## Development Best Practices

### Code Structure
```powershell
# Platform-agnostic function design
function Invoke-EndpointOperation {
    param(
        [Parameter(Mandatory)]
        [string]$OperationType,
        
        [hashtable]$Parameters
    )
    
    # Validate inputs (cross-platform)
    if (-not $Parameters) {
        throw "Parameters are required"
    }
    
    # Platform-specific implementation
    if ($IsWindowsPlatform) {
        Invoke-WindowsOperation -Type $OperationType -Parameters $Parameters
    } else {
        Invoke-MockOperation -Type $OperationType -Parameters $Parameters
    }
}
```

### Error Handling
```powershell
# Cross-platform error handling
function Handle-PlatformError {
    param($Exception)
    
    if ($IsWindowsPlatform) {
        # Windows-specific error handling
        WriteLog -Level "Error" -Message "Windows error: $($Exception.Message)"
        # Could integrate with Windows Event Log
    } else {
        # Development environment error handling
        WriteLog -Level "Error" -Message "Mock error: $($Exception.Message)"
        # Could integrate with syslog or container logging
    }
}
```

### Logging Strategy
```powershell
function WriteLog {
    param(
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory)]
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $platform = if ($IsWindowsPlatform) { "Windows" } else { "Linux" }
    $logMessage = "[$timestamp] [$platform] [$Level] $Message"
    
    # Cross-platform logging
    if ($IsWindowsPlatform) {
        # Windows Event Log or file
        Add-Content -Path "$env:LOCALAPPDATA\EndpointPilot\EndpointPilot.log" -Value $logMessage
    } else {
        # Linux development logging
        Add-Content -Path "$HOME/.endpointpilot/development.log" -Value $logMessage
        Write-Host $logMessage -ForegroundColor $(
            switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                default { "White" }
            }
        )
    }
}
```

## Performance Considerations

### Mock Performance
- Mocks should be fast and lightweight
- Avoid complex logic in mock implementations
- Cache mock responses where appropriate

### Memory Management
```powershell
# Efficient mock data handling
$script:MockCache = @{}

function Get-CachedMockData {
    param($Key)
    
    if (-not $script:MockCache.ContainsKey($Key)) {
        $script:MockCache[$Key] = Generate-MockData -Type $Key
    }
    
    return $script:MockCache[$Key]
}
```

## Limitations and Considerations

### What Cannot Be Mocked
- **Performance Characteristics**: Real Windows performance vs. mock performance
- **Timing Dependencies**: Windows service startup times, registry lock behavior
- **Security Contexts**: Windows authentication, elevation, impersonation
- **Hardware Integration**: TPM, secure boot, hardware-specific drivers

### When to Use Real Windows Testing
- Security feature validation
- Performance benchmarking
- Hardware compatibility testing
- Final integration validation
- Production deployment validation

### Development Workflow Recommendations
1. **Initial Development**: Linux container with mocks (fast iteration)
2. **Integration Testing**: Windows container (real Windows APIs)
3. **Final Validation**: Real Windows 10/11 environment
4. **Production Testing**: Target Intune/NinjaOne environments

## Troubleshooting Cross-Platform Issues

### Common Problems
```powershell
# Mock not loading
if (-not (Get-Module EndpointPilotMocks)) {
    Import-Module EndpointPilotMocks -Force -ErrorAction Stop
}

# Platform detection issues
if ($null -eq $IsWindowsPlatform) {
    Write-Warning "Platform variables not set - ensuring compatibility"
    $IsWindowsPlatform = ($PSVersionTable.PSVersion.Major -lt 6) -or $IsWindows
}

# Path separator issues
$configPath = Join-Path -Path $basePath -ChildPath "CONFIG.json"  # Cross-platform safe
# Avoid: $configPath = "$basePath\CONFIG.json"  # Windows-only
```

### Debugging Mock Behavior
```powershell
# Enable mock debugging
$env:ENDPOINTPILOT_DEBUG_MOCKS = "true"

# Trace mock calls
function Trace-MockCall {
    param($FunctionName, $Parameters)
    
    if ($env:ENDPOINTPILOT_DEBUG_MOCKS -eq "true") {
        WriteLog -Level "Info" -Message "MOCK CALL: $FunctionName with parameters: $($Parameters | ConvertTo-Json -Compress)"
    }
}
```

## Future Enhancements

### Planned Improvements
- **Enhanced ARM64 Support**: Both Windows ARM64 and Apple Silicon
- **Improved Mock Fidelity**: More accurate Windows behavior simulation
- **Performance Profiling**: Mock vs. real performance comparison tools
- **Mock Recording**: Capture real Windows behavior for mock generation

### Integration Opportunities
- **Container Registry**: Pre-built containers with mock environments
- **CI/CD Templates**: GitHub Actions workflows for cross-platform testing
- **Development Tools**: VS Code extensions for mock management