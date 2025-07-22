using System.Management.Automation;
using System.Security.Principal;

namespace EndpointPilot.SystemAgent.Services;

/// <summary>
/// Interface for executing PowerShell scripts in different security contexts
/// </summary>
public interface IPowerShellExecutor
{
    /// <summary>
    /// Executes a PowerShell script in the SYSTEM context (elevated privileges)
    /// </summary>
    /// <param name="scriptPath">Path to the PowerShell script</param>
    /// <param name="parameters">Parameters to pass to the script</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Execution result containing output, errors, and exit code</returns>
    Task<PowerShellExecutionResult> ExecuteAsSystemAsync(string scriptPath, Dictionary<string, object>? parameters = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Executes a PowerShell script in the current user session context (user privileges)
    /// </summary>
    /// <param name="scriptPath">Path to the PowerShell script</param>
    /// <param name="parameters">Parameters to pass to the script</param>
    /// <param name="sessionId">User session ID to target</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Execution result containing output, errors, and exit code</returns>
    Task<PowerShellExecutionResult> ExecuteAsUserAsync(string scriptPath, Dictionary<string, object>? parameters = null, int? sessionId = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Validates that a PowerShell script is safe to execute
    /// </summary>
    /// <param name="scriptPath">Path to the script to validate</param>
    /// <returns>True if the script is safe, false otherwise</returns>
    Task<bool> ValidateScriptSafetyAsync(string scriptPath);
}

/// <summary>
/// Result of a PowerShell script execution
/// </summary>
public class PowerShellExecutionResult
{
    public int ExitCode { get; set; }
    public string Output { get; set; } = string.Empty;
    public string Error { get; set; } = string.Empty;
    public TimeSpan ExecutionTime { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public string ExecutionContext { get; set; } = string.Empty; // "System" or "User"
    public bool Success => ExitCode == 0 && string.IsNullOrEmpty(Error);
}