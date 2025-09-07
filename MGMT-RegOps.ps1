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
                        WriteLog "Signature validation passed for registry operation: $($_.comments)"
                    } else {
                        $errorMsg = "Signature validation failed for registry operation: $($_.comments). Reason: $($validationResult.ErrorMessage)"
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
                    $errorMsg = "Exception during signature validation for registry operation: $($_.comments). Error: $_"
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
                    WriteLog "ERROR: Registry operation missing required signature (strict mode): $($_.comments)"
                    return
                } elseif ($signatureConfig.EnforcementMode -eq 'warn') {
                    WriteLog "WARNING: Processing unsigned registry operation (warn mode): $($_.comments)"
                }
                # In disabled mode, no logging needed for unsigned operations
            }
            
            # Extract registry operation information from JSON
            $keyPath = $_.keyPath
            $valueName = $_.valueName
            $valueData = $_.valueData
            $valueType = $_.valueType
            $operation = $_.operation
            $requiresAdmin = $_.requiresAdmin
            $comments = $_.comments
            
            # Check if this operation requires administrative privileges
            if ($requiresAdmin -eq $true) {
                WriteLog "WARNING: Registry operation requires administrative privileges: $comments"
                # Skip operation if not running with appropriate privileges
                # This will be handled by the System Agent in future versions
                return
            }
            
            try {
                # Process registry operation based on operation type
                switch ($operation.ToLower()) {
                    'create' {
                        WriteLog "Creating registry key: $keyPath"
                        if (-not (Test-Path "Registry::$keyPath")) {
                            New-Item -Path "Registry::$keyPath" -Force -ErrorAction Stop
                            WriteLog "Successfully created registry key: $keyPath"
                        } else {
                            WriteLog "Registry key already exists: $keyPath"
                        }
                    }
                    'set' {
                        WriteLog "Setting registry value: $keyPath\$valueName = $valueData"
                        Set-ItemProperty -Path "Registry::$keyPath" -Name $valueName -Value $valueData -Type $valueType -ErrorAction Stop
                        WriteLog "Successfully set registry value: $keyPath\$valueName"
                    }
                    'delete' {
                        if ($valueName) {
                            WriteLog "Deleting registry value: $keyPath\$valueName"
                            Remove-ItemProperty -Path "Registry::$keyPath" -Name $valueName -ErrorAction Stop
                            WriteLog "Successfully deleted registry value: $keyPath\$valueName"
                        } else {
                            WriteLog "Deleting registry key: $keyPath"
                            Remove-Item -Path "Registry::$keyPath" -Recurse -Force -ErrorAction Stop
                            WriteLog "Successfully deleted registry key: $keyPath"
                        }
                    }
                    default {
                        WriteLog "ERROR: Unknown registry operation type: $operation"
                    }
                }
            }
            catch {
                WriteLog "ERROR processing registry operation: $comments. Error: $_"
            }
        }
    } else {
        WriteLog "REG-OPS.json not found. Skipping registry operations."
    }
} catch {
    WriteLog "ERROR reading or processing REG-OPS.json: $_"
}