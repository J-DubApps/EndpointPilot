@{
    Run = @{
        Path = @(
            './tests/integration'
            './tests/scenarios'
        )
        Exit = $true
        PassThru = $true
    }
    
    Filter = @{
        Tag = @('Integration', 'Windows')
        ExcludeTag = @('RequiresAD')  # Exclude AD tests unless in domain environment
        Line = @()
        ExcludeLine = @()
    }
    
    Output = @{
        Verbosity = 'Detailed'
        StackTraceVerbosity = 'Full'
        CIFormat = 'Auto'
    }
    
    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = './tests/results/Integration-TestResults.xml'
    }
    
    CodeCoverage = @{
        Enabled = $false  # Integration tests focus on behavior, not coverage
    }
    
    Should = @{
        ErrorAction = 'Stop'
    }
    
    Debug = @{
        ShowFullErrors = $true
        WriteDebugMessages = $false
        WriteDebugMessagesFrom = @()
        ReturnRawResultObject = $false
    }
}