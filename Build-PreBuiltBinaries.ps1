#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Builds pre-compiled binaries for EndpointPilot System Agent

.DESCRIPTION
    This script builds both x64 and ARM64 versions of the System Agent
    and places them in the SystemAgent/bin folder for distribution.

.PARAMETER BuildConfiguration
    The build configuration to use (Debug or Release). Default is Release.

.PARAMETER Architecture
    Specific architecture to build (win-x64, win-arm64, or both). Default is both.

.EXAMPLE
    .\Build-PreBuiltBinaries.ps1
    
.EXAMPLE
    .\Build-PreBuiltBinaries.ps1 -Architecture win-arm64 -BuildConfiguration Debug
#>

param(
    [string]$BuildConfiguration = "Release",
    [ValidateSet("win-x64", "win-arm64", "both")]
    [string]$Architecture = "both"
)

# Enable strict mode
Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

function WriteLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Build-Architecture {
    param(
        [string]$RuntimeId,
        [string]$Configuration
    )
    
    try {
        WriteLog "Building $RuntimeId binaries..."
        
        $projectPath = Join-Path $PSScriptRoot "SystemAgent\EndpointPilot.SystemAgent.csproj"
        $tempPublishPath = Join-Path $PSScriptRoot "SystemAgent\bin\temp-$RuntimeId"
        $finalPath = Join-Path $PSScriptRoot "SystemAgent\bin\$RuntimeId"
        
        # Clean temp and final directories
        if (Test-Path $tempPublishPath) {
            Remove-Item -Path $tempPublishPath -Recurse -Force
        }
        if (Test-Path $finalPath) {
            Remove-Item -Path $finalPath -Recurse -Force
        }
        
        # Build
        WriteLog "Publishing $RuntimeId..."
        & dotnet publish $projectPath -c $Configuration -r $RuntimeId --self-contained false -o $tempPublishPath
        
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed for $RuntimeId with exit code: $LASTEXITCODE"
        }
        
        # Verify build output
        $exePath = Join-Path $tempPublishPath "EndpointPilot.SystemAgent.exe"
        if (!(Test-Path $exePath)) {
            throw "Build output not found: $exePath"
        }
        
        # Create final directory and copy files
        New-Item -Path $finalPath -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$tempPublishPath\*" -Destination $finalPath -Recurse -Force
        
        # Clean up temp directory
        Remove-Item -Path $tempPublishPath -Recurse -Force
        
        # Get file info
        $finalExe = Join-Path $finalPath "EndpointPilot.SystemAgent.exe"
        $fileInfo = Get-Item $finalExe
        $fileSize = [math]::Round($fileInfo.Length / 1MB, 2)
        
        WriteLog "✅ $RuntimeId build completed: $fileSize MB"
        WriteLog "   Output: $finalPath"
        
    } catch {
        WriteLog "❌ Build failed for $RuntimeId : $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Test-Prerequisites {
    # Check .NET SDK
    try {
        $dotnetVersion = & dotnet --version 2>$null
        if ($dotnetVersion) {
            WriteLog "Found .NET SDK version: $dotnetVersion"
        } else {
            throw ".NET SDK not found"
        }
    } catch {
        WriteLog ".NET SDK is required to build the System Agent" "ERROR"
        throw
    }
    
    # Check project file
    $projectPath = Join-Path $PSScriptRoot "SystemAgent\EndpointPilot.SystemAgent.csproj"
    if (!(Test-Path $projectPath)) {
        WriteLog "System Agent project file not found: $projectPath" "ERROR"
        throw "Project file not found"
    }
}

# Main execution
try {
    WriteLog "Starting pre-built binaries generation..."
    WriteLog "Configuration: $BuildConfiguration"
    WriteLog "Architecture: $Architecture"
    
    Test-Prerequisites
    
    # Create bin directory structure
    $binPath = Join-Path $PSScriptRoot "SystemAgent\bin"
    if (!(Test-Path $binPath)) {
        New-Item -Path $binPath -ItemType Directory -Force | Out-Null
    }
    
    # Build specified architectures
    switch ($Architecture) {
        "win-x64" {
            Build-Architecture -RuntimeId "win-x64" -Configuration $BuildConfiguration
        }
        "win-arm64" {
            Build-Architecture -RuntimeId "win-arm64" -Configuration $BuildConfiguration
        }
        "both" {
            Build-Architecture -RuntimeId "win-x64" -Configuration $BuildConfiguration
            Build-Architecture -RuntimeId "win-arm64" -Configuration $BuildConfiguration
        }
    }
    
    WriteLog ""
    WriteLog "🎉 Pre-built binaries generation completed successfully!"
    WriteLog ""
    WriteLog "Generated binaries:"
    
    if ($Architecture -eq "both" -or $Architecture -eq "win-x64") {
        $x64Path = Join-Path $PSScriptRoot "SystemAgent\bin\win-x64"
        if (Test-Path $x64Path) {
            $x64Files = Get-ChildItem $x64Path | Measure-Object -Property Length -Sum
            $x64Size = [math]::Round($x64Files.Sum / 1MB, 2)
            WriteLog "  📁 win-x64: $($x64Files.Count) files, $x64Size MB"
        }
    }
    
    if ($Architecture -eq "both" -or $Architecture -eq "win-arm64") {
        $arm64Path = Join-Path $PSScriptRoot "SystemAgent\bin\win-arm64"
        if (Test-Path $arm64Path) {
            $arm64Files = Get-ChildItem $arm64Path | Measure-Object -Property Length -Sum
            $arm64Size = [math]::Round($arm64Files.Sum / 1MB, 2)
            WriteLog "  📁 win-arm64: $($arm64Files.Count) files, $arm64Size MB"
        }
    }
    
    WriteLog ""
    WriteLog "Usage:"
    WriteLog "  .\deploy\Install-SystemAgent.ps1 -UsePreBuilt"
    WriteLog "  .\deploy\Install-SystemAgent.ps1 -UsePreBuilt -RuntimeIdentifier win-arm64"
    
} catch {
    WriteLog "Pre-built binaries generation failed: $($_.Exception.Message)" "ERROR"
    exit 1
}