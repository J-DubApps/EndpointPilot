namespace EndpointPilot.SystemAgent.Services;

/// <summary>
/// Interface for scheduling and managing EndpointPilot operations
/// </summary>
public interface ISchedulerService
{
    /// <summary>
    /// Starts the scheduler service
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    Task StartAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Stops the scheduler service
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    Task StopAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Schedules user-mode operations to run at specified intervals
    /// </summary>
    /// <param name="interval">Interval between runs</param>
    /// <param name="cancellationToken">Cancellation token</param>
    Task ScheduleUserOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default);

    /// <summary>
    /// Schedules system-mode operations to run at specified intervals
    /// </summary>
    /// <param name="interval">Interval between runs</param>
    /// <param name="cancellationToken">Cancellation token</param>
    Task ScheduleSystemOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default);

    /// <summary>
    /// Forces an immediate execution of user operations
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    Task ExecuteUserOperationsNowAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Forces an immediate execution of system operations
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    Task ExecuteSystemOperationsNowAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets the next scheduled execution times
    /// </summary>
    /// <returns>Dictionary with operation type and next execution time</returns>
    Dictionary<string, DateTime> GetNextExecutionTimes();
}