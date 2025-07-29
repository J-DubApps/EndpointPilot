# Multi-platform PowerShell image selection with explicit ARG declarations
ARG VARIANT="7.4-ubuntu-22.04"
ARG BUILDPLATFORM
ARG TARGETPLATFORM

# Handle platform specification more robustly
# Default to linux/arm64 if TARGETPLATFORM is not set
FROM --platform=${TARGETPLATFORM:-linux/arm64} mcr.microsoft.com/powershell:${VARIANT}

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

# Skip PowerShell module installation during build to avoid QEMU segfault
# Modules will be installed via postCreateCommand instead
RUN echo "PowerShell modules will be installed after container creation"

# Set the default shell to pwsh for the user
RUN chsh -s /usr/bin/pwsh $USERNAME

USER $USERNAME
WORKDIR /workspace

# Set PowerShell as the default shell
SHELL ["pwsh", "-NoProfile", "-Command"]

ENV DEBIAN_FRONTEND=dialog
