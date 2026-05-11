using Newtonsoft.Json;

namespace EndpointPilot.SystemAgent.Models;

/// <summary>
/// Deserialization model for hashes.json — maps script filenames to their SHA-256 hashes.
/// Used by PowerShellExecutor to verify script integrity before execution.
/// </summary>
public class ScriptHashManifest
{
    [JsonProperty("generatedAt")]
    public DateTime GeneratedAt { get; set; }

    [JsonProperty("hashAlgorithm")]
    public string HashAlgorithm { get; set; } = "SHA-256";

    [JsonProperty("scripts")]
    public Dictionary<string, string> Scripts { get; set; } = new();
}
