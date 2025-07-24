using System.Diagnostics;
using System.Security.Cryptography;
using Microsoft.Win32;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using EndpointPilot.SystemAgent.Models;

namespace EndpointPilot.SystemAgent.Services;

/// <summary>
/// Service for processing system-level operations from SYSTEM-OPS.json
/// </summary>
public class SystemOperationsService : ISystemOperationsService
{
    private readonly ILogger<SystemOperationsService> _logger;
    private readonly string _endpointPilotPath;
    private readonly string _systemOpsFilePath;

    public SystemOperationsService(ILogger<SystemOperationsService> logger)
    {
        _logger = logger;
        _endpointPilotPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "EndpointPilot");
        _systemOpsFilePath = Path.Combine(_endpointPilotPath, "SYSTEM-OPS.json");
    }

    public async Task<SystemOperationsResult> ProcessSystemOperationsAsync(CancellationToken cancellationToken = default)
    {
        var result = new SystemOperationsResult
        {
            StartTime = DateTime.UtcNow
        };

        try
        {
            _logger.LogInformation("Starting system operations processing from: {FilePath}", _systemOpsFilePath);

            if (!await ValidateSystemOperationsFileAsync(_systemOpsFilePath))
            {
                _logger.LogWarning("System operations file validation failed: {FilePath}", _systemOpsFilePath);
                result.EndTime = DateTime.UtcNow;
                result.TotalExecutionTime = result.EndTime - result.StartTime;
                return result;
            }

            var configJson = await File.ReadAllTextAsync(_systemOpsFilePath, cancellationToken);
            var config = JsonConvert.DeserializeObject<SystemOperationsConfig>(configJson);

            if (config?.Operations == null)
            {
                _logger.LogWarning("No operations found in system operations file");
                result.EndTime = DateTime.UtcNow;
                result.TotalExecutionTime = result.EndTime - result.StartTime;
                return result;
            }

            result.TotalOperations = config.Operations.Count;
            _logger.LogInformation("Processing {OperationCount} system operations", result.TotalOperations);

            foreach (var operation in config.Operations)
            {
                try
                {
                    var operationResult = await ProcessOperationAsync(operation, cancellationToken);
                    result.Results.Add(operationResult);

                    if (operationResult.Success)
                        result.SuccessfulOperations++;
                    else
                        result.FailedOperations++;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Unexpected error processing operation {OperationId}", operation.Id);
                    result.Results.Add(new SystemOperationResult
                    {
                        OperationId = operation.Id,
                        OperationType = operation.OperationType,
                        Success = false,
                        Error = ex.Message,
                        StartTime = DateTime.UtcNow,
                        EndTime = DateTime.UtcNow
                    });
                    result.FailedOperations++;
                }
            }

            result.EndTime = DateTime.UtcNow;
            result.TotalExecutionTime = result.EndTime - result.StartTime;

            _logger.LogInformation("System operations completed. Total: {Total}, Success: {Success}, Failed: {Failed}, Duration: {Duration}ms",
                result.TotalOperations, result.SuccessfulOperations, result.FailedOperations, result.TotalExecutionTime.TotalMilliseconds);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing system operations");
            result.EndTime = DateTime.UtcNow;
            result.TotalExecutionTime = result.EndTime - result.StartTime;
            return result;
        }
    }

    public async Task<SystemOperationResult> ProcessOperationAsync(SystemOperation operation, CancellationToken cancellationToken = default)
    {
        var result = new SystemOperationResult
        {
            OperationId = operation.Id,
            OperationType = operation.OperationType,
            StartTime = DateTime.UtcNow
        };

        try
        {
            _logger.LogInformation("Processing system operation {OperationId} of type {OperationType}", operation.Id, operation.OperationType);

            switch (operation.OperationType.ToLowerInvariant())
            {
                case "installmsi":
                    await ProcessInstallMsiAsync(operation, result, cancellationToken);
                    break;
                case "setregistryvalue":
                    await ProcessSetRegistryValueAsync(operation, result, cancellationToken);
                    break;
                case "manageservice":
                    await ProcessManageServiceAsync(operation, result, cancellationToken);
                    break;
                case "copyfile":
                    await ProcessCopyFileAsync(operation, result, cancellationToken);
                    break;
                default:
                    result.Success = false;
                    result.Error = $"Unknown operation type: {operation.OperationType}";
                    break;
            }

            result.EndTime = DateTime.UtcNow;
            result.ExecutionTime = result.EndTime - result.StartTime;

            _logger.LogInformation("Operation {OperationId} completed. Success: {Success}, Duration: {Duration}ms",
                operation.Id, result.Success, result.ExecutionTime.TotalMilliseconds);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing operation {OperationId}", operation.Id);
            result.Success = false;
            result.Error = ex.Message;
            result.EndTime = DateTime.UtcNow;
            result.ExecutionTime = result.EndTime - result.StartTime;
            return result;
        }
    }

    public async Task<bool> ValidateSystemOperationsFileAsync(string filePath)
    {
        try
        {
            if (!File.Exists(filePath))
            {
                _logger.LogWarning("System operations file does not exist: {FilePath}", filePath);
                return false;
            }

            // Check file is in secure location
            var fileInfo = new FileInfo(filePath);
            var securePath = Path.GetFullPath(_endpointPilotPath);
            var fileDirPath = Path.GetFullPath(fileInfo.DirectoryName ?? "");
            
            if (!fileDirPath.StartsWith(securePath, StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning("System operations file not in secure location: {FilePath}", filePath);
                return false;
            }

            // Validate JSON structure
            var content = await File.ReadAllTextAsync(filePath);
            var config = JsonConvert.DeserializeObject<SystemOperationsConfig>(content);

            if (config?.Operations == null)
            {
                _logger.LogWarning("Invalid system operations file structure");
                return false;
            }

            // Validate each operation has required fields
            foreach (var operation in config.Operations)
            {
                if (string.IsNullOrEmpty(operation.Id) || string.IsNullOrEmpty(operation.OperationType))
                {
                    _logger.LogWarning("Operation missing required fields: {OperationId}", operation.Id);
                    return false;
                }
            }

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating system operations file: {FilePath}", filePath);
            return false;
        }
    }

    private async Task ProcessInstallMsiAsync(SystemOperation operation, SystemOperationResult result, CancellationToken cancellationToken)
    {
        try
        {
            var sourcePath = operation.Parameters.GetValueOrDefault("sourcePath")?.ToString();
            var arguments = operation.Parameters.GetValueOrDefault("arguments")?.ToString() ?? "/quiet /norestart";
            var expectedVersion = operation.Parameters.GetValueOrDefault("expectedVersion")?.ToString();
            var checksum = operation.Parameters.GetValueOrDefault("checksum")?.ToString();

            if (string.IsNullOrEmpty(sourcePath))
            {
                result.Error = "sourcePath parameter is required for installMsi operation";
                return;
            }

            _logger.LogInformation("Installing MSI from: {SourcePath}", sourcePath);

            // Download or access the MSI file
            var localMsiPath = await GetLocalFileAsync(sourcePath, checksum, cancellationToken);
            if (localMsiPath == null)
            {
                result.Error = "Failed to access or download MSI file";
                return;
            }

            // Install the MSI using msiexec
            var startInfo = new ProcessStartInfo
            {
                FileName = "msiexec.exe",
                Arguments = $"/i \"{localMsiPath}\" {arguments}",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using var process = Process.Start(startInfo);
            if (process == null)
            {
                result.Error = "Failed to start msiexec process";
                return;
            }

            var output = await process.StandardOutput.ReadToEndAsync();
            var error = await process.StandardError.ReadToEndAsync();

            await process.WaitForExitAsync(cancellationToken);

            result.Output = output;
            if (process.ExitCode == 0)
            {
                result.Success = true;
                _logger.LogInformation("MSI installation completed successfully");
            }
            else
            {
                result.Error = $"MSI installation failed with exit code {process.ExitCode}: {error}";
                _logger.LogError("MSI installation failed: {Error}", result.Error);
            }
        }
        catch (Exception ex)
        {
            result.Error = $"Exception during MSI installation: {ex.Message}";
            _logger.LogError(ex, "Exception during MSI installation");
        }
    }

    private Task ProcessSetRegistryValueAsync(SystemOperation operation, SystemOperationResult result, CancellationToken cancellationToken)
    {
        try
        {
            var path = operation.Parameters.GetValueOrDefault("path")?.ToString();
            var name = operation.Parameters.GetValueOrDefault("name")?.ToString();
            var value = operation.Parameters.GetValueOrDefault("value")?.ToString();
            var regType = operation.Parameters.GetValueOrDefault("regType")?.ToString();

            if (string.IsNullOrEmpty(path) || string.IsNullOrEmpty(name) || value == null || string.IsNullOrEmpty(regType))
            {
                result.Error = "path, name, value, and regType parameters are required for setRegistryValue operation";
                return Task.CompletedTask;
            }

            // Ensure path starts with HKLM (security constraint)
            if (!path.StartsWith("HKLM\\", StringComparison.OrdinalIgnoreCase))
            {
                result.Error = "Registry path must start with HKLM\\ for system operations";
                return Task.CompletedTask;
            }

            var keyPath = path.Substring(5); // Remove "HKLM\" prefix
            
            _logger.LogInformation("Setting registry value: {Path}\\{Name} = {Value} ({Type})", path, name, value, regType);

            using var key = Registry.LocalMachine.CreateSubKey(keyPath, true);
            if (key == null)
            {
                result.Error = $"Failed to create or open registry key: {path}";
                return Task.CompletedTask;
            }

            object regValue = regType.ToLowerInvariant() switch
            {
                "dword" => int.Parse(value),
                "qword" => long.Parse(value),
                "string" => value,
                "expandstring" => value,
                _ => value
            };

            var registryValueKind = regType.ToLowerInvariant() switch
            {
                "dword" => RegistryValueKind.DWord,
                "qword" => RegistryValueKind.QWord,
                "string" => RegistryValueKind.String,
                "expandstring" => RegistryValueKind.ExpandString,
                _ => RegistryValueKind.String
            };

            key.SetValue(name, regValue, registryValueKind);
            result.Success = true;
            result.Output = $"Registry value set successfully: {path}\\{name}";
            _logger.LogInformation("Registry value set successfully");
        }
        catch (Exception ex)
        {
            result.Error = $"Exception setting registry value: {ex.Message}";
            _logger.LogError(ex, "Exception setting registry value");
        }
        
        return Task.CompletedTask;
    }

    private async Task ProcessManageServiceAsync(SystemOperation operation, SystemOperationResult result, CancellationToken cancellationToken)
    {
        try
        {
            var serviceName = operation.Parameters.GetValueOrDefault("serviceName")?.ToString();
            var state = operation.Parameters.GetValueOrDefault("state")?.ToString();
            var startupType = operation.Parameters.GetValueOrDefault("startupType")?.ToString();

            if (string.IsNullOrEmpty(serviceName))
            {
                result.Error = "serviceName parameter is required for manageService operation";
                return;
            }

            _logger.LogInformation("Managing service: {ServiceName}, State: {State}, StartupType: {StartupType}", 
                serviceName, state, startupType);

            // Use sc.exe for service management (more reliable than ServiceController for some operations)
            var commands = new List<string>();
            
            if (!string.IsNullOrEmpty(startupType))
            {
                var scStartupType = startupType.ToLowerInvariant() switch
                {
                    "automatic" => "auto",
                    "manual" => "demand",
                    "disabled" => "disabled",
                    _ => startupType.ToLowerInvariant()
                };
                commands.Add($"config {serviceName} start= {scStartupType}");
            }

            if (!string.IsNullOrEmpty(state))
            {
                if (state.Equals("running", StringComparison.OrdinalIgnoreCase))
                    commands.Add($"start {serviceName}");
                else if (state.Equals("stopped", StringComparison.OrdinalIgnoreCase))
                    commands.Add($"stop {serviceName}");
            }

            var outputs = new List<string>();
            var errors = new List<string>();

            foreach (var command in commands)
            {
                var startInfo = new ProcessStartInfo
                {
                    FileName = "sc.exe",
                    Arguments = command,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                using var process = Process.Start(startInfo);
                if (process == null)
                {
                    errors.Add($"Failed to start sc.exe for command: {command}");
                    continue;
                }

                var output = await process.StandardOutput.ReadToEndAsync();
                var error = await process.StandardError.ReadToEndAsync();

                await process.WaitForExitAsync(cancellationToken);

                outputs.Add($"Command: sc {command}\nOutput: {output}");
                
                if (process.ExitCode != 0)
                {
                    errors.Add($"Command failed: sc {command}\nError: {error}");
                }
            }

            result.Output = string.Join("\n\n", outputs);
            
            if (errors.Count > 0)
            {
                result.Error = string.Join("\n", errors);
                _logger.LogError("Service management completed with errors: {Errors}", result.Error);
            }
            else
            {
                result.Success = true;
                _logger.LogInformation("Service management completed successfully");
            }
        }
        catch (Exception ex)
        {
            result.Error = $"Exception managing service: {ex.Message}";
            _logger.LogError(ex, "Exception managing service");
        }
    }

    private async Task ProcessCopyFileAsync(SystemOperation operation, SystemOperationResult result, CancellationToken cancellationToken)
    {
        try
        {
            var sourcePath = operation.Parameters.GetValueOrDefault("sourcePath")?.ToString();
            var destinationPath = operation.Parameters.GetValueOrDefault("destinationPath")?.ToString();
            var overwrite = operation.Parameters.GetValueOrDefault("overwrite")?.ToString()?.Equals("true", StringComparison.OrdinalIgnoreCase) ?? false;

            if (string.IsNullOrEmpty(sourcePath) || string.IsNullOrEmpty(destinationPath))
            {
                result.Error = "sourcePath and destinationPath parameters are required for copyFile operation";
                return;
            }

            _logger.LogInformation("Copying file from {SourcePath} to {DestinationPath}", sourcePath, destinationPath);

            // Get the source file (local or download)
            var localSourcePath = await GetLocalFileAsync(sourcePath, null, cancellationToken);
            if (localSourcePath == null)
            {
                result.Error = "Failed to access or download source file";
                return;
            }

            // Ensure destination directory exists
            var destDir = Path.GetDirectoryName(destinationPath);
            if (!string.IsNullOrEmpty(destDir))
            {
                Directory.CreateDirectory(destDir);
            }

            // Check if destination exists and handle overwrite
            if (File.Exists(destinationPath) && !overwrite)
            {
                result.Error = "Destination file exists and overwrite is false";
                return;
            }

            File.Copy(localSourcePath, destinationPath, overwrite);
            result.Success = true;
            result.Output = $"File copied successfully to: {destinationPath}";
            _logger.LogInformation("File copy completed successfully");
        }
        catch (Exception ex)
        {
            result.Error = $"Exception copying file: {ex.Message}";
            _logger.LogError(ex, "Exception copying file");
        }
    }

    private async Task<string?> GetLocalFileAsync(string sourcePath, string? expectedChecksum, CancellationToken cancellationToken)
    {
        try
        {
            // If it's already a local file, validate and return
            if (File.Exists(sourcePath))
            {
                if (!string.IsNullOrEmpty(expectedChecksum) && !await ValidateFileChecksumAsync(sourcePath, expectedChecksum))
                {
                    _logger.LogWarning("Local file checksum validation failed: {SourcePath}", sourcePath);
                    return null;
                }
                return sourcePath;
            }

            // If it's a URI, download it
            if (Uri.TryCreate(sourcePath, UriKind.Absolute, out var uri) && (uri.Scheme == "http" || uri.Scheme == "https"))
            {
                var tempDir = Path.Combine(Path.GetTempPath(), "EndpointPilot");
                Directory.CreateDirectory(tempDir);
                
                var fileName = Path.GetFileName(uri.LocalPath);
                if (string.IsNullOrEmpty(fileName))
                    fileName = "downloaded_file";
                
                var localPath = Path.Combine(tempDir, fileName);
                
                using var httpClient = new HttpClient();
                httpClient.Timeout = TimeSpan.FromMinutes(10);
                
                using var response = await httpClient.GetAsync(uri, cancellationToken);
                response.EnsureSuccessStatusCode();
                
                await using var fileStream = File.Create(localPath);
                await response.Content.CopyToAsync(fileStream, cancellationToken);
                
                if (!string.IsNullOrEmpty(expectedChecksum) && !await ValidateFileChecksumAsync(localPath, expectedChecksum))
                {
                    File.Delete(localPath);
                    _logger.LogWarning("Downloaded file checksum validation failed: {SourcePath}", sourcePath);
                    return null;
                }
                
                return localPath;
            }

            _logger.LogWarning("Invalid source path (not a local file or valid URI): {SourcePath}", sourcePath);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting local file from source: {SourcePath}", sourcePath);
            return null;
        }
    }

    private async Task<bool> ValidateFileChecksumAsync(string filePath, string expectedChecksum)
    {
        try
        {
            using var sha256 = SHA256.Create();
            await using var stream = File.OpenRead(filePath);
            var hash = await sha256.ComputeHashAsync(stream);
            var actualChecksum = BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
            var expectedLower = expectedChecksum.ToLowerInvariant();
            
            return actualChecksum == expectedLower;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating file checksum: {FilePath}", filePath);
            return false;
        }
    }
}