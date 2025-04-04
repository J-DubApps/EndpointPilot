using System;
using Newtonsoft.Json;

namespace EndpointPilotJsonEditor.Core.Models
{
    /// <summary>
    /// Model for the CONFIG.json file
    /// </summary>
    public class ConfigModel
    {
        /// <summary>
        /// Organization name
        /// </summary>
        [JsonProperty("OrgName")]
        public string OrgName { get; set; } = string.Empty;

        /// <summary>
        /// Refresh interval in minutes
        /// </summary>
        [JsonProperty("Refresh_Interval")]
        public int RefreshInterval { get; set; } = 120;

        /// <summary>
        /// Network path to script root
        /// </summary>
        [JsonProperty("NetworkScriptRootPath")]
        public string NetworkScriptRootPath { get; set; } = string.Empty;

        /// <summary>
        /// Whether to copy log files to network location
        /// </summary>
        [JsonProperty("CopyLogFileToNetwork")]
        public bool CopyLogFileToNetwork { get; set; } = false;

        /// <summary>
        /// Whether to enable file roaming
        /// </summary>
        [JsonProperty("RoamFiles")]
        public bool RoamFiles { get; set; } = false;

        /// <summary>
        /// Network path for log files
        /// </summary>
        [JsonProperty("NetworkLogFile")]
        public string NetworkLogFile { get; set; } = string.Empty;

        /// <summary>
        /// Network path for roaming files
        /// </summary>
        [JsonProperty("NetworkRoamFolder")]
        public string NetworkRoamFolder { get; set; } = string.Empty;

        /// <summary>
        /// Whether to skip file operations
        /// </summary>
        [JsonProperty("SkipFileOps")]
        public bool SkipFileOps { get; set; } = false;

        /// <summary>
        /// Whether to skip drive operations
        /// </summary>
        [JsonProperty("SkipDriveOps")]
        public bool SkipDriveOps { get; set; } = false;

        /// <summary>
        /// Whether to skip registry operations
        /// </summary>
        [JsonProperty("SkipRegOps")]
        public bool SkipRegOps { get; set; } = false;

        /// <summary>
        /// Whether to skip roaming operations
        /// </summary>
        [JsonProperty("SkipRoamOps")]
        public bool SkipRoamOps { get; set; } = false;
    }
}