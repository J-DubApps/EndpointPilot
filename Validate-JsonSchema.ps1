###############################################################################################
#
#	    EndpointPilot Configuration tool validation script
#			Validate-JsonSchema.PS1
#
#  Description
#    This script validates EndpointPilot JSON directive files against their corresponding schemas.
#    It can be used to ensure that JSON files are properly formatted before they are used by
#    the EndpointPilot scripts.
#
#				Written by Julian West April 2025
#
###############################################################################################

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$JsonFilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$SchemaFilePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$ValidateAll
)

function Test-JsonAgainstSchema {
    param (
        [string]$JsonFilePath,
        [string]$SchemaFilePath
    )
    
    try {
        # Check if files exist
        if (-not (Test-Path -Path $JsonFilePath)) {
            Write-Error "JSON file not found: $JsonFilePath"
            return $false
        }
        
        if (-not (Test-Path -Path $SchemaFilePath)) {
            Write-Error "Schema file not found: $SchemaFilePath"
            return $false
        }
        
        $jsonContent = Get-Content -Raw -Path $JsonFilePath
        
        # For PowerShell 6+
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            Write-Verbose "Using PowerShell 6+ Test-Json cmdlet"
            $result = Test-Json -Json $jsonContent -SchemaFile $SchemaFilePath -ErrorAction Stop
            return $result
        }
        # For PowerShell 5.1
        else {
            Write-Verbose "PowerShell 5.1 detected. Native JSON Schema validation is not available."
            Write-Warning "For PowerShell 5.1, this script provides basic JSON syntax validation only."
            Write-Warning "For full schema validation, please use PowerShell 6+ or install a third-party module."
            
            # Basic JSON syntax validation
            try {
                $null = ConvertFrom-Json -InputObject $jsonContent -ErrorAction Stop
                Write-Host "JSON syntax is valid for $JsonFilePath" -ForegroundColor Green
                return $true
            }
            catch {
                Write-Error "Invalid JSON syntax in $JsonFilePath`: $_"
                return $false
            }
        }
    }
    catch {
        Write-Error "Error validating JSON: $_"
        return $false
    }
}

function Validate-AllJsonFiles {
    $filesToValidate = @(
        @{JsonFile = "CONFIG.json"; SchemaFile = "CONFIG.schema.json"},
        @{JsonFile = "FILE-OPS.json"; SchemaFile = "FILE-OPS.schema.json"},
        @{JsonFile = "REG-OPS.json"; SchemaFile = "REG-OPS.schema.json"},
        @{JsonFile = "DRIVE-OPS.json"; SchemaFile = "DRIVE-OPS.schema.json"}
    )
    
    $allValid = $true
    
    foreach ($file in $filesToValidate) {
        $jsonPath = Join-Path -Path $PSScriptRoot -ChildPath $file.JsonFile
        $schemaPath = Join-Path -Path $PSScriptRoot -ChildPath $file.SchemaFile
        
        if (Test-Path -Path $jsonPath) {
            Write-Host "Validating $($file.JsonFile) against $($file.SchemaFile)..." -ForegroundColor Yellow
            $result = Test-JsonAgainstSchema -JsonFilePath $jsonPath -SchemaFilePath $schemaPath
            
            if ($result) {
                Write-Host "$($file.JsonFile) is valid according to its schema." -ForegroundColor Green
            }
            else {
                Write-Host "$($file.JsonFile) is NOT valid according to its schema." -ForegroundColor Red
                $allValid = $false
            }
        }
        else {
            Write-Warning "$($file.JsonFile) not found. Skipping validation."
        }
    }
    
    return $allValid
}

# Main script execution
if ($ValidateAll) {
    Write-Host "Validating all EndpointPilot JSON files..." -ForegroundColor Cyan
    $result = Validate-AllJsonFiles
    
    if ($result) {
        Write-Host "All JSON files are valid!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "One or more JSON files are invalid. Please check the errors above." -ForegroundColor Red
        exit 1
    }
}
elseif ($JsonFilePath -and $SchemaFilePath) {
    Write-Host "Validating $JsonFilePath against $SchemaFilePath..." -ForegroundColor Cyan
    $result = Test-JsonAgainstSchema -JsonFilePath $JsonFilePath -SchemaFilePath $SchemaFilePath
    
    if ($result) {
        Write-Host "$JsonFilePath is valid according to its schema." -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "$JsonFilePath is NOT valid according to its schema." -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "EndpointPilot JSON Schema Validator" -ForegroundColor Cyan
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  Validate a specific JSON file:" -ForegroundColor Yellow
    Write-Host "    .\Validate-JsonSchema.ps1 -JsonFilePath FILE-OPS.json -SchemaFilePath FILE-OPS.schema.json" -ForegroundColor Gray
    Write-Host "  Validate all EndpointPilot JSON files:" -ForegroundColor Yellow
    Write-Host "    .\Validate-JsonSchema.ps1 -ValidateAll" -ForegroundColor Gray
    exit 0
}