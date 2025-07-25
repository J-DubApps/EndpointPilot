#Requires -Version 5.1
<#
.SYNOPSIS
    EndpointPilot Test Runner - Executes Pester tests with various configurations
    
.DESCRIPTION
    This script provides a unified interface for running EndpointPilot tests across
    different categories (Unit, Integration, Scenario) and environments (Local, CI).
    
.PARAMETER TestType
    Specifies which type of tests to run: Unit, Integration, Scenario, or All
    
.PARAMETER Environment
    Specifies the environment configuration: Local, CI, or Integration
    
.PARAMETER OutputFormat
    Specifies the output format for test results: Console, NUnit, JUnit, or All
    
.PARAMETER CodeCoverage
    Enable code coverage reporting
    
.PARAMETER PassThru
    Return the Pester result object
    
.PARAMETER SkipInstall
    Skip Pester module installation check
    
.EXAMPLE
    .\RunTests.ps1 -TestType Unit
    Runs unit tests with default local configuration
    
.EXAMPLE
    .\RunTests.ps1 -TestType All -Environment CI -CodeCoverage
    Runs all tests with CI configuration and code coverage
    
.EXAMPLE
    .\RunTests.ps1 -TestType Integration -Environment Integration -OutputFormat All
    Runs integration tests with full output formats
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Unit', 'Integration', 'Scenario', 'All')]
    [string]$TestType = 'Unit',
    
    [Parameter()]
    [ValidateSet('Local', 'CI', 'Integration')]
    [string]$Environment = 'Local',
    
    [Parameter()]
    [ValidateSet('Console', 'NUnit', 'JUnit', 'All')]
    [string]$OutputFormat = 'Console',
    
    [Parameter()]
    [switch]$CodeCoverage,
    
    [Parameter()]
    [switch]$PassThru,
    
    [Parameter()]
    [switch]$SkipInstall
)

#region Helper Functions

function Write-TestHeader {
    param($Message)
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "="*60 -ForegroundColor Cyan
}

function Write-TestResult {
    param($Result)
    
    $color = if ($Result.FailedCount -eq 0) { 'Green' } else { 'Red' }
    
    Write-Host "`nTest Results:" -ForegroundColor White
    Write-Host "  Total Tests: $($Result.TotalCount)" -ForegroundColor White
    Write-Host "  Passed: $($Result.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed: $($Result.FailedCount)" -ForegroundColor $(if ($Result.FailedCount -eq 0) { 'Green' } else { 'Red' })
    Write-Host "  Skipped: $($Result.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Duration: $($Result.Duration)" -ForegroundColor White
    
    if ($Result.CodeCoverage) {
        $coveragePercent = [math]::Round(($Result.CodeCoverage.NumberOfCommandsExecuted / $Result.CodeCoverage.NumberOfCommandsAnalyzed) * 100, 2)
        Write-Host "  Code Coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { 'Green' } else { 'Yellow' })
    }
}

function Test-PesterInstallation {
    $pesterModule = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
    
    if (-not $pesterModule) {
        Write-Warning "Pester module not found. Installing Pester 5.5.0..."
        Install-Module -Name Pester -RequiredVersion 5.5.0 -Scope CurrentUser -Force -SkipPublisherCheck
    } elseif ($pesterModule.Version -lt [Version]"5.0.0") {
        Write-Warning "Pester version $($pesterModule.Version) detected. EndpointPilot requires Pester 5.x. Installing Pester 5.5.0..."
        Install-Module -Name Pester -RequiredVersion 5.5.0 -Scope CurrentUser -Force -SkipPublisherCheck
    }
    
    # Import the correct version
    Import-Module Pester -RequiredVersion 5.5.0 -Force
    
    $importedPester = Get-Module -Name Pester
    if ($importedPester.Version -lt [Version]"5.0.0") {
        throw "Failed to import Pester 5.x. Current version: $($importedPester.Version)"
    }
    
    Write-Host "✓ Pester $($importedPester.Version) loaded successfully" -ForegroundColor Green
}

function Get-TestConfiguration {
    param($Environment)
    
    $configFile = switch ($Environment) {
        'CI' { './PesterConfiguration.CI.psd1' }
        'Integration' { './PesterConfiguration.Integration.psd1' }
        default { './PesterConfiguration.psd1' }
    }
    
    if (-not (Test-Path $configFile)) {
        throw "Configuration file not found: $configFile"
    }
    
    return Import-PowerShellDataFile -Path $configFile
}

function Set-TestPaths {
    param($TestType, $Config)
    
    switch ($TestType) {
        'Unit' {
            $Config.Run.Path = @('./tests/unit')
            $Config.Filter.ExcludeTag = @('Integration', 'Scenario', 'Slow')
        }
        'Integration' {
            $Config.Run.Path = @('./tests/integration')
            $Config.Filter.Tag = @('Integration')
            $Config.Filter.ExcludeTag = @('RequiresAD', 'RequiresNetwork')
        }
        'Scenario' {
            $Config.Run.Path = @('./tests/scenarios')
            $Config.Filter.Tag = @('Scenario')
            $Config.Filter.ExcludeTag = @('RequiresElevation')
        }
        'All' {
            $Config.Run.Path = @('./tests/unit', './tests/integration', './tests/scenarios')
            $Config.Filter.ExcludeTag = @('RequiresAD', 'RequiresElevation', 'Manual')
        }
    }
}

function Set-OutputConfiguration {
    param($OutputFormat, $Config)
    
    # Ensure results directory exists
    $resultsDir = './tests/results'
    if (-not (Test-Path $resultsDir)) {
        New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
    }
    
    switch ($OutputFormat) {
        'NUnit' {
            $Config.TestResult.Enabled = $true
            $Config.TestResult.OutputFormat = 'NUnitXml'
            $Config.TestResult.OutputPath = "$resultsDir/TestResults-NUnit.xml"
        }
        'JUnit' {
            $Config.TestResult.Enabled = $true
            $Config.TestResult.OutputFormat = 'JUnitXml'
            $Config.TestResult.OutputPath = "$resultsDir/TestResults-JUnit.xml"
        }
        'All' {
            $Config.TestResult.Enabled = $true
            $Config.TestResult.OutputFormat = 'NUnitXml'
            $Config.TestResult.OutputPath = "$resultsDir/TestResults.xml"
            
            # Additional formats will be handled post-execution
        }
        'Console' {
            $Config.TestResult.Enabled = $false
        }
    }
}

#endregion

#region Main Execution

try {
    Write-TestHeader "EndpointPilot Test Runner"
    Write-Host "Test Type: $TestType" -ForegroundColor White
    Write-Host "Environment: $Environment" -ForegroundColor White
    Write-Host "Output Format: $OutputFormat" -ForegroundColor White
    Write-Host "Code Coverage: $($CodeCoverage.IsPresent)" -ForegroundColor White
    
    # Check Pester installation
    if (-not $SkipInstall) {
        Write-Host "`nChecking Pester installation..." -ForegroundColor Yellow
        Test-PesterInstallation
    }
    
    # Load configuration
    Write-Host "`nLoading test configuration..." -ForegroundColor Yellow
    $config = Get-TestConfiguration -Environment $Environment
    
    # Configure test paths based on type
    Set-TestPaths -TestType $TestType -Config $config
    
    # Configure output format
    Set-OutputConfiguration -OutputFormat $OutputFormat -Config $config
    
    # Configure code coverage
    if ($CodeCoverage) {
        $config.CodeCoverage.Enabled = $true
        Write-Host "✓ Code coverage enabled" -ForegroundColor Green
    } else {
        $config.CodeCoverage.Enabled = $false
    }
    
    # Validate test paths exist
    $missingPaths = $config.Run.Path | Where-Object { -not (Test-Path $_) }
    if ($missingPaths) {
        Write-Warning "The following test paths do not exist: $($missingPaths -join ', ')"
        $config.Run.Path = $config.Run.Path | Where-Object { Test-Path $_ }
        
        if (-not $config.Run.Path) {
            throw "No valid test paths found"
        }
    }
    
    Write-Host "`nTest paths: $($config.Run.Path -join ', ')" -ForegroundColor White
    if ($config.Filter.Tag) {
        Write-Host "Include tags: $($config.Filter.Tag -join ', ')" -ForegroundColor White
    }
    if ($config.Filter.ExcludeTag) {
        Write-Host "Exclude tags: $($config.Filter.ExcludeTag -join ', ')" -ForegroundColor White
    }
    
    # Create Pester configuration object
    $pesterConfig = New-PesterConfiguration
    
    # Apply configuration
    foreach ($section in $config.Keys) {
        if ($pesterConfig.$section) {
            foreach ($setting in $config.$section.Keys) {
                if ($pesterConfig.$section.$setting -ne $null) {
                    $pesterConfig.$section.$setting = $config.$section.$setting
                }
            }
        }
    }
    
    # Run tests
    Write-TestHeader "Executing Tests"
    $startTime = Get-Date
    
    $result = Invoke-Pester -Configuration $pesterConfig
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    # Display results
    Write-TestResult -Result $result
    
    # Generate additional output formats if requested
    if ($OutputFormat -eq 'All' -and $result.TestResult) {
        Write-Host "`nGenerating additional output formats..." -ForegroundColor Yellow
        
        # Convert NUnit to JUnit (basic conversion)
        if ($result.TestResult.OutputPath -and (Test-Path $result.TestResult.OutputPath)) {
            $junitPath = $result.TestResult.OutputPath -replace '\.xml$', '-JUnit.xml'
            Copy-Item -Path $result.TestResult.OutputPath -Destination $junitPath
            Write-Host "✓ JUnit format: $junitPath" -ForegroundColor Green
        }
    }
    
    # Exit with appropriate code
    if ($result.FailedCount -gt 0) {
        Write-Host "`n❌ Tests completed with failures" -ForegroundColor Red
        if (-not $PassThru) {
            exit 1
        }
    } else {
        Write-Host "`n✅ All tests passed" -ForegroundColor Green
        if (-not $PassThru) {
            exit 0
        }
    }
    
    # Return result if requested
    if ($PassThru) {
        return $result
    }
    
} catch {
    Write-Host "`n❌ Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    
    if (-not $PassThru) {
        exit 2
    }
    throw
}

#endregion