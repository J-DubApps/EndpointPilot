#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs the EndpointPilot System Agent as a Windows Service

.DESCRIPTION
    This script builds, installs, and configures the EndpointPilot System Agent
    Windows Service for system-level operations.

.PARAMETER BuildConfiguration
    The build configuration to use (Debug or Release). Default is Release.

.PARAMETER ServiceName
    The name of the Windows service. Default is "EndpointPilot System Agent".

.PARAMETER Force
    Force reinstallation even if the service already exists.

.PARAMETER RuntimeIdentifier
    Target architecture (win-x64 or win-arm64). Auto-detected if not specified.

.PARAMETER UsePreBuilt
    Use pre-built binaries from SystemAgent/bin folder instead of building from source.

.EXAMPLE
    .\Install-SystemAgent.ps1
    
.EXAMPLE
    .\Install-SystemAgent.ps1 -BuildConfiguration Debug -Force

.EXAMPLE
    .\Install-SystemAgent.ps1 -UsePreBuilt -RuntimeIdentifier win-arm64
#>

param(
    [string]$BuildConfiguration = "Release",
    [string]$ServiceName = "EndpointPilot System Agent",
    [switch]$Force,
    [ValidateSet("win-x64", "win-arm64")]
    [string]$RuntimeIdentifier = "win-x64",
    [switch]$UsePreBuilt
)

# Enable strict mode
Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

# Import required functions
if (Test-Path ".\MGMT-Functions.psm1") {
    Import-Module ".\MGMT-Functions.psm1" -Force
}
if (Test-Path ".\MGMT-SHARED.ps1") {
    . ".\MGMT-SHARED.ps1"
}

function WriteLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# Auto-detect architecture if not specified
if ($RuntimeIdentifier -eq "win-x64" -and $env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    WriteLog "ARM64 architecture detected, switching to win-arm64 build"
    $RuntimeIdentifier = "win-arm64"
}

function Test-DotNetRuntime {
    try {
        $dotnetVersion = & dotnet --version 2>$null
        if ($dotnetVersion) {
            WriteLog "Found .NET Runtime version: $dotnetVersion"
            return $true
        } else {
            WriteLog ".NET Runtime not found" "ERROR"
            return $false
        }
    } catch {
        WriteLog ".NET Runtime not found: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Build-SystemAgent {
    param(
        [string]$Configuration,
        [string]$RuntimeId
    )
    
    try {
        WriteLog "Building System Agent with configuration: $Configuration for $RuntimeId"
        
        $projectPath = Join-Path $PSScriptRoot "SystemAgent\EndpointPilot.SystemAgent.csproj"
        if (!(Test-Path $projectPath)) {
            throw "System Agent project file not found: $projectPath"
        }
        
        $publishPath = Join-Path $PSScriptRoot "SystemAgent\bin\$Configuration\net8.0-windows\$RuntimeId\publish"
        
        # Clean previous build
        if (Test-Path $publishPath) {
            WriteLog "Cleaning previous build: $publishPath"
            Remove-Item -Path $publishPath -Recurse -Force
        }
        
        # Build and publish
        WriteLog "Publishing System Agent..."
        & dotnet publish $projectPath -c $Configuration -r $RuntimeId --self-contained false -o $publishPath
        
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed with exit code: $LASTEXITCODE"
        }
        
        $exePath = Join-Path $publishPath "EndpointPilot.SystemAgent.exe"
        if (!(Test-Path $exePath)) {
            throw "Build output not found: $exePath"
        }
        
        WriteLog "Build completed successfully: $exePath"
        return $publishPath
    } catch {
        WriteLog "Build failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-PreBuiltBinaries {
    param([string]$RuntimeId)
    
    try {
        WriteLog "Using pre-built binaries for: $RuntimeId"
        
        $preBuiltPath = Join-Path $PSScriptRoot "SystemAgent\bin\$RuntimeId"
        if (!(Test-Path $preBuiltPath)) {
            throw "Pre-built binaries not found: $preBuiltPath"
        }
        
        $exePath = Join-Path $preBuiltPath "EndpointPilot.SystemAgent.exe"
        if (!(Test-Path $exePath)) {
            throw "Pre-built executable not found: $exePath"
        }
        
        WriteLog "Found pre-built binaries: $exePath"
        return $preBuiltPath
    } catch {
        WriteLog "Pre-built binaries failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Install-SystemAgentService {
    param(
        [string]$PublishPath,
        [string]$Name,
        [bool]$ForceReinstall
    )
    
    try {
        $exePath = Join-Path $PublishPath "EndpointPilot.SystemAgent.exe"
        $installPath = "$env:ProgramData\EndpointPilot\SystemAgent"
        
        # Check if service already exists
        $existingService = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if ($existingService) {
            if ($ForceReinstall) {
                WriteLog "Removing existing service: $Name"
                Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
                & sc.exe delete $Name
                Start-Sleep -Seconds 2
            } else {
                WriteLog "Service already exists: $Name. Use -Force to reinstall." "WARNING"
                return $false
            }
        }
        
        # Create installation directory
        WriteLog "Creating installation directory: $installPath"
        if (Test-Path $installPath) {
            Remove-Item -Path $installPath -Recurse -Force
        }
        New-Item -Path $installPath -ItemType Directory -Force | Out-Null
        
        # Copy service files
        WriteLog "Copying service files to: $installPath"
        Copy-Item -Path "$PublishPath\*" -Destination $installPath -Recurse -Force
        
        # Copy configuration files to parent EndpointPilot directory
        $endpointPilotPath = "$env:ProgramData\EndpointPilot"
        if (!(Test-Path $endpointPilotPath)) {
            WriteLog "Creating EndpointPilot directory: $endpointPilotPath"
            New-Item -Path $endpointPilotPath -ItemType Directory -Force | Out-Null
        }
        
        WriteLog "Copying configuration files to: $endpointPilotPath"
        $configFiles = @("CONFIG.json", "SYSTEM-OPS.json", "MAIN.PS1")
        foreach ($file in $configFiles) {
            $sourcePath = Join-Path $PSScriptRoot $file
            if (Test-Path $sourcePath) {
                $destPath = Join-Path $endpointPilotPath $file
                if (!(Test-Path $destPath)) {
                    Copy-Item -Path $sourcePath -Destination $destPath -Force
                    WriteLog "Copied: $file"
                } else {
                    WriteLog "Configuration file already exists (preserving): $file" "WARNING"
                }
            } else {
                WriteLog "Configuration file not found: $file" "WARNING"
            }
        }
        
        # Set secure permissions on installation directory
        WriteLog "Setting secure permissions on installation directory"
        $acl = Get-Acl $installPath
        
        # Remove inherited permissions
        $acl.SetAccessRuleProtection($true, $false)
        
        # Grant SYSTEM full control
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "NT AUTHORITY\SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.SetAccessRule($systemRule)
        
        # Grant Administrators full control
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.SetAccessRule($adminRule)
        
        Set-Acl -Path $installPath -AclObject $acl
        
        # Install the service
        $serviceExePath = Join-Path $installPath "EndpointPilot.SystemAgent.exe"
        WriteLog "Installing Windows Service: $Name"
        
        & sc.exe create $Name binpath= $serviceExePath start= auto
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create service with exit code: $LASTEXITCODE"
        }
        
        # Set service description
        & sc.exe description $Name "EndpointPilot System Agent - Provides system-level endpoint configuration management"
        
        # Configure service recovery options
        & sc.exe failure $Name reset= 86400 actions= restart/30000/restart/60000/restart/120000
        
        WriteLog "Service installed successfully: $Name"
        return $true
    } catch {
        WriteLog "Service installation failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Start-SystemAgentService {
    param([string]$Name)
    
    try {
        WriteLog "Starting service: $Name"
        Start-Service -Name $Name
        
        # Wait for service to start
        $timeout = 30
        $timer = 0
        do {
            Start-Sleep -Seconds 1
            $timer++
            $service = Get-Service -Name $Name
        } while ($service.Status -ne "Running" -and $timer -lt $timeout)
        
        if ($service.Status -eq "Running") {
            WriteLog "Service started successfully: $Name"
            return $true
        } else {
            WriteLog "Service failed to start within $timeout seconds" "ERROR"
            return $false
        }
    } catch {
        WriteLog "Failed to start service: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Test-SystemAgentHealth {
    param([string]$Name)
    
    try {
        WriteLog "Testing System Agent health..."
        
        # Check service status
        $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if (!$service) {
            WriteLog "Service not found: $Name" "ERROR"
            return $false
        }
        
        if ($service.Status -ne "Running") {
            WriteLog "Service is not running: $($service.Status)" "ERROR"
            return $false
        }
        
        # Check log file exists and has recent entries
        $logPath = "$env:ProgramData\EndpointPilot\Agent.log"
        if (Test-Path $logPath) {
            $lastWrite = (Get-Item $logPath).LastWriteTime
            $timeDiff = (Get-Date) - $lastWrite
            
            if ($timeDiff.TotalMinutes -lt 10) {
                WriteLog "Agent log is active (last write: $lastWrite)"
            } else {
                WriteLog "Agent log appears stale (last write: $lastWrite)" "WARNING"
            }
        } else {
            WriteLog "Agent log file not found: $logPath" "WARNING"
        }
        
        # Check Windows Event Log
        try {
            $recentEvents = Get-WinEvent -LogName Application -MaxEvents 5 -FilterXPath "*[System[Provider[@Name='EndpointPilot System Agent']]]" -ErrorAction SilentlyContinue
            if ($recentEvents) {
                WriteLog "Found $($recentEvents.Count) recent event log entries"
            } else {
                WriteLog "No recent event log entries found" "WARNING"
            }
        } catch {
            WriteLog "Could not check event log: $($_.Exception.Message)" "WARNING"
        }
        
        WriteLog "System Agent health check completed"
        return $true
    } catch {
        WriteLog "Health check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main installation process
try {
    WriteLog "Starting EndpointPilot System Agent installation"
    WriteLog "Build Configuration: $BuildConfiguration"
    WriteLog "Service Name: $ServiceName"
    WriteLog "Force Reinstall: $Force"
    
    # Verify we're running as administrator
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (!$isAdmin) {
        throw "This script must be run as Administrator"
    }
    
    # Check .NET Runtime
    if (!(Test-DotNetRuntime)) {
        throw ".NET Runtime is required to run the System Agent"
    }
    
    # Get binaries (either build or use pre-built)
    if ($UsePreBuilt) {
        $publishPath = Get-PreBuiltBinaries -RuntimeId $RuntimeIdentifier
    } else {
        $publishPath = Build-SystemAgent -Configuration $BuildConfiguration -RuntimeId $RuntimeIdentifier
    }
    
    # Install the service
    $installed = Install-SystemAgentService -PublishPath $publishPath -Name $ServiceName -ForceReinstall $Force
    
    if ($installed) {
        # Start the service
        $started = Start-SystemAgentService -Name $ServiceName
        
        if ($started) {
            # Test health
            Start-Sleep -Seconds 5  # Allow service to initialize
            Test-SystemAgentHealth -Name $ServiceName
            
            WriteLog "EndpointPilot System Agent installation completed successfully!"
            WriteLog ""
            WriteLog "Next Steps:"
            WriteLog "1. Review/customize configuration files in: $env:ProgramData\EndpointPilot\"
            WriteLog "   - CONFIG.json: General EndpointPilot settings"
            WriteLog "   - SYSTEM-OPS.json: System-level operations"
            WriteLog "   - MAIN.PS1: User-mode operations script"
            WriteLog "2. Monitor service logs at: $env:ProgramData\EndpointPilot\Agent.log"
            WriteLog "3. Check Windows Event Logs for 'EndpointPilot System Agent' source"
            WriteLog ""
            WriteLog "Service Management Commands:"
            WriteLog "  Start:   Start-Service '$ServiceName'"
            WriteLog "  Stop:    Stop-Service '$ServiceName'"
            WriteLog "  Status:  Get-Service '$ServiceName'"
        } else {
            WriteLog "Installation completed but service failed to start properly" "ERROR"
            exit 1
        }
    } else {
        WriteLog "Service installation failed" "ERROR"
        exit 1
    }
} catch {
    WriteLog "Installation failed: $($_.Exception.Message)" "ERROR"
    WriteLog $_.ScriptStackTrace "ERROR"
    exit 1
}