# EndpointPilot Installer Script

Below is the PowerShell installer script for EndpointPilot. To use this script:

1. Copy the code below
2. Save it as `Install-EndpointPilotAdmin.ps1`
3. Run it with administrator privileges

```powershell
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

# Ensure running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires administrator privileges. Attempting to elevate..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Define installation paths
$programDataPath = [Environment]::GetFolderPath('CommonApplicationData')
$baseInstallPath = Join-Path -Path $programDataPath -ChildPath "EndpointPilot"
$jsonEditorToolPath = Join-Path -Path $baseInstallPath -ChildPath "JsonEditorTool"

# Create directories if they don't exist
Write-Host "Creating installation directories..." -ForegroundColor Cyan
if (-not (Test-Path -Path $baseInstallPath)) {
    New-Item -Path $baseInstallPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $jsonEditorToolPath)) {
    New-Item -Path $jsonEditorToolPath -ItemType Directory -Force | Out-Null
}

# Install JsonEditorTool
Write-Host "Installing JsonEditorTool..." -ForegroundColor Cyan
$jsonEditorSourcePath = Join-Path -Path $PSScriptRoot -ChildPath "JsonEditorTool\publish"
if (Test-Path -Path $jsonEditorSourcePath) {
    Copy-Item -Path "$jsonEditorSourcePath\*" -Destination $jsonEditorToolPath -Recurse -Force
    Write-Host "JsonEditorTool installed successfully." -ForegroundColor Green
} else {
    Write-Warning "JsonEditorTool source path not found: $jsonEditorSourcePath"
}

# Install script files
Write-Host "Installing EndpointPilot scripts..." -ForegroundColor Cyan
$scriptExtensions = @("*.ps1", "*.psm1", "*.psd1", "*.json", "*.cmd", "*.exe", "*.vbs")
$filesInstalled = 0

foreach ($extension in $scriptExtensions) {
    $files = Get-ChildItem -Path $PSScriptRoot -Filter $extension -File
    foreach ($file in $files) {
        # Skip the installer itself
        if ($file.Name -eq "Install-EndpointPilot.ps1") {
            continue
        }
        
        Copy-Item -Path $file.FullName -Destination $baseInstallPath -Force
        $filesInstalled++
    }
}

Write-Host "Installed $filesInstalled script files." -ForegroundColor Green

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
    } else {
        Write-Warning "JsonEditorTool executable not found: $jsonEditorExePath"
    }
}

# Installation summary
Write-Host "`nEndpointPilot installation complete!" -ForegroundColor Green
Write-Host "JsonEditorTool installed to: $jsonEditorToolPath" -ForegroundColor Yellow
Write-Host "Scripts installed to: $baseInstallPath" -ForegroundColor Yellow

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
}

Write-Host "`nThank you for installing EndpointPilot!" -ForegroundColor Cyan
```

## Usage Instructions

1. Plan is to place this script in the root of EndpointPilot project itself
2. Ensure the latest JsonEditorTool is built and available in the `JsonEditorTool\publish` directory
3. Run the script with administrator privileges
4. Follow the prompts to complete the installation

## What This Script Does

1. Checks for and requests administrator privileges if needed
2. Creates the necessary directories in `%PROGRAMDATA%\EndpointPilot\`
3. Copies the JsonEditorTool files to `%PROGRAMDATA%\EndpointPilot\JsonEditorTool\`
4. Copies all script files (*.ps1, *.psm1, *.psd1, *.json, *.cmd, *.exe, *.vbs) to `%PROGRAMDATA%\EndpointPilot\`
5. Optionally creates a desktop shortcut for the JsonEditorTool
6. Optionally creates an uninstaller script

## Customization

You can customize this script by:

- Modifying the installation paths
- Adding validation checks
- etc
