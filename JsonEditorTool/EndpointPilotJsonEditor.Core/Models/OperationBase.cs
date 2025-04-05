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