# EndpointPilot Testing Strategy

## Overview

EndpointPilot uses a comprehensive three-tier testing approach designed for PowerShell-based endpoint management solutions. This strategy balances development speed, reliability, and real-world validation.

## Testing Philosophy

### Core Principles
- **Fast Feedback**: Unit tests provide immediate validation during development
- **Real-World Validation**: Integration tests verify actual Windows behavior
- **End-to-End Confidence**: Scenario tests validate complete workflows
- **Cross-Platform Development**: Linux-based development with Windows validation

### Test Categories

## 1. Unit Tests (`/tests/unit/`)

**Purpose**: Fast, isolated testing of individual functions and modules

**Characteristics**:
- Run in seconds
- No external dependencies
- Extensive mocking of Windows APIs
- Cross-platform compatible (Linux/Windows containers)

**Coverage Areas**:
- MGMT-Functions.psm1 core utilities
- JSON schema validation
- Configuration parsing
- Error handling logic

**Example Test Structure**:
```powershell
Describe "MGMT-Functions Unit Tests" {
    BeforeAll {
        Import-Module ./MGMT-Functions.psm1 -Force
    }
    
    Context "InGroup Function" {
        It "Should return true for valid group membership" {
            Mock Get-ADGroupMember { return @{Name = "TestUser"} }
            InGroup -GroupName "TestGroup" -UserName "TestUser" | Should -Be $true
        }
    }
}
```

## 2. Integration Tests (`/tests/integration/`)

**Purpose**: Validate interactions with real Windows systems and APIs

**Characteristics**:
- Run in Windows containers or real Windows environments
- Access to real registry, services, and file system
- Moderate execution time (minutes)
- Platform-specific (Windows only)

**Coverage Areas**:
- Registry operations (MGMT-RegOps.ps1)
- File system operations (MGMT-FileOps.ps1)
- Service management
- Active Directory interactions

**Example Test Structure**:
```powershell
Describe "Registry Operations Integration" {
    BeforeAll {
        $testPath = "HKCU:\Software\EndpointPilotTest"
    }
    
    It "Should create registry key successfully" {
        { New-Item -Path $testPath -Force } | Should -Not -Throw
        Test-Path $testPath | Should -Be $true
    }
    
    AfterAll {
        Remove-Item -Path $testPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
```

## 3. Scenario Tests (`/tests/scenarios/`)

**Purpose**: End-to-end validation of complete EndpointPilot workflows

**Characteristics**:
- Longest execution time (5-15 minutes)
- Full system integration
- Real configuration files and operations
- Deployment scenario validation

**Coverage Areas**:
- Fresh installation workflows
- Upgrade scenarios
- Configuration changes
- Error recovery

**Example Test Structure**:
```powershell
Describe "Fresh Install Scenario" {
    It "Should complete full installation workflow" {
        # Test entry point
        { .\ENDPOINT-PILOT.PS1 } | Should -Not -Throw
        
        # Verify scheduled task creation
        Get-ScheduledTask -TaskName "EndpointPilot*" | Should -Not -BeNullOrEmpty
        
        # Verify configuration files
        Test-Path "$env:LOCALAPPDATA\EndpointPilot\CONFIG.json" | Should -Be $true
    }
}
```

## Pester Configuration

### Version Requirements
- **Pester 5.5.0**: Consistent across all environments
- **PowerShell 5.1+**: Minimum compatibility requirement
- **PowerShell 7+**: Preferred for enhanced features

### Configuration Files

#### Global Pester Configuration (`PesterConfiguration.psd1`):
```powershell
@{
    Run = @{
        Path = @('./tests/unit', './tests/integration', './tests/scenarios')
        Exit = $true
        PassThru = $true
    }
    Output = @{
        Verbosity = 'Detailed'
        StackTraceVerbosity = 'Filtered'
        CIFormat = 'Auto'
    }
    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = './tests/results/TestResults.xml'
    }
    CodeCoverage = @{
        Enabled = $true
        Path = @('./MGMT-*.ps1', './MGMT-*.psm1')
        OutputFormat = 'JaCoCo'
        OutputPath = './tests/results/CodeCoverage.xml'
    }
}
```

## Testing Workflows

### Development Testing
```powershell
# Quick unit tests during development (Linux container)
Invoke-Pester -Path ./tests/unit -Output Detailed

# Function-specific testing
Invoke-Pester -Path ./tests/unit/MGMT-Functions.Tests.ps1 -Output Detailed
```

### Pre-Commit Testing
```powershell
# Comprehensive test suite
Invoke-Pester -Configuration (Import-PowerShellDataFile ./PesterConfiguration.psd1)

# Syntax and style validation
Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSGallery
```

### CI/CD Pipeline Testing
```powershell
# Automated testing with results export
$config = Import-PowerShellDataFile ./PesterConfiguration.psd1
$results = Invoke-Pester -Configuration $config
if ($results.FailedCount -gt 0) { exit 1 }
```

## Mock Strategy

### Windows API Mocking (Linux Development)
```powershell
# Registry mocking
Mock Get-ItemProperty {
    return @{
        'TestValue' = 'MockedData'
        'Version' = '1.0.0'
    }
} -ParameterFilter { $Path -like "*SOFTWARE*" }

# WMI mocking
Mock Get-WmiObject {
    return @{
        Name = 'MOCK-COMPUTER'
        Domain = 'MOCK.LOCAL'
        TotalPhysicalMemory = 8589934592
    }
} -ParameterFilter { $Class -eq 'Win32_ComputerSystem' }
```

### Service Mocking
```powershell
Mock Get-Service {
    return @{
        Name = 'TestService'
        Status = 'Running'
        StartType = 'Automatic'
    }
} -ParameterFilter { $Name -eq 'TestService' }
```

## Test Data Management

### Test Configuration Files
- Use `.test.json` suffix for test-specific configurations
- Store in `/tests/testdata/` directory
- Include both valid and invalid configurations for error testing

### Environment Variables
```powershell
# Test environment detection
$env:ENDPOINTPILOT_TEST_MODE = 'true'
$env:ENDPOINTPILOT_TEST_DATA_PATH = './tests/testdata'
$env:ENDPOINTPILOT_MOCK_REGISTRY = 'true'
```

## Test Execution Environments

### Local Development
- **Linux Container**: Unit tests, mocked integration tests
- **Windows Container**: Real integration tests, limited scenario tests
- **Host Windows**: Full scenario testing, performance validation

### Continuous Integration
- **GitHub Actions**: Automated unit and integration testing
- **Test Matrix**: Multiple PowerShell versions and Windows editions
- **Artifact Collection**: Test results, coverage reports, logs

## Performance Testing

### Test Execution Targets
- Unit tests: < 30 seconds total
- Integration tests: < 5 minutes total  
- Scenario tests: < 15 minutes total

### Resource Monitoring
```powershell
# Memory usage validation
Describe "Performance Tests" {
    It "Should not exceed memory threshold" {
        $before = (Get-Process -Name powershell).WorkingSet64
        # Execute test logic
        $after = (Get-Process -Name powershell).WorkingSet64
        ($after - $before) | Should -BeLessThan 100MB
    }
}
```

## Test Reporting

### Coverage Requirements
- **Unit Tests**: 90%+ coverage of MGMT-Functions.psm1
- **Integration Tests**: 80%+ coverage of helper scripts
- **Critical Functions**: 100% coverage (InGroup, Get-Permission, WriteLog)

### Report Formats
- **NUnit XML**: CI/CD integration
- **JaCoCo XML**: Code coverage analysis
- **HTML Reports**: Developer-friendly detailed results

## Troubleshooting Tests

### Common Issues
```powershell
# Pester module conflicts
Get-Module Pester -ListAvailable
Remove-Module Pester -Force
Import-Module Pester -RequiredVersion 5.5.0

# Mock not working
Mock Get-ItemProperty {} -Verifiable
# Verify mock was called
Assert-VerifiableMock
```

### Debug Mode
```powershell
# Enhanced debugging output
$PesterPreference = [PesterConfiguration]::Default
$PesterPreference.Debug.WriteDebugMessages = $true
$PesterPreference.Debug.ShowFullErrors = $true
Invoke-Pester -Configuration $PesterPreference
```

## Best Practices

### Writing Effective Tests
- Use descriptive test names that explain expected behavior
- Follow Arrange-Act-Assert pattern
- Keep tests focused and independent
- Use appropriate assertion methods (`Should -Be`, `Should -Throw`, etc.)

### Test Organization
- Group related tests in `Context` blocks
- Use `BeforeAll`/`AfterAll` for expensive setup/cleanup
- Use `BeforeEach`/`AfterEach` for test isolation

### Mock Management
- Mock at the lowest level possible
- Verify mocks are called with expected parameters
- Clean up mocks between test runs

## Integration with Development Containers

### Linux Container Testing
```bash
# Available in Linux container profile
Test-EndpointPilotLinux -Type Unit
Test-EndpointPilotLinux -Type Syntax  
Test-EndpointPilotLinux -Type Compatibility
```

### Windows Container Testing
```powershell
# Available in Windows container profile
Test-EndpointPilotWindows -Component Registry
Test-EndpointPilotWindows -Component Services
Test-EndpointPilotWindows -Component AD
```

## Future Enhancements

### Planned Improvements
- Automated test generation from JSON schemas
- Performance regression detection
- Mutation testing for test quality validation
- Integration with Intune/NinjaOne test environments

### Test Environment Expansion
- ARM64 Windows container support
- Multi-tenant testing scenarios
- Offline/disconnected environment testing
- Load testing for large-scale deployments