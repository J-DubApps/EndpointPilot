using System;
using Newtonsoft.Json;

namespace EndpointPilotJsonEditor.Core.Models
{
    /// <summary>
    /// Model for registry operations in REG-OPS.json
    /// </summary>
    public class RegOperation : OperationBase
    {
        /// <summary>
        /// Registry value name
        /// </summary>
        [JsonProperty("name")]
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// Registry key path
        /// </summary>
        [JsonProperty("path")]
        public string Path { get; set; } = string.Empty;

        /// <summary>
        /// Registry value
        /// </summary>
        [JsonProperty("value")]
        public string Value { get; set; } = string.Empty;

        /// <summary>
        /// Registry value type (string, dword, qword, binary, multi-string, expandable)
        /// </summary>
        [JsonProperty("regtype")]
        public string RegType { get; set; } = "string";

        /// <summary>
        /// Whether to write the registry value only once
        /// </summary>
        [JsonProperty("write_once")]
        public string WriteOnce { get; set; } = "false";

        /// <summary>
        /// Whether to delete the registry value
        /// </summary>
        [JsonProperty("delete")]
        public bool Delete { get; set; } = false;

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
                if (Delete)
                {
                    return $"[{Id}] Delete: {Path}\\{Name}";
                }
                else
                {
                    return $"[{Id}] {Path}\\{Name} = {Value} ({RegType})";
                }
            }
        }

        /// <summary>
        /// Gets the type of operation
        /// </summary>
        [JsonIgnore] // <-- Add attribute here
        public override string OperationType => "Registry";

        /// <summary>
        /// Gets a boolean representation of the WriteOnce property
        /// </summary>
        [JsonIgnore]
        public bool WriteOnceAsBool
        {
            get => WriteOnce.ToLower() == "true";
            set => WriteOnce = value ? "true" : "false";
        }

        /// <summary>
        /// Gets the available registry value types
        /// </summary>
        [JsonIgnore]
        public static string[] AvailableRegTypes => new[]
        {
            "string",
            "dword",
            "qword",
            "binary",
            "multi-string",
            "expandable"
        };

        /// <summary>
        /// Gets the available registry hives
        /// </summary>
        [JsonIgnore]
        public static string[] AvailableHives => new[]
        {
            "HKEY_CURRENT_USER",
            "HKEY_LOCAL_MACHINE",
            "HKEY_CLASSES_ROOT",
            "HKEY_USERS",
            "HKEY_CURRENT_CONFIG"
        };

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