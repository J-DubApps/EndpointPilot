# EndpointPilot System Agent Documentation

## Overview

The EndpointPilot System Agent is a Windows Service that extends EndpointPilot's capabilities by enabling system-level operations requiring Administrator/SYSTEM privileges. It operates alongside the existing user-mode functionality, providing a dual-mode execution environment for PowerShell scripts.

## Architecture

The System Agent follows a service-oriented architecture with dependency injection, implementing best practices for Windows Services in .NET 8.

### Core Components

```
EndpointPilot System Agent (Windows Service)
├── AgentWorker - Main service coordinator
├── PowerShellExecutor - Dual-mode script execution
├── SystemOperationsService - SYSTEM-OPS.json processor
├── SchedulerService - Timer-based operation scheduling
└── Models - Data models and configurations
```

## Key Files and Their Functions

### Service Entry Point

#### `Program.cs`
- **Purpose**: Service configuration and dependency injection setup
- **Key Functions**:
  - Configures the Windows Service host
  - Sets up dependency injection container
  - Registers all services and their interfaces
  - Configures logging (file and Windows Event Log)
- **Dependencies**: All service interfaces and implementations

### Core Service Implementation

#### `AgentWorker.cs`
- **Purpose**: Main service coordinator that orchestrates all operations
- **Key Functions**:
  - Initializes and starts the scheduler service
  - Monitors service health and logs status
  - Handles service lifecycle (start/stop)
  - Provides health check information
- **Dependencies**: ISchedulerService, ILogger

### Service Layer

#### `Services/IPowerShellExecutor.cs`
- **Purpose**: Interface defining PowerShell execution contract
- **Methods**:
  - `ExecuteScriptAsync(string scriptPath, ExecutionContext context)`
  - `ExecuteScriptAsUserAsync(string scriptPath, string userName)`

#### `Services/PowerShellExecutor.cs`
- **Purpose**: Secure PowerShell script execution in both System and User contexts
- **Key Functions**:
  - Validates scripts against allowlist before execution
  - Executes scripts with appropriate security context
  - Implements basic malicious content detection
  - Provides detailed execution logging
- **Security Features**:
  - Script path validation (must be in EndpointPilot directories)
  - Content scanning for suspicious PowerShell patterns
  - Execution context isolation

#### `Services/ISystemOperationsService.cs`
- **Purpose**: Interface for system operations processing
- **Methods**:
  - `ProcessSystemOperationsAsync()`
  - Returns `SystemOperationsResult` with operation outcomes

#### `Services/SystemOperationsService.cs`
- **Purpose**: Processes SYSTEM-OPS.json directives for system-level tasks
- **Supported Operations**:
  1. **installMsi**: Download and install MSI packages
  2. **setRegistryValue**: Modify HKLM registry entries
  3. **manageService**: Start/stop/configure Windows services
  4. **copyFile**: Download or copy files to system locations
- **Key Functions**:
  - Loads and validates SYSTEM-OPS.json
  - Executes operations with error handling
  - Provides detailed operation logging
  - Implements security constraints (e.g., HKLM-only for registry)

#### `Services/ISchedulerService.cs`
- **Purpose**: Interface for scheduling operations
- **Methods**:
  - `StartAsync()`: Begin scheduled operations
  - `StopAsync()`: Stop all scheduled operations
  - `GetNextExecutionTimes()`: Query upcoming execution times

#### `Services/SchedulerService.cs`
- **Purpose**: Timer-based scheduling for both user and system operations
- **Key Functions**:
  - Reads scheduling intervals from CONFIG.json
  - Maintains separate timers for user and system operations
  - Executes MAIN.PS1 for user operations
  - Triggers system operations processing
  - Provides next execution time information
- **Configuration**:
  - UserRefreshMinutes (default: 30)
  - SystemRefreshMinutes (default: 60)

### Data Models

#### `Models/SystemOperation.cs`
- **Purpose**: Data model for individual system operations
- **Properties**:
  - `Id`: Unique operation identifier
  - `OperationType`: Type of operation (installMsi, setRegistryValue, etc.)
  - `Comment`: Human-readable description
  - `Parameters`: Operation-specific parameters

#### `Models/SystemOperationsResult.cs`
- **Purpose**: Result model for operation execution
- **Properties**:
  - `Success`: Overall success status
  - `ProcessedCount`: Number of operations processed
  - `FailedOperations`: List of failed operation IDs
  - `Message`: Summary message

### Project Configuration

#### `EndpointPilot.SystemAgent.csproj`
- **Purpose**: .NET project configuration file
- **Key Elements**:
  - Target Framework: .NET 8.0
  - Platform: x64 (with ARM64 support planned)
  - Package References:
    - Microsoft.Extensions.Hosting.WindowsServices
    - Microsoft.PowerShell.SDK
    - System.Management.Automation
    - Newtonsoft.Json (standardized JSON library)
  - Service Configuration: Configured for Windows Service deployment

## Security Model

### Script Security
1. **Allowlist Enforcement**: Only scripts from `%PROGRAMDATA%\EndpointPilot` can execute
2. **Path Validation**: All paths validated against directory traversal attacks
3. **Content Scanning**: Basic detection of potentially malicious PowerShell patterns
4. **Context Isolation**: Clear separation between System and User execution contexts

### File System Security
1. **Installation Directory**: `%PROGRAMDATA%\EndpointPilot\SystemAgent`
2. **ACL Configuration**: SYSTEM and Administrators only
3. **Temporary Files**: Secure handling of downloads and temporary files

### Registry Security
1. **Scope Limitation**: System operations restricted to HKEY_LOCAL_MACHINE
2. **Path Validation**: Registry paths validated before access
3. **Audit Logging**: All registry modifications logged

## Logging and Monitoring

### Log Locations
- **Primary Log**: `%PROGRAMDATA%\EndpointPilot\Agent.log`
- **Windows Event Log**: Application log, source "EndpointPilot System Agent"

### Log Rotation
- Daily rotation with 7-day retention
- Automatic cleanup of old log files

### Log Content
- Service lifecycle events (start/stop)
- Operation execution details with timing
- Error conditions with stack traces
- Security validation results
- Health check status

## Configuration

### CONFIG.json Integration
The System Agent reads from the existing EndpointPilot CONFIG.json:
```json
{
  "UserRefreshMinutes": 30,
  "SystemRefreshMinutes": 60,
  "SkipSystemOps": false
}
```

### SYSTEM-OPS.json Format
System operations are defined in SYSTEM-OPS.json:
```json
{
  "operations": [
    {
      "id": "unique-operation-id",
      "operationType": "installMsi|setRegistryValue|manageService|copyFile",
      "comment": "Description of the operation",
      "parameters": {
        // Operation-specific parameters
      }
    }
  ]
}
```

## Development Guidelines

### Building the Service
```powershell
# Build for x64 (default)
dotnet build -c Release

# Build output location
SystemAgent\bin\Release\net8.0\win-x64\
```

### Testing Locally
1. Build the project in Debug configuration
2. Run as console application for debugging
3. Use Visual Studio debugger for breakpoint debugging
4. Check logs in `%PROGRAMDATA%\EndpointPilot\`

### Adding New Operation Types
1. Define operation parameters in `SystemOperation.cs`
2. Implement operation logic in `SystemOperationsService.cs`
3. Add operation type to the switch statement
4. Update SYSTEM-OPS.schema.json with new operation schema
5. Add appropriate security validations

## Troubleshooting

### Common Issues

#### Service Won't Start
- Check .NET 8 Runtime is installed
- Verify `%PROGRAMDATA%\EndpointPilot` directory exists
- Check Windows Event Log for detailed errors
- Ensure running as Administrator

#### Operations Not Executing
- Verify SYSTEM-OPS.json exists and is valid JSON
- Check SkipSystemOps flag in CONFIG.json
- Review Agent.log for operation errors
- Ensure operations have required parameters

#### Permission Errors
- Verify service is running as SYSTEM
- Check ACLs on target directories
- Ensure registry paths are under HKLM
- Review security validation in logs

### Debug Mode
Set environment variable for verbose logging:
```powershell
[Environment]::SetEnvironmentVariable("ENDPOINTPILOT_DEBUG", "true", "Machine")
```

## Future Enhancements

### Planned Features
1. **ARM64 Support**: Native ARM64 builds for Windows on ARM
2. **Remote Management**: REST API for remote service control
3. **Certificate Validation**: Code signing verification
4. **Advanced Scheduling**: Cron-like scheduling expressions
5. **Operation Dependencies**: Define operation execution order

### Extension Points
- Custom operation types via plugin architecture
- External configuration sources (e.g., Azure Key Vault)
- Integration with monitoring systems (SCOM, Zabbix)
- Multi-tenant support for MSP scenarios