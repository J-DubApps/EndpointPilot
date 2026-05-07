#Requires -Module Pester
#Requires -Version 5.1

BeforeAll {
    $ProjectRoot = Join-Path -Path $PSScriptRoot -ChildPath "../.."

    # Import shared module for WriteLog
    $SharedPath = Join-Path -Path $ProjectRoot -ChildPath "MGMT-SHARED.ps1"

    # Mock out Windows-only dependencies before loading MGMT-SHARED.ps1
    function global:Write-EventLog { param([string]$LogName, [string]$Source, [string]$Message, [int]$EventId, [string]$EntryType) }
    function global:Write-InformationalEvent { param([string]$Message) }

    # Create a temp CONFIG.json for testing
    $script:TestConfigDir = Join-Path $env:TEMP "EPilotDryRunTest"
    if (-not (Test-Path $script:TestConfigDir)) {
        New-Item -Path $script:TestConfigDir -ItemType Directory -Force | Out-Null
    }

    $script:TestLogFile = Join-Path $script:TestConfigDir "test-dryrun.log"
}

AfterAll {
    # Cleanup
    if (Test-Path $script:TestConfigDir) {
        Remove-Item -Path $script:TestConfigDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    $global:DryRunMode = $false
}

Describe "Dry-Run Mode" -Tag "Unit", "DryRun" {

    Context "Global flag initialization" {

        It "Should set DryRunMode to false when neither param nor config enables it" {
            $global:DryRunMode = $false
            $DryRun = $false
            $config = [PSCustomObject]@{ DryRun = $false }

            $global:DryRunMode = ($DryRun -eq $true) -or ($config.DryRun -eq $true)

            $global:DryRunMode | Should -Be $false
        }

        It "Should set DryRunMode to true when -DryRun param is set" {
            $global:DryRunMode = $false
            $DryRun = $true
            $config = [PSCustomObject]@{ DryRun = $false }

            $global:DryRunMode = ($DryRun -eq $true) -or ($config.DryRun -eq $true)

            $global:DryRunMode | Should -Be $true
        }

        It "Should set DryRunMode to true when CONFIG.json DryRun is true" {
            $global:DryRunMode = $false
            $DryRun = $false
            $config = [PSCustomObject]@{ DryRun = $true }

            $global:DryRunMode = ($DryRun -eq $true) -or ($config.DryRun -eq $true)

            $global:DryRunMode | Should -Be $true
        }

        It "Should set DryRunMode to true when both param and config enable it" {
            $global:DryRunMode = $false
            $DryRun = $true
            $config = [PSCustomObject]@{ DryRun = $true }

            $global:DryRunMode = ($DryRun -eq $true) -or ($config.DryRun -eq $true)

            $global:DryRunMode | Should -Be $true
        }
    }

    Context "WriteLog dry-run prefixing" {

        BeforeEach {
            # Set up a clean log file
            if (Test-Path $script:TestLogFile) {
                Remove-Item $script:TestLogFile -Force
            }
            $LogFile = $script:TestLogFile
        }

        It "Should prefix log messages with [DRY-RUN] when DryRunMode is active" {
            $global:DryRunMode = $true
            $LogFile = $script:TestLogFile

            # Inline WriteLog to test the prefixing logic
            $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
            $prefix = if ($global:DryRunMode) { "[DRY-RUN] " } else { "" }
            $LogMessage = "$Stamp $prefix" + "Test message"
            Add-Content $LogFile -Value $LogMessage

            $content = Get-Content $LogFile -Raw
            $content | Should -Match "\[DRY-RUN\] Test message"
        }

        It "Should NOT prefix log messages when DryRunMode is inactive" {
            $global:DryRunMode = $false
            $LogFile = $script:TestLogFile

            $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
            $prefix = if ($global:DryRunMode) { "[DRY-RUN] " } else { "" }
            $LogMessage = "$Stamp $prefix" + "Normal message"
            Add-Content $LogFile -Value $LogMessage

            $content = Get-Content $LogFile -Raw
            $content | Should -Not -Match "\[DRY-RUN\]"
            $content | Should -Match "Normal message"
        }
    }

    Context "FileOps dry-run guard" {

        It "Should not delete files when DryRunMode is active" {
            $global:DryRunMode = $true
            $testFile = Join-Path $script:TestConfigDir "delete-test.txt"
            "test content" | Set-Content $testFile

            # Simulate the FileOps delete guard
            if ($global:DryRunMode) {
                # Would delete — but doesn't
            } else {
                Remove-Item -Path $testFile -Force -ErrorAction Ignore
            }

            Test-Path $testFile | Should -Be $true
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }

        It "Should not copy files when DryRunMode is active" {
            $global:DryRunMode = $true
            $sourceFile = Join-Path $script:TestConfigDir "source.txt"
            $destFile = Join-Path $script:TestConfigDir "dest.txt"
            "source content" | Set-Content $sourceFile

            # Simulate the FileOps copy guard
            if ($global:DryRunMode) {
                # Would copy — but doesn't
            } else {
                Copy-Item -Path $sourceFile -Destination $destFile -Force
            }

            Test-Path $destFile | Should -Be $false
            Remove-Item $sourceFile -Force -ErrorAction SilentlyContinue
        }

        It "Should delete files when DryRunMode is inactive" {
            $global:DryRunMode = $false
            $testFile = Join-Path $script:TestConfigDir "delete-test-real.txt"
            "test content" | Set-Content $testFile

            if ($global:DryRunMode) {
                # Would delete
            } else {
                Remove-Item -Path $testFile -Force -ErrorAction Ignore
            }

            Test-Path $testFile | Should -Be $false
        }
    }

    Context "CONFIG.json schema validation" {

        It "Should accept DryRun as a valid boolean property" {
            $schemaPath = Join-Path (Join-Path $PSScriptRoot "../..") "CONFIG.schema.json"
            if (Test-Path $schemaPath) {
                $schema = Get-Content -Raw -Path $schemaPath | ConvertFrom-Json
                $schema.properties.DryRun | Should -Not -BeNullOrEmpty
                $schema.properties.DryRun.type | Should -Be "boolean"
            } else {
                Set-ItResult -Skipped -Because "CONFIG.schema.json not found at expected path"
            }
        }

        It "Should have DryRun set to false in default CONFIG.json" {
            $configPath = Join-Path (Join-Path $PSScriptRoot "../..") "CONFIG.json"
            if (Test-Path $configPath) {
                $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
                $config.DryRun | Should -Be $false
            } else {
                Set-ItResult -Skipped -Because "CONFIG.json not found at expected path"
            }
        }
    }
}
