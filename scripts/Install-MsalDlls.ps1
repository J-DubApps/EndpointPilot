<#
.SYNOPSIS
    Downloads and installs MSAL.NET DLLs for EndpointPilot Entra Graph integration.

.DESCRIPTION
    Fetches Microsoft.Identity.Client, Microsoft.Identity.Client.Broker, and
    Microsoft.Identity.Client.NativeInterop NuGet packages from nuget.org,
    extracts the required DLLs to lib/msal/ in the EndpointPilot repo.

    Run this on any Windows machine after cloning the repo. DLLs are .gitignored
    so each endpoint bootstraps its own copy.

.PARAMETER TargetDir
    Override the default target directory (lib/msal relative to repo root).

.PARAMETER Force
    Re-download even if DLLs already exist.

.EXAMPLE
    .\scripts\Install-MsalDlls.ps1
    .\scripts\Install-MsalDlls.ps1 -Force
#>

# Copyright (c) Julian West. Licensed under BSD-3-Clause.

[CmdletBinding()]
param(
    [string]$TargetDir,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# TLS 1.2 -- PS 5.1 defaults to older protocols
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Default target: lib/msal relative to repo root (one level up from scripts/)
if (-not $TargetDir) {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $TargetDir = Join-Path (Join-Path $repoRoot "lib") "msal"
}

# Idempotent -- skip if already installed
$checkFile = Join-Path (Join-Path $TargetDir "net462") "Microsoft.Identity.Client.dll"
if ((Test-Path $checkFile) -and -not $Force) {
    Write-Host "MSAL DLLs already installed at $TargetDir" -ForegroundColor Green
    Write-Host "Use -Force to re-download."
    exit 0
}

Write-Host ""
Write-Host "Installing MSAL.NET DLLs for EndpointPilot..." -ForegroundColor Cyan
Write-Host "Target: $TargetDir"
Write-Host ""

# NuGet packages and the specific files we need from each.
# Includes transitive dependencies required for Add-Type to succeed on PS 5.1.
# Source paths use the nearest compatible TFM folder in each .nupkg;
# all managed DLLs land in net462/ for a single Add-Type load path.
$packages = @(
    # Pinned versions: newer releases of these System.* packages dropped net461/net462 TFMs.
    @{
        Id          = "System.Buffers"
        Version     = "4.5.1"
        Extractions = @(
            @{ Source = "lib/net461/System.Buffers.dll"; Dest = "net462/System.Buffers.dll" }
        )
    },
    @{
        Id          = "System.Numerics.Vectors"
        Version     = "4.5.0"
        Extractions = @(
            @{ Source = "lib/net46/System.Numerics.Vectors.dll"; Dest = "net462/System.Numerics.Vectors.dll" }
        )
    },
    @{
        Id          = "System.Runtime.CompilerServices.Unsafe"
        Version     = "6.0.0"
        Extractions = @(
            @{ Source = "lib/net461/System.Runtime.CompilerServices.Unsafe.dll"; Dest = "net462/System.Runtime.CompilerServices.Unsafe.dll" }
        )
    },
    @{
        Id          = "System.Memory"
        Version     = "4.5.5"
        Extractions = @(
            @{ Source = "lib/net461/System.Memory.dll"; Dest = "net462/System.Memory.dll" }
        )
    },
    @{
        Id          = "System.Diagnostics.DiagnosticSource"
        Version     = "6.0.1"
        Extractions = @(
            @{ Source = "lib/net461/System.Diagnostics.DiagnosticSource.dll"; Dest = "net462/System.Diagnostics.DiagnosticSource.dll" }
        )
    },
    @{
        Id          = "System.Formats.Asn1"
        Version     = "8.0.1"
        Extractions = @(
            @{ Source = "lib/net462/System.Formats.Asn1.dll"; Dest = "net462/System.Formats.Asn1.dll" }
        )
    },
    @{
        Id          = "Microsoft.IdentityModel.Abstractions"
        Extractions = @(
            @{ Source = "lib/net462/Microsoft.IdentityModel.Abstractions.dll"; Dest = "net462/Microsoft.IdentityModel.Abstractions.dll" }
        )
    },
    @{
        Id          = "Microsoft.Identity.Client"
        Extractions = @(
            @{ Source = "lib/net462/Microsoft.Identity.Client.dll"; Dest = "net462/Microsoft.Identity.Client.dll" }
        )
    },
    @{
        Id          = "Microsoft.Identity.Client.Broker"
        Extractions = @(
            @{ Source = "lib/net462/Microsoft.Identity.Client.Broker.dll"; Dest = "net462/Microsoft.Identity.Client.Broker.dll" }
        )
    },
    @{
        Id          = "Microsoft.Identity.Client.NativeInterop"
        Extractions = @(
            @{ Source = "runtimes/win-x64/native/msalruntime.dll"; Dest = "runtimes/win-x64/native/msalruntime.dll"; Optional = $false },
            @{ Source = "runtimes/win-arm64/native/msalruntime.dll"; Dest = "runtimes/win-arm64/native/msalruntime.dll"; Optional = $true }
        )
    }
)

$tempBase = Join-Path ([System.IO.Path]::GetTempPath()) "msal-install-$(Get-Random)"
New-Item -Path $tempBase -ItemType Directory -Force | Out-Null

$success = $true

try {
    foreach ($pkg in $packages) {
        $pkgLower = $pkg.Id.ToLower()

        Write-Host ('[{0}]' -f $pkg.Id) -ForegroundColor White

        if ($pkg.Version) {
            # Pinned version -- use directly, skip NuGet query
            $version = $pkg.Version
            Write-Host "  Version: $version (pinned)"
        }
        else {
            # Query NuGet flat container for latest stable version
            $indexUrl = "https://api.nuget.org/v3-flatcontainer/$pkgLower/index.json"

            try {
                $indexData = Invoke-RestMethod -Uri $indexUrl -UseBasicParsing
            }
            catch {
                Write-Host ('  ERROR: Failed to query NuGet for {0}: {1}' -f $pkg.Id, $_.Exception.Message) -ForegroundColor Red
                $success = $false
                continue
            }

            # Filter to stable versions (no prerelease dash)
            $stableVersions = $indexData.versions | Where-Object { $_ -notmatch '-' }
            if (-not $stableVersions -or $stableVersions.Count -eq 0) {
                Write-Host ('  ERROR: No stable versions found for {0}' -f $pkg.Id) -ForegroundColor Red
                $success = $false
                continue
            }
            $version = $stableVersions[-1]
            Write-Host "  Version: $version"
        }

        # Download the .nupkg (it's a ZIP)
        $nupkgUrl  = "https://api.nuget.org/v3-flatcontainer/$pkgLower/$version/$pkgLower.$version.nupkg"
        $zipPath   = Join-Path $tempBase "$pkgLower.$version.zip"
        $extractTo = Join-Path $tempBase $pkgLower

        Write-Host "  Downloading..."
        try {
            Invoke-WebRequest -Uri $nupkgUrl -OutFile $zipPath -UseBasicParsing
        }
        catch {
            Write-Host ('  ERROR: Download failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
            $success = $false
            continue
        }

        Write-Host "  Extracting..."
        Expand-Archive -Path $zipPath -DestinationPath $extractTo -Force

        # Copy each required file into lib/msal/
        foreach ($ex in $pkg.Extractions) {
            $srcPath  = Join-Path $extractTo ($ex.Source -replace '/', [IO.Path]::DirectorySeparatorChar)
            $destPath = Join-Path $TargetDir  ($ex.Dest  -replace '/', [IO.Path]::DirectorySeparatorChar)
            $destDir  = Split-Path $destPath -Parent

            if (-not (Test-Path $srcPath)) {
                if ($ex.Optional) {
                    Write-Host ('  Optional, not present: {0}' -f $ex.Source) -ForegroundColor DarkGray
                }
                else {
                    Write-Host ('  WARNING: Expected file not found in package: {0}' -f $ex.Source) -ForegroundColor Yellow
                    Write-Host "           NuGet package structure may have changed." -ForegroundColor Yellow
                    $success = $false
                }
                continue
            }

            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }

            Copy-Item -Path $srcPath -Destination $destPath -Force
            $sizeKB = [math]::Round((Get-Item $destPath).Length / 1KB)
            Write-Host ('  -> {0} ({1} KB)' -f $ex.Dest, $sizeKB) -ForegroundColor Green
        }

        Write-Host ""
    }

    # -- Verification ---------------------------------------------
    Write-Host "Verification" -ForegroundColor Cyan
    Write-Host "---------------------------------------------" -ForegroundColor DarkGray

    # Detect architecture for native DLL verification
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -eq 'ARM64') {
        $nativeRuntime = "runtimes/win-arm64/native/msalruntime.dll"
        $crossRuntime  = "runtimes/win-x64/native/msalruntime.dll"
    }
    else {
        $nativeRuntime = "runtimes/win-x64/native/msalruntime.dll"
        $crossRuntime  = "runtimes/win-arm64/native/msalruntime.dll"
    }
    Write-Host ('  Architecture: {0}' -f $arch)

    $expectedFiles = @(
        "net462/System.Buffers.dll",
        "net462/System.Numerics.Vectors.dll",
        "net462/System.Runtime.CompilerServices.Unsafe.dll",
        "net462/System.Memory.dll",
        "net462/System.Diagnostics.DiagnosticSource.dll",
        "net462/System.Formats.Asn1.dll",
        "net462/Microsoft.IdentityModel.Abstractions.dll",
        "net462/Microsoft.Identity.Client.dll",
        "net462/Microsoft.Identity.Client.Broker.dll",
        $nativeRuntime
    )

    foreach ($f in $expectedFiles) {
        $path = Join-Path $TargetDir ($f -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (Test-Path $path) {
            $sizeKB = [math]::Round((Get-Item $path).Length / 1KB)
            Write-Host ('  [OK]      {0} ({1} KB)' -f $f, $sizeKB) -ForegroundColor Green
        }
        else {
            Write-Host "  [MISSING] $f" -ForegroundColor Red
            $success = $false
        }
    }

    # Note cross-architecture native DLL status (non-fatal)
    $crossPath = Join-Path $TargetDir ($crossRuntime -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (Test-Path $crossPath) {
        $sizeKB = [math]::Round((Get-Item $crossPath).Length / 1KB)
        Write-Host ('  [OK]      {0} ({1} KB) (cross-arch)' -f $crossRuntime, $sizeKB) -ForegroundColor DarkGray
    }
    else {
        Write-Host ('  [--]      {0} (not available, cross-arch)' -f $crossRuntime) -ForegroundColor DarkGray
    }

    Write-Host ""
    if ($success) {
        Write-Host "MSAL.NET DLLs installed successfully." -ForegroundColor Green
        Write-Host "Path: $TargetDir" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "WARNING: Installation completed with issues. Review output above." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Host ('FATAL: {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
finally {
    if (Test-Path $tempBase) {
        Remove-Item -Path $tempBase -Recurse -Force -ErrorAction SilentlyContinue
    }
}
