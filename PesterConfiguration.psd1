@{
    Run = @{
        Path = @(
            './tests/unit'
            './tests/integration' 
            './tests/scenarios'
        )
        Exit = $true
        PassThru = $true
        Container = (New-PesterContainer -Path './tests/unit' -Data @{})
    }
    
    Filter = @{
        Tag = @()
        ExcludeTag = @('Slow', 'Integration')  # Exclude by default for fast runs
        Line = @()
        ExcludeLine = @()
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
        Path = @(
            './MGMT-Functions.psm1'
            './MGMT-*.ps1'
            './MAIN.ps1'
            './ENDPOINT-PILOT.ps1'
        )
        OutputFormat = 'JaCoCo'
        OutputPath = './tests/results/CodeCoverage.xml'
        RecursePaths = $false
        CoveragePercentTarget = 80
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