#!/bin/bash
# Pre-stage ARM64 Docker images for EndpointPilot development

echo "Pre-staging ARM64 Docker images..."

# Pull the main .NET SDK ARM64 images
docker pull --platform linux/arm64 mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim-arm64v8
docker pull --platform linux/arm64 mcr.microsoft.com/dotnet/sdk:8.0-alpine3.21-arm64v8

# Pull the Azure PowerShell ARM64 image for future use
docker pull --platform linux/arm64 mcr.microsoft.com/azure-powershell:14.1.0-mariner-2-arm64

echo "ARM64 images pre-staged successfully!"
docker images | grep arm64