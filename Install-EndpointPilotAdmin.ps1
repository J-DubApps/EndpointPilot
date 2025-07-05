<# 
.SYNOPSIS
    Installer for EndpointPilot
.DESCRIPTION
    Installs EndpointPilot components to the appropriate locations
    - JsonEditorTool to %PROGRAMDATA%\EndpointPilot\JsonEditorTool\
    - Script files to %PROGRAMDATA%\EndpointPilot\
.NOTES
    Author: Julian West
    Version: 1.0.0
    Requires: PowerShell 5.1 or later, Administrator privileges
#>
[CmdletBinding()]
param()

Function WriteLog($LogString) {
    ##########################################################################
    ##	Writes Run info to a logfile set in $LogFile variable
    ##########################################################################

    #Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
}

# Ensure running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires administrator privileges. Attempting to elevate..."
    WriteLog "WARNING: This script requires administrator privileges. Attempting to elevate..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$LogFile = Join-Path -Path $env:windir -ChildPath "Temp\EPilotAdmin-Install-$env:computername.log"

# region OS Architecture
# Determine the OS Architecture (x64, x86, or Arm64)
# This code works in both Windows PowerShell 5.1 (Desktop) and PowerShell Core

# If running under WOW64 (32-bit process on a 64-bit OS), $env:PROCESSOR_ARCHITEW6432 will be defined.
if ($env:PROCESSOR_ARCHITEW6432) {
    $arch = $env:PROCESSOR_ARCHITEW6432
} else {
    $arch = $env:PROCESSOR_ARCHITECTURE
}

# Map the raw architecture value to a friendly output.
switch ($arch) {
    "AMD64" { $archFriendly = "x64" }
    "x86"   { $archFriendly = "x86 (32-bit)" }
    "ARM64" { $archFriendly = "Arm64" }
    default { $archFriendly = "Unknown Architecture ($arch)" }
}
# endregion OS Architecture
# Write-Output "Detected Operating System Architecture: $archFriendly"

If ($archFriendly -eq "x86 (32-bit)") {
    Write-Warning "This script is not supported on 32-bit systems. Please use a 64-bit version of PowerShell."
    WriteLog "WARNING: This script is not supported on 32-bit systems. Please use a 64-bit version of PowerShell."
    exit
}

# Define source and temporary paths
$githubRepoUrl = "https://github.com/J-DubApps/EndpointPilot/archive/refs/heads/main.zip"
$tempDir = Join-Path -Path $env:windir -ChildPath "Temp\EPilotTmp"
$zipFilePath = Join-Path -Path $tempDir -ChildPath "EndpointPilot-main.zip" # Consistent naming
$stagingSourcePath = $null # Will be set after extraction

# --- Download and Extract ---
Write-Host "Preparing temporary staging area..." -ForegroundColor Cyan
WriteLog "Preparing temporary staging area..."

# Create Temp Directory
try {
    if (Test-Path -Path $tempDir) {
        Write-Host "Removing existing temporary directory: $tempDir" -ForegroundColor Yellow
        WriteLog "Removing existing temporary directory: $tempDir"
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Stop
    }
    Write-Host "Creating temporary directory: $tempDir"
    WriteLog "Creating temporary directory: $tempDir"
    New-Item -Path $tempDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Failed to create temporary directory '$tempDir'. Error: $($_.Exception.Message)"
    WriteLog "ERROR: Failed to create temporary directory '$tempDir'. Error: $($_.Exception.Message)"
    exit 1
}

# Download Zip
try {
    Write-Host "Downloading EndpointPilot source from $githubRepoUrl..."
    WriteLog "Downloading EndpointPilot source from $githubRepoUrl..."
    Invoke-WebRequest -Uri $githubRepoUrl -OutFile $zipFilePath -UseBasicParsing -ErrorAction Stop
    Write-Host "Download complete: $zipFilePath" -ForegroundColor Green
    WriteLog "Download complete: $zipFilePath"
} catch [System.Net.WebException] {
    Write-Error "Failed to download file from '$githubRepoUrl'. Status: $($_.Exception.Response.StatusCode). Error: $($_.Exception.Message)"
    WriteLog "ERROR: Failed to download file from '$githubRepoUrl'. Status: $($_.Exception.Response.StatusCode). Error: $($_.Exception.Message)"
    # Clean up partial download if it exists
    if (Test-Path -Path $zipFilePath) { Remove-Item -Path $zipFilePath -Force }
    # Clean up temp dir
    if (Test-Path -Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
    exit 1
} catch {
    Write-Error "An unexpected error occurred during download. Error: $($_.Exception.Message)"
    WriteLog "ERROR: An unexpected error occurred during download. Error: $($_.Exception.Message)"
    # Clean up partial download if it exists
    if (Test-Path -Path $zipFilePath) { Remove-Item -Path $zipFilePath -Force }
    # Clean up temp dir
    if (Test-Path -Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
    exit 1
}

# Extract Zip
try {
    Write-Host "Extracting archive $zipFilePath to $tempDir..."
    WriteLog "Extracting archive $zipFilePath to $tempDir..."
    Expand-Archive -Path $zipFilePath -DestinationPath $tempDir -Force -ErrorAction Stop
    Write-Host "Extraction complete." -ForegroundColor Green
    WriteLog "Extraction complete."
} catch {
    Write-Error "Failed to extract archive '$zipFilePath'. Error: $($_.Exception.Message)"
    WriteLog "ERROR: Failed to extract archive '$zipFilePath'. Error: $($_.Exception.Message)"
    # Clean up zip and temp dir
    if (Test-Path -Path $zipFilePath) { Remove-Item -Path $zipFilePath -Force }
    if (Test-Path -Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
    exit 1
}

# Identify Extracted Folder and Set Staging Path
try {
    $extractedItems = Get-ChildItem -Path $tempDir -Directory -ErrorAction Stop
    if ($extractedItems.Count -ne 1) {
        # Handle case where zip might contain multiple top-level items or none
        $expectedFolderName = "EndpointPilot-main" # Common pattern for GitHub zips
        $potentialPath = Join-Path -Path $tempDir -ChildPath $expectedFolderName
        if (Test-Path -Path $potentialPath -PathType Container) {
             $stagingSourcePath = $potentialPath
        } else {
            throw "Expected exactly one directory or '$expectedFolderName' after extraction, but structure is different. Contents: $($extractedItems.Name -join ', ')"
        }
    } else {
         $stagingSourcePath = $extractedItems[0].FullName
    }

    if (-not (Test-Path -Path $stagingSourcePath -PathType Container)) {
        throw "Determined staging source path '$stagingSourcePath' does not exist or is not a directory."
    }
    Write-Host "Staging source path set to: $stagingSourcePath" -ForegroundColor Green
    WriteLog "Staging source path set to: $stagingSourcePath"

} catch {
    Write-Error "Failed to identify the extracted source directory in '$tempDir'. Error: $($_.Exception.Message)"
    WriteLog "ERROR: Failed to identify the extracted source directory in '$tempDir'. Error: $($_.Exception.Message)"
    # Clean up zip and temp dir
    if (Test-Path -Path $zipFilePath) { Remove-Item -Path $zipFilePath -Force }
    if (Test-Path -Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
    exit 1
}

# Cleanup downloaded zip file now that it's extracted
Write-Host "Removing downloaded zip file: $zipFilePath"
WriteLog "Removing downloaded zip file: $zipFilePath"
Remove-Item -Path $zipFilePath -Force
# --- End Download and Extract ---

# Define installation paths
$programDataPath = [Environment]::GetFolderPath('CommonApplicationData')
$baseInstallPath = Join-Path -Path $programDataPath -ChildPath "EndpointPilot"
$jsonEditorToolPath = Join-Path -Path $baseInstallPath -ChildPath "JsonEditorTool"
$agentInstallPath = Join-Path -Path $env:ProgramFiles -ChildPath "EndpointPilot System Agent"

# --- Start Main Installation ---
try {
    # Create directories if they don't exist
Write-Host "Creating installation directories..." -ForegroundColor Cyan
WriteLog "Creating installation directories..."
if (-not (Test-Path -Path $baseInstallPath)) {
    New-Item -Path $baseInstallPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $jsonEditorToolPath)) {
    New-Item -Path $jsonEditorToolPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $agentInstallPath)) {
    New-Item -Path $agentInstallPath -ItemType Directory -Force | Out-Null
}

# Install JsonEditorTool
Write-Host "Installing JsonEditorTool..." -ForegroundColor Cyan
WriteLog "Installing JsonEditorTool..."
If ($archFriendly -eq "x64") { $jsonEditorSourcePath = Join-Path -Path $stagingSourcePath -ChildPath "JsonEditorTool\publish" }
If ($archFriendly -eq "Arm64") { $jsonEditorSourcePath = Join-Path -Path $stagingSourcePath -ChildPath "JsonEditorTool\publish-arm64" }
if (Test-Path -Path $jsonEditorSourcePath) {
    Copy-Item -Path "$jsonEditorSourcePath\*" -Destination $jsonEditorToolPath -Recurse -Force
    Write-Host "JsonEditorTool installed successfully." -ForegroundColor Green
    WriteLog "JsonEditorTool installed successfully."
} else {
    Write-Warning "JsonEditorTool source path not found: $jsonEditorSourcePath"
    WriteLog "WARNING: JsonEditorTool source path not found: $jsonEditorSourcePath"
}

# Install System Agent Service
Write-Host "Installing EndpointPilot System Agent..." -ForegroundColor Cyan
WriteLog "Installing EndpointPilot System Agent..."
$agentSourcePath = Join-Path -Path $stagingSourcePath -ChildPath "SystemAgent\publish"
if (Test-Path -Path $agentSourcePath) {
    # Copy files
    Copy-Item -Path "$agentSourcePath\*" -Destination $agentInstallPath -Recurse -Force
    Write-Host "System Agent files installed to $agentInstallPath" -ForegroundColor Green
    WriteLog "System Agent files installed to $agentInstallPath"

    # Create and Start Service
    $serviceExe = Join-Path -Path $agentInstallPath -ChildPath "EndpointPilot.SystemAgent.exe"
    if (Test-Path $serviceExe) {
        Write-Host "Creating and starting the Windows Service..."
        WriteLog "Creating and starting the Windows Service..."
        try {
            if (Get-Service -Name "EndpointPilotSystemAgent" -ErrorAction SilentlyContinue) {
                Write-Host "Service already exists. Removing it before reinstalling." -ForegroundColor Yellow
                WriteLog "Service already exists. Removing it before reinstalling."
                Stop-Service -Name "EndpointPilotSystemAgent" -Force -ErrorAction SilentlyContinue
                Get-Service -Name "EndpointPilotSystemAgent" | Remove-Service -Force -ErrorAction Stop
                Start-Sleep -Seconds 5 # Give time for service to be removed
            }
            New-Service -Name "EndpointPilotSystemAgent" -BinaryPathName $serviceExe -DisplayName "EndpointPilot System Agent" -Description "Provides system-level configuration and management for EndpointPilot." -StartupType Automatic -Credential "NT AUTHORITY\SYSTEM" -ErrorAction Stop
            Start-Service -Name "EndpointPilotSystemAgent" -ErrorAction Stop
            Write-Host "System Agent service created and started successfully." -ForegroundColor Green
            WriteLog "System Agent service created and started successfully."
        } catch {
            Write-Error "Failed to create or start the System Agent service. Error: $($_.Exception.Message)"
            WriteLog "ERROR: Failed to create or start the System Agent service. Error: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "System Agent executable not found at '$serviceExe'. Cannot create service."
        WriteLog "WARNING: System Agent executable not found at '$serviceExe'. Cannot create service."
    }
} else {
    Write-Warning "System Agent source path not found: $agentSourcePath"
    WriteLog "WARNING: System Agent source path not found: $agentSourcePath"
}

# Install script files
Write-Host "Installing EndpointPilot scripts..." -ForegroundColor Cyan
WriteLog "Installing EndpointPilot scripts..."
$scriptExtensions = @("*.ps1", "*.psm1", "*.psd1", "*.json", "*.cmd", "*.exe", "*.vbs")
$filesInstalled = 0

foreach ($extension in $scriptExtensions) {
    $files = Get-ChildItem -Path $stagingSourcePath -Filter $extension -File
    foreach ($file in $files) {
        # Skip the installer itself
        if ($file.Name -eq "Install-EndpointPilotAdmin.ps1") { # Ensure we skip the correct installer name
            continue
        }
        
        Copy-Item -Path $file.FullName -Destination $baseInstallPath -Force
        $filesInstalled++
    }
}

Write-Host "Installed $filesInstalled script files." -ForegroundColor Green
WriteLog "Installed $filesInstalled script files."

# Create desktop shortcut (optional)
$createShortcut = Read-Host "Create desktop shortcut for JsonEditorTool? (Y/N)"
if ($createShortcut -eq "Y" -or $createShortcut -eq "y") {
    $jsonEditorExePath = Join-Path -Path $jsonEditorToolPath -ChildPath "EndpointPilotJsonEditor.App.exe"
    
    if (Test-Path -Path $jsonEditorExePath) {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\EndpointPilot JSON Editor.lnk")
        $Shortcut.TargetPath = $jsonEditorExePath
        $Shortcut.Save()
        Write-Host "Desktop shortcut created." -ForegroundColor Green
        WriteLog "Desktop shortcut created."
    } else {
        Write-Warning "JsonEditorTool executable not found: $jsonEditorExePath"
        WriteLog "WARNING: JsonEditorTool executable not found: $jsonEditorExePath"
    }
}

# Installation summary
Write-Host "`nEndpointPilot installation complete!" -ForegroundColor Green
WriteLog "`nEndpointPilot installation complete!"
Write-Host "JsonEditorTool installed to: $jsonEditorToolPath" -ForegroundColor Yellow
WriteLog "JsonEditorTool installed to: $jsonEditorToolPath"
Write-Host "Scripts installed to: $baseInstallPath" -ForegroundColor Yellow
WriteLog "Scripts installed to: $baseInstallPath"

# Optional: Create uninstaller
$createUninstaller = Read-Host "Create uninstaller script? (Y/N)"
if ($createUninstaller -eq "Y" -or $createUninstaller -eq "y") {
    $uninstallerPath = Join-Path -Path $baseInstallPath -ChildPath "Uninstall-EndpointPilot.ps1"
    
    $uninstallerContent = @"
<# 
.SYNOPSIS
    Uninstaller for EndpointPilot
.DESCRIPTION
    Removes EndpointPilot components from the system
#>
[CmdletBinding()]
param()

# Ensure running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires administrator privileges. Attempting to elevate..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"```$PSCommandPath`"" -Verb RunAs
    exit
}

# Define installation paths
```$programDataPath = [Environment]::GetFolderPath('CommonApplicationData')
```$baseInstallPath = Join-Path -Path ```$programDataPath -ChildPath "EndpointPilot"
```$jsonEditorToolPath = Join-Path -Path ```$baseInstallPath -ChildPath "JsonEditorTool"

# Remove System Agent Service
if (Get-Service -Name "EndpointPilotSystemAgent" -ErrorAction SilentlyContinue) {
    Write-Host "Stopping and removing EndpointPilot System Agent service..." -ForegroundColor Cyan
    Stop-Service -Name "EndpointPilotSystemAgent" -Force -ErrorAction SilentlyContinue
    Get-Service -Name "EndpointPilotSystemAgent" | Remove-Service -Force
}

# Remove agent installation directory
```$agentInstallPath = Join-Path -Path ```$env:ProgramFiles -ChildPath "EndpointPilot System Agent"
if (Test-Path -Path ```$agentInstallPath) {
    Write-Host "Removing System Agent directory..." -ForegroundColor Cyan
    Remove-Item -Path ```$agentInstallPath -Recurse -Force
}

# Remove desktop shortcut if it exists
```$shortcutPath = "```$env:PUBLIC\Desktop\EndpointPilot JSON Editor.lnk"
if (Test-Path -Path ```$shortcutPath) {
    Write-Host "Removing desktop shortcut..." -ForegroundColor Cyan
    Remove-Item -Path ```$shortcutPath -Force
}

# Remove installation directories
if (Test-Path -Path ```$baseInstallPath) {
    Write-Host "Removing EndpointPilot files..." -ForegroundColor Cyan
    Remove-Item -Path ```$baseInstallPath -Recurse -Force
}

Write-Host "EndpointPilot has been uninstalled." -ForegroundColor Green
"@
    
    Set-Content -Path $uninstallerPath -Value $uninstallerContent
    Write-Host "Uninstaller created at: $uninstallerPath" -ForegroundColor Green
    WriteLog "Uninstaller created at: $uninstallerPath"
}
} # End Try block
finally {
    Write-Host "`nPerforming cleanup..." -ForegroundColor Cyan
    WriteLog "`nPerforming cleanup..."
    if ($null -ne $tempDir -and (Test-Path -Path $tempDir)) {
        Write-Host "Removing temporary directory: $tempDir"
        WriteLog "Removing temporary directory: $tempDir"
        Remove-Item -Path $tempDir -Recurse -Force
        Write-Host "Temporary directory removed." -ForegroundColor Green
        WriteLog "Temporary directory removed."
    } else {
        Write-Host "Temporary directory path is invalid or not found, skipping removal." -ForegroundColor Yellow
        WriteLog "Temporary directory path is invalid or not found, skipping removal."
    }
}
# --- End Main Installation ---

Write-Host "`nThank you for installing EndpointPilot!" -ForegroundColor Cyan
WriteLog "`nThank you for installing EndpointPilot!"