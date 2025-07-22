using EndpointPilot.SystemAgent.Services;

namespace EndpointPilot.SystemAgent;

public class AgentWorker : BackgroundService
{
    private readonly ILogger<AgentWorker> _logger;
    private readonly ISchedulerService _schedulerService;
    private readonly ISystemOperationsService _systemOperationsService;
    private readonly IPowerShellExecutor _powerShellExecutor;

    public AgentWorker(
        ILogger<AgentWorker> logger,
        ISchedulerService schedulerService,
        ISystemOperationsService systemOperationsService,
        IPowerShellExecutor powerShellExecutor)
    {
        _logger = logger;
        _schedulerService = schedulerService;
        _systemOperationsService = systemOperationsService;
        _powerShellExecutor = powerShellExecutor;
    }

    public override async Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("EndpointPilot System Agent Service starting.");
        
        try
        {
            // Start the scheduler service
            await _schedulerService.StartAsync(cancellationToken);
            _logger.LogInformation("Scheduler service started successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to start scheduler service.");
            throw;
        }

        await base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("EndpointPilot System Agent is running.");

        // The main execution loop is now handled by the scheduler service
        // This method just keeps the service alive and handles shutdown requests
        try
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                // Health check and status logging
                _logger.LogDebug("System Agent health check at: {time}", DateTimeOffset.Now);
                
                // Log next execution times for visibility
                var nextExecutions = _schedulerService.GetNextExecutionTimes();
                foreach (var execution in nextExecutions)
                {
                    _logger.LogDebug("Next {OperationType} execution scheduled for: {NextExecution}", 
                        execution.Key, execution.Value);
                }

                // Wait for 5 minutes before next health check
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
        }
        catch (OperationCanceledException)
        {
            // Expected when service is being stopped
            _logger.LogInformation("System Agent execution cancelled - service is stopping.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error in System Agent main loop.");
            throw;
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("EndpointPilot System Agent Service stopping.");
        
        try
        {
            await _schedulerService.StopAsync(cancellationToken);
            _logger.LogInformation("Scheduler service stopped successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error stopping scheduler service.");
        }

        await base.StopAsync(cancellationToken);
    }
}