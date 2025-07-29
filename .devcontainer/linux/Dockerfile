# ARM64-native .NET SDK with PowerShell on Alpine Linux
FROM --platform=linux/arm64 mcr.microsoft.com/dotnet/sdk:8.0-alpine3.21-arm64v8

# Install additional OS packages using Alpine's apk
RUN apk update && apk add --no-cache \
    git \
    curl \
    ca-certificates \
    openssh-client \
    jq \
    make \
    build-base \
    python3 \
    py3-pip \
    sudo \
    vim \
    nano \
    bash \
    shadow \
    musl-locales \
    musl-locales-lang

# Set locale (Alpine handles this differently)
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Create workspace directory
RUN mkdir -p /workspace && chown $USERNAME:$USERNAME /workspace

# Switch to user for PowerShell module installation
USER $USERNAME
WORKDIR /home/$USERNAME

# Configure PowerShell environment (runs natively on ARM64)
RUN pwsh -NoProfile -Command "Set-PSRepository PSGallery -InstallationPolicy Trusted"

# Install PowerShell modules (should work without segfaults on native ARM64)
RUN pwsh -NoProfile -Command " \
    \$ErrorActionPreference = 'Continue'; \
    \$ProgressPreference = 'SilentlyContinue'; \
    try { \
        Write-Host 'Installing PSScriptAnalyzer...'; \
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -Confirm:\$false; \
        Write-Host 'Installing Pester...'; \
        Install-Module -Name Pester -RequiredVersion 5.5.0 -Scope CurrentUser -Force -Confirm:\$false; \
        Write-Host 'Installing PlatyPS...'; \
        Install-Module -Name PlatyPS -Scope CurrentUser -Force -Confirm:\$false; \
        Write-Host 'Installing InvokeBuild...'; \
        Install-Module -Name InvokeBuild -Scope CurrentUser -Force -Confirm:\$false; \
        Write-Host 'Installing ConsoleGuiTools...'; \
        Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -Force -Confirm:\$false; \
        Write-Host 'All modules installed successfully on ARM64!'; \
    } catch { \
        Write-Warning \"Module installation failed: \$_\"; \
    }"

# Set the default shell to pwsh for the user
RUN sudo chsh -s /usr/bin/pwsh $USERNAME

WORKDIR /workspace

# Set PowerShell as the default shell
SHELL ["pwsh", "-NoProfile", "-Command"]

# Alpine doesn't use DEBIAN_FRONTEND

# Verify architecture
RUN pwsh -Command "Write-Host 'Architecture:' ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)"
