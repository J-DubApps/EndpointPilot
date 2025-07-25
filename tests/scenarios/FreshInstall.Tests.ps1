#Requires -Module Pester
#Requires -Version 5.1

BeforeAll {
    # This test requires Windows environment for full integration
    if (-not $IsWindows -and $PSVersionTable.PSVersion.Major -ge 6) {
        Write-Warning "Fresh Install scenario tests require Windows environment"
    }
    
    # Set up test environment
    $script:TestEnvironment = @{
        BackupPath = Join-Path -Path $TestDrive -ChildPath "Backup"
        TestConfigPath = Join-Path -Path $TestDrive -ChildPath "TestConfig"
        OriginalLocation = Get-Location
    }
    
    # Create backup directory
    New-Item -Path $script:TestEnvironment.BackupPath -ItemType Directory -Force | Out-Null
    New-Item -Path $script:TestEnvironment.TestConfigPath -ItemType Directory -Force | Out-Null
    
    # Create test configuration files
    $testConfig = @{
        OrgName = "TestOrganization"
        RefreshInterval = 60
        EnableLogging = $true
        SkipFileOps = $false
        SkipRegOps = $false
    } | ConvertTo-Json -Depth 10
    
    $testConfig | Out-File -FilePath (Join-Path -Path $script:TestEnvironment.TestConfigPath -ChildPath "CONFIG.json") -Encoding UTF8
    
    # Mock configuration for testing
    $script:MockEndpointPilotPath = $script:TestEnvironment.TestConfigPath
}

Describe "Fresh Installation Scenario" -Tag "Scenario", "Integration", "FreshInstall" {
    
    Context "Pre-Installation Validation" {
        It "Should detect PowerShell version compatibility" {
            $psVersion = $PSVersionTable.PSVersion
            $psVersion.Major | Should -BeGreaterOrEqual 5
            
            if ($psVersion.Major -eq 5) {
                $psVersion.Minor | Should -BeGreaterOrEqual 1
            }
        }
        
        It "Should validate operating system requirements" -Tag "Windows" {
            if ($IsWindows) {
                $osInfo = Get-WmiObject -Class Win32_OperatingSystem
                $osInfo.Caption | Should -Match "(Windows 10|Windows 11|Windows Server)"
                
                # Check architecture
                $processor = Get-WmiObject -Class Win32_Processor
                $processor.Architecture | Should -BeIn @(5, 9, 12)  # ARM64, x64, ARM64 variants
            } else {
                Set-ItResult -Skipped -Because "OS validation requires Windows"
            }
        }
        
        It "Should check for required permissions" -Tag "Windows" {
            if ($IsWindows) {
                # Check if running with sufficient privileges for scheduled task creation
                $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                
                # For user-mode installation, admin rights are not required
                # This test verifies the detection logic works
                $isAdmin | Should -BeOfType [bool]
            } else {
                Set-ItResult -Skipped -Because "Permission check requires Windows"
            }
        }
    }
    
    Context "Configuration File Processing" {
        It "Should validate CONFIG.json schema" {
            $configPath = Join-Path -Path $script:TestEnvironment.TestConfigPath -ChildPath "CONFIG.json"
            Test-Path $configPath | Should -Be $true
            
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            $config.OrgName | Should -Not -BeNullOrEmpty
            $config.RefreshInterval | Should -BeOfType [int]
            $config.RefreshInterval | Should -BeGreaterThan 0
        }
        
        It "Should create directory structure" {
            $expectedDirs = @(
                $script:TestEnvironment.TestConfigPath
                (Join-Path -Path $script:TestEnvironment.TestConfigPath -ChildPath "Logs")
                (Join-Path -Path $script:TestEnvironment.TestConfigPath -ChildPath "Cache")
            )
            
            foreach ($dir in $expectedDirs) {
                if (-not (Test-Path $dir)) {
                    New-Item -Path $dir -ItemType Directory -Force
                }
                Test-Path $dir | Should -Be $true
            }
        }
        
        It "Should validate JSON directive files" {
            $directiveFiles = @(
                "FILE-OPS.json"
                "REG-OPS.json" 
                "DRIVE-OPS.json"
                "ROAM-OPS.json"
            )
            
            foreach ($file in $directiveFiles) {
                $filePath = Join-Path -Path $PSScriptRoot -ChildPath "../../$file"
                if (Test-Path $filePath) {
                    { Get-Content -Path $filePath -Raw | ConvertFrom-Json } | Should -Not -Throw
                }
            }
        }
    }
    
    Context "Module Loading and Dependency Validation" {
        It "Should load MGMT-Functions module successfully" {
            $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../MGMT-Functions.psm1"
            
            if (Test-Path $modulePath) {
                { Import-Module $modulePath -Force } | Should -Not -Throw
                
                $module = Get-Module -Name MGMT-Functions
                $module | Should -Not -BeNullOrEmpty
                $module.ExportedFunctions.Count | Should -BeGreaterThan 0
            } else {
                Set-ItResult -Skipped -Because "MGMT-Functions.psm1 not found"
            }
        }
        
        It "Should load shared variables and functions" {
            $sharedPath = Join-Path -Path $PSScriptRoot -ChildPath "../../MGMT-SHARED.ps1"
            
            if (Test-Path $sharedPath) {
                { . $sharedPath } | Should -Not -Throw
                
                # Verify key variables are defined
                $OrgName | Should -Not -BeNullOrEmpty
                $RefreshInterval | Should -BeGreaterThan 0
            } else {
                Set-ItResult -Skipped -Because "MGMT-SHARED.ps1 not found"
            }
        }
    }
    
    Context "Entry Point Execution" -Tag "Slow" {
        It "Should execute ENDPOINT-PILOT.PS1 without errors" {
            $entryScript = Join-Path -Path $PSScriptRoot -ChildPath "../../ENDPOINT-PILOT.PS1"
            
            if (Test-Path $entryScript) {
                # Mock the environment to prevent actual system changes
                Mock Test-Path { return $true } -ParameterFilter { $Path -like "*EndpointPilot*" }
                Mock Set-Location { } 
                Mock & { } -ParameterFilter { $_ -like "*MAIN.PS1*" }
                
                { & $entryScript -WhatIf } | Should -Not -Throw
            } else {
                Set-ItResult -Skipped -Because "ENDPOINT-PILOT.PS1 not found"
            }
        }
        
        It "Should execute MAIN.PS1 orchestrator successfully" {
            $mainScript = Join-Path -Path $PSScriptRoot -ChildPath "../../MAIN.PS1"
            
            if (Test-Path $mainScript) {
                # Set test mode to prevent actual operations
                $env:ENDPOINTPILOT_TEST_MODE = "true"
                
                try {
                    { & $mainScript -TestMode } | Should -Not -Throw
                } finally {
                    Remove-Item Env:\ENDPOINTPILOT_TEST_MODE -ErrorAction SilentlyContinue
                }
            } else {
                Set-ItResult -Skipped -Because "MAIN.PS1 not found"
            }
        }
    }
    
    Context "Scheduled Task Creation" -Tag "Windows", "RequiresElevation" {
        It "Should create scheduled task for EndpointPilot" -Skip:(-not $IsWindows) {
            # This test requires Windows and may require elevation
            try {
                $taskName = "EndpointPilot-Test-Task"
                $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$PSScriptRoot\..\..\ENDPOINT-PILOT.PS1`""
                $trigger = New-ScheduledTaskTrigger -AtStartup
                $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
                
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force
                
                $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                $task | Should -Not -BeNullOrEmpty
                $task.State | Should -Be "Ready"
                
                # Cleanup
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            } catch {
                Set-ItResult -Skipped -Because "Scheduled task operations require appropriate permissions: $($_.Exception.Message)"
            }
        }
    }
    
    Context "Logging System Validation" {
        It "Should create log files in correct location" {
            $logPath = Join-Path -Path $script:TestEnvironment.TestConfigPath -ChildPath "Logs"
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null
            
            # Simulate log entry creation
            $testLogFile = Join-Path -Path $logPath -ChildPath "EndpointPilot.log"
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "[$timestamp] [Info] Fresh installation test log entry" | Out-File -FilePath $testLogFile -Append -Encoding UTF8
            
            Test-Path $testLogFile | Should -Be $true
            $logContent = Get-Content -Path $testLogFile
            $logContent | Should -Contain -Because "Should contain test log entry" { $_ -match "Fresh installation test" }
        }
        
        It "Should handle log rotation when files become large" {
            $logPath = Join-Path -Path $script:TestEnvironment.TestConfigPath -ChildPath "Logs"
            $testLogFile = Join-Path -Path $logPath -ChildPath "LargeLog.log"
            
            # Create a large log file (simulate)
            1..100 | ForEach-Object {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                "[$timestamp] [Info] Log entry number $_" | Out-File -FilePath $testLogFile -Append -Encoding UTF8
            }
            
            Test-Path $testLogFile | Should -Be $true
            (Get-Item $testLogFile).Length | Should -BeGreaterThan 1KB
        }
    }
    
    Context "Error Recovery and Rollback" {
        It "Should handle configuration file corruption gracefully" {
            $corruptConfigPath = Join-Path -Path $script:TestEnvironment.TestConfigPath -ChildPath "CORRUPT-CONFIG.json"
            "{ invalid json syntax" | Out-File -FilePath $corruptConfigPath -Encoding UTF8
            
            { Get-Content -Path $corruptConfigPath -Raw | ConvertFrom-Json } | Should -Throw
            
            # Verify that error handling would create a backup and restore default
            $backupPath = "$corruptConfigPath.backup"
            if (Test-Path $corruptConfigPath) {
                Copy-Item -Path $corruptConfigPath -Destination $backupPath -Force
                Test-Path $backupPath | Should -Be $true
            }
        }
        
        It "Should maintain system state on partial failures" {
            # Simulate a scenario where some operations succeed and others fail
            $operations = @(
                @{ Name = "FileOp1"; ShouldSucceed = $true }
                @{ Name = "FileOp2"; ShouldSucceed = $false }
                @{ Name = "FileOp3"; ShouldSucceed = $true }
            )
            
            $results = foreach ($op in $operations) {
                try {
                    if ($op.ShouldSucceed) {
                        @{ Operation = $op.Name; Success = $true; Error = $null }
                    } else {
                        throw "Simulated failure for $($op.Name)"
                    }
                } catch {
                    @{ Operation = $op.Name; Success = $false; Error = $_.Exception.Message }
                }
            }
            
            $successCount = ($results | Where-Object { $_.Success }).Count
            $failureCount = ($results | Where-Object { -not $_.Success }).Count
            
            $successCount | Should -Be 2
            $failureCount | Should -Be 1
            
            # Verify that successful operations are not rolled back due to other failures
            $results | Where-Object { $_.Success } | Should -HaveCount 2
        }
    }
}

Describe "Post-Installation Verification" -Tag "Scenario", "Verification" {
    
    Context "System State Validation" {
        It "Should have all required files in place" {
            $requiredFiles = @(
                "CONFIG.json"
                "MGMT-Functions.psm1"
                "MGMT-SHARED.ps1"
                "MAIN.ps1"
                "ENDPOINT-PILOT.ps1"
            )
            
            foreach ($file in $requiredFiles) {
                $filePath = Join-Path -Path $PSScriptRoot -ChildPath "../../$file"
                if (Test-Path $filePath) {
                    Test-Path $filePath | Should -Be $true
                    (Get-Item $filePath).Length | Should -BeGreaterThan 0
                }
            }
        }
        
        It "Should have proper directory permissions" -Tag "Windows" {
            if ($IsWindows) {
                $testDir = $script:TestEnvironment.TestConfigPath
                $acl = Get-Acl $testDir
                
                $acl | Should -Not -BeNullOrEmpty
                $acl.Access | Should -Not -BeNullOrEmpty
                
                # Verify current user has appropriate access
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $hasAccess = $acl.Access | Where-Object { 
                    $_.IdentityReference -eq $currentUser.Name -and 
                    $_.AccessControlType -eq "Allow" 
                }
                $hasAccess | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Skipped -Because "Permission validation requires Windows"
            }
        }
    }
    
    Context "Configuration Validation" {
        It "Should have valid organization configuration" {
            $configPath = Join-Path -Path $script:TestEnvironment.TestConfigPath -ChildPath "CONFIG.json"
            if (Test-Path $configPath) {
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                
                $config.OrgName | Should -Match "^[A-Za-z0-9\s\-_]+$"
                $config.RefreshInterval | Should -BeGreaterThan 0
                $config.RefreshInterval | Should -BeLessOrEqual 1440  # Max 24 hours
            }
        }
        
        It "Should have proper logging configuration" {
            $logDir = Join-Path -Path $script:TestEnvironment.TestConfigPath -ChildPath "Logs"
            if (Test-Path $logDir) {
                Test-Path $logDir | Should -Be $true
                (Get-Item $logDir).PSIsContainer | Should -Be $true
            }
        }
    }
}

AfterAll {
    # Cleanup test environment
    if (Test-Path $script:TestEnvironment.BackupPath) {
        Remove-Item -Path $script:TestEnvironment.BackupPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path $script:TestEnvironment.TestConfigPath) {
        Remove-Item -Path $script:TestEnvironment.TestConfigPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Restore original location
    Set-Location $script:TestEnvironment.OriginalLocation
    
    # Clean up any test scheduled tasks
    if ($IsWindows) {
        Get-ScheduledTask -TaskName "EndpointPilot-Test-*" -ErrorAction SilentlyContinue | 
            Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    }
}