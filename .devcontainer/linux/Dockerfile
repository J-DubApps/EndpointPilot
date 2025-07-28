# Multi-platform PowerShell image selection
ARG VARIANT="7.4-ubuntu-22.04"
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Use platform-specific base image to avoid emulation issues
FROM --platform=$TARGETPLATFORM mcr.microsoft.com/powershell:${VARIANT}

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install additional OS packages
RUN apt-get update && apt-get -y install --no-install-recommends \
    git \
    curl \
    ca-certificates \
    openssh-client \
    jq \
    make \
    build-essential \
    python3 \
    python3-pip \
    sudo \
    locales \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create non-root user first to avoid permission issues
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Create workspace directory
RUN mkdir -p /workspace && chown $USERNAME:$USERNAME /workspace

# ARM64-compatible PowerShell module installation
# Install modules individually with error handling and retries
RUN pwsh -NoProfile -Command " \
    Set-PSRepository PSGallery -InstallationPolicy Trusted; \
    \$ProgressPreference = 'SilentlyContinue'; \
    try { \
        Write-Host 'Installing PSScriptAnalyzer...'; \
        Install-Module -Name PSScriptAnalyzer -Scope AllUsers -Force -ErrorAction Stop; \
        Write-Host 'Installing Pester...'; \
        Install-Module -Name Pester -RequiredVersion 5.5.0 -Scope AllUsers -Force -ErrorAction Stop; \
        Write-Host 'Installing PlatyPS...'; \
        Install-Module -Name PlatyPS -Scope AllUsers -Force -ErrorAction Stop; \
        Write-Host 'Installing InvokeBuild...'; \
        Install-Module -Name InvokeBuild -Scope AllUsers -Force -ErrorAction Stop; \
        Write-Host 'Installing PSWindowsUpdate...'; \
        Install-Module -Name PSWindowsUpdate -Scope AllUsers -Force -SkipPublisherCheck -ErrorAction Stop; \
        Write-Host 'Installing ConsoleGuiTools...'; \
        Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -Scope AllUsers -Force -ErrorAction Stop; \
        Write-Host 'All modules installed successfully'; \
    } catch { \
        Write-Warning \"Module installation failed: \$_\"; \
        Write-Host 'Continuing with basic PowerShell setup...'; \
    }"

# Set the default shell to pwsh for the user
RUN chsh -s /usr/bin/pwsh $USERNAME

USER $USERNAME
WORKDIR /workspace

# Set PowerShell as the default shell
SHELL ["pwsh", "-NoProfile", "-Command"]

ENV DEBIAN_FRONTEND=dialog
