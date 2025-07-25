# escape=`
ARG VARIANT="windowsservercore-ltsc2022"
FROM mcr.microsoft.com/windows/servercore:${VARIANT}

# Install PowerShell 7
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Invoke-WebRequest -Uri https://aka.ms/install-powershell.ps1 -OutFile install-powershell.ps1; `
    .\install-powershell.ps1 -UseMSI -Quiet -AddToPath

# Install Chocolatey
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install development tools
RUN choco install -y git vscode nodejs python3 7zip

# Install .NET SDK
RUN Invoke-WebRequest -Uri https://dot.net/v1/dotnet-install.ps1 -OutFile dotnet-install.ps1; `
    .\dotnet-install.ps1 -Channel 8.0

# Create non-admin user
RUN New-LocalUser -Name "ContainerUser" -Password (ConvertTo-SecureString -AsPlainText "P@ssw0rd" -Force) -PasswordNeverExpires -UserMayNotChangePassword; `
    Add-LocalGroupMember -Group "Users" -Member "ContainerUser"

# Install PowerShell modules
RUN pwsh -NoProfile -Command " `
    Set-PSRepository PSGallery -InstallationPolicy Trusted; `
    Install-Module -Name PSScriptAnalyzer -Scope AllUsers -Force; `
    Install-Module -Name Pester -RequiredVersion 5.5.0 -Scope AllUsers -Force; `
    Install-Module -Name PlatyPS -Scope AllUsers -Force; `
    Install-Module -Name InvokeBuild -Scope AllUsers -Force"

# Create workspace directory
RUN New-Item -ItemType Directory -Path C:\workspace -Force; `
    icacls C:\workspace /grant "ContainerUser:(OI)(CI)F"

USER ContainerUser
WORKDIR C:\workspace

# Set PowerShell 7 as default
SHELL ["pwsh", "-NoProfile", "-Command"]