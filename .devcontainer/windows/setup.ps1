#Requires -Version 5.1
Write-Host "🚀 Setting up EndpointPilot Windows Development Environment..." -ForegroundColor Cyan

# Detect Windows version and architecture
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$arch = (Get-CimInstance -ClassName Win32_Processor).Architecture
$archStr = switch ($arch) {
    0 { "x86" }
    5 { "ARM64" }
    9 { "x64" }
    12 { "ARM64" }
    default { "Unknown" }
}

Write-Host "🪟 Windows Version: $($osInfo.Caption)" -ForegroundColor Gray
Write-Host "📦 Architecture: $archStr" -ForegroundColor Gray
Write-Host "🔧 PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Gray

# Create directory structure
Write-Host "`n📁 Creating project structure..." -ForegroundColor Blue
$directories = @(
    ".devcontainer\windows\tests\unit"
    ".devcontainer\windows\tests\integration"
    ".devcontainer\windows\tests\results"
    "docs\windows"
    ".build\reports\windows"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# Install Windows-specific modules
Write-Host "`n📦 Installing Windows-specific PowerShell modules..." -ForegroundColor Blue
$modules = @(
    @{Name = "ActiveDirectory"; SkipPublisherCheck = $true}
    @{Name = "GroupPolicy"; SkipPublisherCheck = $true}
    @{Name = "PSWindowsUpdate"; SkipPublisherCheck = $true}
)

foreach ($module in $modules) {
    try {
        Install-Module @module -Force -Scope CurrentUser -ErrorAction Stop
        Write-Host "  ✓ Installed $($module.Name)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ Could not install $($module.Name): $_" -ForegroundColor Yellow
    }
}

# Create Windows test configuration
$testConfig = @{
    platform = "windows"
    testEnvironments = @{
        local = @{
            type = "windows-container"
            description = "Local Windows container environment"
        }
        integration = @{
            type = "windows-full"
            description = "Full Windows environment tests"
            features = @(
                "Registry"
                "Services"
                "ActiveDirectory"
                "GroupPolicy"
            )
        }
    }
} | ConvertTo-Json -Depth 10

$testConfig | Out-File -FilePath ".devcontainer\windows\tests\test.config.json" -Encoding UTF8

# Create Windows-specific PowerShell profile
$profileContent = @'
# EndpointPilot Windows Development Profile
Write-Host "🪟 EndpointPilot Windows Development Environment" -ForegroundColor Cyan
Write-Host "📍 Container OS: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Gray
Write-Host "🔧 PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Gray

# Windows-specific aliases
Set-Alias -Name ep-test -Value Invoke-Build
Set-Alias -Name ep-lint -Value Invoke-ScriptAnalyzer

# Helper functions for Windows development
function Test-EndpointPilotWindows {
    param(
        [ValidateSet('Registry', 'Services', 'AD', 'All')]
        [string]$Component = 'All'
    )
    
    Write-Host "🧪 Running Windows $Component tests..." -ForegroundColor Yellow
    
    switch ($Component) {
        'Registry' {
            Invoke-Pester -Path "C:\workspace\.devcontainer\windows\tests\unit\*Registry*.Tests.ps1" -Output Detailed
        }
        'Services' {
            Invoke-Pester -Path "C:\workspace\.devcontainer\windows\tests\unit\*Service*.Tests.ps1" -Output Detailed
        }
        'AD' {
            if (Get-Module -ListAvailable -Name ActiveDirectory) {
                Invoke-Pester -Path "C:\workspace\.devcontainer\windows\tests\unit\*AD*.Tests.ps1" -Output Detailed
            } else {
                Write-Warning "ActiveDirectory module not available"
            }
        }
        'All' {
            Invoke-Pester -Path "C:\workspace\.devcontainer\windows\tests\unit" -Output Detailed
        }
    }
}

function Test-RegistryOperation {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )
    
    Write-Host "🔍 Testing registry operation..." -ForegroundColor Yellow
    Write-Host "  Path: $Path"
    Write-Host "  Name: $Name"
    Write-Host "  Value: $Value"
    
    # Test in container-safe location
    $testPath = "HKCU:\Software\EndpointPilotTest"
    try {
        New-Item -Path $testPath -Force | Out-Null
        Set-ItemProperty -Path $testPath -Name $Name -Value $Value
        $result = Get-ItemProperty -Path $testPath -Name $Name
        Write-Host "✅ Registry operation successful" -ForegroundColor Green
        Remove-Item -Path $testPath -Recurse -Force
    } catch {
        Write-Host "❌ Registry operation failed: $_" -ForegroundColor Red
    }
}

Write-Host "`n💡 Tips:" -ForegroundColor DarkGray
Write-Host "  • Use 'Test-EndpointPilotWindows' to run component tests" -ForegroundColor DarkGray
Write-Host "  • Use 'Test-RegistryOperation' to test registry operations" -ForegroundColor DarkGray
'@

$profilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
New-Item -ItemType Directory -Path (Split-Path $profilePath) -Force | Out-Null
$profileContent | Out-File -FilePath $profilePath -Encoding UTF8

Write-Host "`n✅ Windows development environment ready!" -ForegroundColor Green
Write-Host "`n📝 Windows-specific features enabled:" -ForegroundColor Yellow
Write-Host "  • Full Windows PowerShell + PowerShell 7"
Write-Host "  • Registry access for testing"
Write-Host "  • Service management capabilities"
Write-Host "  • Active Directory cmdlets (if domain-joined)"