# EndpointPilot Product Requirements Document

Version 2.0 | May 2026 (Revised from v1.0 August 2025)

## Product Overview

EndpointPilot is a lightweight endpoint compliance and configuration engine for Windows. It executes locally on managed PCs, processing JSON directive files to enforce file operations, registry settings, drive mappings, and system-level configurations. It reports endpoint compliance status back to the managing RMM platform.

EndpointPilot fills the gap between raw RMM scripting and full-scale configuration management by providing **declarative, JSON-driven configuration with schema validation, cryptographic signing, and dual-context execution** (user-mode and SYSTEM-mode).

### What Changed in v2.0

The original PRD (v1.0) positioned EndpointPilot as a "logon script replacement." That undersold the project. The codebase has evolved to include compliance auditing (BitLocker, Chrome extensions, PST detection), cryptographic signature validation for all directives, a production-ready .NET 8 System Agent, and comprehensive deployment automation. This revision reflects that reality.

## Goals

### Business Goals

- Provide consistent endpoint configuration for hybrid and remote work scenarios, independent of network connectivity
- Deliver enterprise-scale deployment via NinjaOne (primary) and Intune (planned)
- Enable IT admins to manage endpoint config as auditable, version-controlled JSON — not scattered scripts
- Report endpoint compliance status (security settings, application state) back to the RMM dashboard
- Support modern Windows architectures including ARM64 devices

### Non-Goals

- Inventory or asset tracking (delegated to NinjaOne/Intune)
- Remote control or IT service management features
- Database or stateful data storage
- Windows Server support
- x86 (32-bit) Windows support
- Windows 10/11 Pro editions (Enterprise only for now)
- Cloud storage dependencies (S3, Azure Blob) for config distribution

## User Personas

### IT System Administrator (Primary)

- Manages Windows endpoint configurations across the organization
- Intermediate PowerShell and JSON knowledge
- Edits JSON directives via JsonEditorTool or text editor, deploys via NinjaOne
- Pain point: network-dependent GPO limitations, inconsistent remote worker configs

### Security / Compliance Administrator

- Defines security-related endpoint configurations, monitors compliance
- Needs audit trail of what was applied, when, and whether signatures validated
- Uses NinjaOne dashboard custom fields to monitor fleet compliance status

### DevOps Engineer

- Manages deployment packages, CI/CD, version control
- Builds .intunewin packages, NinjaOne automations, GitHub Actions workflows
- Pain point: manual deployment processes, no config-as-code story

## Architecture

### Execution Model

EndpointPilot operates in two contexts:

**User mode** — Scheduled task running as the logged-in user. Handles user profile management, HKCU registry, file operations, telemetry collection, and compliance reporting.

**System mode** — .NET 8 Windows Service (System Agent) running as LocalSystem. Handles MSI installations, HKLM registry, Windows service management, and system-level file operations with strict ACLs.

### Runtime Flow

```
ENDPOINT-PILOT.PS1 → MAIN.PS1 → MGMT-*.ps1 helpers → *-OPS.json directives
                                                    ↓
                                            NinjaOne custom fields (status reporting)
```

### JSON Distribution (NinjaOne)

JSON directive files are distributed via **NinjaOne File Transfer Automation** — binary delivery that preserves cryptographic signatures. Endpoint status is reported back via `Ninja-Property-Set` custom fields and structured exit codes. Full design: `docs/planningdocs/NinjaOne-Distribution-Model.md`.

### Security Model

- All JSON directives support **cryptographic digital signatures** (SHA-256 + RSA-2048, certificate-based)
- Three enforcement modes: `strict` (reject unsigned), `warn` (log and proceed), `disabled`
- System Agent runs with strict ACLs (SYSTEM and Administrators only)
- JSON schema validation before any operation executes

## Functional Requirements

### Implemented

| Requirement                                                           | Component                         | Status   |
| --------------------------------------------------------------------- | --------------------------------- | -------- |
| File copy/move/delete with signature validation                       | MGMT-FileOps.ps1                  | Complete |
| Registry create/set/delete with write-once and signatures             | MGMT-RegOps.ps1                   | Complete |
| Roaming profile and folder redirection                                | MGMT-RoamOps.ps1                  | Complete |
| System telemetry (BitLocker, Chrome extensions, PSTs, 20+ datapoints) | MGMT-Telemetry.ps1                | Complete |
| Desktop shortcut cleanup                                              | MGMT-Maint.ps1                    | Complete |
| Outlook modern auth configuration                                     | MGMT-USER-CUSTOM.ps1              | Complete |
| Scheduled task management                                             | MGMT-SchedTsk.ps1                 | Complete |
| Architecture detection and PS version validation                      | ENDPOINT-PILOT.PS1                | Complete |
| System-level operations (MSI, HKLM registry, services)                | SystemAgent (.NET 8)              | Complete |
| JSON schema validation for all directive types                        | Schemas + Validate-JsonSchema.ps1 | Complete |
| Cryptographic signature validation (SHA-256/RSA-2048)                 | MGMT-Functions.psm1               | Complete |
| WPF JSON editor for admin workstations                                | JsonEditorTool                    | Complete |
| Install/uninstall/update scripts (user, admin, System Agent)          | deploy/                           | Complete |
| AD group membership-based conditional execution                       | InGroup/InGroupGP                 | Complete |
| Pre-built binaries for x64 and ARM64                                  | SystemAgent/bin/                  | Complete |

### Not Yet Implemented

| Requirement                                            | Priority | Notes                                  |
| ------------------------------------------------------ | -------- | -------------------------------------- |
| Network drive mapping                                  | P3       | MGMT-DriveOps.ps1 is a placeholder     |
| NinjaOne health reporting (custom fields + exit codes) | P1       | Design complete, implementation next   |
| Entra ID group checks (fallback for remote endpoints)  | P2       | AD checks fail off-network             |
| Dry-run mode for safe testing                          | P2       | No rollback mechanism exists today     |
| Centralized logging (Event Log / SIEM)                 | P3       | Currently local-only                   |
| Self-update mechanism                                  | P3       | No version drift detection on endpoint |
| Intune deployment packages                             | Deferred | NinjaOne is primary target             |

## User Experience

### Endpoint (Automatic, Silent)

1. Scheduled task or System Agent triggers execution
2. ENDPOINT-PILOT.PS1 validates architecture and PS version
3. MAIN.PS1 loads modules and executes helpers based on CONFIG.json skip flags
4. Each helper validates JSON signatures, then processes directives
5. Status is reported to NinjaOne custom fields (when NinjaOne agent is present)
6. System returns to idle until next scheduled run

### Admin Workflow (NinjaOne)

1. Edit JSON directives on admin workstation (JsonEditorTool or text editor)
2. Sign modified entries with signing certificate
3. Validate locally: `.\Validate-JsonSchema.ps1 -ValidateAll`
4. Upload signed JSON to NinjaOne File Transfer Automation
5. NinjaOne delivers files to targeted device groups on schedule
6. Monitor via NinjaOne dashboard custom fields (`EPilot_LastRunStatus`, `EPilot_ConfigHash`)

## Success Metrics

| Metric                                 | Target                      | How Measured                                     |
| -------------------------------------- | --------------------------- | ------------------------------------------------ |
| Configuration application success rate | >99%                        | `EPilot_LastRunStatus` custom field across fleet |
| Signature validation pass rate         | 100% (strict mode)          | `EPilot_RunSummary` custom field                 |
| Config drift (stale JSON on endpoint)  | <5% of fleet at any time    | `EPilot_ConfigHash` vs expected hash             |
| Execution time                         | <2 minutes per run          | Local log timestamps                             |
| Memory usage                           | <100MB during execution     | MGMT-Telemetry self-reporting                    |
| Config-related support tickets         | <2 per 1000 endpoints/month | Help desk tracking                               |

## Technical Constraints

- **PowerShell:** 5.1 minimum, 7+ preferred. Both detected and supported.
- **OS:** Windows 10/11 Enterprise only. x64/ARM64 only.
- **Development:** Primary dev on macOS (VS Code). All PS/Windows/.NET testing on Windows VMs.
- **No cloud dependencies** for config distribution — NinjaOne native mechanisms only.
- **Stateless** — no database, no persistent state beyond JSON files and logs on the endpoint.

## Milestones (May 2026 Re-Kickstart)

### Phase 1: Foundation (Current)

- [x] Fix P0 bugs (PS7 detection, RegOps field alignment, MAIN.PS1 assignment)
- [x] Define NinjaOne distribution model
- [x] Rewrite CLAUDE.md and PRD to reflect current state
- [ ] Implement NinjaOne health reporting in MAIN.PS1
- [ ] First test deployment to NinjaOne tenant

### Phase 2: Hardening

- [ ] Implement MGMT-DriveOps.ps1
- [ ] Add dry-run mode
- [ ] Entra ID group check fallback for remote endpoints
- [ ] Expand Pester test coverage
- [ ] Config drift detection (hash-based)

### Phase 3: Enterprise Readiness

- [ ] Centralized logging (Windows Event Log integration)
- [ ] Self-update mechanism
- [ ] Intune deployment packages
- [ ] Admin documentation and troubleshooting guides
- [ ] Production pilot with NinjaOne tenant
