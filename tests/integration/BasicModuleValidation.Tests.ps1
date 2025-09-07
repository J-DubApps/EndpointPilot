# Basic module validation tests that can run cross-platform
# These tests validate the module structure and function availability

Describe "MGMT-Functions Module Validation" {
    Context "Module Loading" {
        It "Should load the MGMT-Functions module successfully" {
            { Import-Module "./MGMT-Functions.psm1" -Force } | Should -Not -Throw
        }
        
        It "Should export the signature validation functions" {
            Import-Module "./MGMT-Functions.psm1" -Force
            $expectedFunctions = @(
                'Test-JsonSignature',
                'Get-SignerCertificate',
                'ConvertTo-CanonicalJson',
                'Test-CertificateForSigning',
                'Invoke-SignatureVerification',
                'Get-SignatureValidationConfig'
            )
            
            foreach ($functionName in $expectedFunctions) {
                Get-Command $functionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Function $functionName should be available"
            }
        }
    }
    
    Context "Function Parameter Validation" {
        BeforeAll {
            Import-Module "./MGMT-Functions.psm1" -Force
        }
        
        It "Test-JsonSignature should have correct parameters" {
            $command = Get-Command Test-JsonSignature
            $command.Parameters.Keys | Should -Contain 'OperationData'
            $command.Parameters.Keys | Should -Contain 'SignatureData'
        }
        
        It "Get-SignerCertificate should have correct parameters" {
            $command = Get-Command Get-SignerCertificate
            $command.Parameters.Keys | Should -Contain 'Thumbprint'
        }
        
        It "ConvertTo-CanonicalJson should have correct parameters" {
            $command = Get-Command ConvertTo-CanonicalJson
            $command.Parameters.Keys | Should -Contain 'InputObject'
        }
        
        It "Get-SignatureValidationConfig should have correct parameters" {
            $command = Get-Command Get-SignatureValidationConfig
            # Should have no mandatory parameters
            $mandatoryParams = $command.Parameters.Values | Where-Object { $_.Attributes.Mandatory -eq $true }
            $mandatoryParams | Should -BeNullOrEmpty
        }
    }
    
    Context "File Integration Structure" {
        It "MGMT-FileOps.ps1 should contain signature validation calls" {
            $fileContent = Get-Content "MGMT-FileOps.ps1" -Raw
            $fileContent | Should -Match "Get-SignatureValidationConfig"
            $fileContent | Should -Match "Test-JsonSignature"
            $fileContent | Should -Match "SECURITY WARNING"
        }
        
        It "MGMT-RegOps.ps1 should contain signature validation calls" {
            $fileContent = Get-Content "MGMT-RegOps.ps1" -Raw
            $fileContent | Should -Match "Get-SignatureValidationConfig"
            $fileContent | Should -Match "Test-JsonSignature"
            $fileContent | Should -Match "SECURITY WARNING"
        }
    }
    
    Context "JSON Schema Updates" {
        It "FILE-OPS.schema.json should contain signature fields" {
            $schemaContent = Get-Content "FILE-OPS.schema.json" -Raw | ConvertFrom-Json
            $schemaContent.items.properties | Should -Not -BeNullOrEmpty
            $schemaContent.items.properties.signature | Should -Not -BeNullOrEmpty
            $schemaContent.items.properties.signerCertThumbprint | Should -Not -BeNullOrEmpty
            $schemaContent.version | Should -Be "1.1.0"
        }
        
        It "REG-OPS.schema.json should contain signature fields" {
            $schemaContent = Get-Content "REG-OPS.schema.json" -Raw | ConvertFrom-Json
            $schemaContent.items.properties | Should -Not -BeNullOrEmpty
            $schemaContent.items.properties.signature | Should -Not -BeNullOrEmpty
            $schemaContent.items.properties.signerCertThumbprint | Should -Not -BeNullOrEmpty
            $schemaContent.version | Should -Be "1.1.0"
        }
    }
}