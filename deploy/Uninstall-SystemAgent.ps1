#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls the EndpointPilot System Agent Windows Service

.DESCRIPTION
    This script stops and removes the EndpointPilot System Agent Windows Service
    and optionally removes the installation files.

.PARAMETER ServiceName
    The name of the Windows service. Default is "EndpointPilot System Agent".

.PARAMETER RemoveFiles
    Remove the installation files after uninstalling the service.

.PARAMETER Force
    Force removal even if the service is running.

.EXAMPLE
    .\Uninstall-SystemAgent.ps1
    
.EXAMPLE
    .\Uninstall-SystemAgent.ps1 -RemoveFiles -Force
#>

param(
    [string]$ServiceName = "EndpointPilot System Agent",
    [switch]$RemoveFiles,
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

function Remove-SystemAgentService {
    param(
        [string]$Name,
        [bool]$ForceRemoval
    )
    
    try {
        # Check if service exists
        $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if (!$service) {
            WriteLog "Service not found: $Name" "WARNING"
            return $true
        }
        
        WriteLog "Found service: $Name (Status: $($service.Status))"
        
        # Stop the service if running
        if ($service.Status -eq "Running") {
            WriteLog "Stopping service: $Name"
            
            if ($ForceRemoval) {
                Stop-Service -Name $Name -Force
            } else {
                Stop-Service -Name $Name
            }
            
            # Wait for service to stop
            $timeout = 30
            $timer = 0
            do {
                Start-Sleep -Seconds 1
                $timer++
                $service = Get-Service -Name $Name
            } while ($service.Status -ne "Stopped" -and $timer -lt $timeout)
            
            if ($service.Status -ne "Stopped") {
                if ($ForceRemoval) {
                    WriteLog "Force killing service process..." "WARNING"
                    # This is a last resort - try to kill the process
                    $processes = Get-Process | Where-Object { $_.ProcessName -like "*EndpointPilot*" }
                    foreach ($proc in $processes) {
                        WriteLog "Killing process: $($proc.ProcessName) (ID: $($proc.Id))"
                        Stop-Process -Id $proc.Id -Force
                    }
                } else {
                    throw "Service failed to stop within $timeout seconds"
                }
            } else {
                WriteLog "Service stopped successfully"
            }
        }
        
        # Delete the service
        WriteLog "Removing service: $Name"
        & sc.exe delete $Name
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete service with exit code: $LASTEXITCODE"
        }
        
        WriteLog "Service removed successfully: $Name"
        return $true
    } catch {
        WriteLog "Failed to remove service: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Remove-SystemAgentFiles {
    try {
        $installPath = "$env:ProgramData\EndpointPilot\SystemAgent"
        
        if (!(Test-Path $installPath)) {
            WriteLog "Installation directory not found: $installPath" "WARNING"
            return $true
        }
        
        WriteLog "Removing installation files from: $installPath"
        
        # Remove the SystemAgent directory
        Remove-Item -Path $installPath -Recurse -Force
        
        WriteLog "Installation files removed successfully"
        
        # Check if parent EndpointPilot directory is empty (except for user-mode files)
        $parentDir = "$env:ProgramData\EndpointPilot"
        $remainingItems = Get-ChildItem -Path $parentDir -ErrorAction SilentlyContinue
        
        if ($remainingItems) {
            $fileCount = ($remainingItems | Measure-Object).Count
            WriteLog "EndpointPilot directory contains $fileCount remaining items (user-mode files)"
        } else {
            WriteLog "EndpointPilot directory is empty - consider removing it if no longer needed" "INFO"
        }
        
        return $true
    } catch {
        WriteLog "Failed to remove installation files: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Show-UninstallSummary {
    param(
        [string]$ServiceName,
        [bool]$FilesRemoved
    )
    
    WriteLog ""
    WriteLog "=== Uninstall Summary ==="
    WriteLog "Service '$ServiceName' has been removed"
    
    if ($FilesRemoved) {
        WriteLog "Installation files have been removed"
    } else {
        WriteLog "Installation files remain at: $env:ProgramData\EndpointPilot\SystemAgent"
        WriteLog "Use -RemoveFiles parameter to remove them"
    }
    
    WriteLog ""
    WriteLog "Remaining EndpointPilot components:"
    
    # Check for user-mode files
    $userModeFiles = @(
        "$env:ProgramData\EndpointPilot\MAIN.PS1",
        "$env:ProgramData\EndpointPilot\CONFIG.json",
        "$env:ProgramData\EndpointPilot\FILE-OPS.json"
    )
    
    $foundUserFiles = $false
    foreach ($file in $userModeFiles) {
        if (Test-Path $file) {
            if (!$foundUserFiles) {
                WriteLog "- User-mode EndpointPilot files (still active)"
                $foundUserFiles = $true
            }
        }
    }
    
    # Check for log files
    $logFile = "$env:ProgramData\EndpointPilot\Agent.log"
    if (Test-Path $logFile) {
        WriteLog "- System Agent log files"
    }
    
    if (!$foundUserFiles -and !(Test-Path $logFile)) {
        WriteLog "- None found"
    }
    
    WriteLog ""
    WriteLog "EndpointPilot System Agent has been successfully uninstalled!"
}

# Main uninstallation process
try {
    WriteLog "Starting EndpointPilot System Agent uninstallation"
    WriteLog "Service Name: $ServiceName"
    WriteLog "Remove Files: $RemoveFiles"
    WriteLog "Force Removal: $Force"
    
    # Verify we're running as administrator
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (!$isAdmin) {
        throw "This script must be run as Administrator"
    }
    
    # Remove the service
    Remove-SystemAgentService -Name $ServiceName -ForceRemoval $Force
    
    # Remove files if requested
    if ($RemoveFiles) {
        Remove-SystemAgentFiles
    }
    
    # Show summary
    Show-UninstallSummary -ServiceName $ServiceName -FilesRemoved $RemoveFiles
    
} catch {
    WriteLog "Uninstallation failed: $($_.Exception.Message)" "ERROR"
    WriteLog $_.ScriptStackTrace "ERROR"
    exit 1
}