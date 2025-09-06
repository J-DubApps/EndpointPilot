using System;
using Newtonsoft.Json;

namespace EndpointPilotJsonEditor.Core.Models
{
    /// <summary>
    /// Model for file operations in FILE-OPS.json
    /// </summary>
    public class FileOperation : OperationBase
    {
        /// <summary>
        /// Source filename
        /// </summary>
        [JsonProperty("srcfilename")]
        public string SourceFilename { get; set; } = string.Empty;

        /// <summary>
        /// Destination filename
        /// </summary>
        [JsonProperty("dstfilename")]
        public string DestinationFilename { get; set; } = string.Empty;

        /// <summary>
        /// Source directory path
        /// </summary>
        [JsonProperty("sourcePath")]
        public string SourcePath { get; set; } = string.Empty;

        /// <summary>
        /// Destination directory path
        /// </summary>
        [JsonProperty("destinationPath")]
        public string DestinationPath { get; set; } = string.Empty;

        /// <summary>
        /// Whether to overwrite existing files
        /// </summary>
        [JsonProperty("overwrite")]
        public bool Overwrite { get; set; } = false;

        /// <summary>
        /// Whether to copy the file only once
        /// </summary>
        [JsonProperty("copyonce")]
        public bool CopyOnce { get; set; } = false;

        /// <summary>
        /// Location to check for existence
        /// </summary>
        [JsonProperty("existCheckLocation")]
        public string ExistCheckLocation { get; set; } = string.Empty;

        /// <summary>
        /// Whether to check if file exists
        /// </summary>
        [JsonProperty("existCheck")]
        public bool ExistCheck { get; set; } = false;

        /// <summary>
        /// Whether to delete the file
        /// </summary>
        [JsonProperty("deleteFile")]
        public bool DeleteFile { get; set; } = false;

        /// <summary>
        /// Whether this operation requires administrative/SYSTEM privileges
        /// </summary>
        [JsonProperty("requiresAdmin")]
        public bool RequiresAdmin { get; set; } = false;

        /// <summary>
        /// Execution context when admin is required (user, system, auto)
        /// </summary>
        [JsonProperty("adminContext")]
        public string AdminContext { get; set; } = "auto";

        /// <summary>
        /// Gets a display name for the operation
        /// </summary>
        [JsonIgnore] // <-- Add attribute here too
        public override string DisplayName
        {
            get
            {
                if (DeleteFile)
                {
                    return $"[{Id}] Delete: {DestinationFilename}";
                }
                else
                {
                    return $"[{Id}] {SourceFilename} → {DestinationFilename}";
                }
            }
        }

        /// <summary>
        /// Gets the type of operation
        /// </summary>
        [JsonIgnore] // <-- Add attribute here
        public override string OperationType => "File";

        /// <summary>
        /// Gets the available admin context options
        /// </summary>
        [JsonIgnore]
        public static string[] AvailableAdminContexts => new[]
        {
            "auto",
            "user", 
            "system"
        };
    }
}