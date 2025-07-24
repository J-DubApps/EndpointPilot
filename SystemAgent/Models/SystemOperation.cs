using Newtonsoft.Json;

namespace EndpointPilot.SystemAgent.Models;

/// <summary>
/// Represents a system operation from SYSTEM-OPS.json
/// </summary>
public class SystemOperation
{
    [JsonProperty("id")]
    public string Id { get; set; } = string.Empty;

    [JsonProperty("operationType")]
    public string OperationType { get; set; } = string.Empty;

    [JsonProperty("comment")]
    public string? Comment { get; set; }

    [JsonProperty("parameters")]
    public Dictionary<string, object> Parameters { get; set; } = new();
}

/// <summary>
/// Root object for SYSTEM-OPS.json
/// </summary>
public class SystemOperationsConfig
{
    [JsonProperty("operations")]
    public List<SystemOperation> Operations { get; set; } = new();
}

/// <summary>
/// Result of processing system operations
/// </summary>
public class SystemOperationsResult
{
    public int TotalOperations { get; set; }
    public int SuccessfulOperations { get; set; }
    public int FailedOperations { get; set; }
    public List<SystemOperationResult> Results { get; set; } = new();
    public TimeSpan TotalExecutionTime { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
}

/// <summary>
/// Result of a single system operation
/// </summary>
public class SystemOperationResult
{
    public string OperationId { get; set; } = string.Empty;
    public string OperationType { get; set; } = string.Empty;
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string? Output { get; set; }
    public TimeSpan ExecutionTime { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
}