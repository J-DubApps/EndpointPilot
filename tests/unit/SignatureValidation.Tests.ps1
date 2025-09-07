#Requires -Module Pester
#Requires -Version 5.1

BeforeAll {
    # Import the module being tested
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../MGMT-Functions.psm1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        throw "Cannot find MGMT-Functions.psm1 at expected path: $ModulePath"
    }
    
    # Import shared variables if available
    $SharedPath = Join-Path -Path $PSScriptRoot -ChildPath "../../MGMT-SHARED.ps1"
    if (Test-Path $SharedPath) {
        . $SharedPath
    }
    
    # Sample test data for signature validation
    $script:TestOperationData = @{
        id = "test-001"
        srcfilename = "test.txt"
        dstfilename = "test.txt"
        sourcePath = "C:\Source"
        destinationPath = "C:\Dest"
        targeting_type = "none"
        target = "all"
    }
    
    $script:ValidSignatureData = @{
        signature = "SGVsbG8gV29ybGQ="  # "Hello World" in Base64
        timestamp = "2025-09-07T10:30:00Z"
        signerCertThumbprint = "A1B2C3D4E5F6789012345678901234567890ABCD"
        hashAlgorithm = "SHA-256"
        signatureVersion = "1.0"
    }
    
    $script:InvalidSignatureData = @{
        signature = "InvalidBase64!"
        timestamp = "invalid-date"
        signerCertThumbprint = "INVALID"
        hashAlgorithm = "MD5"
        signatureVersion = "2.0"
    }
    
    # Mock certificate for testing
    $script:MockCertificate = [PSCustomObject]@{
        Thumbprint = "A1B2C3D4E5F6789012345678901234567890ABCD"
        Subject = "CN=Test Certificate"
        NotBefore = (Get-Date).AddDays(-30)
        NotAfter = (Get-Date).AddDays(365)
        PublicKey = [PSCustomObject]@{
            Key = [PSCustomObject]@{
                KeySize = 2048
            }
        }
        Extensions = @(
            [PSCustomObject]@{
                Oid = [PSCustomObject]@{ Value = "1.3.6.1.5.5.7.3.3" }  # Code Signing EKU
            }
        )
    }
}

Describe "Test-JsonSignature Function Tests" -Tag "Unit", "Signature", "Cryptography" {
    
    Context "Parameter Validation" {
        It "Should require OperationData parameter" {
            { Test-JsonSignature -SignatureData $script:ValidSignatureData } | Should -Throw "*OperationData*"
        }
        
        It "Should require SignatureData parameter" {
            { Test-JsonSignature -OperationData $script:TestOperationData } | Should -Throw "*SignatureData*"
        }
        
        It "Should accept valid parameter combinations" {
            # Mock the internal validation to avoid certificate dependencies
            Mock ConvertTo-CanonicalJson { return '{"test":"data"}' } -ModuleName MGMT-Functions
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
            Mock Invoke-SignatureVerification { return $true } -ModuleName MGMT-Functions
            
            { Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $script:ValidSignatureData } | Should -Not -Throw
        }
    }
    
    Context "Signature Data Validation" {
        BeforeEach {
            Mock ConvertTo-CanonicalJson { return '{"test":"data"}' } -ModuleName MGMT-Functions
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
            Mock Invoke-SignatureVerification { return $true } -ModuleName MGMT-Functions
        }
        
        It "Should validate required signature fields" {
            $incompleteSignature = @{
                signature = $script:ValidSignatureData.signature
                # Missing other required fields
            }
            
            Mock Write-Warning { } -ModuleName MGMT-Functions
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $incompleteSignature
            $result | Should -Be $false
        }
        
        It "Should validate Base64 signature format" {
            $invalidSignature = $script:ValidSignatureData.Clone()
            $invalidSignature.signature = "Invalid Base64!"
            
            Mock Write-Warning { } -ModuleName MGMT-Functions
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $invalidSignature
            $result | Should -Be $false
        }
        
        It "Should validate timestamp format" {
            $invalidSignature = $script:ValidSignatureData.Clone()
            $invalidSignature.timestamp = "invalid-date"
            
            Mock Write-Warning { } -ModuleName MGMT-Functions
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $invalidSignature
            $result | Should -Be $false
        }
        
        It "Should validate certificate thumbprint format" {
            $invalidSignature = $script:ValidSignatureData.Clone()
            $invalidSignature.signerCertThumbprint = "INVALID"
            
            Mock Write-Warning { } -ModuleName MGMT-Functions
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $invalidSignature
            $result | Should -Be $false
        }
        
        It "Should validate supported hash algorithms" {
            $invalidSignature = $script:ValidSignatureData.Clone()
            $invalidSignature.hashAlgorithm = "MD5"
            
            Mock Write-Warning { } -ModuleName MGMT-Functions
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $invalidSignature
            $result | Should -Be $false
        }
        
        It "Should validate signature version" {
            $invalidSignature = $script:ValidSignatureData.Clone()
            $invalidSignature.signatureVersion = "2.0"
            
            Mock Write-Warning { } -ModuleName MGMT-Functions  
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $invalidSignature
            $result | Should -Be $false
        }
    }
    
    Context "Certificate Validation Integration" {
        It "Should call Get-SignerCertificate with thumbprint" {
            Mock ConvertTo-CanonicalJson { return '{"test":"data"}' } -ModuleName MGMT-Functions
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions -Verifiable -ParameterFilter { 
                $Thumbprint -eq $script:ValidSignatureData.signerCertThumbprint 
            }
            Mock Invoke-SignatureVerification { return $true } -ModuleName MGMT-Functions
            
            Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $script:ValidSignatureData
            
            Should -InvokeVerifiable
        }
        
        It "Should return false when certificate not found" {
            Mock ConvertTo-CanonicalJson { return '{"test":"data"}' } -ModuleName MGMT-Functions
            Mock Get-SignerCertificate { return $null } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $script:ValidSignatureData
            $result | Should -Be $false
        }
    }
    
    Context "Signature Verification" {
        BeforeEach {
            Mock ConvertTo-CanonicalJson { return '{"test":"data"}' } -ModuleName MGMT-Functions
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
        }
        
        It "Should return true for valid signature" {
            Mock Invoke-SignatureVerification { return $true } -ModuleName MGMT-Functions
            
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $script:ValidSignatureData
            $result | Should -Be $true
        }
        
        It "Should return false for invalid signature" {
            Mock Invoke-SignatureVerification { return $false } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $script:ValidSignatureData
            $result | Should -Be $false
        }
        
        It "Should handle signature verification exceptions" {
            Mock Invoke-SignatureVerification { throw "Verification error" } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $script:ValidSignatureData
            $result | Should -Be $false
        }
    }
    
    Context "JSON Canonicalization" {
        It "Should call ConvertTo-CanonicalJson for hash input" {
            Mock ConvertTo-CanonicalJson { return '{"canonical":"json"}' } -ModuleName MGMT-Functions -Verifiable
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
            Mock Invoke-SignatureVerification { return $true } -ModuleName MGMT-Functions
            
            Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $script:ValidSignatureData
            
            Should -InvokeVerifiable
        }
        
        It "Should exclude signature fields from canonicalization" {
            $capturedHashInput = $null
            Mock ConvertTo-CanonicalJson { 
                param($HashInput)
                $capturedHashInput = $HashInput
                return '{"canonical":"json"}' 
            } -ModuleName MGMT-Functions
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
            Mock Invoke-SignatureVerification { return $true } -ModuleName MGMT-Functions
            
            Test-JsonSignature -OperationData $script:TestOperationData -SignatureData $script:ValidSignatureData
            
            # Verify signature fields are excluded from hash input
            $capturedHashInput.operationData | Should -Not -BeNullOrEmpty
            $capturedHashInput.timestamp | Should -Be $script:ValidSignatureData.timestamp
            $capturedHashInput.signerCertThumbprint | Should -Be $script:ValidSignatureData.signerCertThumbprint
            $capturedHashInput.PSObject.Properties.Name | Should -Not -Contain "signature"
            $capturedHashInput.PSObject.Properties.Name | Should -Not -Contain "signatureVersion"
        }
    }
}

Describe "Get-SignerCertificate Function Tests" -Tag "Unit", "Certificate", "Security" {
    
    Context "Parameter Validation" {
        It "Should require Thumbprint parameter" {
            { Get-SignerCertificate } | Should -Throw "*Thumbprint*"
        }
        
        It "Should validate thumbprint format" {
            { Get-SignerCertificate -Thumbprint "INVALID" } | Should -Throw "*thumbprint*format*"
        }
        
        It "Should accept valid thumbprint format" {
            Mock Get-ChildItem { return @() } -ModuleName MGMT-Functions
            
            { Get-SignerCertificate -Thumbprint "A1B2C3D4E5F6789012345678901234567890ABCD" } | Should -Not -Throw
        }
    }
    
    Context "Certificate Store Access" {
        BeforeEach {
            # Mock certificate store access
            Mock Get-ChildItem {
                param($Path)
                if ($Path -like "*CurrentUser\My*") {
                    return @($script:MockCertificate)
                } elseif ($Path -like "*LocalMachine\My*") {
                    return @($script:MockCertificate)
                }
                return @()
            } -ModuleName MGMT-Functions
        }
        
        It "Should search CurrentUser store first" {
            $result = Get-SignerCertificate -Thumbprint $script:MockCertificate.Thumbprint
            $result | Should -Not -BeNullOrEmpty
            $result.Thumbprint | Should -Be $script:MockCertificate.Thumbprint
        }
        
        It "Should search LocalMachine store if not found in CurrentUser" {
            Mock Get-ChildItem {
                param($Path)
                if ($Path -like "*CurrentUser\My*") {
                    return @()  # Not found in user store
                } elseif ($Path -like "*LocalMachine\My*") {
                    return @($script:MockCertificate)  # Found in machine store
                }
                return @()
            } -ModuleName MGMT-Functions
            
            $result = Get-SignerCertificate -Thumbprint $script:MockCertificate.Thumbprint
            $result | Should -Not -BeNullOrEmpty
            $result.Thumbprint | Should -Be $script:MockCertificate.Thumbprint
        }
        
        It "Should return null when certificate not found" {
            Mock Get-ChildItem { return @() } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Get-SignerCertificate -Thumbprint "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
            $result | Should -BeNullOrEmpty
        }
        
        It "Should handle certificate store access errors" {
            Mock Get-ChildItem { throw "Access denied" } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Get-SignerCertificate -Thumbprint $script:MockCertificate.Thumbprint
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context "Certificate Validation" {
        BeforeEach {
            Mock Get-ChildItem { return @($script:MockCertificate) } -ModuleName MGMT-Functions
        }
        
        It "Should validate certificate dates" {
            $expiredCert = $script:MockCertificate.PSObject.Copy()
            $expiredCert.NotAfter = (Get-Date).AddDays(-1)  # Expired yesterday
            
            Mock Get-ChildItem { return @($expiredCert) } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Get-SignerCertificate -Thumbprint $expiredCert.Thumbprint
            $result | Should -BeNullOrEmpty
        }
        
        It "Should validate Enhanced Key Usage for code signing" {
            $invalidEkuCert = $script:MockCertificate.PSObject.Copy()
            $invalidEkuCert.Extensions = @(
                [PSCustomObject]@{
                    Oid = [PSCustomObject]@{ Value = "1.3.6.1.5.5.7.3.1" }  # Server Authentication EKU
                }
            )
            
            Mock Get-ChildItem { return @($invalidEkuCert) } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Get-SignerCertificate -Thumbprint $invalidEkuCert.Thumbprint
            $result | Should -BeNullOrEmpty
        }
        
        It "Should accept certificate with code signing EKU" {
            $result = Get-SignerCertificate -Thumbprint $script:MockCertificate.Thumbprint
            $result | Should -Not -BeNullOrEmpty
            $result.Thumbprint | Should -Be $script:MockCertificate.Thumbprint
        }
        
        It "Should validate minimum key size" {
            $weakKeyCert = $script:MockCertificate.PSObject.Copy()
            $weakKeyCert.PublicKey.Key.KeySize = 1024  # Below minimum 2048
            
            Mock Get-ChildItem { return @($weakKeyCert) } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Get-SignerCertificate -Thumbprint $weakKeyCert.Thumbprint
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe "ConvertTo-CanonicalJson Function Tests" -Tag "Unit", "JSON", "Canonicalization" {
    
    Context "JSON Canonicalization" {
        It "Should sort object properties alphabetically" {
            $unsortedObject = [PSCustomObject]@{
                zebra = "last"
                alpha = "first"
                beta = "second"
            }
            
            $result = ConvertTo-CanonicalJson -InputObject $unsortedObject
            
            # Parse the result to verify ordering
            $resultObj = ConvertFrom-Json -InputObject $result
            $propertyNames = $resultObj.PSObject.Properties.Name
            $propertyNames[0] | Should -Be "alpha"
            $propertyNames[1] | Should -Be "beta"
            $propertyNames[2] | Should -Be "zebra"
        }
        
        It "Should handle nested objects" {
            $nestedObject = [PSCustomObject]@{
                outer = [PSCustomObject]@{
                    zebra = "nested_last"
                    alpha = "nested_first"
                }
                first = "value"
            }
            
            $result = ConvertTo-CanonicalJson -InputObject $nestedObject
            $result | Should -Not -BeNullOrEmpty
            
            # Verify it's valid JSON
            { ConvertFrom-Json -InputObject $result } | Should -Not -Throw
        }
        
        It "Should handle arrays consistently" {
            $objectWithArray = [PSCustomObject]@{
                items = @("third", "first", "second")
                name = "test"
            }
            
            $result = ConvertTo-CanonicalJson -InputObject $objectWithArray
            $resultObj = ConvertFrom-Json -InputObject $result
            
            # Array order should be preserved
            $resultObj.items[0] | Should -Be "third"
            $resultObj.items[1] | Should -Be "first"  
            $resultObj.items[2] | Should -Be "second"
        }
        
        It "Should produce consistent output for same input" {
            $testObject = [PSCustomObject]@{
                id = "test-001"
                timestamp = "2025-09-07T10:30:00Z"
                data = [PSCustomObject]@{
                    value = "example"
                    number = 42
                }
            }
            
            $result1 = ConvertTo-CanonicalJson -InputObject $testObject
            $result2 = ConvertTo-CanonicalJson -InputObject $testObject
            
            $result1 | Should -BeExactly $result2
        }
        
        It "Should handle null and empty values" {
            $objectWithNulls = [PSCustomObject]@{
                nullValue = $null
                emptyString = ""
                normalValue = "test"
            }
            
            $result = ConvertTo-CanonicalJson -InputObject $objectWithNulls
            { ConvertFrom-Json -InputObject $result } | Should -Not -Throw
        }
        
        It "Should remove whitespace and formatting" {
            $testObject = [PSCustomObject]@{
                test = "value"
            }
            
            $result = ConvertTo-CanonicalJson -InputObject $testObject
            
            # Should not contain extra whitespace
            $result | Should -Not -Match "\s{2,}"
            $result | Should -Not -Match "^\s"
            $result | Should -Not -Match "\s$"
        }
    }
}

Describe "Signature Validation Configuration Tests" -Tag "Unit", "Configuration" {
    
    Context "Enforcement Mode Configuration" {
        It "Should support strict enforcement mode" {
            # Test that strict mode is properly configured
            $config = Get-SignatureValidationConfig -Mode "strict"
            $config.EnforcementMode | Should -Be "strict"
            $config.FailOnUnsigned | Should -Be $true
            $config.FailOnInvalid | Should -Be $true
        }
        
        It "Should support warn enforcement mode" {
            $config = Get-SignatureValidationConfig -Mode "warn"
            $config.EnforcementMode | Should -Be "warn"
            $config.FailOnUnsigned | Should -Be $false
            $config.FailOnInvalid | Should -Be $true
        }
        
        It "Should support disabled enforcement mode" {
            $config = Get-SignatureValidationConfig -Mode "disabled"
            $config.EnforcementMode | Should -Be "disabled"
            $config.FailOnUnsigned | Should -Be $false
            $config.FailOnInvalid | Should -Be $false
        }
        
        It "Should default to warn mode when not specified" {
            $config = Get-SignatureValidationConfig
            $config.EnforcementMode | Should -Be "warn"
        }
    }
}

Describe "Signature Validation Performance Tests" -Tag "Integration", "Performance" {
    
    Context "Certificate Validation Caching" {
        It "Should cache certificate validation results" {
            Mock Get-ChildItem { return @($script:MockCertificate) } -ModuleName MGMT-Functions
            
            # First call should hit certificate store
            $result1 = Get-SignerCertificate -Thumbprint $script:MockCertificate.Thumbprint
            
            # Second call should use cache
            $result2 = Get-SignerCertificate -Thumbprint $script:MockCertificate.Thumbprint
            
            $result1 | Should -Not -BeNullOrEmpty
            $result2 | Should -Not -BeNullOrEmpty
            
            # Verify certificate store was only accessed once (due to caching)
            Should -Invoke Get-ChildItem -ModuleName MGMT-Functions -Exactly 1
        }
    }
}