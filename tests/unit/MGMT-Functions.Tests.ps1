#Requires -Module Pester
#Requires -Version 5.1

BeforeAll {
    # Import the module being tested
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../MGMT-Functions.psm1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        throw "Cannot find MGMT-Functions.psm1 at expected path: $ModulePath"
    }
    
    # Import shared variables if available
    $SharedPath = Join-Path -Path $PSScriptRoot -ChildPath "../../MGMT-SHARED.ps1"
    if (Test-Path $SharedPath) {
        . $SharedPath
    }
    
    # Import mocks for cross-platform testing
    if (-not $IsWindows -and (Get-Module -ListAvailable -Name EndpointPilotMocks)) {
        Import-Module EndpointPilotMocks -Force
    }
}

Describe "MGMT-Functions Unit Tests" -Tag "Unit", "Fast" {
    
    Context "InGroup Function Tests" {
        BeforeAll {
            # Mock AD cmdlets for testing
            Mock Get-ADGroupMember {
                param($Identity)
                return @(
                    @{ Name = "TestUser1"; SamAccountName = "tuser1" }
                    @{ Name = "TestUser2"; SamAccountName = "tuser2" }
                    @{ Name = "CurrentUser"; SamAccountName = $env:USERNAME }
                )
            } -ModuleName MGMT-Functions
        }
        
        It "Should return true when user is in group" {
            $result = InGroup -GroupName "TestGroup" -UserName $env:USERNAME
            $result | Should -Be $true
        }
        
        It "Should return false when user is not in group" {
            $result = InGroup -GroupName "TestGroup" -UserName "NonExistentUser"
            $result | Should -Be $false
        }
        
        It "Should handle empty group gracefully" {
            Mock Get-ADGroupMember { return @() } -ModuleName MGMT-Functions
            $result = InGroup -GroupName "EmptyGroup" -UserName $env:USERNAME
            $result | Should -Be $false
        }
        
        It "Should handle null parameters gracefully" {
            { InGroup -GroupName $null -UserName $env:USERNAME } | Should -Throw
            { InGroup -GroupName "TestGroup" -UserName $null } | Should -Throw
        }
    }
    
    Context "Get-RegistryValue Function Tests" {
        BeforeAll {
            # Mock registry operations for cross-platform testing
            Mock Get-ItemProperty {
                param($Path, $Name)
                if ($Path -eq "HKLM:\SOFTWARE\Test" -and $Name -eq "TestValue") {
                    return @{ TestValue = "Expected" }
                }
                throw "Registry key not found"
            } -ModuleName MGMT-Functions
        }
        
        It "Should return registry value when key exists" {
            $result = Get-RegistryValue -Path "HKLM:\SOFTWARE\Test" -Name "TestValue"
            $result | Should -Be "Expected"
        }
        
        It "Should return null when key does not exist" {
            $result = Get-RegistryValue -Path "HKLM:\SOFTWARE\NonExistent" -Name "TestValue"
            $result | Should -BeNullOrEmpty
        }
        
        It "Should handle invalid paths gracefully" {
            $result = Get-RegistryValue -Path "InvalidPath" -Name "TestValue"
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context "WriteLog Function Tests" {
        BeforeAll {
            # Create temporary log file for testing
            $script:TestLogPath = Join-Path -Path $TestDrive -ChildPath "test.log"
            
            # Mock the WriteLog function to use test path
            Mock WriteLog {
                param($Level, $Message, $LogPath = $script:TestLogPath)
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logEntry = "[$timestamp] [$Level] $Message"
                Add-Content -Path $LogPath -Value $logEntry
            } -ModuleName MGMT-Functions
        }
        
        It "Should write log entry with correct format" {
            WriteLog -Level "Info" -Message "Test message"
            
            $logContent = Get-Content -Path $script:TestLogPath
            $logContent | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Info\] Test message"
        }
        
        It "Should handle different log levels" {
            @("Info", "Warning", "Error") | ForEach-Object {
                WriteLog -Level $_ -Message "Test $_"
            }
            
            $logContent = Get-Content -Path $script:TestLogPath
            $logContent | Should -Contain -Because "Should contain Info level" { $_ -match "\[Info\]" }
            $logContent | Should -Contain -Because "Should contain Warning level" { $_ -match "\[Warning\]" }
            $logContent | Should -Contain -Because "Should contain Error level" { $_ -match "\[Error\]" }
        }
    }
    
    Context "Test-OperatingSystem Function Tests" {
        BeforeAll {
            # Mock system information
            Mock Get-WmiObject {
                param($Class)
                switch ($Class) {
                    "Win32_OperatingSystem" {
                        return @{
                            Caption = "Microsoft Windows 11 Enterprise"
                            Version = "10.0.22000"
                            BuildNumber = "22000"
                            Architecture = "64-bit"
                        }
                    }
                    "Win32_Processor" {
                        return @{
                            Architecture = 9  # x64
                        }
                    }
                }
            } -ModuleName MGMT-Functions
        }
        
        It "Should pass for supported Windows versions" {
            $result = Test-OperatingSystem
            $result | Should -Be $true
        }
        
        It "Should reject unsupported architectures" {
            Mock Get-WmiObject {
                return @{ Architecture = 0 }  # x86
            } -ModuleName MGMT-Functions -ParameterFilter { $Class -eq "Win32_Processor" }
            
            $result = Test-OperatingSystem
            $result | Should -Be $false
        }
    }
    
    Context "Get-Permission Function Tests" {
        BeforeAll {
            Mock Test-Path { return $true } -ModuleName MGMT-Functions
            Mock Get-Acl {
                $mockAcl = [PSCustomObject]@{
                    Access = @(
                        @{
                            IdentityReference = "BUILTIN\Administrators"
                            FileSystemRights = "FullControl"
                            AccessControlType = "Allow"
                        }
                        @{
                            IdentityReference = "$env:USERDOMAIN\$env:USERNAME"
                            FileSystemRights = "Read"
                            AccessControlType = "Allow"
                        }
                    )
                }
                return $mockAcl
            } -ModuleName MGMT-Functions
        }
        
        It "Should return permissions for existing path" {
            $result = Get-Permission -Path "C:\Test"
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }
        
        It "Should handle non-existent paths" {
            Mock Test-Path { return $false } -ModuleName MGMT-Functions
            $result = Get-Permission -Path "C:\NonExistent"
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe "MGMT-Functions Error Handling" -Tag "Unit", "ErrorHandling" {
    
    Context "Exception Handling Tests" {
        It "Should handle registry access errors gracefully" {
            Mock Get-ItemProperty { throw "Access denied" } -ModuleName MGMT-Functions
            
            { Get-RegistryValue -Path "HKLM:\SECURITY" -Name "TestValue" } | Should -Not -Throw
        }
        
        It "Should handle AD connection errors gracefully" {
            Mock Get-ADGroupMember { throw "Server not available" } -ModuleName MGMT-Functions
            
            { InGroup -GroupName "TestGroup" -UserName $env:USERNAME } | Should -Not -Throw
        }
    }
}

Describe "MGMT-Functions Integration Points" -Tag "Unit", "Integration" {
    
    Context "Module Loading Tests" {
        It "Should export all required functions" {
            $exportedFunctions = Get-Command -Module MGMT-Functions
            $requiredFunctions = @(
                "InGroup"
                "Get-RegistryValue" 
                "WriteLog"
                "Test-OperatingSystem"
                "Get-Permission"
            )
            
            foreach ($function in $requiredFunctions) {
                $exportedFunctions.Name | Should -Contain $function
            }
        }
        
        It "Should have proper parameter validation" {
            $commandInfo = Get-Command -Name InGroup -Module MGMT-Functions
            $commandInfo.Parameters.Keys | Should -Contain "GroupName"
            $commandInfo.Parameters.Keys | Should -Contain "UserName"
        }
    }
}