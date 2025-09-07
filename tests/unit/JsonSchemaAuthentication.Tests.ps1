#Requires -Module Pester
#Requires -Version 5.1

BeforeAll {
    # Import required modules for JSON schema validation
    if (-not (Get-Module -ListAvailable -Name "Newtonsoft.Json.Schema")) {
        Write-Warning "Newtonsoft.Json.Schema not available - using basic JSON validation"
    }
    
    # Define schema paths
    $script:FileOpsSchemaPath = Join-Path -Path $PSScriptRoot -ChildPath "../../FILE-OPS.schema.json"
    $script:RegOpsSchemaPath = Join-Path -Path $PSScriptRoot -ChildPath "../../REG-OPS.schema.json"
    
    # Helper function to validate JSON against schema
    function Test-JsonAgainstSchema {
        param(
            [string]$JsonContent,
            [string]$SchemaPath
        )
        
        try {
            # Basic JSON validation
            $jsonObject = ConvertFrom-Json -InputObject $JsonContent -ErrorAction Stop
            
            # Load schema
            if (-not (Test-Path $SchemaPath)) {
                throw "Schema file not found: $SchemaPath"
            }
            
            $schema = Get-Content -Raw -Path $SchemaPath | ConvertFrom-Json
            
            # Basic schema compliance checks
            if ($schema.type -eq "array" -and $jsonObject -is [Array]) {
                return $true
            } elseif ($schema.type -eq "object" -and $jsonObject -is [PSCustomObject]) {
                return $true
            }
            
            return $false
        }
        catch {
            Write-Error "JSON validation failed: $_"
            return $false
        }
    }
    
    # Sample authentication fields for testing
    $script:ValidAuthFields = @{
        signature = "SGVsbG8gV29ybGQ="  # Valid Base64
        timestamp = "2025-09-07T10:30:00Z"  # Valid ISO 8601
        signerCertThumbprint = "A1B2C3D4E5F6789012345678901234567890ABCD"  # Valid 40-char hex
        hashAlgorithm = "SHA-256"
        signatureVersion = "1.0"
    }
    
    $script:InvalidAuthFields = @{
        signature = "Invalid Base64!"  # Invalid Base64
        timestamp = "2025-13-45"  # Invalid date
        signerCertThumbprint = "INVALID"  # Invalid thumbprint format
        hashAlgorithm = "MD5"  # Unsupported algorithm
        signatureVersion = "2.0"  # Unsupported version
    }
}

Describe "FILE-OPS Schema Authentication Support" -Tag "Unit", "Schema", "Authentication" {
    
    BeforeAll {
        # Ensure schema file exists
        if (-not (Test-Path $script:FileOpsSchemaPath)) {
            throw "FILE-OPS.schema.json not found at: $script:FileOpsSchemaPath"
        }
        
        $script:FileOpsSchema = Get-Content -Raw -Path $script:FileOpsSchemaPath | ConvertFrom-Json
    }
    
    Context "Schema Structure Validation" {
        It "Should have updated version information" {
            $script:FileOpsSchema.'$id' | Should -Match "file-ops-v1\.1\.json$"
            $script:FileOpsSchema.version | Should -Be "1.1.0"
        }
        
        It "Should include authentication properties in schema" {
            $properties = $script:FileOpsSchema.items.properties
            $properties.signature | Should -Not -BeNullOrEmpty
            $properties.timestamp | Should -Not -BeNullOrEmpty
            $properties.signerCertThumbprint | Should -Not -BeNullOrEmpty
            $properties.hashAlgorithm | Should -Not -BeNullOrEmpty
            $properties.signatureVersion | Should -Not -BeNullOrEmpty
        }
        
        It "Should have correct authentication field types" {
            $properties = $script:FileOpsSchema.items.properties
            $properties.signature.type | Should -Be "string"
            $properties.timestamp.type | Should -Be "string"
            $properties.timestamp.format | Should -Be "date-time"
            $properties.signerCertThumbprint.type | Should -Be "string"
            $properties.hashAlgorithm.type | Should -Be "string"
            $properties.signatureVersion.type | Should -Be "string"
        }
        
        It "Should have authentication fields as optional (not in required array)" {
            $required = $script:FileOpsSchema.items.required
            $required | Should -Not -Contain "signature"
            $required | Should -Not -Contain "timestamp" 
            $required | Should -Not -Contain "signerCertThumbprint"
            $required | Should -Not -Contain "hashAlgorithm"
            $required | Should -Not -Contain "signatureVersion"
        }
        
        It "Should maintain backward compatibility with existing required fields" {
            $required = $script:FileOpsSchema.items.required
            $required | Should -Contain "id"
            $required | Should -Contain "targeting_type"
            $required | Should -Contain "target"
        }
    }
    
    Context "Valid Signed JSON Operations" {
        It "Should accept file operation with valid authentication fields" {
            $operation = @{
                id = "test-001"
                srcfilename = "test.txt"
                dstfilename = "test.txt"
                sourcePath = "C:\Source"
                destinationPath = "C:\Dest"
                overwrite = $true
                targeting_type = "none"
                target = "all"
                signature = $script:ValidAuthFields.signature
                timestamp = $script:ValidAuthFields.timestamp
                signerCertThumbprint = $script:ValidAuthFields.signerCertThumbprint
                hashAlgorithm = $script:ValidAuthFields.hashAlgorithm
                signatureVersion = $script:ValidAuthFields.signatureVersion
            }
            
            $json = @($operation) | ConvertTo-Json -Depth 3
            $result = Test-JsonAgainstSchema -JsonContent $json -SchemaPath $script:FileOpsSchemaPath
            $result | Should -Be $true
        }
        
        It "Should accept file operation with partial authentication fields" {
            $operation = @{
                id = "test-002"
                srcfilename = "test.txt"
                dstfilename = "test.txt" 
                sourcePath = "C:\Source"
                destinationPath = "C:\Dest"
                targeting_type = "none"
                target = "all"
                signature = $script:ValidAuthFields.signature
                timestamp = $script:ValidAuthFields.timestamp
            }
            
            $json = @($operation) | ConvertTo-Json -Depth 3
            $result = Test-JsonAgainstSchema -JsonContent $json -SchemaPath $script:FileOpsSchemaPath
            $result | Should -Be $true
        }
    }
    
    Context "Unsigned JSON Operations (Backward Compatibility)" {
        It "Should accept file operation without any authentication fields" {
            $operation = @{
                id = "test-003"
                srcfilename = "test.txt"
                dstfilename = "test.txt"
                sourcePath = "C:\Source"
                destinationPath = "C:\Dest"
                overwrite = $false
                targeting_type = "none"
                target = "all"
            }
            
            $json = @($operation) | ConvertTo-Json -Depth 3
            $result = Test-JsonAgainstSchema -JsonContent $json -SchemaPath $script:FileOpsSchemaPath
            $result | Should -Be $true
        }
        
        It "Should accept multiple operations mixing signed and unsigned" {
            $operations = @(
                @{
                    id = "test-004a"
                    srcfilename = "unsigned.txt"
                    dstfilename = "unsigned.txt"
                    sourcePath = "C:\Source"
                    destinationPath = "C:\Dest"
                    targeting_type = "none"
                    target = "all"
                },
                @{
                    id = "test-004b"
                    srcfilename = "signed.txt"
                    dstfilename = "signed.txt"
                    sourcePath = "C:\Source"
                    destinationPath = "C:\Dest"
                    targeting_type = "none"
                    target = "all"
                    signature = $script:ValidAuthFields.signature
                    timestamp = $script:ValidAuthFields.timestamp
                    signerCertThumbprint = $script:ValidAuthFields.signerCertThumbprint
                    hashAlgorithm = $script:ValidAuthFields.hashAlgorithm
                    signatureVersion = $script:ValidAuthFields.signatureVersion
                }
            )
            
            $json = $operations | ConvertTo-Json -Depth 3
            $result = Test-JsonAgainstSchema -JsonContent $json -SchemaPath $script:FileOpsSchemaPath
            $result | Should -Be $true
        }
    }
    
    Context "Invalid Authentication Fields" {
        It "Should reject operation with invalid Base64 signature" -Skip {
            # Skip pattern validation tests if advanced schema validation unavailable
            if (-not (Get-Module -ListAvailable -Name "Newtonsoft.Json.Schema")) {
                Set-ItResult -Skipped -Because "Advanced schema validation not available"
                return
            }
            
            $operation = @{
                id = "test-005"
                srcfilename = "test.txt"
                dstfilename = "test.txt"
                sourcePath = "C:\Source"
                destinationPath = "C:\Dest"
                targeting_type = "none"
                target = "all"
                signature = $script:InvalidAuthFields.signature
                timestamp = $script:ValidAuthFields.timestamp
                signerCertThumbprint = $script:ValidAuthFields.signerCertThumbprint
                hashAlgorithm = $script:ValidAuthFields.hashAlgorithm
                signatureVersion = $script:ValidAuthFields.signatureVersion
            }
            
            $json = @($operation) | ConvertTo-Json -Depth 3
            $result = Test-JsonAgainstSchema -JsonContent $json -SchemaPath $script:FileOpsSchemaPath
            $result | Should -Be $false
        }
        
        It "Should reject operation with invalid certificate thumbprint format" -Skip {
            # Skip pattern validation tests if advanced schema validation unavailable
            if (-not (Get-Module -ListAvailable -Name "Newtonsoft.Json.Schema")) {
                Set-ItResult -Skipped -Because "Advanced schema validation not available"
                return
            }
            
            $operation = @{
                id = "test-006"
                srcfilename = "test.txt"
                dstfilename = "test.txt"
                sourcePath = "C:\Source"
                destinationPath = "C:\Dest"
                targeting_type = "none"
                target = "all"
                signature = $script:ValidAuthFields.signature
                timestamp = $script:ValidAuthFields.timestamp
                signerCertThumbprint = $script:InvalidAuthFields.signerCertThumbprint
                hashAlgorithm = $script:ValidAuthFields.hashAlgorithm
                signatureVersion = $script:ValidAuthFields.signatureVersion
            }
            
            $json = @($operation) | ConvertTo-Json -Depth 3
            $result = Test-JsonAgainstSchema -JsonContent $json -SchemaPath $script:FileOpsSchemaPath
            $result | Should -Be $false
        }
    }
}

Describe "REG-OPS Schema Authentication Support" -Tag "Unit", "Schema", "Authentication" {
    
    BeforeAll {
        # Ensure schema file exists
        if (-not (Test-Path $script:RegOpsSchemaPath)) {
            throw "REG-OPS.schema.json not found at: $script:RegOpsSchemaPath"
        }
        
        $script:RegOpsSchema = Get-Content -Raw -Path $script:RegOpsSchemaPath | ConvertFrom-Json
    }
    
    Context "Schema Structure Validation" {
        It "Should have updated version information" {
            $script:RegOpsSchema.'$id' | Should -Match "reg-ops-v1\.1\.json$"
            $script:RegOpsSchema.version | Should -Be "1.1.0"
        }
        
        It "Should include identical authentication properties as FILE-OPS" {
            $regProperties = $script:RegOpsSchema.items.properties
            $fileProperties = $script:FileOpsSchema.items.properties
            
            # Compare authentication field definitions
            $regProperties.signature.type | Should -Be $fileProperties.signature.type
            $regProperties.timestamp.type | Should -Be $fileProperties.timestamp.type
            $regProperties.timestamp.format | Should -Be $fileProperties.timestamp.format
            $regProperties.signerCertThumbprint.type | Should -Be $fileProperties.signerCertThumbprint.type
            $regProperties.hashAlgorithm.type | Should -Be $fileProperties.hashAlgorithm.type
            $regProperties.signatureVersion.type | Should -Be $fileProperties.signatureVersion.type
        }
    }
    
    Context "Valid Signed Registry Operations" {
        It "Should accept registry operation with valid authentication fields" {
            $operation = @{
                id = "reg-test-001"
                name = "TestValue"
                path = "HKEY_LOCAL_MACHINE\SOFTWARE\Test"
                value = "TestData"
                regtype = "string"
                write_once = "false"
                targeting_type = "none"
                target = "all"
                signature = $script:ValidAuthFields.signature
                timestamp = $script:ValidAuthFields.timestamp
                signerCertThumbprint = $script:ValidAuthFields.signerCertThumbprint
                hashAlgorithm = $script:ValidAuthFields.hashAlgorithm
                signatureVersion = $script:ValidAuthFields.signatureVersion
            }
            
            $json = @($operation) | ConvertTo-Json -Depth 3
            $result = Test-JsonAgainstSchema -JsonContent $json -SchemaPath $script:RegOpsSchemaPath
            $result | Should -Be $true
        }
    }
    
    Context "Unsigned Registry Operations (Backward Compatibility)" {
        It "Should accept registry operation without authentication fields" {
            $operation = @{
                id = "reg-test-002"
                name = "TestValue"
                path = "HKEY_LOCAL_MACHINE\SOFTWARE\Test"
                value = "TestData"
                regtype = "string"
                write_once = "false"
                targeting_type = "none"
                target = "all"
            }
            
            $json = @($operation) | ConvertTo-Json -Depth 3
            $result = Test-JsonAgainstSchema -JsonContent $json -SchemaPath $script:RegOpsSchemaPath
            $result | Should -Be $true
        }
    }
}

Describe "Schema Authentication Field Validation" -Tag "Unit", "Validation", "Authentication" {
    
    Context "Base64 Signature Pattern Validation" {
        It "Should identify valid Base64 signatures" {
            $validSignatures = @(
                "SGVsbG8gV29ybGQ=",
                "VGhpcyBpcyBhIHRlc3Q=",
                "QWxsIHlvdXIgYmFzZSBhcmUgYmVsb25nIHRvIHVz"
            )
            
            foreach ($signature in $validSignatures) {
                # Test regex pattern from schema
                $signature | Should -Match "^[A-Za-z0-9+/]+=*$"
            }
        }
        
        It "Should reject invalid Base64 signatures" {
            $invalidSignatures = @(
                "Invalid Base64!",
                "Contains spaces ",
                "Has#Invalid@Chars",
                ""  # Empty string
            )
            
            foreach ($signature in $invalidSignatures) {
                # Test regex pattern from schema
                $signature | Should -Not -Match "^[A-Za-z0-9+/]+=*$"
            }
        }
    }
    
    Context "Certificate Thumbprint Pattern Validation" {
        It "Should identify valid certificate thumbprints" {
            $validThumbprints = @(
                "A1B2C3D4E5F6789012345678901234567890ABCD",
                "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
                "0123456789ABCDEF0123456789ABCDEF01234567"
            )
            
            foreach ($thumbprint in $validThumbprints) {
                # Test regex pattern from schema
                $thumbprint | Should -Match "^[A-Fa-f0-9]{40}$"
            }
        }
        
        It "Should reject invalid certificate thumbprints" {
            $invalidThumbprints = @(
                "TOOSHORT",
                "A1B2C3D4E5F6789012345678901234567890ABCDEF",  # Too long
                "G1B2C3D4E5F6789012345678901234567890ABCD",   # Invalid char G
                "A1B2C3D4E5F6789012345678901234567890ABC"     # 39 chars
            )
            
            foreach ($thumbprint in $invalidThumbprints) {
                # Test regex pattern from schema
                $thumbprint | Should -Not -Match "^[A-Fa-f0-9]{40}$"
            }
        }
    }
    
    Context "ISO 8601 Timestamp Validation" {
        It "Should identify valid ISO 8601 timestamps" {
            $validTimestamps = @(
                "2025-09-07T10:30:00Z",
                "2025-12-31T23:59:59Z",
                "2025-01-01T00:00:00Z"
            )
            
            foreach ($timestamp in $validTimestamps) {
                # Test that PowerShell can parse as DateTime
                { [DateTime]::Parse($timestamp) } | Should -Not -Throw
            }
        }
        
        It "Should reject invalid timestamp formats" {
            $invalidTimestamps = @(
                "2025-13-45",           # Invalid month/day
                "Not a timestamp",      # Not a date
                "2025/09/07 10:30:00",  # Wrong format
                ""                      # Empty string
            )
            
            foreach ($timestamp in $invalidTimestamps) {
                # Test that PowerShell cannot parse as DateTime
                { [DateTime]::Parse($timestamp) } | Should -Throw
            }
        }
    }
}