using Newtonsoft.Json;

namespace EndpointPilot.SystemAgent.Models;

/// <summary>
/// Configuration model for EndpointPilot CONFIG.json.
/// Deserialized by SchedulerService and (future) DistributionService.
/// </summary>
public class EndpointPilotConfig
{
    [JsonProperty("OrgName")]
    public string OrgName { get; set; } = string.Empty;

    [JsonProperty("Refresh_Interval")]
    public int Refresh_Interval { get; set; } = 30;

    [JsonProperty("NetworkScriptRootPath")]
    public string NetworkScriptRootPath { get; set; } = string.Empty;

    [JsonProperty("NetworkScriptRootEnabled")]
    public bool NetworkScriptRootEnabled { get; set; } = false;

    [JsonProperty("HttpsScriptRootEnabled")]
    public bool HttpsScriptRootEnabled { get; set; } = false;

    [JsonProperty("HttpsScriptRootPath")]
    public string HttpsScriptRootPath { get; set; } = string.Empty;

    [JsonProperty("CopyLogFileToNetwork")]
    public bool CopyLogFileToNetwork { get; set; } = false;

    [JsonProperty("RoamFiles")]
    public bool RoamFiles { get; set; } = false;

    [JsonProperty("NetworkLogFile")]
    public string NetworkLogFile { get; set; } = string.Empty;

    [JsonProperty("NetworkRoamFolder")]
    public string NetworkRoamFolder { get; set; } = string.Empty;

    [JsonProperty("SkipFileOps")]
    public bool SkipFileOps { get; set; } = false;

    [JsonProperty("SkipDriveOps")]
    public bool SkipDriveOps { get; set; } = false;

    [JsonProperty("SkipRegOps")]
    public bool SkipRegOps { get; set; } = false;

    [JsonProperty("SkipRoamOps")]
    public bool SkipRoamOps { get; set; } = false;

    [JsonProperty("DryRun")]
    public bool DryRun { get; set; } = false;

    [JsonProperty("EnterpriseOnly")]
    public bool EnterpriseOnly { get; set; } = false;

    [JsonProperty("EntraClientId")]
    public string EntraClientId { get; set; } = string.Empty;

    [JsonProperty("EntraTenantId")]
    public string EntraTenantId { get; set; } = string.Empty;

    [JsonProperty("EntraTransitiveGroups")]
    public bool EntraTransitiveGroups { get; set; } = true;

    [JsonProperty("Distribution")]
    public DistributionConfig? Distribution { get; set; }
}

/// <summary>
/// Distribution API client configuration. Stub for Phase B — fields TBD during API design.
/// </summary>
public class DistributionConfig
{
    [JsonProperty("apiUrl")]
    public string ApiUrl { get; set; } = string.Empty;

    [JsonProperty("pollIntervalMinutes")]
    public int PollIntervalMinutes { get; set; } = 60;
}