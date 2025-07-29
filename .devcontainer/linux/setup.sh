#!/bin/bash
set -e

echo "🚀 Setting up EndpointPilot Linux Development Environment..."
echo "📦 Architecture: $(uname -m)"
echo "🐧 Distribution: $(lsb_release -d | cut -f2)"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create directory structure
echo -e "${BLUE}📁 Creating project structure...${NC}"
mkdir -p .devcontainer/linux/tests/{unit,integration,mocks}
mkdir -p .devcontainer/linux/tests/results
mkdir -p docs/linux
mkdir -p .build/reports/linux

# Install PowerShell modules (moved from Dockerfile to avoid QEMU segfault)
echo -e "${BLUE}📦 Installing PowerShell modules...${NC}"
pwsh -NoProfile -Command "
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    \$ProgressPreference = 'SilentlyContinue'
    
    # Core modules that were previously in the Dockerfile
    try {
        Write-Host 'Installing PSScriptAnalyzer...'
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
        Write-Host 'Installing Pester...'
        Install-Module -Name Pester -RequiredVersion 5.5.0 -Scope CurrentUser -Force
        Write-Host 'Installing PlatyPS...'
        Install-Module -Name PlatyPS -Scope CurrentUser -Force
        Write-Host 'Installing InvokeBuild...'
        Install-Module -Name InvokeBuild -Scope CurrentUser -Force
        Write-Host 'Installing ConsoleGuiTools...'
        Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        
        # Linux-specific testing tools
        Install-Module -Name PSUnixUtils -Force -Scope CurrentUser -ErrorAction SilentlyContinue
        Install-Module -Name PSLogging -Force -Scope CurrentUser
        
        # Cross-platform compatibility layer
        Install-Module -Name Microsoft.PowerShell.UnixCompleters -Force -Scope CurrentUser -ErrorAction SilentlyContinue
        
        Write-Host 'All modules installed successfully' -ForegroundColor Green
    } catch {
        Write-Warning \"Module installation failed: \$_\"
        Write-Host 'Some modules may not be available' -ForegroundColor Yellow
    }
"

# Create Linux-specific mock module
mkdir -p ~/.local/share/powershell/Modules/EndpointPilotMocks
cat > ~/.local/share/powershell/Modules/EndpointPilotMocks/EndpointPilotMocks.psm1 << 'EOF'
# Mock Windows-specific cmdlets for Linux testing
function Get-ItemProperty {
    param($Path, $Name)
    Write-Warning "MOCK: Get-ItemProperty called with Path: $Path"
    return @{
        $Name = "MockedValue"
    }
}

function Get-WmiObject {
    param($Class, $Namespace)
    Write-Warning "MOCK: Get-WmiObject called for Class: $Class"
    return @{
        Name = "MockedComputer"
        Domain = "MOCKED"
    }
}

function Get-ADComputer {
    param($Identity)
    Write-Warning "MOCK: Get-ADComputer called for: $Identity"
    return @{
        Name = $Identity
        DistinguishedName = "CN=$Identity,OU=Computers,DC=mock,DC=local"
    }
}

Export-ModuleMember -Function * -Alias *
EOF

# Create Linux test configuration
cat > .devcontainer/linux/tests/test.config.json << 'EOF'
{
    "platform": "linux",
    "testEnvironments": {
        "local": {
            "type": "linux-mock",
            "description": "Local Linux mocked environment",
            "mockModules": ["EndpointPilotMocks"]
        },
        "container": {
            "type": "linux-container",
            "description": "Containerized Linux tests"
        },
        "remote-windows": {
            "type": "windows-vm",
            "description": "Remote Windows VM tests from Linux",
            "targets": []
        }
    }
}
EOF

# Create Linux-specific PowerShell profile
mkdir -p ~/.config/powershell
cat > ~/.config/powershell/Microsoft.PowerShell_profile.ps1 << 'EOF'
# EndpointPilot Linux Development Profile
Write-Host "🐧 EndpointPilot Linux Development Environment" -ForegroundColor Cyan
Write-Host "📍 Container Arch: $(uname -m)" -ForegroundColor Gray
Write-Host "🔧 PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Gray

# Import mock module for development
Import-Module EndpointPilotMocks -ErrorAction SilentlyContinue

# Linux-specific aliases
Set-Alias -Name ll -Value "ls -la"
Set-Alias -Name ep-test -Value Invoke-Build
Set-Alias -Name ep-lint -Value Invoke-ScriptAnalyzer

# Helper functions for cross-platform development
function Test-EndpointPilotLinux {
    param(
        [ValidateSet('Syntax', 'Unit', 'Compatibility', 'All')]
        [string]$Type = 'All'
    )
    
    Write-Host "🧪 Running Linux $Type tests..." -ForegroundColor Yellow
    
    switch ($Type) {
        'Syntax' {
            Invoke-ScriptAnalyzer -Path /workspace -Recurse -ExcludeRule PSAvoidUsingCmdletAliases
        }
        'Unit' {
            Invoke-Pester -Path /workspace/.devcontainer/linux/tests/unit -Output Detailed
        }
        'Compatibility' {
            # Check for Windows-specific cmdlets
            /workspace/.devcontainer/linux/Check-Compatibility.ps1
        }
        'All' {
            Test-EndpointPilotLinux -Type Syntax
            Test-EndpointPilotLinux -Type Unit
            Test-EndpointPilotLinux -Type Compatibility
        }
    }
}

Write-Host "💡 Tip: Use 'Test-EndpointPilotLinux' to run Linux-specific tests" -ForegroundColor DarkGray
EOF

echo -e "${GREEN}✅ Linux development environment ready!${NC}"
echo -e "${YELLOW}📝 Linux-specific features enabled:${NC}"
echo "  • PowerShell Core on Ubuntu 22.04"
echo "  • Windows cmdlet mocking for testing"
echo "  • Cross-platform compatibility checking"
echo "  • Docker-in-Docker for container testing"