<#
.SYNOPSIS
    Generates hashes.json manifest for EndpointPilot script integrity verification.

.DESCRIPTION
    Scans the EndpointPilot install directory for .ps1 and .psm1 files, computes
    SHA-256 hashes, and writes a hashes.json manifest. The SystemAgent's
    PowerShellExecutor uses this manifest to verify script integrity before execution.

    Run this script after installing or updating EndpointPilot scripts.

.PARAMETER InstallPath
    Path to the EndpointPilot install directory.
    Default: $env:ProgramData\EndpointPilot

.PARAMETER OutputPath
    Path to write the hashes.json manifest.
    Default: $InstallPath\hashes.json

.EXAMPLE
    .\Generate-ScriptHashes.ps1
    Generates hashes.json in the default install location.

.EXAMPLE
    .\Generate-ScriptHashes.ps1 -InstallPath "C:\Test\EndpointPilot" -OutputPath "C:\Test\hashes.json"
    Generates hashes.json for a custom install location.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallPath = (Join-Path $env:ProgramData "EndpointPilot"),

    [Parameter()]
    [string]$OutputPath
)

if (-not $OutputPath) {
    $OutputPath = Join-Path $InstallPath "hashes.json"
}

if (-not (Test-Path $InstallPath)) {
    Write-Error "Install path does not exist: $InstallPath"
    exit 1
}

$scriptFiles = Get-ChildItem -Path (Join-Path $InstallPath "*") -Include "*.ps1", "*.psm1" -File
if ($scriptFiles.Count -eq 0) {
    Write-Warning "No .ps1 or .psm1 files found in: $InstallPath"
    exit 1
}

$hashes = [ordered]@{}
foreach ($file in ($scriptFiles | Sort-Object Name)) {
    $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashes[$file.Name] = $hash
    Write-Verbose "  $($file.Name): $hash"
}

$manifest = [ordered]@{
    generatedAt   = (Get-Date -Format "o")
    hashAlgorithm = "SHA-256"
    scripts       = $hashes
}

$json = $manifest | ConvertTo-Json -Depth 3
Set-Content -Path $OutputPath -Value $json -Encoding UTF8

Write-Host "Generated hashes.json with $($hashes.Count) entries at: $OutputPath"
