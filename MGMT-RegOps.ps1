###############################################################################################
#
#	    EndpointPilot Configuration tool shared helper script
#			MGMT-RegOps.PS1 (Placeholder)
#
#  Description
#    This is a placeholder script for registry operations.
#    It currently performs no actions.
#    It is called by MAIN.PS1 if $SkipRegOps is $false.
#    Registry directives should be placed in REG-OPS.json.
#
#				Written by Julian West February 2025 (Placeholder by Roo)
#
###############################################################################################

# Check if running independently (should be dot-sourced by MAIN.PS1)
if ($MyInvocation.InvocationName -ne '.') {
    # Load shared components if run standalone (for potential future testing)
    try {
        Import-Module MGMT-Functions.psm1 -ErrorAction Stop
        . .\MGMT-SHARED.ps1 -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to load shared modules/variables. Ensure MGMT-Functions.psm1 and MGMT-SHARED.ps1 are present. Error: $_"
        # Exit or return depending on desired behavior when run standalone
        return
    }
}

# Registry operations implementation with signature validation
WriteLog "Executing MGMT-RegOps.ps1 - Processing registry operations with signature validation."

try {
    $regJsonPath = Join-Path $PSScriptRoot "REG-OPS.json"
    if (Test-Path $regJsonPath) {
        # Read JSON file
        $json = Get-Content -Raw -Path $regJsonPath | ConvertFrom-Json
        
        # Get signature validation configuration
        $signatureConfig = Get-SignatureValidationConfig
        
        # Loop through each registry operation
        $json | ForEach-Object {
            # Validate signature if present (Phase 1 compatibility)
            if ($_.signature -or $_.signerCertThumbprint) {
                WriteLog "Validating signature for registry operation"
                
                $signatureData = @{
                    signature = $_.signature
                    timestamp = $_.timestamp
                    signerCertThumbprint = $_.signerCertThumbprint
                    hashAlgorithm = $_.hashAlgorithm
                    signatureVersion = $_.signatureVersion
                }
                
                try {
                    $validationResult = Test-JsonSignature -OperationData $_ -SignatureData $signatureData
                    if ($validationResult.IsValid) {
                        WriteLog "Signature validation passed for registry operation: $($_._comment1) (id: $($_.id))"
                    } else {
                        $errorMsg = "Signature validation failed for registry operation: $($_._comment1) (id: $($_.id)). Reason: $($validationResult.ErrorMessage)"
                        WriteLog "SECURITY WARNING: $errorMsg"
                        
                        if ($signatureConfig.EnforcementMode -eq 'strict') {
                            WriteLog "ERROR: Skipping registry operation due to failed signature validation (strict mode)"
                            return
                        } elseif ($signatureConfig.EnforcementMode -eq 'warn') {
                            WriteLog "WARNING: Proceeding with unsigned registry operation (warn mode)"
                        } else {
                            WriteLog "INFO: Signature validation disabled (disabled mode)"
                        }
                    }
                }
                catch {
                    $errorMsg = "Exception during signature validation for registry operation: $($_._comment1) (id: $($_.id)). Error: $_"
                    WriteLog "SECURITY ERROR: $errorMsg"
                    
                    if ($signatureConfig.EnforcementMode -eq 'strict') {
                        WriteLog "ERROR: Skipping registry operation due to signature validation exception (strict mode)"
                        return
                    } else {
                        WriteLog "WARNING: Proceeding despite signature validation error"
                    }
                }
            } else {
                # No signature present - Phase 1 compatibility
                if ($signatureConfig.EnforcementMode -eq 'strict') {
                    WriteLog "ERROR: Registry operation missing required signature (strict mode): $($_._comment1) (id: $($_.id))"
                    return
                } elseif ($signatureConfig.EnforcementMode -eq 'warn') {
                    WriteLog "WARNING: Processing unsigned registry operation (warn mode): $($_._comment1) (id: $($_.id))"
                }
                # In disabled mode, no logging needed for unsigned operations
            }
            
            # Extract registry operation information from JSON
            # Field names match REG-OPS.schema.json: name, path, value, regtype, write_once, delete
            $regName = $_.name
            $regPath = $_.path
            $regValue = $_.value
            $regType = $_.regtype
            $writeOnce = $_.write_once
            $deleteValue = $_.delete
            $requiresAdmin = $_.requiresAdmin
            $comment = $_._comment1

            # Check if this operation requires administrative privileges
            if ($requiresAdmin -eq $true) {
                WriteLog "WARNING: Registry operation requires administrative privileges: $comment (id: $($_.id))"
                return
            }

            try {
                if ($deleteValue -eq $true) {
                    # Delete operation
                    if ($regName) {
                        WriteLog "Deleting registry value: $regPath\$regName"
                        Remove-ItemProperty -Path "Registry::$regPath" -Name $regName -ErrorAction Stop
                        WriteLog "Successfully deleted registry value: $regPath\$regName"
                    } else {
                        WriteLog "Deleting registry key: $regPath"
                        Remove-Item -Path "Registry::$regPath" -Recurse -Force -ErrorAction Stop
                        WriteLog "Successfully deleted registry key: $regPath"
                    }
                } else {
                    # Set operation — ensure the key path exists
                    if (-not (Test-Path "Registry::$regPath")) {
                        New-Item -Path "Registry::$regPath" -Force -ErrorAction Stop | Out-Null
                        WriteLog "Created registry key: $regPath"
                    }

                    # Handle write_once: skip if value already exists
                    if ($writeOnce -eq "true") {
                        $existing = Get-ItemProperty -Path "Registry::$regPath" -Name $regName -ErrorAction SilentlyContinue
                        if ($null -ne $existing) {
                            WriteLog "Skipping write-once registry value (already exists): $regPath\$regName"
                            return
                        }
                    }

                    # Map regtype to PowerShell registry types
                    $psRegType = switch ($regType) {
                        'string'      { 'String' }
                        'dword'       { 'DWord' }
                        'qword'       { 'QWord' }
                        'binary'      { 'Binary' }
                        'multi-string' { 'MultiString' }
                        'expandable'  { 'ExpandString' }
                        default       { 'String' }
                    }

                    WriteLog "Setting registry value: $regPath\$regName = $regValue (type: $psRegType)"
                    Set-ItemProperty -Path "Registry::$regPath" -Name $regName -Value $regValue -Type $psRegType -ErrorAction Stop
                    WriteLog "Successfully set registry value: $regPath\$regName"
                }
            }
            catch {
                WriteLog "ERROR processing registry operation (id: $($_.id)): $comment. Error: $_"
            }
        }
    } else {
        WriteLog "REG-OPS.json not found. Skipping registry operations."
    }
} catch {
    WriteLog "ERROR reading or processing REG-OPS.json: $_"
}