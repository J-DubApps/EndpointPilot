using EndpointPilot.SystemAgent.Models;

namespace EndpointPilot.SystemAgent.Services;

/// <summary>
/// Interface for processing system-level operations from SYSTEM-OPS.json
/// </summary>
public interface ISystemOperationsService
{
    /// <summary>
    /// Processes all operations from the SYSTEM-OPS.json file
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Results of all operations</returns>
    Task<SystemOperationsResult> ProcessSystemOperationsAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Processes a single system operation
    /// </summary>
    /// <param name="operation">The operation to process</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Result of the operation</returns>
    Task<SystemOperationResult> ProcessOperationAsync(SystemOperation operation, CancellationToken cancellationToken = default);

    /// <summary>
    /// Validates that the SYSTEM-OPS.json file is valid and safe to process
    /// </summary>
    /// <param name="filePath">Path to the SYSTEM-OPS.json file</param>
    /// <returns>True if valid and safe, false otherwise</returns>
    Task<bool> ValidateSystemOperationsFileAsync(string filePath);
}