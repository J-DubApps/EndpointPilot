#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls EndpointPilot Core Scripts from system-wide installation

.DESCRIPTION
    This script removes EndpointPilot Core Scripts from %PROGRAMDATA%\EndpointPilot\,
    removes associated scheduled tasks, and cleans up installation artifacts.
    This uninstaller corresponds to Install-EndpointPilot.ps1 (system-wide installation).

.PARAMETER RemoveUserData
    Remove user-specific configuration files and data.

.PARAMETER RemoveScheduledTasks
    Remove EndpointPilot scheduled tasks for all users.

.PARAMETER Force
    Force removal even if files are in use or access is denied.

.PARAMETER KeepLogs
    Preserve log files during uninstallation.

.EXAMPLE
    .\Uninstall-EndpointPilot.ps1
    
.EXAMPLE
    .\Uninstall-EndpointPilot.ps1 -RemoveUserData -RemoveScheduledTasks

.EXAMPLE
    .\Uninstall-EndpointPilot.ps1 -Force -KeepLogs
#>

param(
    [switch]$RemoveUserData,
    [switch]$RemoveScheduledTasks,
    [switch]$Force,
    [switch]$KeepLogs
)

# Enable strict mode
Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

function WriteLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
    
    # Also log to file if possible
    try {
        $logFile = Join-Path $env:TEMP "EndpointPilot-Uninstall.log"
        "$timestamp [$Level] $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
    } catch {
        # Ignore logging errors during uninstall
    }
}

function Get-EndpointPilotInstallation {
    <#
    .SYNOPSIS
        Discovers EndpointPilot Core Scripts installation
    #>
    
    $programDataPath = [Environment]::GetFolderPath('CommonApplicationData')
    $installPath = Join-Path -Path $programDataPath -ChildPath "EndpointPilot"
    
    $installation = @{
        Found = $false
        Path = $installPath
        CoreFiles = @()
        ConfigFiles = @()
        LogFiles = @()
    }
    
    if (Test-Path $installPath) {
        $installation.Found = $true
        
        # Identify core script files
        $coreFilePatterns = @("*.ps1", "*.psm1", "*.psd1", "*.vbs", "*.cmd")
        foreach ($pattern in $coreFilePatterns) {
            $files = Get-ChildItem -Path $installPath -Filter $pattern -File -ErrorAction SilentlyContinue
            $installation.CoreFiles += $files
        }
        
        # Identify configuration files
        $configFilePatterns = @("*.json")
        foreach ($pattern in $configFilePatterns) {
            $files = Get-ChildItem -Path $installPath -Filter $pattern -File -ErrorAction SilentlyContinue
            $installation.ConfigFiles += $files
        }
        
        # Identify log files
        $logFilePatterns = @("*.log", "*.txt")
        foreach ($pattern in $logFilePatterns) {
            $files = Get-ChildItem -Path $installPath -Filter $pattern -File -ErrorAction SilentlyContinue
            $installation.LogFiles += $files
        }
    }
    
    return $installation
}

function Stop-EndpointPilotProcesses {
    param([bool]$ForceKill)
    
    try {
        WriteLog "Checking for running EndpointPilot processes..."
        
        $processes = Get-Process | Where-Object { 
            $_.ProcessName -like "*EndpointPilot*" -or
            ($_.ProcessName -eq "powershell" -and $_.CommandLine -like "*ENDPOINT-PILOT*")
        }
        
        if ($processes) {
            WriteLog "Found $($processes.Count) potential EndpointPilot process(es)"
            
            foreach ($proc in $processes) {
                WriteLog "Stopping process: $($proc.ProcessName) (ID: $($proc.Id))"
                
                if ($ForceKill) {
                    Stop-Process -Id $proc.Id -Force
                } else {
                    try {
                        $proc.CloseMainWindow()
                        Start-Sleep -Seconds 3
                        
                        if (!$proc.HasExited) {
                            WriteLog "Process did not exit gracefully, force stopping..." "WARNING"
                            Stop-Process -Id $proc.Id -Force
                        }
                    } catch {
                        WriteLog "Could not gracefully stop process, force stopping..." "WARNING"
                        Stop-Process -Id $proc.Id -Force
                    }
                }
            }
            
            Start-Sleep -Seconds 2
            WriteLog "EndpointPilot processes stopped"
        } else {
            WriteLog "No running EndpointPilot processes found"
        }
        
        return $true
    } catch {
        WriteLog "Failed to stop EndpointPilot processes: $($_.Exception.Message)" "ERROR"
        if (!$ForceKill) {
            throw
        }
        return $false
    }
}

function Remove-EndpointPilotScheduledTasks {
    try {
        WriteLog "Searching for EndpointPilot scheduled tasks..."
        
        # Get all scheduled tasks with EndpointPilot in the name
        $endpointPilotTasks = Get-ScheduledTask | Where-Object { 
            $_.TaskName -like "*EndpointPilot*" -or 
            $_.Description -like "*EndpointPilot*"
        }
        
        if ($endpointPilotTasks) {
            WriteLog "Found $($endpointPilotTasks.Count) EndpointPilot scheduled task(s)"
            
            foreach ($task in $endpointPilotTasks) {
                WriteLog "Removing scheduled task: $($task.TaskName)"
                WriteLog "  Path: $($task.TaskPath)"
                WriteLog "  State: $($task.State)"
                
                try {
                    # Stop the task if it's running
                    if ($task.State -eq "Running") {
                        WriteLog "Stopping running task: $($task.TaskName)"
                        Stop-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue
                    }
                    
                    # Remove the task
                    Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
                    WriteLog "Successfully removed task: $($task.TaskName)"
                    
                } catch {
                    WriteLog "Failed to remove task $($task.TaskName): $($_.Exception.Message)" "ERROR"
                    if (!$Force) {
                        throw
                    }
                }
            }
        } else {
            WriteLog "No EndpointPilot scheduled tasks found"
        }
        
        return $true
    } catch {
        WriteLog "Failed to remove scheduled tasks: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Remove-EndpointPilotInstallation {
    param(
        [hashtable]$Installation,
        [bool]$ForceRemoval,
        [bool]$PreserveLogs,
        [bool]$RemoveUserConfigs
    )
    
    try {
        $installPath = $Installation.Path
        
        if (!$Installation.Found) {
            WriteLog "No EndpointPilot installation found at: $installPath" "WARNING"
            return $true
        }
        
        WriteLog "Removing EndpointPilot Core Scripts installation"
        WriteLog "  Path: $installPath"
        WriteLog "  Core Files: $($Installation.CoreFiles.Count)"
        WriteLog "  Config Files: $($Installation.ConfigFiles.Count)"
        WriteLog "  Log Files: $($Installation.LogFiles.Count)"
        
        # Backup important configuration if requested
        $backupPath = $null
        if ($Installation.ConfigFiles.Count -gt 0 -and !$RemoveUserConfigs) {
            $backupPath = Join-Path $env:TEMP "EndpointPilot-Config-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            WriteLog "Creating configuration backup: $backupPath"
            New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
            
            foreach ($configFile in $Installation.ConfigFiles) {
                try {
                    Copy-Item -Path $configFile.FullName -Destination $backupPath -Force
                    WriteLog "Backed up: $($configFile.Name)"
                } catch {
                    WriteLog "Failed to backup $($configFile.Name): $($_.Exception.Message)" "WARNING"
                }
            }
        }
        
        # Backup logs if requested
        if ($PreserveLogs -and $Installation.LogFiles.Count -gt 0) {
            $logBackupPath = Join-Path $env:TEMP "EndpointPilot-Logs-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            WriteLog "Creating log backup: $logBackupPath"
            New-Item -Path $logBackupPath -ItemType Directory -Force | Out-Null
            
            foreach ($logFile in $Installation.LogFiles) {
                try {
                    Copy-Item -Path $logFile.FullName -Destination $logBackupPath -Force
                    WriteLog "Backed up log: $($logFile.Name)"
                } catch {
                    WriteLog "Failed to backup log $($logFile.Name): $($_.Exception.Message)" "WARNING"
                }
            }
        }
        
        # Remove the installation directory
        WriteLog "Removing installation directory: $installPath"
        
        if ($ForceRemoval) {
            Remove-Item -Path $installPath -Recurse -Force -ErrorAction Stop
        } else {
            Remove-Item -Path $installPath -Recurse -ErrorAction Stop
        }
        
        WriteLog "Installation directory removed successfully"
        
        # Show backup locations
        if ($backupPath -and (Test-Path $backupPath)) {
            WriteLog "Configuration backup saved to: $backupPath"
        }
        if ($PreserveLogs -and $logBackupPath -and (Test-Path $logBackupPath)) {
            WriteLog "Log backup saved to: $logBackupPath"
        }
        
        return $true
        
    } catch [System.UnauthorizedAccessException] {
        WriteLog "Access denied removing installation. Ensure you're running as Administrator." "ERROR"
        throw
    } catch [System.IO.IOException] {
        WriteLog "Files may be in use. Close all EndpointPilot processes and try again." "ERROR"
        throw
    } catch {
        WriteLog "Failed to remove installation: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Remove-EndpointPilotUserData {
    try {
        WriteLog "Searching for user-specific EndpointPilot data..."
        
        # Common user data locations
        $userDataPaths = @(
            "$env:LOCALAPPDATA\EndpointPilot",
            "$env:APPDATA\EndpointPilot",
            "$env:USERPROFILE\EndpointPilot"
        )
        
        $removedCount = 0
        
        foreach ($path in $userDataPaths) {
            if (Test-Path $path) {
                WriteLog "Removing user data: $path"
                try {
                    Remove-Item -Path $path -Recurse -Force
                    $removedCount++
                    WriteLog "Successfully removed user data: $path"
                } catch {
                    WriteLog "Failed to remove user data $path`: $($_.Exception.Message)" "ERROR"
                    if (!$Force) {
                        throw
                    }
                }
            }
        }
        
        if ($removedCount -eq 0) {
            WriteLog "No user-specific EndpointPilot data found"
        } else {
            WriteLog "Removed $removedCount user data location(s)"
        }
        
        return $true
    } catch {
        WriteLog "Failed to remove user data: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Test-RemainingEndpointPilotComponents {
    <#
    .SYNOPSIS
        Checks for remaining EndpointPilot components after uninstall
    #>
    
    $remainingComponents = @()
    
    # Check for System Agent
    if (Get-Service -Name "*EndpointPilot*" -ErrorAction SilentlyContinue) {
        $remainingComponents += "System Agent (Windows Service)"
    }
    
    # Check for JsonEditorTool
    $jsonEditorPaths = @(
        "$env:ProgramData\EndpointPilot\JsonEditorTool",
        "$env:USERPROFILE\Desktop\EndpointPilot-JsonEditorTool"
    )
    
    foreach ($path in $jsonEditorPaths) {
        if (Test-Path $path) {
            $remainingComponents += "JsonEditorTool"
            break
        }
    }
    
    # Check for user installations
    if (Test-Path "$env:LOCALAPPDATA\EndpointPilot") {
        $remainingComponents += "User-mode installation"
    }
    
    return $remainingComponents
}

function Show-UninstallSummary {
    param(
        [bool]$InstallationRemoved,
        [bool]$ScheduledTasksRemoved,
        [bool]$UserDataRemoved,
        [array]$RemainingComponents
    )
    
    WriteLog ""
    WriteLog "=== EndpointPilot Core Scripts Uninstall Summary ==="
    
    if ($InstallationRemoved) {
        WriteLog "✓ Core Scripts installation removed from %PROGRAMDATA%\EndpointPilot"
    } else {
        WriteLog "⚠ Core Scripts installation was not found or not removed"
    }
    
    if ($ScheduledTasksRemoved) {
        WriteLog "✓ Scheduled tasks removed"
    }
    
    if ($UserDataRemoved) {
        WriteLog "✓ User-specific data removed"
    }
    
    WriteLog ""
    WriteLog "Remaining EndpointPilot components:"
    
    if ($RemainingComponents.Count -gt 0) {
        foreach ($component in $RemainingComponents) {
            WriteLog "- $component"
        }
        WriteLog ""
        WriteLog "To completely remove EndpointPilot, also run:"
        WriteLog "- .\Uninstall-SystemAgent.ps1 (if System Agent is installed)"
        WriteLog "- .\Uninstall-JsonEditorTool.ps1 (if JsonEditorTool is installed)"
    } else {
        WriteLog "- None found"
    }
    
    WriteLog ""
    WriteLog "EndpointPilot Core Scripts have been successfully uninstalled!"
}

# Main uninstallation process
try {
    WriteLog "Starting EndpointPilot Core Scripts uninstallation"
    WriteLog "Remove User Data: $RemoveUserData"
    WriteLog "Remove Scheduled Tasks: $RemoveScheduledTasks"
    WriteLog "Force Removal: $Force"
    WriteLog "Keep Logs: $KeepLogs"
    
    # Verify we're running as administrator
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (!$isAdmin) {
        throw "This script must be run as Administrator to remove system-wide installation"
    }
    
    # Discover installation
    $installation = Get-EndpointPilotInstallation
    
    if (!$installation.Found) {
        WriteLog "No EndpointPilot Core Scripts installation found" "WARNING"
        
        # Still try to remove scheduled tasks if requested
        if ($RemoveScheduledTasks) {
            Remove-EndpointPilotScheduledTasks
        }
        
        WriteLog "Uninstallation completed (nothing to remove)"
        exit 0
    }
    
    WriteLog "Found EndpointPilot installation:"
    WriteLog "  Path: $($installation.Path)"
    WriteLog "  Core Files: $($installation.CoreFiles.Count)"
    WriteLog "  Config Files: $($installation.ConfigFiles.Count)"
    WriteLog "  Log Files: $($installation.LogFiles.Count)"
    
    # Stop any running processes
    Stop-EndpointPilotProcesses -ForceKill $Force
    
    # Remove scheduled tasks if requested
    $scheduledTasksRemoved = $false
    if ($RemoveScheduledTasks) {
        Remove-EndpointPilotScheduledTasks
        $scheduledTasksRemoved = $true
    }
    
    # Remove installation
    $installationRemoved = Remove-EndpointPilotInstallation -Installation $installation -ForceRemoval $Force -PreserveLogs $KeepLogs -RemoveUserConfigs $RemoveUserData
    
    # Remove user data if requested
    $userDataRemoved = $false
    if ($RemoveUserData) {
        Remove-EndpointPilotUserData
        $userDataRemoved = $true
    }
    
    # Check for remaining components
    $remainingComponents = Test-RemainingEndpointPilotComponents
    
    # Show summary
    Show-UninstallSummary -InstallationRemoved $installationRemoved -ScheduledTasksRemoved $scheduledTasksRemoved -UserDataRemoved $userDataRemoved -RemainingComponents $remainingComponents
    
} catch {
    WriteLog "Uninstallation failed: $($_.Exception.Message)" "ERROR"
    WriteLog $_.ScriptStackTrace "ERROR"
    exit 1
}