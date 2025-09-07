using EndpointPilot.SystemAgent.Models;
using System.Collections.Concurrent;

namespace EndpointPilot.SystemAgent.Services;

/// <summary>
/// Service for scheduling and managing dual-context EndpointPilot operations
/// Executes ENDPOINT-PILOT.PS1 in both user and elevated contexts
/// </summary>
public class SchedulerService : ISchedulerService
{
    private readonly ILogger<SchedulerService> _logger;
    private readonly IPowerShellExecutor _powerShellExecutor;
    private readonly ISystemOperationsService _systemOperationsService;
    private readonly string _endpointPilotPath;
    private readonly string _endpointPilotScript;
    private readonly ConcurrentDictionary<string, Timer> _timers = new();
    private readonly ConcurrentDictionary<string, DateTime> _nextExecutions = new();
    private bool _isStarted = false;

    public SchedulerService(
        ILogger<SchedulerService> logger,
        IPowerShellExecutor powerShellExecutor,
        ISystemOperationsService systemOperationsService)
    {
        _logger = logger;
        _powerShellExecutor = powerShellExecutor;
        _systemOperationsService = systemOperationsService;
        _endpointPilotPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "EndpointPilot");
        _endpointPilotScript = Path.Combine(_endpointPilotPath, "ENDPOINT-PILOT.PS1");
    }

    public async Task StartAsync(CancellationToken cancellationToken = default)
    {
        if (_isStarted)
        {
            _logger.LogWarning("Scheduler service is already started");
            return;
        }

        _logger.LogInformation("Starting EndpointPilot Dual-Context Scheduler Service");

        try
        {
            // Load configuration to determine intervals
            var config = await LoadConfigurationAsync();
            
            var refreshInterval = TimeSpan.FromMinutes(config?.Refresh_Interval ?? 30);

            // Schedule dual-context operations (user + admin)
            await ScheduleDualContextOperationsAsync(refreshInterval, cancellationToken);

            _isStarted = true;
            _logger.LogInformation("Dual-context scheduler started successfully. Interval: {RefreshInterval}min", refreshInterval.TotalMinutes);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to start scheduler service");
            throw;
        }
    }

    public async Task StopAsync(CancellationToken cancellationToken = default)
    {
        if (!_isStarted)
        {
            return;
        }

        _logger.LogInformation("Stopping EndpointPilot Dual-Context Scheduler Service");

        // Dispose all timers
        foreach (var timer in _timers.Values)
        {
            await timer.DisposeAsync();
        }

        _timers.Clear();
        _nextExecutions.Clear();
        _isStarted = false;

        _logger.LogInformation("Scheduler service stopped successfully");
    }

    public async Task ScheduleDualContextOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default)
    {
        const string timerKey = "DualContextOperations";
        
        try
        {
            // Remove existing timer if present
            if (_timers.TryRemove(timerKey, out var existingTimer))
            {
                await existingTimer.DisposeAsync();
            }

            _logger.LogInformation("Scheduling dual-context operations with interval: {Interval}", interval);

            // Create new timer
            var timer = new Timer(async _ =>
            {
                try
                {
                    await ExecuteDualContextOperationsNowAsync(CancellationToken.None);
                    _nextExecutions[timerKey] = DateTime.Now.Add(interval);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in scheduled dual-context operations execution");
                }
            }, null, TimeSpan.Zero, interval); // Start immediately, then repeat at interval

            _timers[timerKey] = timer;
            _nextExecutions[timerKey] = DateTime.Now.Add(interval);

            _logger.LogInformation("Dual-context operations scheduled successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to schedule dual-context operations");
            throw;
        }
    }

    /// <summary>
    /// Execute ENDPOINT-PILOT.PS1 in both user and admin contexts
    /// </summary>
    public async Task ExecuteDualContextOperationsNowAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Starting dual-context EndpointPilot execution");

            if (!File.Exists(_endpointPilotScript))
            {
                _logger.LogWarning("ENDPOINT-PILOT.PS1 not found at: {ScriptPath}", _endpointPilotScript);
                return;
            }

            var totalStartTime = DateTime.UtcNow;

            // Phase 1: Execute as User (non-elevated) - handles requiresAdmin: false operations
            _logger.LogInformation("Phase 1: Executing ENDPOINT-PILOT.PS1 in user context");
            var userResult = await _powerShellExecutor.ExecuteAsUserAsync(_endpointPilotScript, cancellationToken: cancellationToken);
            
            if (userResult.Success)
            {
                _logger.LogInformation("User context execution completed successfully. Duration: {Duration}ms", userResult.ExecutionTime.TotalMilliseconds);
            }
            else
            {
                _logger.LogWarning("User context execution completed with errors. Duration: {Duration}ms, Error: {Error}", 
                    userResult.ExecutionTime.TotalMilliseconds, userResult.Error);
            }

            // Brief delay between executions to avoid conflicts
            await Task.Delay(TimeSpan.FromSeconds(30), cancellationToken);

            // Phase 2: Execute as Elevated Admin - handles requiresAdmin: true operations
            _logger.LogInformation("Phase 2: Executing ENDPOINT-PILOT.PS1 in elevated admin context");
            var adminResult = await _powerShellExecutor.ExecuteAsElevatedAsync(_endpointPilotScript, cancellationToken: cancellationToken);
            
            if (adminResult.Success)
            {
                _logger.LogInformation("Elevated admin execution completed successfully. Duration: {Duration}ms", adminResult.ExecutionTime.TotalMilliseconds);
            }
            else
            {
                _logger.LogWarning("Elevated admin execution completed with errors. Duration: {Duration}ms, Error: {Error}", 
                    adminResult.ExecutionTime.TotalMilliseconds, adminResult.Error);
            }

            var totalDuration = DateTime.UtcNow - totalStartTime;
            _logger.LogInformation("Dual-context execution complete. Total duration: {TotalDuration}ms, User success: {UserSuccess}, Admin success: {AdminSuccess}",
                totalDuration.TotalMilliseconds, userResult.Success, adminResult.Success);

            // Log condensed output for debugging (truncate if too long)
            LogExecutionOutput("User", userResult.Output);
            LogExecutionOutput("Admin", adminResult.Output);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing dual-context operations");
        }
    }

    /// <summary>
    /// Legacy method maintained for backward compatibility
    /// </summary>
    public async Task ScheduleUserOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Legacy ScheduleUserOperationsAsync called - redirecting to dual-context scheduling");
        await ScheduleDualContextOperationsAsync(interval, cancellationToken);
    }

    /// <summary>
    /// Legacy method maintained for backward compatibility
    /// </summary>
    public async Task ScheduleSystemOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Legacy ScheduleSystemOperationsAsync called - dual-context already handles this");
        // No-op - dual context execution handles both user and system operations
        await Task.CompletedTask;
    }

    /// <summary>
    /// Legacy method maintained for backward compatibility
    /// </summary>
    public async Task ExecuteUserOperationsNowAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Legacy ExecuteUserOperationsNowAsync called - executing dual-context");
        await ExecuteDualContextOperationsNowAsync(cancellationToken);
    }

    /// <summary>
    /// Legacy method maintained for backward compatibility
    /// </summary>
    public async Task ExecuteSystemOperationsNowAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Legacy ExecuteSystemOperationsNowAsync called - dual-context already handles this");
        // The dual context execution already handles elevated operations
        await Task.CompletedTask;
    }

    public Dictionary<string, DateTime> GetNextExecutionTimes()
    {
        return new Dictionary<string, DateTime>(_nextExecutions);
    }

    private async Task<EndpointPilotConfig?> LoadConfigurationAsync()
    {
        try
        {
            var configPath = Path.Combine(_endpointPilotPath, "CONFIG.json");
            
            if (!File.Exists(configPath))
            {
                _logger.LogWarning("CONFIG.json not found at: {ConfigPath}. Using default intervals.", configPath);
                return null;
            }

            var configJson = await File.ReadAllTextAsync(configPath);
            var config = Newtonsoft.Json.JsonConvert.DeserializeObject<EndpointPilotConfig>(configJson);

            _logger.LogDebug("Configuration loaded successfully");
            return config;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading configuration, using defaults");
            return null;
        }
    }

    private void LogExecutionOutput(string context, string? output)
    {
        if (!string.IsNullOrEmpty(output))
        {
            var truncatedOutput = output.Length > 500 ? output.Substring(0, 500) + "..." : output;
            _logger.LogDebug("{Context} context output: {Output}", context, truncatedOutput);
        }
    }
}

/// <summary>
/// Configuration model for EndpointPilot CONFIG.json
/// </summary>
public class EndpointPilotConfig
{
    public string OrgName { get; set; } = string.Empty;
    public int Refresh_Interval { get; set; } = 30;
    public string NetworkScriptRootPath { get; set; } = string.Empty;
    public bool NetworkScriptRootEnabled { get; set; } = false;
    public bool HttpsScriptRootEnabled { get; set; } = false;
    public string HttpsScriptRootPath { get; set; } = string.Empty;
    public bool CopyLogFileToNetwork { get; set; } = false;
    public bool RoamFiles { get; set; } = false;
    public string NetworkLogFile { get; set; } = string.Empty;
    public string NetworkRoamFolder { get; set; } = string.Empty;
    public bool SkipFileOps { get; set; } = false;
    public bool SkipDriveOps { get; set; } = false;
    public bool SkipRegOps { get; set; } = false;
    public bool SkipRoamOps { get; set; } = false;
    public bool SkipSchedTsk { get; set; } = false;
    public bool SkipTelemetry { get; set; } = false;
    public bool SkipUserCustom { get; set; } = false;
    public bool SkipMaint { get; set; } = false;
}