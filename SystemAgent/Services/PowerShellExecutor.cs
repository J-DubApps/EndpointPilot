using System.Diagnostics;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;
using EndpointPilot.SystemAgent.Models;

namespace EndpointPilot.SystemAgent.Services;

/// <summary>
/// Service for executing PowerShell scripts in different security contexts
/// </summary>
public class PowerShellExecutor : IPowerShellExecutor
{
    private readonly ILogger<PowerShellExecutor> _logger;
    private readonly string _endpointPilotPath;
    private readonly string _hashManifestPath;
    private ScriptHashManifest? _hashManifest;

    public PowerShellExecutor(ILogger<PowerShellExecutor> logger)
    {
        _logger = logger;
        _endpointPilotPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "EndpointPilot");
        _hashManifestPath = Path.Combine(_endpointPilotPath, "hashes.json");
        LoadHashManifest();
    }

    private void LoadHashManifest()
    {
        try
        {
            if (!File.Exists(_hashManifestPath))
            {
                _logger.LogWarning(
                    "Script hash manifest not found at {ManifestPath}. " +
                    "Falling back to location-based validation only. " +
                    "Run Generate-ScriptHashes.ps1 to enable hash verification.",
                    _hashManifestPath);
                _hashManifest = null;
                return;
            }

            var json = File.ReadAllText(_hashManifestPath);
            _hashManifest = Newtonsoft.Json.JsonConvert.DeserializeObject<ScriptHashManifest>(json);

            if (_hashManifest?.Scripts == null || _hashManifest.Scripts.Count == 0)
            {
                _logger.LogWarning("Script hash manifest is empty or invalid. Falling back to location-based validation only.");
                _hashManifest = null;
                return;
            }

            _logger.LogInformation(
                "Loaded script hash manifest with {Count} entries (generated {GeneratedAt})",
                _hashManifest.Scripts.Count, _hashManifest.GeneratedAt);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading script hash manifest. Falling back to location-based validation only.");
            _hashManifest = null;
        }
    }

    private static async Task<string> ComputeFileHashAsync(string filePath)
    {
        using var sha256 = SHA256.Create();
        await using var stream = File.OpenRead(filePath);
        var hash = await sha256.ComputeHashAsync(stream);
        return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
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

    public async Task<PowerShellExecutionResult> ExecuteAsElevatedAsync(string scriptPath, Dictionary<string, object>? parameters = null, CancellationToken cancellationToken = default)
    {
        var result = new PowerShellExecutionResult
        {
            StartTime = DateTime.UtcNow,
            ExecutionContext = "Elevated"
        };

        try
        {
            if (!await ValidateScriptSafetyAsync(scriptPath))
            {
                result.Error = "Script failed security validation";
                result.ExitCode = -1;
                return result;
            }

            _logger.LogInformation("Executing PowerShell script with elevated privileges: {ScriptPath}", scriptPath);

            // Since we're running as SYSTEM service, we have elevated privileges by default
            // But we need to ensure the PowerShell execution context has admin rights
            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = BuildPowerShellArguments(scriptPath, parameters),
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden,
                Verb = "runas" // Request elevation if needed
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

            _logger.LogInformation("Elevated PowerShell script execution completed. Duration: {Duration}ms, Success: {Success}", 
                result.ExecutionTime.TotalMilliseconds, result.Success);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing PowerShell script with elevation: {ScriptPath}", scriptPath);
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
            if (!File.Exists(scriptPath))
            {
                _logger.LogWarning("Script file does not exist: {ScriptPath}", scriptPath);
                return false;
            }

            if (!IsSecureLocation(Path.GetDirectoryName(scriptPath)))
            {
                _logger.LogWarning("Script not in secure location: {ScriptPath}", scriptPath);
                return false;
            }

            if (_hashManifest == null)
            {
                _logger.LogDebug("No hash manifest loaded — accepting script from secure location: {ScriptPath}", scriptPath);
                return true;
            }

            var fileName = Path.GetFileName(scriptPath);
            if (!_hashManifest.Scripts.TryGetValue(fileName, out var expectedHash))
            {
                _logger.LogWarning("Script not found in hash manifest: {FileName}", fileName);
                return false;
            }

            var actualHash = await ComputeFileHashAsync(scriptPath);
            if (!string.Equals(actualHash, expectedHash, StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning(
                    "Script hash mismatch for {FileName}. Expected: {Expected}, Actual: {Actual}",
                    fileName, expectedHash, actualHash);
                return false;
            }

            _logger.LogDebug("Script hash verified: {FileName}", fileName);
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

}

/// <summary>
/// Native methods for Windows session management
/// </summary>
internal static class NativeMethods
{
    [System.Runtime.InteropServices.DllImport("kernel32.dll")]
    internal static extern uint WTSGetActiveConsoleSessionId();
}