<# 
.SYNOPSIS
    Updater for EndpointPilot
.DESCRIPTION
    Updates EndpointPilot components to the appropriate locations, preserving specific configuration files.
    - JsonEditorTool to %PROGRAMDATA%\EndpointPilot\JsonEditorTool\
    - Script files to %PROGRAMDATA%\EndpointPilot\, preserving specific configuration files.
.NOTES
    Author: Julian West
    Version: 1.0.0 (Update)
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

$LogFile = Join-Path -Path $env:windir -ChildPath "Temp\EPilotAdmin-Update-$env:computername.log" # Updated log file name

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
$tempDir = Join-Path -Path $env:windir -ChildPath "Temp\EPilotTmpUpdate" # Use a different temp dir name potentially
$zipFilePath = Join-Path -Path $tempDir -ChildPath "EndpointPilot-main.zip" # Consistent naming
$stagingSourcePath = $null # Will be set after extraction

# --- Download and Extract ---
Write-Host "Preparing temporary staging area for update..." -ForegroundColor Cyan
WriteLog "Preparing temporary staging area for update..."

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
    Write-Host "Downloading latest EndpointPilot source from $githubRepoUrl..."
    WriteLog "Downloading latest EndpointPilot source from $githubRepoUrl..."
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

# --- Start Main Update ---
try {
    # Create directories if they don't exist (might be redundant for update, but safe)
    Write-Host "Ensuring installation directories exist..." -ForegroundColor Cyan
    WriteLog "Ensuring installation directories exist..."
    if (-not (Test-Path -Path $baseInstallPath)) {
        New-Item -Path $baseInstallPath -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path -Path $jsonEditorToolPath)) {
        New-Item -Path $jsonEditorToolPath -ItemType Directory -Force | Out-Null
    }

    # Update JsonEditorTool
    Write-Host "Updating JsonEditorTool..." -ForegroundColor Cyan
    WriteLog "Updating JsonEditorTool..."
    If ($archFriendly -eq "x64") { $jsonEditorSourcePath = Join-Path -Path $stagingSourcePath -ChildPath "JsonEditorTool\publish" }
    If ($archFriendly -eq "Arm64") { $jsonEditorSourcePath = Join-Path -Path $stagingSourcePath -ChildPath "JsonEditorTool\publish-arm64" }
    if (Test-Path -Path $jsonEditorSourcePath) {
        Copy-Item -Path "$jsonEditorSourcePath\*" -Destination $jsonEditorToolPath -Recurse -Force
        Write-Host "JsonEditorTool updated successfully." -ForegroundColor Green
        WriteLog "JsonEditorTool updated successfully."
    } else {
        Write-Warning "JsonEditorTool source path not found: $jsonEditorSourcePath"
        WriteLog "WARNING: JsonEditorTool source path not found: $jsonEditorSourcePath"
    }

    # Update script files, excluding specific JSON configs
    Write-Host "Updating EndpointPilot scripts..." -ForegroundColor Cyan
    WriteLog "Updating EndpointPilot scripts..."
    $scriptExtensions = @("*.ps1", "*.psm1", "*.psd1", "*.json", "*.cmd", "*.exe", "*.vbs")
    $filesInstalled = 0 # Renamed to filesUpdated for clarity
    $filesUpdated = 0

    # Define configuration files to exclude from overwrite during update
    $excludedConfigFiles = @("CONFIG.json", "REG-OPS.json", "FILE-OPS.json", "DRIVE-OPS.json")
    $selfInstallerName = "Install-EndpointPilotAdmin.ps1" # Original installer name
    $selfUpdaterName = "Update-EndpointPilotAdmin.ps1"   # This script's name

    foreach ($extension in $scriptExtensions) {
        $files = Get-ChildItem -Path $stagingSourcePath -Filter $extension -File
        foreach ($file in $files) {
            # Skip the original installer and this updater script
            if ($file.Name -eq $selfInstallerName -or $file.Name -eq $selfUpdaterName) {
                Write-Host "Skipping $($file.Name) (installer/updater)" -ForegroundColor Gray
                WriteLog "Skipping $($file.Name) (installer/updater)"
                continue
            }

            # Skip specific JSON configuration files to preserve user settings
            if ($extension -eq "*.json" -and $file.Name -in $excludedConfigFiles) {
                Write-Host "Skipping $($file.Name) (preserving user configuration)" -ForegroundColor Yellow
                WriteLog "Skipping $($file.Name) (preserving user configuration)"
                continue
            }

            # Copy the file if it's not excluded
            Copy-Item -Path $file.FullName -Destination $baseInstallPath -Force
            $filesUpdated++
        }
    }

    Write-Host "Updated $filesUpdated script files." -ForegroundColor Green
    WriteLog "Updated $filesUpdated script files."

    # Create desktop shortcut (optional, check if exists first?)
    $createShortcut = Read-Host "Create/Update desktop shortcut for JsonEditorTool? (Y/N)"
    if ($createShortcut -eq "Y" -or $createShortcut -eq "y") {
        $jsonEditorExePath = Join-Path -Path $jsonEditorToolPath -ChildPath "EndpointPilotJsonEditor.App.exe"
        
        if (Test-Path -Path $jsonEditorExePath) {
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\EndpointPilot JSON Editor.lnk")
            $Shortcut.TargetPath = $jsonEditorExePath
            $Shortcut.Save()
            Write-Host "Desktop shortcut created/updated." -ForegroundColor Green
            WriteLog "Desktop shortcut created/updated."
        } else {
            Write-Warning "JsonEditorTool executable not found: $jsonEditorExePath"
            WriteLog "WARNING: JsonEditorTool executable not found: $jsonEditorExePath"
        }
    }

    # Update summary
    Write-Host "`nEndpointPilot update complete!" -ForegroundColor Green
    WriteLog "`nEndpointPilot update complete!"
    Write-Host "JsonEditorTool updated in: $jsonEditorToolPath" -ForegroundColor Yellow
    WriteLog "JsonEditorTool updated in: $jsonEditorToolPath"
    Write-Host "Scripts updated in: $baseInstallPath (User JSON files preserved)" -ForegroundColor Yellow
    WriteLog "Scripts updated in: $baseInstallPath (User JSON files preserved)"

    # Optional: Create/Update uninstaller
    $createUninstaller = Read-Host "Create/Update uninstaller script? (Y/N)"
    if ($createUninstaller -eq "Y" -or $createUninstaller -eq "y") {
        $uninstallerPath = Join-Path -Path $baseInstallPath -ChildPath "Uninstall-EndpointPilot.ps1"
        
        $uninstallerContent = @"
<# 
.SYNOPSIS
    Uninstaller for EndpointPilot (after update)
.DESCRIPTION
    Removes updated EndpointPilot components from the system
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

Write-Host "EndpointPilot (updated version) has been uninstalled." -ForegroundColor Green
"@
        
        Set-Content -Path $uninstallerPath -Value $uninstallerContent
        Write-Host "Uninstaller created/updated at: $uninstallerPath" -ForegroundColor Green
        WriteLog "Uninstaller created/updated at: $uninstallerPath"
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
# --- End Main Update ---

Write-Host "`nThank you for updating EndpointPilot!" -ForegroundColor Cyan
WriteLog "`nThank you for updating EndpointPilot!"