namespace EndpointPilot.SystemAgent;

public class AgentWorker : BackgroundService
{
    private readonly ILogger<AgentWorker> _logger;

    public AgentWorker(ILogger<AgentWorker> logger)
    {
        _logger = logger;
    }

    public override Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("EndpointPilot System Agent Service starting.");
        return base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("EndpointPilot System Agent is running.");

        while (!stoppingToken.IsCancellationRequested)
        {
            _logger.LogDebug("Worker running at: {time}", DateTimeOffset.Now);
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }

    public override Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("EndpointPilot System Agent Service stopping.");
        return base.StopAsync(cancellationToken);
    }
}