# EndpointPilot v1.0b release notes outline

## Executive summary and release significance

This section will establish EndpointPilot's purpose as a PowerShell-based Windows endpoint configuration solution designed to replace traditional logon scripts. It will highlight how v1.0b represents the first beta release of a mature configuration management system that operates independently of network connectivity through scheduled tasks and agent-based deployment.

The summary will emphasize EndpointPilot's core value proposition: providing reliable endpoint configuration for hybrid and remote work scenarios where traditional GPO/Intune methods may be insufficient. It will position this release as the foundation for enterprise deployment readiness while acknowledging its beta status.

## Key features and capabilities overview

This section will detail EndpointPilot's architectural strengths and operational capabilities. It will cover the modular PowerShell framework that supports both PowerShell 5.1 and Core compatibility, ensuring broad Windows endpoint support across x64 and ARM64 architectures.

The section will explain the JSON-driven configuration system using directive files (FILE-OPS.json, REG-OPS.json, DRIVE-OPS.json, ROAM-OPS.json) that enable declarative endpoint management. It will highlight the separation of concerns through helper scripts (MGMT-FileOps, MGMT-RegOps, etc.) and the centralized orchestration via MAIN.PS1.

Key operational features include scheduled task automation, VPN-aware execution, user-mode operation with planned system-mode capabilities, and comprehensive logging through the WriteLog function and MGMT-SHARED.ps1 utilities.

## What's new in version 1.0b

This section will catalog the specific deliverables included in the v1.0b release. It will cover the completion of the core PowerShell framework with all essential modules (MGMT-Functions.psm1, MGMT-SHARED.ps1) and helper scripts for file, registry, drive, and roaming profile operations.

The JsonEditorTool WPF application represents a major addition, providing IT administrators with a graphical interface for managing JSON configuration files without requiring manual JSON editing skills. The tool includes built-in schema validation and supports both x64 and ARM64 Windows architectures.

Installation capabilities have been established through Install-EndpointPilot.ps1 and Install-EndpointPilotAdmin.ps1 scripts, with basic uninstallation and update mechanisms. The SystemAgent framework has been scaffolded in preparation for system-level operations in future releases.

## Installation and deployment instructions

This section will provide step-by-step guidance for deploying EndpointPilot in enterprise environments. It will cover both user-mode installation via Install-EndpointPilot.ps1 and administrative installation through Install-EndpointPilotAdmin.ps1.

The instructions will detail file placement locations (%LOCALAPPDATA%\EndpointPilot for user mode, %PROGRAMDATA%\EndpointPilot for system components), required permissions, and scheduled task configuration. It will include guidance for Intune and NinjaOne deployment scenarios, including package preparation and detection rules.

Configuration management will be explained through the CONFIG.json file structure, including refresh intervals, organization settings, and skip flags for selective operation execution.

## Known limitations and current issues

This section will transparently communicate EndpointPilot's current constraints and planned improvements. Primary limitations include user-mode only operation (until SystemAgent completion), requirement for scheduled task creation privileges, and Windows 10/11 Enterprise restriction.

Technical limitations will be addressed, including the lack of automatic updates, script signing implementation, and the current JSON file accessibility in user locations. The section will acknowledge placeholder functionality in some MGMT scripts and ongoing development of the system agent for elevated operations.

Performance considerations for large deployments will be discussed, along with current testing framework gaps that are being addressed through Pester implementation.