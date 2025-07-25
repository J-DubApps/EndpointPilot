#Requires -Version 5.1

<#
.SYNOPSIS
    EndpointPilot Mock Module for Cross-Platform Development
    
.DESCRIPTION
    Provides mock implementations of Windows-specific cmdlets and functions
    to enable EndpointPilot development and testing on Linux/macOS platforms.
    
.NOTES
    This module is automatically loaded in Linux development containers
    and provides realistic mock responses for Windows API calls.
#>

# Module variables
$script:MockDataCache = @{}
$script:DebugMode = $env:ENDPOINTPILOT_DEBUG_MOCKS -eq 'true'

#region Helper Functions

function Write-MockDebug {
    param(
        [string]$FunctionName,
        [hashtable]$Parameters = @{},
        [object]$ReturnValue = $null
    )
    
    if ($script:DebugMode) {
        $paramString = if ($Parameters.Count -gt 0) { 
            ($Parameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
        } else { 
            "none" 
        }
        
        Write-Host "[MOCK] $FunctionName($paramString)" -ForegroundColor DarkYellow
        if ($ReturnValue) {
            Write-Host "[MOCK] -> Returned: $($ReturnValue | ConvertTo-Json -Compress -Depth 2)" -ForegroundColor DarkGray
        }
    }
}

function Get-MockRegistryData {
    param([string]$Path)
    
    # Simulate common registry paths with realistic data
    $registryMocks = @{
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" = @{
            ProductName = "Microsoft Windows 11 Enterprise"
            CurrentVersion = "10.0"
            CurrentBuild = "22000"
            CurrentBuildNumber = "22000"
            ReleaseId = "21H2"
            UBR = 318
        }
        "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" = @{
            ComputerName = "MOCK-DEV-PC"
        }
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" = @{
            ProductName = "Windows 11 Enterprise"
            EditionID = "Enterprise"
            InstallationType = "Client"
            RegisteredOwner = "Mock Organization"
            RegisteredOrganization = "EndpointPilot Dev"
        }
        "HKCU:\Software\EndpointPilot" = @{
            LastRun = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Version = "1.0.0"
            InstallPath = "/home/vscode/.endpointpilot"
            ConfigVersion = "1.0"
        }
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" = @{
            # Mock installed programs
        }
    }
    
    foreach ($mockPath in $registryMocks.Keys) {
        if ($Path -like "$mockPath*") {
            return $registryMocks[$mockPath]
        }
    }
    
    # Default mock data for unknown paths
    return @{
        MockValue = "DefaultMockData"
        MockType = "REG_SZ"
        MockData = Get-Date
    }
}

#endregion

#region Registry Cmdlet Mocks

function Get-ItemProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [Parameter(Position = 1)]
        [string]$Name,
        
        [object]$ErrorAction = 'Continue'
    )
    
    Write-MockDebug -FunctionName "Get-ItemProperty" -Parameters @{ Path = $Path; Name = $Name }
    
    try {
        $mockData = Get-MockRegistryData -Path $Path
        
        if ($Name) {
            if ($mockData.ContainsKey($Name)) {
                $result = @{ $Name = $mockData[$Name] }
            } else {
                $result = @{ $Name = "MockValue_$Name" }
            }
        } else {
            $result = $mockData
        }
        
        Write-MockDebug -FunctionName "Get-ItemProperty" -ReturnValue $result
        return $result
        
    } catch {
        if ($ErrorAction -eq 'Stop') {
            throw "MOCK: Registry path not found: $Path"
        }
        Write-Warning "MOCK: Registry access failed for $Path"
        return $null
    }
}

function Set-ItemProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [object]$Value,
        
        [string]$Type = "String"
    )
    
    Write-MockDebug -FunctionName "Set-ItemProperty" -Parameters @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }
    Write-Warning "MOCK: Set registry value $Name=$Value at $Path (Type: $Type)"
    
    # Simulate success
    return $true
}

function New-Item {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [string]$ItemType = "Unknown",
        
        [switch]$Force
    )
    
    # Handle registry paths
    if ($Path -match "^HK[LCU][MU]?:") {
        Write-MockDebug -FunctionName "New-Item (Registry)" -Parameters @{ Path = $Path; ItemType = $ItemType; Force = $Force.IsPresent }
        Write-Warning "MOCK: Created registry key: $Path"
        
        return [PSCustomObject]@{
            PSPath = $Path
            PSChildName = Split-Path -Leaf $Path
            Name = Split-Path -Leaf $Path
        }
    }
    
    # Handle file system paths (call original)
    $originalNewItem = Get-Command -Name New-Item -Module Microsoft.PowerShell.Management
    return & $originalNewItem @PSBoundParameters
}

function Remove-Item {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [switch]$Recurse,
        [switch]$Force,
        [string]$ErrorAction = 'Continue'
    )
    
    # Handle registry paths
    if ($Path -match "^HK[LCU][MU]?:") {
        Write-MockDebug -FunctionName "Remove-Item (Registry)" -Parameters @{ Path = $Path; Recurse = $Recurse.IsPresent; Force = $Force.IsPresent }
        Write-Warning "MOCK: Removed registry key: $Path"
        return $true
    }
    
    # Handle file system paths (call original)
    $originalRemoveItem = Get-Command -Name Remove-Item -Module Microsoft.PowerShell.Management
    return & $originalRemoveItem @PSBoundParameters
}

function Test-Path {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [string]$PathType
    )
    
    # Handle registry paths
    if ($Path -match "^HK[LCU][MU]?:") {
        Write-MockDebug -FunctionName "Test-Path (Registry)" -Parameters @{ Path = $Path; PathType = $PathType }
        
        # Mock common registry paths as existing
        $commonPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"
            "HKLM:\SYSTEM\CurrentControlSet"
            "HKCU:\Software"
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        )
        
        $exists = $commonPaths | Where-Object { $Path -like "$_*" }
        $result = [bool]$exists
        
        Write-MockDebug -FunctionName "Test-Path (Registry)" -ReturnValue $result
        return $result
    }
    
    # Handle file system paths (call original)
    $originalTestPath = Get-Command -Name Test-Path -Module Microsoft.PowerShell.Management
    return & $originalTestPath @PSBoundParameters
}

#endregion

#region WMI/CIM Cmdlet Mocks

function Get-WmiObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Class,
        
        [string]$Namespace = "root\cimv2",
        [string]$ComputerName = "localhost"
    )
    
    Write-MockDebug -FunctionName "Get-WmiObject" -Parameters @{ Class = $Class; Namespace = $Namespace; ComputerName = $ComputerName }
    
    $result = switch ($Class) {
        "Win32_ComputerSystem" {
            @{
                Name = "MOCK-DEV-PC"
                Domain = "MOCKDOMAIN.LOCAL"
                TotalPhysicalMemory = 17179869184  # 16GB
                Manufacturer = "Mock Hardware Inc."
                Model = "MockBook Pro"
                SystemType = "x64-based PC"
                UserName = "MOCKDOMAIN\mockuser"
                Workgroup = $null
                PartOfDomain = $true
            }
        }
        "Win32_OperatingSystem" {
            @{
                Caption = "Microsoft Windows 11 Enterprise"
                Version = "10.0.22000"
                BuildNumber = "22000"
                ServicePackMajorVersion = 0
                ServicePackMinorVersion = 0
                OSArchitecture = "64-bit"
                TotalVisibleMemorySize = 16777216  # 16GB in KB
                FreePhysicalMemory = 8388608      # 8GB in KB
                InstallDate = [DateTime]::Parse("2023-01-01")
                LastBootUpTime = (Get-Date).AddDays(-1)
            }
        }
        "Win32_Processor" {
            @{
                Name = "Mock Processor x64 Family 6 Model 142 Stepping 10"
                Architecture = 9  # x64
                NumberOfCores = 8
                NumberOfLogicalProcessors = 16
                MaxClockSpeed = 2800
                Manufacturer = "Mock Intel Corporation"
            }
        }
        "Win32_LogicalDisk" {
            @(
                @{
                    DeviceID = "C:"
                    DriveType = 3  # Fixed disk
                    FileSystem = "NTFS"
                    Size = 1099511627776      # 1TB
                    FreeSpace = 549755813888  # 512GB
                    VolumeName = "System"
                }
                @{
                    DeviceID = "D:"
                    DriveType = 3  # Fixed disk
                    FileSystem = "NTFS"
                    Size = 2199023255552      # 2TB
                    FreeSpace = 1649267441664 # 1.5TB
                    VolumeName = "Data"
                }
            )
        }
        "Win32_NetworkAdapter" {
            @(
                @{
                    Name = "Mock Ethernet Adapter"
                    AdapterType = "Ethernet 802.3"
                    NetConnectionID = "Ethernet"
                    NetEnabled = $true
                    PhysicalAdapter = $true
                }
                @{
                    Name = "Mock Wi-Fi Adapter"
                    AdapterType = "Wireless"
                    NetConnectionID = "Wi-Fi"
                    NetEnabled = $true
                    PhysicalAdapter = $true
                }
            )
        }
        "Win32_Service" {
            @(
                @{
                    Name = "Spooler"
                    DisplayName = "Print Spooler"
                    State = "Running"
                    StartMode = "Auto"
                    ServiceType = "Own Process"
                }
                @{
                    Name = "BITS"
                    DisplayName = "Background Intelligent Transfer Service"
                    State = "Running"
                    StartMode = "Manual"
                    ServiceType = "Share Process"
                }
            )
        }
        default {
            Write-Warning "MOCK: Unknown WMI class: $Class"
            @{
                MockClass = $Class
                MockProperty = "MockValue"
                MockDate = Get-Date
            }
        }
    }
    
    Write-MockDebug -FunctionName "Get-WmiObject" -ReturnValue $result
    return $result
}

function Get-CimInstance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ClassName,
        
        [string]$Namespace = "root\cimv2",
        [string]$ComputerName = "localhost"
    )
    
    Write-MockDebug -FunctionName "Get-CimInstance" -Parameters @{ ClassName = $ClassName; Namespace = $Namespace; ComputerName = $ComputerName }
    
    # Delegate to Get-WmiObject mock
    return Get-WmiObject -Class $ClassName -Namespace $Namespace -ComputerName $ComputerName
}

#endregion

#region Active Directory Cmdlet Mocks

function Get-ADComputer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Identity,
        
        [string[]]$Properties = @(),
        [string]$Server
    )
    
    Write-MockDebug -FunctionName "Get-ADComputer" -Parameters @{ Identity = $Identity; Properties = ($Properties -join ","); Server = $Server }
    
    $result = @{
        Name = $Identity
        DNSHostName = "$Identity.mockdomain.local"
        DistinguishedName = "CN=$Identity,OU=Computers,DC=mockdomain,DC=local"
        Enabled = $true
        OperatingSystem = "Windows 11 Enterprise"
        OperatingSystemVersion = "10.0 (22000)"
        LastLogonDate = (Get-Date).AddHours(-2)
        Created = (Get-Date).AddDays(-30)
        Modified = (Get-Date).AddDays(-5)
        ObjectClass = "computer"
        ObjectGUID = [System.Guid]::NewGuid()
        SID = "S-1-5-21-1234567890-1234567890-1234567890-1001"
    }
    
    Write-MockDebug -FunctionName "Get-ADComputer" -ReturnValue $result
    return $result
}

function Get-ADUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Identity,
        
        [string[]]$Properties = @(),
        [string]$Server
    )
    
    Write-MockDebug -FunctionName "Get-ADUser" -Parameters @{ Identity = $Identity; Properties = ($Properties -join ","); Server = $Server }
    
    $result = @{
        Name = $Identity
        SamAccountName = $Identity.ToLower()
        UserPrincipalName = "$($Identity.ToLower())@mockdomain.local"
        DistinguishedName = "CN=$Identity,OU=Users,DC=mockdomain,DC=local"
        Enabled = $true
        GivenName = "Mock"
        Surname = $Identity
        DisplayName = "Mock $Identity"
        EmailAddress = "$($Identity.ToLower())@mockdomain.local"
        Department = "Mock Department"
        Title = "Mock Title"
        LastLogonDate = (Get-Date).AddHours(-1)
        Created = (Get-Date).AddDays(-60)
        Modified = (Get-Date).AddDays(-1)
        ObjectClass = "user"
        ObjectGUID = [System.Guid]::NewGuid()
        SID = "S-1-5-21-1234567890-1234567890-1234567890-$(Get-Random -Minimum 1000 -Maximum 9999)"
    }
    
    Write-MockDebug -FunctionName "Get-ADUser" -ReturnValue $result
    return $result
}

function Get-ADGroupMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Identity,
        
        [switch]$Recursive,
        [string]$Server
    )
    
    Write-MockDebug -FunctionName "Get-ADGroupMember" -Parameters @{ Identity = $Identity; Recursive = $Recursive.IsPresent; Server = $Server }
    
    # Generate mock group membership
    $mockUsers = @("MockUser1", "MockUser2", "TestUser", $env:USER, $env:USERNAME)
    $mockUsers = $mockUsers | Where-Object { $_ } | Select-Object -Unique
    
    $result = foreach ($user in $mockUsers) {
        @{
            Name = $user
            SamAccountName = $user.ToLower()
            DistinguishedName = "CN=$user,OU=Users,DC=mockdomain,DC=local"
            ObjectClass = "user"
            ObjectGUID = [System.Guid]::NewGuid()
            SID = "S-1-5-21-1234567890-1234567890-1234567890-$(Get-Random -Minimum 1000 -Maximum 9999)"
        }
    }
    
    Write-MockDebug -FunctionName "Get-ADGroupMember" -ReturnValue $result
    return $result
}

function Get-ADDomain {
    [CmdletBinding()]
    param(
        [string]$Server,
        [string]$Identity
    )
    
    Write-MockDebug -FunctionName "Get-ADDomain" -Parameters @{ Server = $Server; Identity = $Identity }
    
    $result = @{
        Name = "mockdomain"
        NetBIOSName = "MOCKDOMAIN"
        DNSRoot = "mockdomain.local"
        DistinguishedName = "DC=mockdomain,DC=local"
        DomainMode = "Windows2016Domain"
        ForestMode = "Windows2016Forest"
        DomainSID = "S-1-5-21-1234567890-1234567890-1234567890"
        PDCEmulator = "mockdc01.mockdomain.local"
        RIDMaster = "mockdc01.mockdomain.local"
        InfrastructureMaster = "mockdc01.mockdomain.local"
    }
    
    Write-MockDebug -FunctionName "Get-ADDomain" -ReturnValue $result
    return $result
}

#endregion

#region Service Management Mocks

function Get-Service {
    [CmdletBinding()]
    param(
        [string[]]$Name = @(),
        [string[]]$DisplayName = @(),
        [string]$ComputerName = "localhost"
    )
    
    Write-MockDebug -FunctionName "Get-Service" -Parameters @{ Name = ($Name -join ","); DisplayName = ($DisplayName -join ","); ComputerName = $ComputerName }
    
    # Mock common Windows services
    $mockServices = @(
        @{ Name = "Spooler"; DisplayName = "Print Spooler"; Status = "Running"; StartType = "Automatic" }
        @{ Name = "BITS"; DisplayName = "Background Intelligent Transfer Service"; Status = "Running"; StartType = "Manual" }
        @{ Name = "Themes"; DisplayName = "Themes"; Status = "Running"; StartType = "Automatic" }
        @{ Name = "AudioSrv"; DisplayName = "Windows Audio"; Status = "Running"; StartType = "Automatic" }
        @{ Name = "EventLog"; DisplayName = "Windows Event Log"; Status = "Running"; StartType = "Automatic" }
        @{ Name = "Winmgmt"; DisplayName = "Windows Management Instrumentation"; Status = "Running"; StartType = "Automatic" }
    )
    
    if ($Name) {
        $result = $mockServices | Where-Object { $_.Name -in $Name }
    } elseif ($DisplayName) {
        $result = $mockServices | Where-Object { $_.DisplayName -in $DisplayName }
    } else {
        $result = $mockServices
    }
    
    Write-MockDebug -FunctionName "Get-Service" -ReturnValue $result
    return $result
}

function Start-Service {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    Write-MockDebug -FunctionName "Start-Service" -Parameters @{ Name = $Name }
    Write-Warning "MOCK: Started service: $Name"
    return $true
}

function Stop-Service {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [switch]$Force
    )
    
    Write-MockDebug -FunctionName "Stop-Service" -Parameters @{ Name = $Name; Force = $Force.IsPresent }
    Write-Warning "MOCK: Stopped service: $Name"
    return $true
}

function Restart-Service {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [switch]$Force
    )
    
    Write-MockDebug -FunctionName "Restart-Service" -Parameters @{ Name = $Name; Force = $Force.IsPresent }
    Write-Warning "MOCK: Restarted service: $Name"
    return $true
}

#endregion

#region Scheduled Task Mocks

function Get-ScheduledTask {
    [CmdletBinding()]
    param(
        [string]$TaskName,
        [string]$TaskPath = "\\"
    )
    
    Write-MockDebug -FunctionName "Get-ScheduledTask" -Parameters @{ TaskName = $TaskName; TaskPath = $TaskPath }
    
    $mockTasks = @(
        @{
            TaskName = "EndpointPilot-Main"
            TaskPath = "\EndpointPilot\"
            State = "Ready"
            LastRunTime = (Get-Date).AddHours(-1)
            NextRunTime = (Get-Date).AddMinutes(30)
        }
        @{
            TaskName = "EndpointPilot-Startup"
            TaskPath = "\EndpointPilot\"
            State = "Ready"
            LastRunTime = (Get-Date).AddDays(-1)
            NextRunTime = (Get-Date).AddDays(1)
        }
    )
    
    if ($TaskName) {
        $result = $mockTasks | Where-Object { $_.TaskName -like $TaskName }
    } else {
        $result = $mockTasks
    }
    
    Write-MockDebug -FunctionName "Get-ScheduledTask" -ReturnValue $result
    return $result
}

function Register-ScheduledTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TaskName,
        
        [object]$Action,
        [object]$Trigger,
        [object]$Settings,
        [string]$TaskPath = "\\",
        [switch]$Force
    )
    
    Write-MockDebug -FunctionName "Register-ScheduledTask" -Parameters @{ TaskName = $TaskName; TaskPath = $TaskPath; Force = $Force.IsPresent }
    Write-Warning "MOCK: Registered scheduled task: $TaskName at $TaskPath"
    
    return @{
        TaskName = $TaskName
        TaskPath = $TaskPath
        State = "Ready"
        LastRunTime = $null
        NextRunTime = $null
    }
}

function Unregister-ScheduledTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TaskName,
        
        [switch]$Confirm
    )
    
    Write-MockDebug -FunctionName "Unregister-ScheduledTask" -Parameters @{ TaskName = $TaskName; Confirm = $Confirm.IsPresent }
    Write-Warning "MOCK: Unregistered scheduled task: $TaskName"
    return $true
}

#endregion

#region Module Export

# Export all mock functions
Export-ModuleMember -Function @(
    # Registry functions
    'Get-ItemProperty', 'Set-ItemProperty', 'New-Item', 'Remove-Item', 'Test-Path',
    
    # WMI/CIM functions
    'Get-WmiObject', 'Get-CimInstance',
    
    # Active Directory functions
    'Get-ADComputer', 'Get-ADUser', 'Get-ADGroupMember', 'Get-ADDomain',
    
    # Service functions
    'Get-Service', 'Start-Service', 'Stop-Service', 'Restart-Service',
    
    # Scheduled Task functions
    'Get-ScheduledTask', 'Register-ScheduledTask', 'Unregister-ScheduledTask'
)

# Display module load message
if ($script:DebugMode) {
    Write-Host "EndpointPilot Mock Module loaded - Debug mode enabled" -ForegroundColor Green
} else {
    Write-Host "EndpointPilot Mock Module loaded" -ForegroundColor Green
}

#endregion