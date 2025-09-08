using System;
using Newtonsoft.Json;

namespace EndpointPilotJsonEditor.Core.Models
{
    /// <summary>
    /// Base class for all operation types (File, Registry, Drive)
    /// </summary>
    public abstract class OperationBase
    {
        /// <summary>
        /// Unique identifier for the operation
        /// </summary>
        [JsonProperty("id")]
        public string Id { get; set; } = string.Empty;

        /// <summary>
        /// Type of targeting to apply (none, group, computer, user)
        /// </summary>
        [JsonProperty("targeting_type")]
        public string TargetingType { get; set; } = "none";

        /// <summary>
        /// Target for the operation
        /// </summary>
        [JsonProperty("target")]
        public string Target { get; set; } = "all";

        /// <summary>
        /// Comment field 1
        /// </summary>
        [JsonProperty("_comment1")]
        public string Comment1 { get; set; } = string.Empty;

        /// <summary>
        /// Comment field 2
        /// </summary>
        [JsonProperty("_comment2")]
        public string Comment2 { get; set; } = string.Empty;

        /// <summary>
        /// Digital signature for operation authentication (Base64 encoded)
        /// </summary>
        [JsonProperty("signature", NullValueHandling = NullValueHandling.Ignore)]
        public string? Signature { get; set; }

        /// <summary>
        /// Timestamp when the operation was signed (ISO 8601 format)
        /// </summary>
        [JsonProperty("timestamp", NullValueHandling = NullValueHandling.Ignore)]
        public string? Timestamp { get; set; }

        /// <summary>
        /// Thumbprint of the certificate used for signing (SHA-1 hash)
        /// </summary>
        [JsonProperty("signerCertThumbprint", NullValueHandling = NullValueHandling.Ignore)]
        public string? SignerCertThumbprint { get; set; }

        /// <summary>
        /// Hash algorithm used for signature generation (e.g., "SHA256")
        /// </summary>
        [JsonProperty("hashAlgorithm", NullValueHandling = NullValueHandling.Ignore)]
        public string? HashAlgorithm { get; set; }

        /// <summary>
        /// Version of the signature format (e.g., "1.0")
        /// </summary>
        [JsonProperty("signatureVersion", NullValueHandling = NullValueHandling.Ignore)]
        public string? SignatureVersion { get; set; }

        /// <summary>
        /// Gets a value indicating whether this operation is digitally signed
        /// </summary>
        [JsonIgnore]
        public bool IsSigned => !string.IsNullOrEmpty(Signature) && !string.IsNullOrEmpty(SignerCertThumbprint);

        /// <summary>
        /// Gets a display name for the operation
        /// </summary>
        public abstract string DisplayName { get; }

        /// <summary>
        /// Gets the type of operation (File, Registry, Drive)
        /// </summary>
        [JsonIgnore] // <-- Add attribute here
        public abstract string OperationType { get; }
    }
}