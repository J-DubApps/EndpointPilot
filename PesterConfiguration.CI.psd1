@{
    Run = @{
        Path = @(
            './tests/unit'
            './tests/integration'
        )
        Exit = $true
        PassThru = $true
    }
    
    Filter = @{
        Tag = @()
        ExcludeTag = @('Slow', 'Manual', 'RequiresAD')  # CI-specific exclusions
        Line = @()
        ExcludeLine = @()
    }
    
    Output = @{
        Verbosity = 'Normal'
        StackTraceVerbosity = 'Filtered'
        CIFormat = 'GithubActions'
    }
    
    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = './tests/results/CI-TestResults.xml'
    }
    
    CodeCoverage = @{
        Enabled = $true
        Path = @(
            './MGMT-Functions.psm1'
            './MGMT-*.ps1'
            './MAIN.ps1'
            './ENDPOINT-PILOT.ps1'
        )
        OutputFormat = 'JaCoCo'
        OutputPath = './tests/results/CI-CodeCoverage.xml'
        RecursePaths = $false
        CoveragePercentTarget = 75  # Slightly lower for CI
    }
    
    Should = @{
        ErrorAction = 'Stop'
    }
    
    Debug = @{
        ShowFullErrors = $false
        WriteDebugMessages = $false
        WriteDebugMessagesFrom = @()
        ReturnRawResultObject = $false
    }
}