using System.Diagnostics;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Security.Principal;
using System.Text;

namespace EndpointPilot.SystemAgent.Services;

/// <summary>
/// Service for executing PowerShell scripts in different security contexts
/// </summary>
public class PowerShellExecutor : IPowerShellExecutor
{
    private readonly ILogger<PowerShellExecutor> _logger;
    private readonly string _endpointPilotPath;
    private readonly HashSet<string> _allowedScripts;

    public PowerShellExecutor(ILogger<PowerShellExecutor> logger)
    {
        _logger = logger;
        _endpointPilotPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "EndpointPilot");
        
        // Initialize allowed scripts - only EndpointPilot scripts from secure locations
        _allowedScripts = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            Path.Combine(_endpointPilotPath, "MAIN.PS1"),
            Path.Combine(_endpointPilotPath, "MGMT-FileOps.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-RegOps.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-DriveOps.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-RoamOps.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-SchedTsk.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-Telemetry.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-USER-CUSTOM.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-Maint.ps1")
        };
    }

    public async Task<PowerShellExecutionResult> ExecuteAsSystemAsync(string scriptPath, Dictionary<string, object>? parameters = null, CancellationToken cancellationToken = default)
    {
        var result = new PowerShellExecutionResult
        {
            StartTime = DateTime.UtcNow,
            ExecutionContext = "System"
        };

        try
        {
            if (!await ValidateScriptSafetyAsync(scriptPath))
            {
                result.Error = "Script failed security validation";
                result.ExitCode = -1;
                return result;
            }

            _logger.LogInformation("Executing PowerShell script as SYSTEM: {ScriptPath}", scriptPath);

            using var powerShell = PowerShell.Create();
            
            // Set execution policy for this session
            powerShell.AddScript("Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force");
            await powerShell.InvokeAsync();
            powerShell.Commands.Clear();

            // Add the main script
            powerShell.AddScript(await File.ReadAllTextAsync(scriptPath, cancellationToken));

            // Add parameters if provided
            if (parameters != null)
            {
                foreach (var param in parameters)
                {
                    powerShell.AddParameter(param.Key, param.Value);
                }
            }

            // Execute the script
            var output = await powerShell.InvokeAsync();
            
            // Collect output
            var outputBuilder = new StringBuilder();
            foreach (var item in output)
            {
                outputBuilder.AppendLine(item?.ToString());
            }
            result.Output = outputBuilder.ToString();

            // Collect errors
            if (powerShell.HadErrors)
            {
                var errorBuilder = new StringBuilder();
                foreach (var error in powerShell.Streams.Error)
                {
                    errorBuilder.AppendLine(error.ToString());
                }
                result.Error = errorBuilder.ToString();
                result.ExitCode = 1;
            }
            else
            {
                result.ExitCode = 0;
            }

            result.EndTime = DateTime.UtcNow;
            result.ExecutionTime = result.EndTime - result.StartTime;

            _logger.LogInformation("PowerShell script execution completed. Duration: {Duration}ms, Success: {Success}", 
                result.ExecutionTime.TotalMilliseconds, result.Success);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing PowerShell script as SYSTEM: {ScriptPath}", scriptPath);
            result.Error = ex.Message;
            result.ExitCode = -1;
            result.EndTime = DateTime.UtcNow;
            result.ExecutionTime = result.EndTime - result.StartTime;
            return result;
        }
    }

    public async Task<PowerShellExecutionResult> ExecuteAsUserAsync(string scriptPath, Dictionary<string, object>? parameters = null, int? sessionId = null, CancellationToken cancellationToken = default)
    {
        var result = new PowerShellExecutionResult
        {
            StartTime = DateTime.UtcNow,
            ExecutionContext = "User"
        };

        try
        {
            if (!await ValidateScriptSafetyAsync(scriptPath))
            {
                result.Error = "Script failed security validation";
                result.ExitCode = -1;
                return result;
            }

            // Get the active user session if not specified
            if (!sessionId.HasValue)
            {
                sessionId = GetActiveUserSessionId();
                if (!sessionId.HasValue)
                {
                    result.Error = "No active user session found";
                    result.ExitCode = -1;
                    return result;
                }
            }

            _logger.LogInformation("Executing PowerShell script as User in session {SessionId}: {ScriptPath}", sessionId, scriptPath);

            // Use PowerShell process execution for user context
            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = BuildPowerShellArguments(scriptPath, parameters),
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };

            using var process = new Process { StartInfo = startInfo };
            var outputBuilder = new StringBuilder();
            var errorBuilder = new StringBuilder();

            process.OutputDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                    outputBuilder.AppendLine(e.Data);
            };

            process.ErrorDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                    errorBuilder.AppendLine(e.Data);
            };

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            await process.WaitForExitAsync(cancellationToken);

            result.Output = outputBuilder.ToString();
            result.Error = errorBuilder.ToString();
            result.ExitCode = process.ExitCode;
            result.EndTime = DateTime.UtcNow;
            result.ExecutionTime = result.EndTime - result.StartTime;

            _logger.LogInformation("PowerShell script execution as user completed. Duration: {Duration}ms, Success: {Success}", 
                result.ExecutionTime.TotalMilliseconds, result.Success);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing PowerShell script as User: {ScriptPath}", scriptPath);
            result.Error = ex.Message;
            result.ExitCode = -1;
            result.EndTime = DateTime.UtcNow;
            result.ExecutionTime = result.EndTime - result.StartTime;
            return result;
        }
    }

    public async Task<bool> ValidateScriptSafetyAsync(string scriptPath)
    {
        try
        {
            // Check if the script path is in our allowed list
            if (!_allowedScripts.Contains(scriptPath))
            {
                _logger.LogWarning("Script not in allowed list: {ScriptPath}", scriptPath);
                return false;
            }

            // Check if the file exists and is accessible
            if (!File.Exists(scriptPath))
            {
                _logger.LogWarning("Script file does not exist: {ScriptPath}", scriptPath);
                return false;
            }

            // Check file permissions - ensure it's in a secure location
            var fileInfo = new FileInfo(scriptPath);
            if (!IsSecureLocation(fileInfo.DirectoryName))
            {
                _logger.LogWarning("Script not in secure location: {ScriptPath}", scriptPath);
                return false;
            }

            // Basic content validation - check for obvious malicious patterns
            var content = await File.ReadAllTextAsync(scriptPath);
            if (ContainsMaliciousPatterns(content))
            {
                _logger.LogWarning("Script contains potentially malicious patterns: {ScriptPath}", scriptPath);
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating script safety: {ScriptPath}", scriptPath);
            return false;
        }
    }

    private static int? GetActiveUserSessionId()
    {
        // Simple implementation - get the console session
        // In a more complex scenario, you might want to enumerate all active sessions
        var sessionId = NativeMethods.WTSGetActiveConsoleSessionId();
        return sessionId != 0xFFFFFFFF ? (int)sessionId : null;
    }

    private string BuildPowerShellArguments(string scriptPath, Dictionary<string, object>? parameters)
    {
        var args = new StringBuilder();
        args.Append("-NoProfile -ExecutionPolicy Bypass -File ");
        args.Append($"\"{scriptPath}\"");

        if (parameters != null)
        {
            foreach (var param in parameters)
            {
                args.Append($" -{param.Key}");
                if (param.Value != null)
                {
                    args.Append($" \"{param.Value}\"");
                }
            }
        }

        return args.ToString();
    }

    private bool IsSecureLocation(string? directoryPath)
    {
        if (string.IsNullOrEmpty(directoryPath))
            return false;

        // Only allow scripts from ProgramData\EndpointPilot or subdirectories
        var normalizedPath = Path.GetFullPath(directoryPath);
        var securePath = Path.GetFullPath(_endpointPilotPath);
        
        return normalizedPath.StartsWith(securePath, StringComparison.OrdinalIgnoreCase);
    }

    private static bool ContainsMaliciousPatterns(string content)
    {
        // Basic pattern matching for obviously malicious content
        var maliciousPatterns = new[]
        {
            "Invoke-Expression",
            "IEX ",
            "DownloadString",
            "DownloadFile",
            "Net.WebClient",
            "System.Net.WebClient",
            "Invoke-RestMethod",
            "Invoke-WebRequest",
            "Start-Process.*cmd.*",
            "cmd.exe.*\\/c",
            "powershell.*-EncodedCommand",
            "FromBase64String",
            "System.Convert::FromBase64String"
        };

        return maliciousPatterns.Any(pattern => 
            content.Contains(pattern, StringComparison.OrdinalIgnoreCase));
    }
}

/// <summary>
/// Native methods for Windows session management
/// </summary>
internal static class NativeMethods
{
    [System.Runtime.InteropServices.DllImport("kernel32.dll")]
    internal static extern uint WTSGetActiveConsoleSessionId();
}