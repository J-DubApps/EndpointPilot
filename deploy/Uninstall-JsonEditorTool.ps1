#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls the EndpointPilot JsonEditorTool application

.DESCRIPTION
    This script removes the EndpointPilot JsonEditorTool WPF application from the system,
    including the installation files and desktop shortcuts.

.PARAMETER InstallLocation
    The installation location to remove (ProgramData, Desktop, or All). Default is All.

.PARAMETER RemoveShortcuts
    Remove desktop shortcuts created during installation.

.PARAMETER Force
    Force removal even if files are in use or access is denied.

.EXAMPLE
    .\Uninstall-JsonEditorTool.ps1
    
.EXAMPLE
    .\Uninstall-JsonEditorTool.ps1 -InstallLocation ProgramData -RemoveShortcuts

.EXAMPLE
    .\Uninstall-JsonEditorTool.ps1 -InstallLocation Desktop -Force
#>

param(
    [ValidateSet("ProgramData", "Desktop", "All")]
    [string]$InstallLocation = "All",
    [switch]$RemoveShortcuts,
    [switch]$Force
)

# Enable strict mode
Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

function WriteLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Get-JsonEditorToolInstallations {
    <#
    .SYNOPSIS
        Discovers JsonEditorTool installations on the system
    #>
    
    $installations = @()
    
    # Check ProgramData location
    $programDataPath = "$env:ProgramData\EndpointPilot\JsonEditorTool"
    if (Test-Path $programDataPath) {
        $installations += @{
            Location = "ProgramData"
            Path = $programDataPath
            Executable = Join-Path $programDataPath "EndpointPilotJsonEditor.App.exe"
        }
    }
    
    # Check Desktop location
    $desktopPath = "$env:USERPROFILE\Desktop\EndpointPilot-JsonEditorTool"
    if (Test-Path $desktopPath) {
        $installations += @{
            Location = "Desktop"
            Path = $desktopPath
            Executable = Join-Path $desktopPath "EndpointPilotJsonEditor.App.exe"
        }
    }
    
    return $installations
}

function Stop-JsonEditorToolProcesses {
    param([bool]$ForceKill)
    
    try {
        WriteLog "Checking for running JsonEditorTool processes..."
        
        $processes = Get-Process | Where-Object { 
            $_.ProcessName -like "*EndpointPilotJsonEditor*" -or 
            $_.ProcessName -like "*JsonEditor*" 
        }
        
        if ($processes) {
            WriteLog "Found $($processes.Count) running JsonEditorTool process(es)"
            
            foreach ($proc in $processes) {
                WriteLog "Stopping process: $($proc.ProcessName) (ID: $($proc.Id))"
                
                if ($ForceKill) {
                    Stop-Process -Id $proc.Id -Force
                } else {
                    $proc.CloseMainWindow()
                    Start-Sleep -Seconds 3
                    
                    # Check if process is still running
                    if (!$proc.HasExited) {
                        WriteLog "Process did not exit gracefully, force stopping..." "WARNING"
                        Stop-Process -Id $proc.Id -Force
                    }
                }
            }
            
            # Wait for processes to fully terminate
            Start-Sleep -Seconds 2
            WriteLog "JsonEditorTool processes stopped"
        } else {
            WriteLog "No running JsonEditorTool processes found"
        }
        
        return $true
    } catch {
        WriteLog "Failed to stop JsonEditorTool processes: $($_.Exception.Message)" "ERROR"
        if (!$ForceKill) {
            throw
        }
        return $false
    }
}

function Remove-JsonEditorToolInstallation {
    param(
        [hashtable]$Installation,
        [bool]$ForceRemoval
    )
    
    try {
        $location = $Installation.Location
        $path = $Installation.Path
        
        WriteLog "Removing JsonEditorTool installation: $location"
        WriteLog "  Path: $path"
        
        if (!(Test-Path $path)) {
            WriteLog "Installation directory not found: $path" "WARNING"
            return $true
        }
        
        # Check if executable exists and get version info
        $exePath = $Installation.Executable
        if (Test-Path $exePath) {
            try {
                $versionInfo = Get-ItemProperty -Path $exePath -ErrorAction SilentlyContinue
                if ($versionInfo) {
                    WriteLog "  Version: $($versionInfo.VersionInfo.FileVersion)"
                }
            } catch {
                # Version info not critical for uninstall
            }
        }
        
        # Remove the installation directory
        WriteLog "Removing files from: $path"
        
        if ($ForceRemoval) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
        } else {
            Remove-Item -Path $path -Recurse -ErrorAction Stop
        }
        
        WriteLog "Installation removed successfully: $location"
        return $true
        
    } catch [System.UnauthorizedAccessException] {
        WriteLog "Access denied removing installation. Try running as Administrator or use -Force." "ERROR"
        if (!$ForceRemoval) {
            throw
        }
        return $false
    } catch [System.IO.IOException] {
        WriteLog "Files may be in use. Close JsonEditorTool and try again, or use -Force." "ERROR"
        if (!$ForceRemoval) {
            throw
        }
        return $false
    } catch {
        WriteLog "Failed to remove installation: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Remove-JsonEditorToolShortcuts {
    try {
        WriteLog "Removing JsonEditorTool desktop shortcuts..."
        
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPatterns = @(
            "EndpointPilot JsonEditor*.lnk",
            "JsonEditor*.lnk",
            "EndpointPilot-JsonEditor*.lnk"
        )
        
        $removedCount = 0
        
        foreach ($pattern in $shortcutPatterns) {
            $shortcuts = Get-ChildItem -Path $desktopPath -Filter $pattern -ErrorAction SilentlyContinue
            
            foreach ($shortcut in $shortcuts) {
                WriteLog "Removing shortcut: $($shortcut.Name)"
                Remove-Item -Path $shortcut.FullName -Force
                $removedCount++
            }
        }
        
        if ($removedCount -gt 0) {
            WriteLog "Removed $removedCount desktop shortcut(s)"
        } else {
            WriteLog "No JsonEditorTool desktop shortcuts found"
        }
        
        return $true
    } catch {
        WriteLog "Failed to remove shortcuts: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-EndpointPilotDirectoryCleanup {
    <#
    .SYNOPSIS
        Checks if parent EndpointPilot directories can be cleaned up
    #>
    
    try {
        # Check ProgramData EndpointPilot directory
        $programDataEP = "$env:ProgramData\EndpointPilot"
        if (Test-Path $programDataEP) {
            $remainingItems = Get-ChildItem -Path $programDataEP -ErrorAction SilentlyContinue
            
            if (!$remainingItems) {
                WriteLog "EndpointPilot ProgramData directory is empty - consider removing: $programDataEP" "INFO"
            } else {
                $itemNames = ($remainingItems | Select-Object -ExpandProperty Name) -join ", "
                WriteLog "EndpointPilot ProgramData directory contains: $itemNames"
            }
        }
        
        return $true
    } catch {
        WriteLog "Failed to check parent directories: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

function Show-UninstallSummary {
    param(
        [array]$RemovedInstallations,
        [bool]$ShortcutsRemoved
    )
    
    WriteLog ""
    WriteLog "=== JsonEditorTool Uninstall Summary ==="
    
    if ($RemovedInstallations.Count -gt 0) {
        WriteLog "Removed installations:"
        foreach ($installation in $RemovedInstallations) {
            WriteLog "  ✓ $($installation.Location): $($installation.Path)"
        }
    } else {
        WriteLog "No installations were removed"
    }
    
    if ($ShortcutsRemoved) {
        WriteLog "  ✓ Desktop shortcuts removed"
    }
    
    WriteLog ""
    WriteLog "Remaining EndpointPilot components:"
    
    # Check for other EndpointPilot components
    $otherComponents = @()
    
    if (Test-Path "$env:ProgramData\EndpointPilot\SystemAgent") {
        $otherComponents += "System Agent"
    }
    
    if (Test-Path "$env:ProgramData\EndpointPilot\MAIN.PS1") {
        $otherComponents += "Core Scripts"
    }
    
    if (Get-Service -Name "EndpointPilot*" -ErrorAction SilentlyContinue) {
        $otherComponents += "Windows Services"
    }
    
    if ($otherComponents.Count -gt 0) {
        foreach ($component in $otherComponents) {
            WriteLog "- $component"
        }
    } else {
        WriteLog "- None found"
    }
    
    WriteLog ""
    WriteLog "EndpointPilot JsonEditorTool has been successfully uninstalled!"
}

# Main uninstallation process
try {
    WriteLog "Starting EndpointPilot JsonEditorTool uninstallation"
    WriteLog "Install Location: $InstallLocation"
    WriteLog "Remove Shortcuts: $RemoveShortcuts"
    WriteLog "Force Removal: $Force"
    
    # Verify we're running as administrator (only required for ProgramData)
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (!$isAdmin -and ($InstallLocation -eq "ProgramData" -or $InstallLocation -eq "All")) {
        WriteLog "Administrator privileges required to remove ProgramData installation" "WARNING"
        WriteLog "Run as Administrator or specify -InstallLocation Desktop" "WARNING"
    }
    
    # Discover existing installations
    $installations = Get-JsonEditorToolInstallations
    
    if ($installations.Count -eq 0) {
        WriteLog "No JsonEditorTool installations found" "WARNING"
        if ($RemoveShortcuts) {
            Remove-JsonEditorToolShortcuts
        }
        WriteLog "Uninstallation completed (nothing to remove)"
        exit 0
    }
    
    WriteLog "Found $($installations.Count) JsonEditorTool installation(s):"
    foreach ($installation in $installations) {
        WriteLog "  - $($installation.Location): $($installation.Path)"
    }
    
    # Stop any running processes
    Stop-JsonEditorToolProcesses -ForceKill $Force
    
    # Filter installations based on location parameter
    $installationsToRemove = if ($InstallLocation -eq "All") {
        $installations
    } else {
        $installations | Where-Object { $_.Location -eq $InstallLocation }
    }
    
    if ($installationsToRemove.Count -eq 0) {
        WriteLog "No installations found for location: $InstallLocation" "WARNING"
    }
    
    # Remove installations
    $removedInstallations = @()
    foreach ($installation in $installationsToRemove) {
        try {
            if (Remove-JsonEditorToolInstallation -Installation $installation -ForceRemoval $Force) {
                $removedInstallations += $installation
            }
        } catch {
            WriteLog "Failed to remove installation at $($installation.Location): $($_.Exception.Message)" "ERROR"
            if (!$Force) {
                throw
            }
        }
    }
    
    # Remove shortcuts if requested
    $shortcutsRemoved = $false
    if ($RemoveShortcuts) {
        $shortcutsRemoved = Remove-JsonEditorToolShortcuts
    }
    
    # Check for cleanup opportunities
    Test-EndpointPilotDirectoryCleanup
    
    # Show summary
    Show-UninstallSummary -RemovedInstallations $removedInstallations -ShortcutsRemoved $shortcutsRemoved
    
} catch {
    WriteLog "Uninstallation failed: $($_.Exception.Message)" "ERROR"
    WriteLog $_.ScriptStackTrace "ERROR"
    exit 1
}