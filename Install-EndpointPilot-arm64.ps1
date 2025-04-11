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
$jsonEditorSourcePath = Join-Path -Path $PSScriptRoot -ChildPath "JsonEditorTool\publish-arm64"
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