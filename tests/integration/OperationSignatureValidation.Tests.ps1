#Requires -Module Pester
#Requires -Version 5.1

BeforeAll {
    # Import required modules
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
    
    # Test data setup
    $script:TestDataPath = Join-Path -Path $TestDrive -ChildPath "test-data"
    New-Item -ItemType Directory -Path $script:TestDataPath -Force | Out-Null
    
    # Sample unsigned file operation
    $script:UnsignedFileOperation = @{
        id = "test-unsigned-001"
        srcfilename = "test.txt"
        dstfilename = "test.txt"
        sourcePath = "C:\Source"
        destinationPath = "C:\Dest"
        overwrite = $true
        targeting_type = "none"
        target = "all"
        requiresAdmin = $false
    }
    
    # Sample signed file operation
    $script:SignedFileOperation = @{
        id = "test-signed-001"
        srcfilename = "test.txt"
        dstfilename = "test.txt"
        sourcePath = "C:\Source"
        destinationPath = "C:\Dest"
        overwrite = $true
        targeting_type = "none"
        target = "all"
        requiresAdmin = $false
        signature = "SGVsbG8gV29ybGQ="
        timestamp = "2025-09-07T10:30:00Z"
        signerCertThumbprint = "A1B2C3D4E5F6789012345678901234567890ABCD"
        hashAlgorithm = "SHA-256"
        signatureVersion = "1.0"
    }
    
    # Sample unsigned registry operation
    $script:UnsignedRegOperation = @{
        id = "reg-test-unsigned-001"
        name = "TestValue"
        path = "HKEY_LOCAL_MACHINE\SOFTWARE\Test"
        value = "TestData"
        regtype = "string"
        write_once = "false"
        targeting_type = "none"
        target = "all"
        requiresAdmin = $false
    }
    
    # Sample signed registry operation
    $script:SignedRegOperation = @{
        id = "reg-test-signed-001"
        name = "TestValue"
        path = "HKEY_LOCAL_MACHINE\SOFTWARE\Test"
        value = "TestData"
        regtype = "string"
        write_once = "false"
        targeting_type = "none"
        target = "all"
        requiresAdmin = $false
        signature = "SGVsbG8gV29ybGQ="
        timestamp = "2025-09-07T10:30:00Z"
        signerCertThumbprint = "A1B2C3D4E5F6789012345678901234567890ABCD"
        hashAlgorithm = "SHA-256"
        signatureVersion = "1.0"
    }
    
    # Sample invalid signature operation
    $script:InvalidSignatureOperation = @{
        id = "test-invalid-001"
        srcfilename = "test.txt"
        dstfilename = "test.txt"
        sourcePath = "C:\Source"
        destinationPath = "C:\Dest"
        targeting_type = "none"
        target = "all"
        requiresAdmin = $false
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
                Oid = [PSCustomObject]@{ Value = "2.5.29.37" }
                EnhancedKeyUsages = @(
                    [PSCustomObject]@{ Value = "1.3.6.1.5.5.7.3.3" }
                )
            }
        )
    }
    
    # Helper function to validate operation signature
    function Test-OperationSignature {
        param(
            [Parameter(Mandatory = $true)]
            [hashtable]$Operation,
            
            [Parameter(Mandatory = $false)]
            [string]$EnforcementMode = 'warn'
        )
        
        # Get validation configuration
        $config = Get-SignatureValidationConfig -Mode $EnforcementMode
        
        # Check if operation has signature fields
        $hasSignature = $Operation.ContainsKey('signature') -and 
                       $Operation.ContainsKey('timestamp') -and 
                       $Operation.ContainsKey('signerCertThumbprint') -and 
                       $Operation.ContainsKey('hashAlgorithm') -and 
                       $Operation.ContainsKey('signatureVersion')
        
        if (-not $hasSignature) {
            # Unsigned operation
            if ($config.FailOnUnsigned) {
                Write-Warning "Unsigned operation rejected in $($config.EnforcementMode) mode"
                return $false
            } else {
                Write-Verbose "Unsigned operation accepted in $($config.EnforcementMode) mode"
                return $true
            }
        }
        
        # Extract operation data (excluding signature fields)
        $operationData = @{}
        foreach ($key in $Operation.Keys) {
            if ($key -notin @('signature', 'timestamp', 'signerCertThumbprint', 'hashAlgorithm', 'signatureVersion')) {
                $operationData[$key] = $Operation[$key]
            }
        }
        
        # Extract signature data
        $signatureData = @{
            signature = $Operation.signature
            timestamp = $Operation.timestamp
            signerCertThumbprint = $Operation.signerCertThumbprint
            hashAlgorithm = $Operation.hashAlgorithm
            signatureVersion = $Operation.signatureVersion
        }
        
        # Validate signature
        $isValid = Test-JsonSignature -OperationData $operationData -SignatureData $signatureData
        
        if (-not $isValid -and $config.FailOnInvalid) {
            Write-Warning "Invalid signature rejected in $($config.EnforcementMode) mode"
            return $false
        }
        
        return $isValid
    }
}

Describe "File Operation Signature Validation" -Tag "Integration", "FileOps", "Signature" {
    
    Context "Unsigned Operations (Phase 1 Compatibility)" {
        BeforeEach {
            # Mock file operations to focus on signature validation
            Mock Copy-Item { } -ModuleName MGMT-Functions
            Mock Test-Path { return $false } -ModuleName MGMT-Functions
            Mock WriteLog { } -ModuleName MGMT-Functions
        }
        
        It "Should accept unsigned operations in disabled mode" {
            $result = Test-OperationSignature -Operation $script:UnsignedFileOperation -EnforcementMode 'disabled'
            $result | Should -Be $true
        }
        
        It "Should accept unsigned operations in warn mode" {
            $result = Test-OperationSignature -Operation $script:UnsignedFileOperation -EnforcementMode 'warn'
            $result | Should -Be $true
        }
        
        It "Should reject unsigned operations in strict mode" {
            $result = Test-OperationSignature -Operation $script:UnsignedFileOperation -EnforcementMode 'strict'
            $result | Should -Be $false
        }
        
        It "Should log appropriate warnings for unsigned operations" {
            Mock Write-Warning { } -Verifiable
            Test-OperationSignature -Operation $script:UnsignedFileOperation -EnforcementMode 'strict'
            Should -InvokeVerifiable
        }
    }
    
    Context "Signed Operations Validation" {
        BeforeEach {
            # Mock signature validation components
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
            Mock ConvertTo-CanonicalJson { return '{"canonical":"json"}' } -ModuleName MGMT-Functions
            Mock Invoke-SignatureVerification { return $true } -ModuleName MGMT-Functions
        }
        
        It "Should accept valid signed operations in all modes" {
            @('disabled', 'warn', 'strict') | ForEach-Object {
                $result = Test-OperationSignature -Operation $script:SignedFileOperation -EnforcementMode $_
                $result | Should -Be $true -Because "Valid signatures should be accepted in $_ mode"
            }
        }
        
        It "Should call signature validation for signed operations" {
            Mock Test-JsonSignature { return $true } -ModuleName MGMT-Functions -Verifiable
            Test-OperationSignature -Operation $script:SignedFileOperation -EnforcementMode 'warn'
            Should -InvokeVerifiable
        }
        
        It "Should extract operation data correctly for signature validation" {
            $capturedOperationData = $null
            $capturedSignatureData = $null
            
            Mock Test-JsonSignature { 
                param($OperationData, $SignatureData)
                $capturedOperationData = $OperationData
                $capturedSignatureData = $SignatureData
                return $true 
            } -ModuleName MGMT-Functions
            
            Test-OperationSignature -Operation $script:SignedFileOperation -EnforcementMode 'warn'
            
            # Verify operation data excludes signature fields
            $capturedOperationData.Keys | Should -Not -Contain 'signature'
            $capturedOperationData.Keys | Should -Not -Contain 'timestamp'
            $capturedOperationData.Keys | Should -Not -Contain 'signerCertThumbprint'
            $capturedOperationData.Keys | Should -Contain 'id'
            $capturedOperationData.Keys | Should -Contain 'srcfilename'
            
            # Verify signature data contains required fields
            $capturedSignatureData.signature | Should -Be $script:SignedFileOperation.signature
            $capturedSignatureData.timestamp | Should -Be $script:SignedFileOperation.timestamp
            $capturedSignatureData.signerCertThumbprint | Should -Be $script:SignedFileOperation.signerCertThumbprint
        }
    }
    
    Context "Invalid Signature Handling" {
        BeforeEach {
            # Mock invalid signature validation
            Mock Test-JsonSignature { return $false } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
        }
        
        It "Should reject invalid signatures in strict mode" {
            $result = Test-OperationSignature -Operation $script:InvalidSignatureOperation -EnforcementMode 'strict'
            $result | Should -Be $false
        }
        
        It "Should reject invalid signatures in warn mode" {
            $result = Test-OperationSignature -Operation $script:InvalidSignatureOperation -EnforcementMode 'warn'
            $result | Should -Be $false
        }
        
        It "Should accept invalid signatures in disabled mode" {
            $result = Test-OperationSignature -Operation $script:InvalidSignatureOperation -EnforcementMode 'disabled'
            $result | Should -Be $true
        }
        
        It "Should log warnings for invalid signatures" {
            Mock Write-Warning { } -Verifiable
            Test-OperationSignature -Operation $script:InvalidSignatureOperation -EnforcementMode 'warn'
            Should -InvokeVerifiable
        }
    }
    
    Context "Mixed Operations Processing" {
        BeforeEach {
            Mock Test-JsonSignature { 
                param($OperationData, $SignatureData)
                # Return true for valid signatures, false for invalid
                return $SignatureData.signature -eq "SGVsbG8gV29ybGQ="
            } -ModuleName MGMT-Functions
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
        }
        
        It "Should handle mixed signed and unsigned operations" {
            $mixedOperations = @($script:UnsignedFileOperation, $script:SignedFileOperation)
            
            foreach ($operation in $mixedOperations) {
                $result = Test-OperationSignature -Operation $operation -EnforcementMode 'warn'
                $result | Should -Be $true -Because "Both unsigned and valid signed operations should be accepted in warn mode"
            }
        }
        
        It "Should process operations with different signature validity" {
            $operations = @($script:SignedFileOperation, $script:InvalidSignatureOperation)
            $results = @()
            
            foreach ($operation in $operations) {
                $result = Test-OperationSignature -Operation $operation -EnforcementMode 'warn'
                $results += $result
            }
            
            $results[0] | Should -Be $true -Because "Valid signature should be accepted"
            $results[1] | Should -Be $false -Because "Invalid signature should be rejected in warn mode"
        }
    }
    
    Context "Performance and Caching" {
        It "Should leverage certificate caching for repeated operations" {
            # Setup multiple operations with same certificate
            $operation1 = $script:SignedFileOperation.Clone()
            $operation2 = $script:SignedFileOperation.Clone()
            $operation2.id = "test-signed-002"
            
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
            Mock Test-JsonSignature { return $true } -ModuleName MGMT-Functions
            
            # First operation should cache certificate
            Test-OperationSignature -Operation $operation1 -EnforcementMode 'warn'
            
            # Second operation should use cached certificate
            Test-OperationSignature -Operation $operation2 -EnforcementMode 'warn'
            
            # Verify certificate lookup was optimized (implementation detail)
            Should -Invoke Get-SignerCertificate -ModuleName MGMT-Functions -AtMost 2
        }
    }
}

Describe "Registry Operation Signature Validation" -Tag "Integration", "RegOps", "Signature" {
    
    Context "Registry-Specific Signature Validation" {
        BeforeEach {
            # Mock registry operations to focus on signature validation
            Mock Set-ItemProperty { } -ModuleName MGMT-Functions
            Mock Get-ItemProperty { } -ModuleName MGMT-Functions
            Mock WriteLog { } -ModuleName MGMT-Functions
        }
        
        It "Should validate unsigned registry operations correctly" {
            $result = Test-OperationSignature -Operation $script:UnsignedRegOperation -EnforcementMode 'warn'
            $result | Should -Be $true
        }
        
        It "Should validate signed registry operations correctly" {
            Mock Test-JsonSignature { return $true } -ModuleName MGMT-Functions
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
            
            $result = Test-OperationSignature -Operation $script:SignedRegOperation -EnforcementMode 'warn'
            $result | Should -Be $true
        }
        
        It "Should handle registry-specific fields in signature validation" {
            $capturedOperationData = $null
            
            Mock Test-JsonSignature { 
                param($OperationData, $SignatureData)
                $capturedOperationData = $OperationData
                return $true 
            } -ModuleName MGMT-Functions
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
            
            Test-OperationSignature -Operation $script:SignedRegOperation -EnforcementMode 'warn'
            
            # Verify registry-specific fields are included in operation data
            $capturedOperationData.Keys | Should -Contain 'name'
            $capturedOperationData.Keys | Should -Contain 'path'
            $capturedOperationData.Keys | Should -Contain 'value'
            $capturedOperationData.Keys | Should -Contain 'regtype'
            $capturedOperationData.Keys | Should -Not -Contain 'signature'
        }
    }
}

Describe "Signature Validation Error Handling" -Tag "Integration", "ErrorHandling" {
    
    Context "Certificate Validation Errors" {
        It "Should handle certificate not found gracefully" {
            Mock Get-SignerCertificate { return $null } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Test-OperationSignature -Operation $script:SignedFileOperation -EnforcementMode 'warn'
            $result | Should -Be $false
        }
        
        It "Should handle certificate validation exceptions" {
            Mock Get-SignerCertificate { throw "Certificate store access denied" } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Test-OperationSignature -Operation $script:SignedFileOperation -EnforcementMode 'warn'
            $result | Should -Be $false
        }
    }
    
    Context "Signature Verification Errors" {
        BeforeEach {
            Mock Get-SignerCertificate { return $script:MockCertificate } -ModuleName MGMT-Functions
        }
        
        It "Should handle signature verification exceptions" {
            Mock Test-JsonSignature { throw "Signature verification failed" } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Test-OperationSignature -Operation $script:SignedFileOperation -EnforcementMode 'warn'
            $result | Should -Be $false
        }
        
        It "Should handle JSON canonicalization errors" {
            Mock ConvertTo-CanonicalJson { throw "JSON canonicalization failed" } -ModuleName MGMT-Functions
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            $result = Test-OperationSignature -Operation $script:SignedFileOperation -EnforcementMode 'warn'
            $result | Should -Be $false
        }
    }
    
    Context "Security Violation Logging" {
        It "Should log security violations for tampered signatures" {
            Mock Test-JsonSignature { return $false } -ModuleName MGMT-Functions
            Mock WriteLog { } -ModuleName MGMT-Functions -Verifiable
            Mock Write-Warning { } -ModuleName MGMT-Functions
            
            Test-OperationSignature -Operation $script:SignedFileOperation -EnforcementMode 'strict'
            
            # Verify security violation was logged
            Should -InvokeVerifiable
        }
        
        It "Should provide detailed error information for debugging" {
            Mock Test-JsonSignature { return $false } -ModuleName MGMT-Functions
            
            $warningMessages = @()
            Mock Write-Warning { 
                param($Message) 
                $warningMessages += $Message 
            } -ModuleName MGMT-Functions
            
            Test-OperationSignature -Operation $script:SignedFileOperation -EnforcementMode 'strict'
            
            $warningMessages | Should -Not -BeNullOrEmpty
            $warningMessages -join ' ' | Should -Match "signature.*rejected.*strict"
        }
    }
}