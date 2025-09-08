using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using EndpointPilotJsonEditor.Core.Models;

namespace EndpointPilotJsonEditor.Core.Services
{
    /// <summary>
    /// Service for cryptographic operations including digital signing and validation
    /// </summary>
    public class CryptographicService
    {
        private readonly Dictionary<string, X509Certificate2> _certificateCache = new();

        /// <summary>
        /// Gets available code signing certificates from the certificate store
        /// </summary>
        /// <returns>List of certificates suitable for code signing</returns>
        public List<X509Certificate2> GetAvailableSigningCertificates()
        {
            var certificates = new List<X509Certificate2>();

            // Search in CurrentUser store
            using (var store = new X509Store(StoreName.My, StoreLocation.CurrentUser))
            {
                store.Open(OpenFlags.ReadOnly);
                certificates.AddRange(GetCodeSigningCertificates(store.Certificates));
            }

            // Search in LocalMachine store
            using (var store = new X509Store(StoreName.My, StoreLocation.LocalMachine))
            {
                store.Open(OpenFlags.ReadOnly);
                certificates.AddRange(GetCodeSigningCertificates(store.Certificates));
            }

            return certificates.OrderBy(c => c.Subject).ToList();
        }

        /// <summary>
        /// Filters certificates to only include those suitable for code signing
        /// </summary>
        /// <param name="certificates">Collection of certificates to filter</param>
        /// <returns>Certificates with code signing capabilities</returns>
        private static List<X509Certificate2> GetCodeSigningCertificates(X509Certificate2Collection certificates)
        {
            var codeSigning = new List<X509Certificate2>();

            foreach (X509Certificate2 cert in certificates)
            {
                try
                {
                    // Check if certificate has private key
                    if (!cert.HasPrivateKey)
                        continue;

                    // Check if certificate is valid
                    if (cert.NotAfter < DateTime.Now || cert.NotBefore > DateTime.Now)
                        continue;

                    // Check for Enhanced Key Usage extension
                    var ekuExtension = cert.Extensions.OfType<X509EnhancedKeyUsageExtension>().FirstOrDefault();
                    if (ekuExtension != null)
                    {
                        // Code Signing OID: 1.3.6.1.5.5.7.3.3
                        var codeSingingOid = new Oid("1.3.6.1.5.5.7.3.3");
                        if (ekuExtension.EnhancedKeyUsages.Cast<Oid>().Any(oid => oid.Value == codeSingingOid.Value))
                        {
                            codeSigning.Add(cert);
                        }
                    }
                    else
                    {
                        // If no EKU extension, check Key Usage for digital signature
                        var kuExtension = cert.Extensions.OfType<X509KeyUsageExtension>().FirstOrDefault();
                        if (kuExtension != null && kuExtension.KeyUsages.HasFlag(X509KeyUsageFlags.DigitalSignature))
                        {
                            codeSigning.Add(cert);
                        }
                    }
                }
                catch
                {
                    // Skip certificates that cause exceptions
                    continue;
                }
            }

            return codeSigning;
        }

        /// <summary>
        /// Signs an operation with the specified certificate
        /// </summary>
        /// <param name="operation">The operation to sign</param>
        /// <param name="certificate">The certificate to use for signing</param>
        /// <returns>True if signing was successful</returns>
        public bool SignOperation(OperationBase operation, X509Certificate2 certificate)
        {
            try
            {
                // Clear existing signature fields
                operation.Signature = null;
                operation.Timestamp = null;
                operation.SignerCertThumbprint = null;
                operation.HashAlgorithm = null;
                operation.SignatureVersion = null;

                // Create canonical JSON for signing (excluding signature fields)
                var canonicalJson = ConvertToCanonicalJson(operation);
                var dataToSign = Encoding.UTF8.GetBytes(canonicalJson);

                // Create signature using RSA-SHA256
                using (var rsa = certificate.GetRSAPrivateKey())
                {
                    if (rsa == null)
                        throw new InvalidOperationException("Certificate does not have an RSA private key");

                    var signature = rsa.SignData(dataToSign, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
                    
                    // Set signature fields
                    operation.Signature = Convert.ToBase64String(signature);
                    operation.Timestamp = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ");
                    operation.SignerCertThumbprint = certificate.Thumbprint;
                    operation.HashAlgorithm = "SHA256";
                    operation.SignatureVersion = "1.0";

                    return true;
                }
            }
            catch (Exception ex)
            {
                // Log error (in a real application, you'd use a proper logging framework)
                Console.WriteLine($"Error signing operation: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Validates the signature of an operation
        /// </summary>
        /// <param name="operation">The operation to validate</param>
        /// <returns>Validation result</returns>
        public SignatureValidationResult ValidateSignature(OperationBase operation)
        {
            try
            {
                if (string.IsNullOrEmpty(operation.Signature) || string.IsNullOrEmpty(operation.SignerCertThumbprint))
                {
                    return new SignatureValidationResult
                    {
                        IsValid = false,
                        ErrorMessage = "Operation is not signed"
                    };
                }

                // Get the signing certificate
                var certificate = GetCertificateByThumbprint(operation.SignerCertThumbprint);
                if (certificate == null)
                {
                    return new SignatureValidationResult
                    {
                        IsValid = false,
                        ErrorMessage = "Signing certificate not found in certificate store"
                    };
                }

                // Create a copy of the operation without signature fields for validation
                var operationForValidation = CloneOperationWithoutSignature(operation);
                var canonicalJson = ConvertToCanonicalJson(operationForValidation);
                var dataToVerify = Encoding.UTF8.GetBytes(canonicalJson);

                // Verify signature
                using (var rsa = certificate.GetRSAPublicKey())
                {
                    if (rsa == null)
                    {
                        return new SignatureValidationResult
                        {
                            IsValid = false,
                            ErrorMessage = "Certificate does not have an RSA public key"
                        };
                    }

                    var signature = Convert.FromBase64String(operation.Signature);
                    var isValid = rsa.VerifyData(dataToVerify, signature, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);

                    return new SignatureValidationResult
                    {
                        IsValid = isValid,
                        Certificate = certificate,
                        SigningTimestamp = operation.Timestamp,
                        ErrorMessage = isValid ? null : "Signature verification failed"
                    };
                }
            }
            catch (Exception ex)
            {
                return new SignatureValidationResult
                {
                    IsValid = false,
                    ErrorMessage = $"Error validating signature: {ex.Message}"
                };
            }
        }

        /// <summary>
        /// Gets a certificate from the cache or certificate store by thumbprint
        /// </summary>
        /// <param name="thumbprint">The certificate thumbprint</param>
        /// <returns>The certificate or null if not found</returns>
        private X509Certificate2? GetCertificateByThumbprint(string thumbprint)
        {
            // Check cache first
            if (_certificateCache.TryGetValue(thumbprint, out var cachedCert))
            {
                return cachedCert;
            }

            // Search certificate stores
            var stores = new[]
            {
                new { Name = StoreName.My, Location = StoreLocation.CurrentUser },
                new { Name = StoreName.My, Location = StoreLocation.LocalMachine }
            };

            foreach (var storeInfo in stores)
            {
                using (var store = new X509Store(storeInfo.Name, storeInfo.Location))
                {
                    store.Open(OpenFlags.ReadOnly);
                    var found = store.Certificates.Find(X509FindType.FindByThumbprint, thumbprint, false);
                    if (found.Count > 0)
                    {
                        var cert = found[0];
                        _certificateCache[thumbprint] = cert;
                        return cert;
                    }
                }
            }

            return null;
        }

        /// <summary>
        /// Creates a canonical JSON representation of an operation for consistent hashing
        /// </summary>
        /// <param name="operation">The operation to convert</param>
        /// <returns>Canonical JSON string</returns>
        private static string ConvertToCanonicalJson(OperationBase operation)
        {
            var json = JsonConvert.SerializeObject(operation, new JsonSerializerSettings
            {
                NullValueHandling = NullValueHandling.Ignore,
                Formatting = Formatting.None
            });

            // Parse and re-serialize to ensure consistent ordering
            var jObject = JObject.Parse(json);
            var sortedProperties = jObject.Properties().OrderBy(p => p.Name).ToList();
            
            var sortedObject = new JObject();
            foreach (var property in sortedProperties)
            {
                sortedObject.Add(property);
            }

            return JsonConvert.SerializeObject(sortedObject, Formatting.None);
        }

        /// <summary>
        /// Creates a copy of an operation without signature fields
        /// </summary>
        /// <param name="operation">The operation to clone</param>
        /// <returns>A new operation instance without signature fields</returns>
        private static OperationBase CloneOperationWithoutSignature(OperationBase operation)
        {
            var json = JsonConvert.SerializeObject(operation);
            var cloned = JsonConvert.DeserializeObject(json, operation.GetType()) as OperationBase;
            
            if (cloned != null)
            {
                cloned.Signature = null;
                cloned.Timestamp = null;
                cloned.SignerCertThumbprint = null;
                cloned.HashAlgorithm = null;
                cloned.SignatureVersion = null;
            }

            return cloned ?? operation;
        }
    }

    /// <summary>
    /// Result of a signature validation operation
    /// </summary>
    public class SignatureValidationResult
    {
        /// <summary>
        /// Gets or sets a value indicating whether the signature is valid
        /// </summary>
        public bool IsValid { get; set; }

        /// <summary>
        /// Gets or sets the signing certificate (if validation was successful)
        /// </summary>
        public X509Certificate2? Certificate { get; set; }

        /// <summary>
        /// Gets or sets the signing timestamp
        /// </summary>
        public string? SigningTimestamp { get; set; }

        /// <summary>
        /// Gets or sets the error message (if validation failed)
        /// </summary>
        public string? ErrorMessage { get; set; }

        /// <summary>
        /// Gets a display-friendly certificate subject
        /// </summary>
        public string CertificateSubject => Certificate?.Subject ?? "Unknown";

        /// <summary>
        /// Gets a display-friendly signing time
        /// </summary>
        public string DisplaySigningTime
        {
            get
            {
                if (DateTime.TryParse(SigningTimestamp, out var timestamp))
                {
                    return timestamp.ToString("yyyy-MM-dd HH:mm:ss UTC");
                }
                return SigningTimestamp ?? "Unknown";
            }
        }
    }
}