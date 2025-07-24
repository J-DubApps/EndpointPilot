using EndpointPilot.SystemAgent.Models;
using System.Collections.Concurrent;

namespace EndpointPilot.SystemAgent.Services;

/// <summary>
/// Service for scheduling and managing EndpointPilot operations
/// </summary>
public class SchedulerService : ISchedulerService
{
    private readonly ILogger<SchedulerService> _logger;
    private readonly IPowerShellExecutor _powerShellExecutor;
    private readonly ISystemOperationsService _systemOperationsService;
    private readonly string _endpointPilotPath;
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
    }

    public async Task StartAsync(CancellationToken cancellationToken = default)
    {
        if (_isStarted)
        {
            _logger.LogWarning("Scheduler service is already started");
            return;
        }

        _logger.LogInformation("Starting EndpointPilot Scheduler Service");

        try
        {
            // Load configuration to determine intervals
            var config = await LoadConfigurationAsync();
            
            var userInterval = TimeSpan.FromMinutes(config?.UserRefreshMinutes ?? 30);
            var systemInterval = TimeSpan.FromMinutes(config?.SystemRefreshMinutes ?? 60);

            // Schedule user operations
            await ScheduleUserOperationsAsync(userInterval, cancellationToken);
            
            // Schedule system operations
            await ScheduleSystemOperationsAsync(systemInterval, cancellationToken);

            _isStarted = true;
            _logger.LogInformation("Scheduler service started successfully. User interval: {UserInterval}min, System interval: {SystemInterval}min", 
                userInterval.TotalMinutes, systemInterval.TotalMinutes);
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

        _logger.LogInformation("Stopping EndpointPilot Scheduler Service");

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

    public async Task ScheduleUserOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default)
    {
        const string timerKey = "UserOperations";
        
        try
        {
            // Remove existing timer if present
            if (_timers.TryRemove(timerKey, out var existingTimer))
            {
                await existingTimer.DisposeAsync();
            }

            _logger.LogInformation("Scheduling user operations with interval: {Interval}", interval);

            // Create new timer
            var timer = new Timer(async _ =>
            {
                try
                {
                    await ExecuteUserOperationsNowAsync(CancellationToken.None);
                    _nextExecutions[timerKey] = DateTime.Now.Add(interval);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in scheduled user operations execution");
                }
            }, null, TimeSpan.Zero, interval); // Start immediately, then repeat at interval

            _timers[timerKey] = timer;
            _nextExecutions[timerKey] = DateTime.Now.Add(interval);

            _logger.LogInformation("User operations scheduled successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to schedule user operations");
            throw;
        }
    }

    public async Task ScheduleSystemOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default)
    {
        const string timerKey = "SystemOperations";
        
        try
        {
            // Remove existing timer if present
            if (_timers.TryRemove(timerKey, out var existingTimer))
            {
                await existingTimer.DisposeAsync();
            }

            _logger.LogInformation("Scheduling system operations with interval: {Interval}", interval);

            // Create new timer
            var timer = new Timer(async _ =>
            {
                try
                {
                    await ExecuteSystemOperationsNowAsync(CancellationToken.None);
                    _nextExecutions[timerKey] = DateTime.Now.Add(interval);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in scheduled system operations execution");
                }
            }, null, TimeSpan.FromMinutes(2), interval); // Start after 2 minutes, then repeat at interval

            _timers[timerKey] = timer;
            _nextExecutions[timerKey] = DateTime.Now.Add(TimeSpan.FromMinutes(2));

            _logger.LogInformation("System operations scheduled successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to schedule system operations");
            throw;
        }
    }

    public async Task ExecuteUserOperationsNowAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Executing user operations immediately");

            var mainScriptPath = Path.Combine(_endpointPilotPath, "MAIN.PS1");
            
            if (!File.Exists(mainScriptPath))
            {
                _logger.LogWarning("User operations main script not found: {ScriptPath}", mainScriptPath);
                return;
            }

            // Execute the main EndpointPilot script in user context
            var result = await _powerShellExecutor.ExecuteAsUserAsync(mainScriptPath, cancellationToken: cancellationToken);
            
            if (result.Success)
            {
                _logger.LogInformation("User operations completed successfully. Duration: {Duration}ms", result.ExecutionTime.TotalMilliseconds);
            }
            else
            {
                _logger.LogWarning("User operations completed with errors. Duration: {Duration}ms, Error: {Error}", 
                    result.ExecutionTime.TotalMilliseconds, result.Error);
            }

            // Log output for debugging (truncate if too long)
            if (!string.IsNullOrEmpty(result.Output))
            {
                var output = result.Output.Length > 1000 ? result.Output.Substring(0, 1000) + "..." : result.Output;
                _logger.LogDebug("User operations output: {Output}", output);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing user operations");
        }
    }

    public async Task ExecuteSystemOperationsNowAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Executing system operations immediately");

            var result = await _systemOperationsService.ProcessSystemOperationsAsync(cancellationToken);
            
            _logger.LogInformation("System operations completed. Total: {Total}, Success: {Success}, Failed: {Failed}, Duration: {Duration}ms",
                result.TotalOperations, result.SuccessfulOperations, result.FailedOperations, result.TotalExecutionTime.TotalMilliseconds);

            // Log individual operation results for debugging
            foreach (var operationResult in result.Results.Where(r => !r.Success))
            {
                _logger.LogWarning("System operation {OperationId} failed: {Error}", operationResult.OperationId, operationResult.Error);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing system operations");
        }
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
}

/// <summary>
/// Configuration model for EndpointPilot CONFIG.json
/// </summary>
public class EndpointPilotConfig
{
    public string OrganizationName { get; set; } = string.Empty;
    public int UserRefreshMinutes { get; set; } = 30;
    public int SystemRefreshMinutes { get; set; } = 60;
    public bool SkipFileOps { get; set; } = false;
    public bool SkipRegOps { get; set; } = false;
    public bool SkipDriveOps { get; set; } = false;
    public bool SkipRoamOps { get; set; } = false;
    public bool SkipSchedTsk { get; set; } = false;
    public bool SkipTelemetry { get; set; } = false;
    public bool SkipUserCustom { get; set; } = false;
    public bool SkipMaint { get; set; } = false;
    public bool SkipSystemOps { get; set; } = false;
}