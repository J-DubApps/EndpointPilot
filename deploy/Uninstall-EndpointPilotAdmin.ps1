#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls EndpointPilot Admin installation (Core Scripts + JsonEditorTool)

.DESCRIPTION
    This script removes the complete EndpointPilot Admin installation from %PROGRAMDATA%\EndpointPilot\,
    including both Core Scripts and JsonEditorTool, scheduled tasks, and installation artifacts.
    This uninstaller corresponds to Install-EndpointPilotAdmin.ps1 (complete admin installation).

.PARAMETER RemoveUserData
    Remove user-specific configuration files and data.

.PARAMETER RemoveScheduledTasks
    Remove EndpointPilot scheduled tasks for all users.

.PARAMETER RemoveShortcuts
    Remove desktop shortcuts created during installation.

.PARAMETER Force
    Force removal even if files are in use or access is denied.

.PARAMETER KeepLogs
    Preserve log files during uninstallation.

.PARAMETER ComponentsOnly
    Remove only Core Scripts and JsonEditorTool, leave System Agent if installed separately.

.EXAMPLE
    .\Uninstall-EndpointPilotAdmin.ps1
    
.EXAMPLE
    .\Uninstall-EndpointPilotAdmin.ps1 -RemoveUserData -RemoveScheduledTasks -RemoveShortcuts

.EXAMPLE
    .\Uninstall-EndpointPilotAdmin.ps1 -Force -KeepLogs -ComponentsOnly
#>

param(
    [switch]$RemoveUserData,
    [switch]$RemoveScheduledTasks,
    [switch]$RemoveShortcuts,
    [switch]$Force,
    [switch]$KeepLogs,
    [switch]$ComponentsOnly
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
        $logFile = Join-Path $env:TEMP "EndpointPilot-AdminUninstall.log"
        "$timestamp [$Level] $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
    } catch {
        # Ignore logging errors during uninstall
    }
}

function Get-EndpointPilotAdminInstallation {
    <#
    .SYNOPSIS
        Discovers EndpointPilot Admin installation components
    #>
    
    $programDataPath = [Environment]::GetFolderPath('CommonApplicationData')
    $basePath = Join-Path -Path $programDataPath -ChildPath "EndpointPilot"
    $jsonEditorPath = Join-Path -Path $basePath -ChildPath "JsonEditorTool"
    
    $installation = @{
        Found = $false
        BasePath = $basePath
        CoreScripts = @{
            Found = $false
            Path = $basePath
            Files = @()
        }
        JsonEditorTool = @{
            Found = $false
            Path = $jsonEditorPath
            Executable = Join-Path $jsonEditorPath "EndpointPilotJsonEditor.App.exe"
            Files = @()
        }
        SystemAgent = @{
            Found = $false
            Path = Join-Path $basePath "SystemAgent"
            Service = $null
        }
        ConfigFiles = @()
        LogFiles = @()
    }
    
    if (Test-Path $basePath) {
        $installation.Found = $true
        
        # Check for core script files
        $coreFilePatterns = @("*.ps1", "*.psm1", "*.psd1", "*.vbs", "*.cmd")
        foreach ($pattern in $coreFilePatterns) {
            $files = Get-ChildItem -Path $basePath -Filter $pattern -File -ErrorAction SilentlyContinue
            if ($files) {
                $installation.CoreScripts.Found = $true
                $installation.CoreScripts.Files += $files
            }
        }
        
        # Check for JsonEditorTool
        if (Test-Path $jsonEditorPath) {
            $installation.JsonEditorTool.Found = $true
            $installation.JsonEditorTool.Files = Get-ChildItem -Path $jsonEditorPath -Recurse -File -ErrorAction SilentlyContinue
        }
        
        # Check for System Agent
        if (Test-Path $installation.SystemAgent.Path) {
            $installation.SystemAgent.Found = $true
            
            # Check for System Agent service
            $agentService = Get-Service -Name "*EndpointPilot*Agent*" -ErrorAction SilentlyContinue
            if ($agentService) {
                $installation.SystemAgent.Service = $agentService
            }
        }
        
        # Identify configuration and log files
        $configFiles = Get-ChildItem -Path $basePath -Filter "*.json" -File -ErrorAction SilentlyContinue
        $installation.ConfigFiles = $configFiles
        
        $logFiles = Get-ChildItem -Path $basePath -Filter "*.log" -File -ErrorAction SilentlyContinue
        $installation.LogFiles = $logFiles
    }
    
    return $installation
}

function Stop-EndpointPilotProcesses {
    param([bool]$ForceKill)
    
    try {
        WriteLog "Checking for running EndpointPilot processes..."
        
        $processes = Get-Process | Where-Object { 
            $_.ProcessName -like "*EndpointPilot*" -or
            $_.ProcessName -like "*JsonEditor*" -or
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
                    if ($task.State -eq "Running") {
                        WriteLog "Stopping running task: $($task.TaskName)"
                        Stop-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue
                    }
                    
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

function Remove-EndpointPilotShortcuts {
    try {
        WriteLog "Removing EndpointPilot desktop shortcuts..."
        
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPatterns = @(
            "EndpointPilot*.lnk",
            "JsonEditor*.lnk",
            "*EndpointPilot*.lnk"
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
            WriteLog "No EndpointPilot desktop shortcuts found"
        }
        
        return $true
    } catch {
        WriteLog "Failed to remove shortcuts: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Remove-SystemAgentService {
    param(
        [object]$Service,
        [bool]$ForceRemoval
    )
    
    if (!$Service) {
        WriteLog "No System Agent service found to remove"
        return $true
    }
    
    try {
        $serviceName = $Service.Name
        WriteLog "Removing System Agent service: $serviceName"
        WriteLog "  Status: $($Service.Status)"
        
        # Stop the service if running
        if ($Service.Status -eq "Running") {
            WriteLog "Stopping service: $serviceName"
            
            if ($ForceRemoval) {
                Stop-Service -Name $serviceName -Force
            } else {
                Stop-Service -Name $serviceName
            }
            
            # Wait for service to stop
            $timeout = 30
            $timer = 0
            do {
                Start-Sleep -Seconds 1
                $timer++
                $currentService = Get-Service -Name $serviceName
            } while ($currentService.Status -ne "Stopped" -and $timer -lt $timeout)
            
            if ($currentService.Status -ne "Stopped") {
                if ($ForceRemoval) {
                    WriteLog "Force killing service processes..." "WARNING"
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
        WriteLog "Removing service: $serviceName"
        & sc.exe delete $serviceName
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete service with exit code: $LASTEXITCODE"
        }
        
        WriteLog "Service removed successfully: $serviceName"
        return $true
    } catch {
        WriteLog "Failed to remove System Agent service: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Remove-EndpointPilotAdminInstallation {
    param(
        [hashtable]$Installation,
        [bool]$ForceRemoval,
        [bool]$PreserveLogs,
        [bool]$RemoveUserConfigs,
        [bool]$ComponentsOnlyMode
    )
    
    try {
        $basePath = $Installation.BasePath
        
        if (!$Installation.Found) {
            WriteLog "No EndpointPilot Admin installation found at: $basePath" "WARNING"
            return @{
                CoreScriptsRemoved = $false
                JsonEditorToolRemoved = $false
                SystemAgentRemoved = $false
            }
        }
        
        WriteLog "Removing EndpointPilot Admin installation components"
        WriteLog "  Base Path: $basePath"
        WriteLog "  Core Scripts Found: $($Installation.CoreScripts.Found)"
        WriteLog "  JsonEditorTool Found: $($Installation.JsonEditorTool.Found)"
        WriteLog "  System Agent Found: $($Installation.SystemAgent.Found)"
        
        $results = @{
            CoreScriptsRemoved = $false
            JsonEditorToolRemoved = $false
            SystemAgentRemoved = $false
        }
        
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
        $logBackupPath = $null
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
        
        # Remove System Agent service (if found and not in components-only mode)
        if ($Installation.SystemAgent.Found -and !$ComponentsOnlyMode) {
            if ($Installation.SystemAgent.Service) {
                Remove-SystemAgentService -Service $Installation.SystemAgent.Service -ForceRemoval $ForceRemoval
                $results.SystemAgentRemoved = $true
            }
        }
        
        # Remove JsonEditorTool
        if ($Installation.JsonEditorTool.Found) {
            WriteLog "Removing JsonEditorTool: $($Installation.JsonEditorTool.Path)"
            try {
                Remove-Item -Path $Installation.JsonEditorTool.Path -Recurse -Force
                WriteLog "JsonEditorTool removed successfully"
                $results.JsonEditorToolRemoved = $true
            } catch {
                WriteLog "Failed to remove JsonEditorTool: $($_.Exception.Message)" "ERROR"
                if (!$ForceRemoval) {
                    throw
                }
            }
        }
        
        # Remove Core Scripts (but preserve System Agent directory if in components-only mode)
        if ($Installation.CoreScripts.Found) {
            WriteLog "Removing Core Scripts files from: $basePath"
            
            try {
                # Remove individual core script files instead of the entire directory
                foreach ($file in $Installation.CoreScripts.Files) {
                    Remove-Item -Path $file.FullName -Force
                    WriteLog "Removed: $($file.Name)"
                }
                
                # Remove config files if user data removal is requested
                if ($RemoveUserConfigs) {
                    foreach ($configFile in $Installation.ConfigFiles) {
                        Remove-Item -Path $configFile.FullName -Force
                        WriteLog "Removed config: $($configFile.Name)"
                    }
                }
                
                # Remove log files if not preserving them
                if (!$PreserveLogs) {
                    foreach ($logFile in $Installation.LogFiles) {
                        Remove-Item -Path $logFile.FullName -Force
                        WriteLog "Removed log: $($logFile.Name)"
                    }
                }
                
                WriteLog "Core Scripts removed successfully"
                $results.CoreScriptsRemoved = $true
                
                # Check if base directory is now empty (except for System Agent)
                $remainingItems = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue | Where-Object { 
                    $_.Name -ne "SystemAgent" -or !$ComponentsOnlyMode 
                }
                
                if (!$remainingItems -or ($ComponentsOnlyMode -and $remainingItems.Count -eq 1 -and $remainingItems[0].Name -eq "SystemAgent")) {
                    # Directory is empty or only contains System Agent (in components-only mode)
                    if (!$ComponentsOnlyMode) {
                        WriteLog "Removing empty EndpointPilot directory: $basePath"
                        Remove-Item -Path $basePath -Force
                    } else {
                        WriteLog "Preserving System Agent directory as requested"
                    }
                }
                
            } catch {
                WriteLog "Failed to remove core scripts: $($_.Exception.Message)" "ERROR"
                if (!$ForceRemoval) {
                    throw
                }
            }
        }
        
        # Show backup locations
        if ($backupPath -and (Test-Path $backupPath)) {
            WriteLog "Configuration backup saved to: $backupPath"
        }
        if ($logBackupPath -and (Test-Path $logBackupPath)) {
            WriteLog "Log backup saved to: $logBackupPath"
        }
        
        return $results
        
    } catch {
        WriteLog "Failed to remove Admin installation: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Remove-EndpointPilotUserData {
    try {
        WriteLog "Searching for user-specific EndpointPilot data..."
        
        $userDataPaths = @(
            "$env:LOCALAPPDATA\EndpointPilot",
            "$env:APPDATA\EndpointPilot", 
            "$env:USERPROFILE\EndpointPilot",
            "$env:USERPROFILE\Desktop\EndpointPilot-JsonEditorTool"
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

function Show-UninstallSummary {
    param(
        [hashtable]$RemovalResults,
        [bool]$ScheduledTasksRemoved,
        [bool]$ShortcutsRemoved,
        [bool]$UserDataRemoved,
        [bool]$ComponentsOnlyMode
    )
    
    WriteLog ""
    WriteLog "=== EndpointPilot Admin Installation Uninstall Summary ==="
    
    if ($RemovalResults.CoreScriptsRemoved) {
        WriteLog "✓ Core Scripts removed from %PROGRAMDATA%\EndpointPilot"
    } else {
        WriteLog "⚠ Core Scripts were not found or not removed"
    }
    
    if ($RemovalResults.JsonEditorToolRemoved) {
        WriteLog "✓ JsonEditorTool removed"
    } else {
        WriteLog "⚠ JsonEditorTool was not found or not removed"
    }
    
    if ($RemovalResults.SystemAgentRemoved) {
        WriteLog "✓ System Agent service removed"
    } elseif ($ComponentsOnlyMode) {
        WriteLog "ℹ System Agent preserved (components-only mode)"
    } else {
        WriteLog "⚠ System Agent service was not found or not removed"
    }
    
    if ($ScheduledTasksRemoved) {
        WriteLog "✓ Scheduled tasks removed"
    }
    
    if ($ShortcutsRemoved) {
        WriteLog "✓ Desktop shortcuts removed"
    }
    
    if ($UserDataRemoved) {
        WriteLog "✓ User-specific data removed"
    }
    
    WriteLog ""
    WriteLog "Remaining EndpointPilot components:"
    
    # Check for remaining components
    $remainingComponents = @()
    
    if ($ComponentsOnlyMode -and (Get-Service -Name "*EndpointPilot*" -ErrorAction SilentlyContinue)) {
        $remainingComponents += "System Agent (preserved by user request)"
    }
    
    if (Test-Path "$env:LOCALAPPDATA\EndpointPilot") {
        $remainingComponents += "User-mode installation"
    }
    
    if ($remainingComponents.Count -gt 0) {
        foreach ($component in $remainingComponents) {
            WriteLog "- $component"
        }
    } else {
        WriteLog "- None found"
    }
    
    WriteLog ""
    WriteLog "EndpointPilot Admin installation has been successfully uninstalled!"
    
    if ($ComponentsOnlyMode) {
        WriteLog ""
        WriteLog "Note: System Agent was preserved. Use .\Uninstall-SystemAgent.ps1 to remove it separately."
    }
}

# Main uninstallation process
try {
    WriteLog "Starting EndpointPilot Admin installation uninstallation"
    WriteLog "Remove User Data: $RemoveUserData"
    WriteLog "Remove Scheduled Tasks: $RemoveScheduledTasks"
    WriteLog "Remove Shortcuts: $RemoveShortcuts"
    WriteLog "Force Removal: $Force"
    WriteLog "Keep Logs: $KeepLogs"
    WriteLog "Components Only: $ComponentsOnly"
    
    # Verify we're running as administrator
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (!$isAdmin) {
        throw "This script must be run as Administrator to remove system-wide installation"
    }
    
    # Discover installation
    $installation = Get-EndpointPilotAdminInstallation
    
    if (!$installation.Found) {
        WriteLog "No EndpointPilot Admin installation found" "WARNING"
        
        # Still try to remove scheduled tasks and shortcuts if requested
        if ($RemoveScheduledTasks) {
            Remove-EndpointPilotScheduledTasks
        }
        if ($RemoveShortcuts) {
            Remove-EndpointPilotShortcuts
        }
        
        WriteLog "Uninstallation completed (nothing to remove)"
        exit 0
    }
    
    WriteLog "Found EndpointPilot Admin installation:"
    WriteLog "  Base Path: $($installation.BasePath)"
    WriteLog "  Core Scripts: $($installation.CoreScripts.Found) ($($installation.CoreScripts.Files.Count) files)"
    WriteLog "  JsonEditorTool: $($installation.JsonEditorTool.Found) ($($installation.JsonEditorTool.Files.Count) files)"
    WriteLog "  System Agent: $($installation.SystemAgent.Found) (Service: $($installation.SystemAgent.Service -ne $null))"
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
    
    # Remove shortcuts if requested
    $shortcutsRemoved = $false
    if ($RemoveShortcuts) {
        $shortcutsRemoved = Remove-EndpointPilotShortcuts
    }
    
    # Remove installation components
    $removalResults = Remove-EndpointPilotAdminInstallation -Installation $installation -ForceRemoval $Force -PreserveLogs $KeepLogs -RemoveUserConfigs $RemoveUserData -ComponentsOnlyMode $ComponentsOnly
    
    # Remove user data if requested
    $userDataRemoved = $false
    if ($RemoveUserData) {
        Remove-EndpointPilotUserData
        $userDataRemoved = $true
    }
    
    # Show summary
    Show-UninstallSummary -RemovalResults $removalResults -ScheduledTasksRemoved $scheduledTasksRemoved -ShortcutsRemoved $shortcutsRemoved -UserDataRemoved $userDataRemoved -ComponentsOnlyMode $ComponentsOnly
    
} catch {
    WriteLog "Uninstallation failed: $($_.Exception.Message)" "ERROR"
    WriteLog $_.ScriptStackTrace "ERROR"
    exit 1
}