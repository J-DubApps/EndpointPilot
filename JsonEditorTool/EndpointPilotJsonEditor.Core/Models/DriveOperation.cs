using System;
using Newtonsoft.Json;

namespace EndpointPilotJsonEditor.Core.Models
{
    /// <summary>
    /// Model for drive operations in DRIVE-OPS.json
    /// </summary>
    public class DriveOperation : OperationBase
    {
        /// <summary>
        /// Drive letter with colon (e.g., "F:")
        /// </summary>
        [JsonProperty("driveLetter")]
        public string DriveLetter { get; set; } = string.Empty;

        /// <summary>
        /// UNC path for the drive (e.g., "\\server\share")
        /// </summary>
        [JsonProperty("drivePath")]
        public string DrivePath { get; set; } = string.Empty;

        /// <summary>
        /// Whether to reconnect the drive
        /// </summary>
        [JsonProperty("reconnect")]
        public bool Reconnect { get; set; } = false;

        /// <summary>
        /// Whether to delete the drive mapping
        /// </summary>
        [JsonProperty("delete")]
        public bool Delete { get; set; } = false;

        /// <summary>
        /// Whether to hide the drive
        /// </summary>
        [JsonProperty("hidden")]
        public bool Hidden { get; set; } = false;

        /// <summary>
        /// Gets a display name for the operation
        /// </summary>
        public override string DisplayName
        {
            get
            {
                if (Delete)
                {
                    return $"[{Id}] Delete: {DriveLetter}";
                }
                else
                {
                    return $"[{Id}] {DriveLetter} → {DrivePath}";
                }
            }
        }

        /// <summary>
        /// Gets the type of operation
        /// </summary>
        public override string OperationType => "Drive";

        /// <summary>
        /// Gets the available drive letters
        /// </summary>
        [JsonIgnore]
        public static string[] AvailableDriveLetters
        {
            get
            {
                var letters = new string[26];
                for (int i = 0; i < 26; i++)
                {
                    letters[i] = $"{(char)('A' + i)}:";
                }
                return letters;
            }
        }
    }
}