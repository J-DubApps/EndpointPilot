using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;
using EndpointPilotJsonEditor.Core.Models;
using EndpointPilotJsonEditor.Core.Services;
using Newtonsoft.Json;

namespace EndpointPilotJsonEditor.Tests
{
    /// <summary>
    /// Comprehensive integration tests for JsonEditorTool digital signing functionality
    /// </summary>
    public class JsonEditorToolSigningIntegrationTests
    {
        private readonly string _testDirectory;
        private readonly JsonFileService _jsonFileService;
        private readonly CryptographicService _cryptographicService;

        public JsonEditorToolSigningIntegrationTests()
        {
            _testDirectory = Path.Combine(Path.GetTempPath(), "EndpointPilotSigningTests", Guid.NewGuid().ToString());
            Directory.CreateDirectory(_testDirectory);
            _jsonFileService = new JsonFileService(_testDirectory);
            _cryptographicService = new CryptographicService();
        }

        /// <summary>
        /// Test complete signing workflow for file operations
        /// </summary>
        public async Task<bool> TestFileOperationsSigningWorkflow()
        {
            try
            {
                Console.WriteLine("Testing File Operations Signing Workflow...");
                
                // Create test file operations
                var fileOperations = new List<FileOperation>
                {
                    new FileOperation
                    {
                        Id = "test-file-1",
                        SourceFilename = "source.txt",
                        DestinationFilename = "dest.txt",
                        SourcePath = @"C:\Source",
                        DestinationPath = @"C:\Dest",
                        Overwrite = true,
                        RequiresAdmin = false,
                        Comment1 = "Test file operation for signing",
                        TargetingType = "none",
                        Target = "all"
                    },
                    new FileOperation
                    {
                        Id = "test-file-2",
                        SourceFilename = "config.json",
                        DestinationFilename = "app-config.json", 
                        SourcePath = @"C:\Config",
                        DestinationPath = @"C:\App",
                        CopyOnce = true,
                        RequiresAdmin = true,
                        AdminContext = "system",
                        Comment1 = "Configuration deployment",
                        TargetingType = "group",
                        Target = "IT-Admins"
                    }
                };

                // Test 1: Save without signing
                await _jsonFileService.WriteFileOperationsAsync(fileOperations, "FILE-OPS.json");
                
                var savedOperations = await _jsonFileService.ReadFileOperationsAsync("FILE-OPS.json");
                if (savedOperations.Any(op => op.IsSigned))
                {
                    Console.WriteLine("❌ FAILED: Operations should not be signed when saved without certificate");
                    return false;
                }
                Console.WriteLine("✅ PASSED: Unsigned operations saved correctly");

                // Test 2: Create test certificate for signing
                var testCertificate = CreateTestCertificate();
                if (testCertificate == null)
                {
                    Console.WriteLine("❌ FAILED: Could not create test certificate");
                    return false;
                }
                Console.WriteLine("✅ PASSED: Test certificate created successfully");

                // Test 3: Save with signing
                await _jsonFileService.WriteFileOperationsAsync(fileOperations, "FILE-OPS-SIGNED.json", testCertificate);
                
                var signedOperations = await _jsonFileService.ReadFileOperationsAsync("FILE-OPS-SIGNED.json");
                if (!signedOperations.All(op => op.IsSigned))
                {
                    Console.WriteLine("❌ FAILED: All operations should be signed when saved with certificate");
                    return false;
                }
                Console.WriteLine("✅ PASSED: All operations signed correctly");

                // Test 4: Validate signatures
                var validationResults = _jsonFileService.ValidateOperationSignatures(signedOperations);
                foreach (var result in validationResults)
                {
                    if (!result.Value.IsValid)
                    {
                        Console.WriteLine($"❌ FAILED: Operation {result.Key} signature validation failed: {result.Value.ErrorMessage}");
                        return false;
                    }
                }
                Console.WriteLine("✅ PASSED: All operation signatures validated successfully");

                // Test 5: Verify signature properties
                foreach (var operation in signedOperations)
                {
                    if (string.IsNullOrEmpty(operation.Signature) ||
                        string.IsNullOrEmpty(operation.SignerCertThumbprint) ||
                        string.IsNullOrEmpty(operation.Timestamp) ||
                        operation.HashAlgorithm != "SHA256" ||
                        operation.SignatureVersion != "1.0")
                    {
                        Console.WriteLine($"❌ FAILED: Operation {operation.Id} missing required signature properties");
                        return false;
                    }
                }
                Console.WriteLine("✅ PASSED: All signature properties set correctly");

                // Test 6: Test signature tampering detection
                var tamperedOperation = signedOperations.First();
                var originalComment = tamperedOperation.Comment1;
                tamperedOperation.Comment1 = "TAMPERED CONTENT";
                
                var tamperedValidation = _cryptographicService.ValidateSignature(tamperedOperation);
                if (tamperedValidation.IsValid)
                {
                    Console.WriteLine("❌ FAILED: Tampered operation should fail signature validation");
                    return false;
                }
                Console.WriteLine("✅ PASSED: Signature tampering detected correctly");
                
                // Restore original content
                tamperedOperation.Comment1 = originalComment;

                Console.WriteLine("🎉 All File Operations Signing Tests Passed!");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ FAILED: Exception in file operations signing test: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Test complete signing workflow for registry operations
        /// </summary>
        public async Task<bool> TestRegistryOperationsSigningWorkflow()
        {
            try
            {
                Console.WriteLine("Testing Registry Operations Signing Workflow...");
                
                // Create test registry operations
                var regOperations = new List<RegOperation>
                {
                    new RegOperation
                    {
                        Id = "test-reg-1",
                        Name = "TestValue",
                        Path = @"HKEY_CURRENT_USER\Software\EndpointPilot",
                        Value = "TestData",
                        RegType = "REG_SZ",
                        RequiresAdmin = false,
                        Comment1 = "Test registry operation for signing",
                        TargetingType = "none",
                        Target = "all"
                    },
                    new RegOperation
                    {
                        Id = "test-reg-2", 
                        Name = "SystemSetting",
                        Path = @"HKEY_LOCAL_MACHINE\SOFTWARE\Company\App",
                        Value = "Production",
                        RegType = "REG_SZ",
                        RequiresAdmin = true,
                        AdminContext = "system",
                        Comment1 = "System-level configuration",
                        TargetingType = "computer",
                        Target = "WORKSTATION-*"
                    }
                };

                // Test with signing
                var testCertificate = CreateTestCertificate();
                await _jsonFileService.WriteRegOperationsAsync(regOperations, "REG-OPS-SIGNED.json", testCertificate);
                
                var signedOperations = await _jsonFileService.ReadRegOperationsAsync("REG-OPS-SIGNED.json");
                if (!signedOperations.All(op => op.IsSigned))
                {
                    Console.WriteLine("❌ FAILED: All registry operations should be signed");
                    return false;
                }

                // Validate signatures
                var validationResults = _jsonFileService.ValidateOperationSignatures(signedOperations);
                if (!validationResults.All(r => r.Value.IsValid))
                {
                    Console.WriteLine("❌ FAILED: Registry operation signatures failed validation");
                    return false;
                }

                Console.WriteLine("✅ PASSED: Registry operations signing workflow completed successfully");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ FAILED: Exception in registry operations signing test: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Test certificate discovery and validation
        /// </summary>
        public bool TestCertificateDiscovery()
        {
            try
            {
                Console.WriteLine("Testing Certificate Discovery...");
                
                var certificates = _cryptographicService.GetAvailableSigningCertificates();
                Console.WriteLine($"Found {certificates.Count} available signing certificates");
                
                // Validate certificate properties
                foreach (var cert in certificates)
                {
                    if (!cert.HasPrivateKey)
                    {
                        Console.WriteLine($"❌ FAILED: Certificate {cert.Subject} should have private key");
                        return false;
                    }
                    
                    if (cert.NotAfter < DateTime.Now)
                    {
                        Console.WriteLine($"❌ FAILED: Certificate {cert.Subject} is expired");
                        return false;
                    }
                }

                Console.WriteLine("✅ PASSED: Certificate discovery completed successfully");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ FAILED: Exception in certificate discovery test: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Test JSON schema compatibility with signed operations
        /// </summary>
        public async Task<bool> TestJsonSchemaCompatibility()
        {
            try
            {
                Console.WriteLine("Testing JSON Schema Compatibility...");
                
                // Create mixed signed and unsigned operations
                var operations = new List<FileOperation>
                {
                    // Unsigned operation
                    new FileOperation
                    {
                        Id = "unsigned-1",
                        SourceFilename = "file1.txt",
                        DestinationFilename = "file1-dest.txt",
                        SourcePath = @"C:\Source",
                        DestinationPath = @"C:\Dest"
                    }
                };

                // Save unsigned first
                await _jsonFileService.WriteFileOperationsAsync(operations, "MIXED-OPS.json");
                
                // Add signed operation
                var testCert = CreateTestCertificate();
                operations.Add(new FileOperation
                {
                    Id = "signed-1",
                    SourceFilename = "file2.txt", 
                    DestinationFilename = "file2-dest.txt",
                    SourcePath = @"C:\Source",
                    DestinationPath = @"C:\Dest"
                });

                // Sign only the new operation
                _cryptographicService.SignOperation(operations[1], testCert);
                
                // Save mixed operations
                await _jsonFileService.WriteFileOperationsAsync(operations, "MIXED-OPS.json");
                
                var loadedOps = await _jsonFileService.ReadFileOperationsAsync("MIXED-OPS.json");
                
                if (loadedOps[0].IsSigned || !loadedOps[1].IsSigned)
                {
                    Console.WriteLine("❌ FAILED: Mixed signed/unsigned operations not handled correctly");
                    return false;
                }

                Console.WriteLine("✅ PASSED: JSON schema handles mixed signed/unsigned operations correctly");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ FAILED: Exception in schema compatibility test: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Creates a test certificate for signing operations
        /// </summary>
        private X509Certificate2? CreateTestCertificate()
        {
            try
            {
                // Create a self-signed certificate for testing
                using (var rsa = RSA.Create(2048))
                {
                    var request = new CertificateRequest(
                        "CN=EndpointPilot Test Certificate", 
                        rsa, 
                        HashAlgorithmName.SHA256,
                        RSASignaturePadding.Pkcs1);

                    // Add code signing enhanced key usage
                    request.Extensions.Add(
                        new X509EnhancedKeyUsageExtension(
                            new OidCollection { new Oid("1.3.6.1.5.5.7.3.3") }, // Code Signing
                            false));

                    // Add key usage for digital signature
                    request.Extensions.Add(
                        new X509KeyUsageExtension(
                            X509KeyUsageFlags.DigitalSignature | X509KeyUsageFlags.KeyEncipherment,
                            false));

                    var certificate = request.CreateSelfSigned(
                        DateTime.UtcNow.AddDays(-1), 
                        DateTime.UtcNow.AddDays(365));

                    return certificate;
                }
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Runs all comprehensive tests
        /// </summary>
        public async Task<bool> RunAllTests()
        {
            Console.WriteLine("🚀 Starting JsonEditorTool Digital Signing Integration Tests");
            Console.WriteLine("=" + new string('=', 60));

            var results = new List<bool>
            {
                TestCertificateDiscovery(),
                await TestFileOperationsSigningWorkflow(),
                await TestRegistryOperationsSigningWorkflow(), 
                await TestJsonSchemaCompatibility()
            };

            Console.WriteLine("=" + new string('=', 60));
            
            if (results.All(r => r))
            {
                Console.WriteLine("🎉 ALL TESTS PASSED! JsonEditorTool digital signing is working correctly.");
                return true;
            }
            else
            {
                Console.WriteLine("❌ Some tests failed. Please review the output above.");
                return false;
            }
        }

        /// <summary>
        /// Clean up test files
        /// </summary>
        public void Dispose()
        {
            try
            {
                if (Directory.Exists(_testDirectory))
                {
                    Directory.Delete(_testDirectory, true);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Warning: Could not clean up test directory: {ex.Message}");
            }
        }

        /// <summary>
        /// Entry point for running tests
        /// </summary>
        public static async Task Main(string[] args)
        {
            var tests = new JsonEditorToolSigningIntegrationTests();
            try
            {
                var success = await tests.RunAllTests();
                Environment.Exit(success ? 0 : 1);
            }
            finally
            {
                tests.Dispose();
            }
        }
    }
}