#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Builds pre-compiled binaries for EndpointPilot JsonEditorTool

.DESCRIPTION
    This script builds both x64 and ARM64 versions of the JsonEditorTool
    and places them in the JsonEditorTool/bin folder for distribution.

.PARAMETER BuildConfiguration
    The build configuration to use (Debug or Release). Default is Release.

.PARAMETER Architecture
    Specific architecture to build (win-x64, win-arm64, or both). Default is both.

.PARAMETER OutputToLegacy
    Also copy outputs to existing publish and publish-arm64 folders for backwards compatibility.

.EXAMPLE
    .\Build-JsonEditorTool.ps1
    
.EXAMPLE
    .\Build-JsonEditorTool.ps1 -Architecture win-arm64 -BuildConfiguration Debug

.EXAMPLE
    .\Build-JsonEditorTool.ps1 -OutputToLegacy
#>

param(
    [string]$BuildConfiguration = "Release",
    [ValidateSet("win-x64", "win-arm64", "both")]
    [string]$Architecture = "both",
    [switch]$OutputToLegacy
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
        WriteLog "Building JsonEditorTool $RuntimeId binaries..."
        
        $projectPath = Join-Path $PSScriptRoot "JsonEditorTool\EndpointPilotJsonEditor.App\EndpointPilotJsonEditor.App.csproj"
        $tempPublishPath = Join-Path $PSScriptRoot "JsonEditorTool\bin\temp-$RuntimeId"
        $finalPath = Join-Path $PSScriptRoot "JsonEditorTool\bin\$RuntimeId"
        
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
        $exePath = Join-Path $tempPublishPath "EndpointPilotJsonEditor.App.exe"
        if (!(Test-Path $exePath)) {
            throw "Build output not found: $exePath"
        }
        
        # Create final directory and copy files
        New-Item -Path $finalPath -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$tempPublishPath\*" -Destination $finalPath -Recurse -Force
        
        # Copy to legacy folders if requested
        if ($OutputToLegacy) {
            $legacyPath = switch ($RuntimeId) {
                "win-x64" { Join-Path $PSScriptRoot "JsonEditorTool\publish" }
                "win-arm64" { Join-Path $PSScriptRoot "JsonEditorTool\publish-arm64" }
            }
            
            if (Test-Path $legacyPath) {
                Remove-Item -Path $legacyPath -Recurse -Force
            }
            New-Item -Path $legacyPath -ItemType Directory -Force | Out-Null
            Copy-Item -Path "$tempPublishPath\*" -Destination $legacyPath -Recurse -Force
            WriteLog "Also copied to legacy folder: $legacyPath"
        }
        
        # Clean up temp directory
        Remove-Item -Path $tempPublishPath -Recurse -Force
        
        # Get file info
        $finalExe = Join-Path $finalPath "EndpointPilotJsonEditor.App.exe"
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
            
            # Check if we have .NET 9 or later
            $version = [Version]$dotnetVersion.Split('-')[0]
            if ($version.Major -lt 9) {
                WriteLog "Warning: .NET 9.0 or later is recommended for JsonEditorTool" "WARNING"
            }
        } else {
            throw ".NET SDK not found"
        }
    } catch {
        WriteLog ".NET SDK (9.0+) is required to build JsonEditorTool" "ERROR"
        throw
    }
    
    # Check project file
    $projectPath = Join-Path $PSScriptRoot "JsonEditorTool\EndpointPilotJsonEditor.App\EndpointPilotJsonEditor.App.csproj"
    if (!(Test-Path $projectPath)) {
        WriteLog "JsonEditorTool project file not found: $projectPath" "ERROR"
        throw "Project file not found"
    }
}

# Main execution
try {
    WriteLog "Starting JsonEditorTool pre-built binaries generation..."
    WriteLog "Configuration: $BuildConfiguration"
    WriteLog "Architecture: $Architecture"
    if ($OutputToLegacy) {
        WriteLog "Legacy output: Enabled"
    }
    
    Test-Prerequisites
    
    # Create bin directory structure
    $binPath = Join-Path $PSScriptRoot "JsonEditorTool\bin"
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
    WriteLog "🎉 JsonEditorTool pre-built binaries generation completed successfully!"
    WriteLog ""
    WriteLog "Generated binaries:"
    
    if ($Architecture -eq "both" -or $Architecture -eq "win-x64") {
        $x64Path = Join-Path $PSScriptRoot "JsonEditorTool\bin\win-x64"
        if (Test-Path $x64Path) {
            $x64Files = Get-ChildItem $x64Path | Measure-Object -Property Length -Sum
            $x64Size = [math]::Round($x64Files.Sum / 1MB, 2)
            WriteLog "  📁 win-x64: $($x64Files.Count) files, $x64Size MB"
        }
    }
    
    if ($Architecture -eq "both" -or $Architecture -eq "win-arm64") {
        $arm64Path = Join-Path $PSScriptRoot "JsonEditorTool\bin\win-arm64"
        if (Test-Path $arm64Path) {
            $arm64Files = Get-ChildItem $arm64Path | Measure-Object -Property Length -Sum
            $arm64Size = [math]::Round($arm64Files.Sum / 1MB, 2)
            WriteLog "  📁 win-arm64: $($arm64Files.Count) files, $arm64Size MB"
        }
    }
    
    WriteLog ""
    WriteLog "Usage:"
    WriteLog "  .\Install-JsonEditorTool.ps1 -UsePreBuilt"
    WriteLog "  .\Install-JsonEditorTool.ps1 -UsePreBuilt -RuntimeIdentifier win-arm64"
    
} catch {
    WriteLog "JsonEditorTool pre-built binaries generation failed: $($_.Exception.Message)" "ERROR"
    exit 1
}