###############################################################################################
#
#       EndpointPilot Configuration tool shared helper script
#           MGMT-DriveOps.PS1
#
#  Description
#    Processes DRIVE-OPS.json directives to map, remove, or reconfigure network drive
#    mappings. Supports targeting by group (AD/Entra/local), computer name, username,
#    or no targeting (applies to all). Uses Resolve-GroupMembership for group-based
#    targeting with automatic fallback across join states.
#
#               Written by Julian West February 2025
#               Implemented May 2026
#
###############################################################################################

# Check if running independently (should be dot-sourced by MAIN.PS1)
if ($MyInvocation.InvocationName -ne '.') {
    try {
        Import-Module (Join-Path $PSScriptRoot "MGMT-Functions.psm1") -Force -ErrorAction Stop
        . (Join-Path $PSScriptRoot "MGMT-SHARED.ps1")
    }
    catch {
        Write-Error "Failed to load shared modules/variables. Ensure MGMT-Functions.psm1 and MGMT-SHARED.ps1 are present. Error: $_"
        return
    }
}

WriteLog "Executing MGMT-DriveOps.ps1 - Processing drive mapping operations."

$driveJsonPath = Join-Path $PSScriptRoot "DRIVE-OPS.json"

if (-not (Test-Path $driveJsonPath)) {
    WriteLog "DRIVE-OPS.json not found at $driveJsonPath. Skipping drive operations."
    return
}

try {
    $driveDirectives = Get-Content -Raw -Path $driveJsonPath | ConvertFrom-Json
}
catch {
    WriteLog "ERROR: Failed to parse DRIVE-OPS.json: $_"
    return
}

if (-not $driveDirectives -or $driveDirectives.Count -eq 0) {
    WriteLog "DRIVE-OPS.json is empty. No drive operations to process."
    return
}

# Get signature validation configuration
$signatureConfig = Get-SignatureValidationConfig

foreach ($directive in $driveDirectives) {
    $directiveId = $directive.id
    $driveLetter = $directive.driveLetter
    $drivePath = $directive.drivePath
    $comment = if ($directive._comment1) { $directive._comment1 } else { "directive $directiveId" }

    WriteLog "Processing drive directive $directiveId ($comment): $driveLetter -> $drivePath"

    # --- Signature validation ---
    if ($directive.signature -or $directive.signerCertThumbprint) {
        $signatureData = @{
            signature = $directive.signature
            timestamp = $directive.timestamp
            signerCertThumbprint = $directive.signerCertThumbprint
            hashAlgorithm = $directive.hashAlgorithm
            signatureVersion = $directive.signatureVersion
        }

        try {
            $validationResult = Test-JsonSignature -OperationData $directive -SignatureData $signatureData
            if ($validationResult.IsValid) {
                WriteLog "Signature validation passed for drive directive $directiveId"
            }
            else {
                $errorMsg = "Signature validation failed for drive directive $directiveId. Reason: $($validationResult.ErrorMessage)"
                WriteLog "SECURITY WARNING: $errorMsg"

                if ($signatureConfig.EnforcementMode -eq 'strict') {
                    WriteLog "ERROR: Skipping drive directive $directiveId due to failed signature (strict mode)"
                    continue
                }
                elseif ($signatureConfig.EnforcementMode -eq 'warn') {
                    WriteLog "WARNING: Proceeding with unsigned drive directive $directiveId (warn mode)"
                }
            }
        }
        catch {
            WriteLog "SECURITY ERROR: Exception during signature validation for drive directive $directiveId`: $_"
            if ($signatureConfig.EnforcementMode -eq 'strict') {
                WriteLog "ERROR: Skipping drive directive $directiveId due to signature exception (strict mode)"
                continue
            }
            else {
                WriteLog "WARNING: Proceeding despite signature validation error for drive directive $directiveId"
            }
        }
    }
    else {
        if ($signatureConfig.EnforcementMode -eq 'strict') {
            WriteLog "ERROR: Drive directive $directiveId missing required signature (strict mode). Skipping."
            continue
        }
        elseif ($signatureConfig.EnforcementMode -eq 'warn') {
            WriteLog "WARNING: Processing unsigned drive directive $directiveId (warn mode)"
        }
    }

    # --- Targeting evaluation ---
    $targetingType = $directive.targeting_type
    $target = $directive.target

    switch ($targetingType) {
        'group' {
            $groupResult = Resolve-GroupMembership -GroupName $target
            if (-not $groupResult.IsMember) {
                WriteLog "SKIP directive $directiveId`: $($groupResult.Reason)"
                continue
            }
            WriteLog "Targeting matched: $($groupResult.Reason) [source: $($groupResult.Source)]"
        }
        'computer' {
            if ($env:COMPUTERNAME -ne $target) {
                WriteLog "SKIP directive $directiveId`: computer name '$env:COMPUTERNAME' does not match target '$target'"
                continue
            }
            WriteLog "Targeting matched: computer name '$env:COMPUTERNAME'"
        }
        'user' {
            if ($env:USERNAME -ne $target) {
                WriteLog "SKIP directive $directiveId`: username '$env:USERNAME' does not match target '$target'"
                continue
            }
            WriteLog "Targeting matched: username '$env:USERNAME'"
        }
        'none' {
            # No targeting — applies to all endpoints
        }
        default {
            WriteLog "WARNING: Unknown targeting_type '$targetingType' on directive $directiveId. Processing anyway."
        }
    }

    # --- Drive operation ---
    $deleteMapping = $directive.delete
    $reconnect = $directive.reconnect
    $hidden = $directive.hidden

    if ($deleteMapping) {
        # Remove an existing drive mapping
        if ($global:DryRunMode) {
            WriteLog "[DRY-RUN] Would remove drive mapping: $driveLetter"
        }
        else {
            try {
                $existing = Get-PSDrive -Name $driveLetter.TrimEnd(':') -ErrorAction SilentlyContinue
                if ($existing) {
                    & net use $driveLetter /delete /y 2>&1 | Out-Null
                    WriteLog "Removed drive mapping: $driveLetter"
                }
                else {
                    WriteLog "Drive $driveLetter is not currently mapped. Nothing to remove."
                }
            }
            catch {
                WriteLog "ERROR: Failed to remove drive mapping $driveLetter`: $_"
            }
        }
        continue
    }

    # Map or re-map the drive
    $persistFlag = if ($reconnect) { '/persistent:yes' } else { '/persistent:no' }

    # Check if the drive is already mapped to the correct path
    $existingDrive = Get-PSDrive -Name $driveLetter.TrimEnd(':') -ErrorAction SilentlyContinue
    if ($existingDrive) {
        $existingRoot = $existingDrive.DisplayRoot
        if ($existingRoot -eq $drivePath) {
            WriteLog "Drive $driveLetter is already mapped to $drivePath. Skipping."
            continue
        }
        else {
            # Mapped to a different path — remove first, then remap
            if ($global:DryRunMode) {
                WriteLog "[DRY-RUN] Would remap drive $driveLetter from '$existingRoot' to '$drivePath'"
            }
            else {
                try {
                    & net use $driveLetter /delete /y 2>&1 | Out-Null
                    WriteLog "Removed existing mapping for $driveLetter (was: $existingRoot)"
                }
                catch {
                    WriteLog "ERROR: Failed to remove existing mapping for $driveLetter before remap: $_"
                    continue
                }
            }
        }
    }

    if ($global:DryRunMode) {
        WriteLog "[DRY-RUN] Would map drive $driveLetter -> $drivePath (persistent: $reconnect, hidden: $hidden)"
    }
    else {
        try {
            $netUseArgs = @($driveLetter, $drivePath, $persistFlag)
            $netUseOutput = & net use @netUseArgs 2>&1

            if ($LASTEXITCODE -ne 0) {
                WriteLog "ERROR: net use failed for $driveLetter -> $drivePath`: $netUseOutput"
                continue
            }

            WriteLog "Mapped drive $driveLetter -> $drivePath (persistent: $reconnect)"

            # Hide the drive in Explorer if requested
            if ($hidden) {
                $driveLetterOnly = $driveLetter.TrimEnd(':')
                $driveIndex = [int][char]$driveLetterOnly - [int][char]'A'
                $hideDrivesPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'

                if (-not (Test-Path $hideDrivesPath)) {
                    New-Item -Path $hideDrivesPath -Force | Out-Null
                }

                $currentMask = Get-ItemProperty -Path $hideDrivesPath -Name 'NoDrives' -ErrorAction SilentlyContinue
                $mask = if ($currentMask) { $currentMask.NoDrives } else { 0 }
                $mask = $mask -bor [Math]::Pow(2, $driveIndex)

                Set-ItemProperty -Path $hideDrivesPath -Name 'NoDrives' -Value ([int]$mask) -Type DWord
                WriteLog "Drive $driveLetter hidden in Explorer (NoDrives bitmask updated)"
            }
        }
        catch {
            WriteLog "ERROR: Failed to map drive $driveLetter -> $drivePath`: $_"
        }
    }
}

WriteLog "MGMT-DriveOps.ps1 completed."
