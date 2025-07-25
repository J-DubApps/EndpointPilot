#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs the EndpointPilot JsonEditorTool application

.DESCRIPTION
    This script builds, installs, and configures the EndpointPilot JsonEditorTool
    WPF application for managing EndpointPilot JSON directive files.

.PARAMETER BuildConfiguration
    The build configuration to use (Debug or Release). Default is Release.

.PARAMETER InstallLocation
    Installation location (ProgramData or Desktop). Default is ProgramData.

.PARAMETER RuntimeIdentifier
    Target architecture (win-x64 or win-arm64). Auto-detected if not specified.

.PARAMETER UsePreBuilt
    Use pre-built binaries from JsonEditorTool/bin folder instead of building from source.

.PARAMETER Force
    Force reinstallation even if the application already exists.

.PARAMETER CreateDesktopShortcut
    Create a desktop shortcut for the JsonEditorTool.

.EXAMPLE
    .\Install-JsonEditorTool.ps1
    
.EXAMPLE
    .\Install-JsonEditorTool.ps1 -UsePreBuilt -CreateDesktopShortcut

.EXAMPLE
    .\Install-JsonEditorTool.ps1 -InstallLocation Desktop -RuntimeIdentifier win-arm64
#>

param(
    [string]$BuildConfiguration = "Release",
    [ValidateSet("ProgramData", "Desktop")]
    [string]$InstallLocation = "ProgramData",
    [ValidateSet("win-x64", "win-arm64")]
    [string]$RuntimeIdentifier = "win-x64",
    [switch]$UsePreBuilt,
    [switch]$Force,
    [switch]$CreateDesktopShortcut
)

# Enable strict mode
Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

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
            
            # Check for .NET 9
            $version = [Version]$dotnetVersion.Split('-')[0]
            if ($version.Major -lt 9) {
                WriteLog "Warning: .NET 9.0 Runtime is recommended for JsonEditorTool" "WARNING"
            }
            return $true
        } else {
            WriteLog ".NET Runtime not found" "WARNING"
            return $false
        }
    } catch {
        WriteLog ".NET Runtime not found" "WARNING"
        return $false
    }
}

function Build-JsonEditorTool {
    param(
        [string]$Configuration,
        [string]$RuntimeId
    )
    
    try {
        WriteLog "Building JsonEditorTool with configuration: $Configuration for $RuntimeId"
        
        $parentPath = Split-Path -Parent $PSScriptRoot
        $projectPath = Join-Path $parentPath "JsonEditorTool\EndpointPilotJsonEditor.App\EndpointPilotJsonEditor.App.csproj"
        if (!(Test-Path $projectPath)) {
            throw "JsonEditorTool project file not found: $projectPath"
        }
        
        $publishPath = Join-Path $parentPath "JsonEditorTool\bin\$Configuration\net9.0-windows\$RuntimeId\publish"
        
        # Clean previous build
        if (Test-Path $publishPath) {
            WriteLog "Cleaning previous build: $publishPath"
            Remove-Item -Path $publishPath -Recurse -Force
        }
        
        # Build and publish
        WriteLog "Publishing JsonEditorTool..."
        & dotnet publish $projectPath -c $Configuration -r $RuntimeId --self-contained false -o $publishPath
        
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed with exit code: $LASTEXITCODE"
        }
        
        $exePath = Join-Path $publishPath "EndpointPilotJsonEditor.App.exe"
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
        
        $parentPath = Split-Path -Parent $PSScriptRoot
        $preBuiltPath = Join-Path $parentPath "JsonEditorTool\bin\$RuntimeId"
        if (!(Test-Path $preBuiltPath)) {
            throw "Pre-built binaries not found: $preBuiltPath"
        }
        
        $exePath = Join-Path $preBuiltPath "EndpointPilotJsonEditor.App.exe"
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

function Install-JsonEditorToolApp {
    param(
        [string]$PublishPath,
        [string]$Location,
        [bool]$ForceReinstall
    )
    
    try {
        $exePath = Join-Path $PublishPath "EndpointPilotJsonEditor.App.exe"
        
        # Determine install path
        $installPath = switch ($Location) {
            "ProgramData" { "$env:ProgramData\EndpointPilot\JsonEditorTool" }
            "Desktop" { "$env:USERPROFILE\Desktop\EndpointPilot-JsonEditorTool" }
        }
        
        # Check if already exists
        if (Test-Path $installPath) {
            if ($ForceReinstall) {
                WriteLog "Removing existing installation: $installPath"
                Remove-Item -Path $installPath -Recurse -Force
            } else {
                WriteLog "JsonEditorTool already installed at: $installPath. Use -Force to reinstall." "WARNING"
                return $installPath
            }
        }
        
        # Create installation directory
        WriteLog "Creating installation directory: $installPath"
        New-Item -Path $installPath -ItemType Directory -Force | Out-Null
        
        # Copy application files
        WriteLog "Copying JsonEditorTool files to: $installPath"
        Copy-Item -Path "$PublishPath\*" -Destination $installPath -Recurse -Force
        
        # Set permissions for ProgramData installation
        if ($Location -eq "ProgramData") {
            WriteLog "Setting permissions on installation directory"
            $acl = Get-Acl $installPath
            
            # Grant Users read and execute permissions
            $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
            )
            $acl.SetAccessRule($userRule)
            Set-Acl -Path $installPath -AclObject $acl
        }
        
        # Verify installation
        $finalExe = Join-Path $installPath "EndpointPilotJsonEditor.App.exe"
        if (!(Test-Path $finalExe)) {
            throw "Installation verification failed: $finalExe not found"
        }
        
        WriteLog "JsonEditorTool installed successfully: $finalExe"
        return $installPath
        
    } catch {
        WriteLog "Installation failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function New-DesktopShortcut {
    param(
        [string]$InstallPath
    )
    
    try {
        $exePath = Join-Path $InstallPath "EndpointPilotJsonEditor.App.exe"
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "EndpointPilot JsonEditor.lnk"
        
        WriteLog "Creating desktop shortcut: $shortcutPath"
        
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $exePath
        $shortcut.WorkingDirectory = $InstallPath
        $shortcut.Description = "EndpointPilot JSON Configuration Editor"
        $shortcut.Save()
        
        WriteLog "Desktop shortcut created successfully"
        
    } catch {
        WriteLog "Failed to create desktop shortcut: $($_.Exception.Message)" "WARNING"
    }
}

function Test-JsonEditorTool {
    param([string]$InstallPath)
    
    try {
        WriteLog "Testing JsonEditorTool installation..."
        
        $exePath = Join-Path $InstallPath "EndpointPilotJsonEditor.App.exe"
        if (!(Test-Path $exePath)) {
            WriteLog "JsonEditorTool executable not found: $exePath" "ERROR"
            return $false
        }
        
        # Check file size (should be reasonable for a WPF app)
        $fileInfo = Get-Item $exePath
        $fileSize = [math]::Round($fileInfo.Length / 1MB, 2)
        WriteLog "Executable size: $fileSize MB"
        
        if ($fileSize -lt 0.1) {
            WriteLog "Executable seems too small, installation may be incomplete" "WARNING"
        }
        
        WriteLog "JsonEditorTool installation test passed"
        return $true
        
    } catch {
        WriteLog "JsonEditorTool test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
try {
    WriteLog "Starting EndpointPilot JsonEditorTool installation..."
    WriteLog "Configuration: $BuildConfiguration"
    WriteLog "Architecture: $RuntimeIdentifier"
    WriteLog "Install Location: $InstallLocation"
    
    # Check .NET Runtime (not required for self-contained, but good to check)
    if (!(Test-DotNetRuntime)) {
        WriteLog ".NET 9.0 Runtime is recommended for optimal performance" "WARNING"
    }
    
    # Get binaries (either build or use pre-built)
    if ($UsePreBuilt) {
        $publishPath = Get-PreBuiltBinaries -RuntimeId $RuntimeIdentifier
    } else {
        $publishPath = Build-JsonEditorTool -Configuration $BuildConfiguration -RuntimeId $RuntimeIdentifier
    }
    
    # Install the application
    $installPath = Install-JsonEditorToolApp -PublishPath $publishPath -Location $InstallLocation -ForceReinstall $Force
    
    # Create desktop shortcut if requested
    if ($CreateDesktopShortcut) {
        New-DesktopShortcut -InstallPath $installPath
    }
    
    # Test installation
    $testPassed = Test-JsonEditorTool -InstallPath $installPath
    
    if ($testPassed) {
        WriteLog ""
        WriteLog "🎉 EndpointPilot JsonEditorTool installation completed successfully!"
        WriteLog ""
        WriteLog "Installation Details:"
        WriteLog "  📁 Location: $installPath"
        WriteLog "  🖥️ Architecture: $RuntimeIdentifier"
        WriteLog "  ⚙️ Configuration: $BuildConfiguration"
        WriteLog ""
        WriteLog "Usage:"
        WriteLog "  Double-click: EndpointPilotJsonEditor.App.exe"
        if ($CreateDesktopShortcut) {
            WriteLog "  Or use the desktop shortcut: 'EndpointPilot JsonEditor'"
        }
        WriteLog ""
        WriteLog "The JsonEditorTool provides a graphical interface for:"
        WriteLog "  • Editing CONFIG.json settings"
        WriteLog "  • Managing FILE-OPS.json operations"
        WriteLog "  • Configuring REG-OPS.json registry settings"
        WriteLog "  • Setting up DRIVE-OPS.json drive mappings"
        WriteLog "  • Creating ROAM-OPS.json roaming profiles"
        WriteLog ""
    } else {
        WriteLog "Installation completed but tests failed. Please check the installation manually." "WARNING"
    }
    
} catch {
    WriteLog "JsonEditorTool installation failed: $($_.Exception.Message)" "ERROR"
    exit 1
}