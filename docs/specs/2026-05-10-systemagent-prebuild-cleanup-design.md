# SystemAgent Pre-Build Cleanup — Design Spec

**Date:** 2026-05-10
**Context:** Phase A prep for Distribution API build (Session 14)
**Scope:** Bug fixes + refactoring in `SystemAgent/` — no new features, no API changes

---

## Problem Statement

Code review of the SystemAgent identified two bugs and two structural issues that should be resolved before building the Distribution API client (Phase B-C). Fixing these now prevents compounding technical debt during the API build.

---

## Change 1: Replace Script Blocklist with Hash Verification

### Current Behavior (Buggy)

`PowerShellExecutor` validates scripts via two mechanisms:

1. **Static allowlist** (`_allowedScripts` HashSet) — hardcoded paths to permitted `.ps1` files. `ENDPOINT-PILOT.PS1` is missing from this list, causing `ValidateScriptSafetyAsync` to reject it even though `SchedulerService` invokes it every cycle.

2. **Pattern blocklist** (`ContainsMaliciousPatterns`) — rejects scripts containing cmdlets like `Invoke-RestMethod` and `Invoke-WebRequest`. These are used legitimately by EndpointPilot's Entra ID / Graph API integration (Sessions 6-11).

### New Behavior

Both mechanisms replaced by a single `hashes.json` manifest:

```json
{
    "generatedAt": "2026-05-10T14:30:00Z",
    "hashAlgorithm": "SHA-256",
    "scripts": {
        "ENDPOINT-PILOT.PS1": "a3f2c8d1e5...",
        "MAIN.PS1": "b7d1e4f2a9...",
        "MGMT-FileOps.ps1": "c9e5f0b3d7...",
        "MGMT-RegOps.ps1": "...",
        "MGMT-DriveOps.ps1": "...",
        "MGMT-RoamOps.ps1": "...",
        "MGMT-SchedTsk.ps1": "...",
        "MGMT-Telemetry.ps1": "...",
        "MGMT-USER-CUSTOM.ps1": "...",
        "MGMT-Maint.ps1": "...",
        "MGMT-Functions.psm1": "...",
        "MGMT-SHARED.ps1": "..."
    }
}
```

**Location:** `%PROGRAMDATA%\EndpointPilot\hashes.json`

**Validation logic in `ValidateScriptSafetyAsync`:**

1. Is the file inside `%PROGRAMDATA%\EndpointPilot\`? (existing secure-location check, retained)
2. Does the file's SHA-256 hash match the corresponding entry in `hashes.json`?
3. If both pass, script is authorized for execution.

**Graceful degradation:** If `hashes.json` does not exist (pre-upgrade installs, first-run before deploy scripts generate it), validation falls back to secure-location-only with a warning:

```
"Script hash manifest not found. Falling back to location-based validation only.
 Run Generate-ScriptHashes.ps1 to enable hash verification."
```

This ensures existing deployments don't break on upgrade.

### Removed

- `_allowedScripts` HashSet — the hash manifest IS the allowlist
- `ContainsMaliciousPatterns()` method — replaced entirely by hash verification
- All individual pattern strings (`Invoke-Expression`, `IEX`, `DownloadString`, etc.)

### New Utility Script

`scripts/Generate-ScriptHashes.ps1` — scans the EndpointPilot install directory for `*.ps1` and `*.psm1` files, computes SHA-256 hashes, writes `hashes.json`. Deploy scripts should call this after copying/updating script files.

**Parameters:**

- `-InstallPath` (optional, default: `$env:ProgramData\EndpointPilot`)
- `-OutputPath` (optional, default: `$InstallPath\hashes.json`)

---

## Change 2: Extract EndpointPilotConfig to Models/

### Current State

`EndpointPilotConfig` class is defined at the bottom of `SchedulerService.cs` (lines 268-288). It's missing fields that were added to `CONFIG.json` in Sessions 4-12.

### New State

Move to `Models/EndpointPilotConfig.cs`. Add missing fields:

```csharp
// Entra ID integration (Sessions 4-11)
public bool EntraGroupCheckEnabled { get; set; } = false;
public string EntraGroupCheckTenantId { get; set; } = string.Empty;
public string EntraGroupCheckClientId { get; set; } = string.Empty;

// Signature enforcement (Session 12)
public string SignatureEnforcement { get; set; } = "warn";
public string HashAlgorithm { get; set; } = "SHA-256";

// Distribution (stub for Phase B)
public DistributionConfig? Distribution { get; set; }
```

`DistributionConfig` is a stub class in the same file — empty for now, populated during Phase B API build.

`SchedulerService.cs` adds `using EndpointPilot.SystemAgent.Models;` and removes the inline class definition.

---

## Change 3: Clean Up ISchedulerService Legacy Methods

### Current State

`ISchedulerService` exposes 7 methods. Four are legacy redirects added for backward compatibility during the dual-context refactor:

- `ScheduleUserOperationsAsync` — redirects to `ScheduleDualContextOperationsAsync`
- `ScheduleSystemOperationsAsync` — no-ops
- `ExecuteUserOperationsNowAsync` — redirects to `ExecuteDualContextOperationsNowAsync`
- `ExecuteSystemOperationsNowAsync` — no-ops

No code outside `SchedulerService` itself calls these methods. `AgentWorker` only calls `StartAsync`, `StopAsync`, and `GetNextExecutionTimes`.

### New State

Remove all four legacy methods from both `ISchedulerService` and `SchedulerService`. Retained interface:

```csharp
public interface ISchedulerService
{
    Task StartAsync(CancellationToken cancellationToken = default);
    Task StopAsync(CancellationToken cancellationToken = default);
    Task ScheduleDualContextOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default);
    Task ExecuteDualContextOperationsNowAsync(CancellationToken cancellationToken = default);
    Dictionary<string, DateTime> GetNextExecutionTimes();
}
```

---

## Files Changed

| File                                          | Action                                                                                                             |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `SystemAgent/Services/PowerShellExecutor.cs`  | Remove allowlist + blocklist, add hash manifest loading + SHA-256 verification, update `ValidateScriptSafetyAsync` |
| `SystemAgent/Services/IPowerShellExecutor.cs` | No change (interface unchanged)                                                                                    |
| `SystemAgent/Services/ISchedulerService.cs`   | Remove 4 legacy method signatures                                                                                  |
| `SystemAgent/Services/SchedulerService.cs`    | Remove 4 legacy method implementations + remove `EndpointPilotConfig` class                                        |
| `SystemAgent/Models/EndpointPilotConfig.cs`   | New file — extracted + expanded config model                                                                       |
| `scripts/Generate-ScriptHashes.ps1`           | New file — hash manifest generator utility                                                                         |

## Files NOT Changed

| File                         | Reason                                                   |
| ---------------------------- | -------------------------------------------------------- |
| `AgentWorker.cs`             | Only calls Start/Stop/GetNextExecutionTimes — unaffected |
| `Program.cs`                 | DI registrations unchanged                               |
| `SystemOperationsService.cs` | Independent of script validation                         |
| `Models/SystemOperation.cs`  | Unrelated models                                         |

## Testing Notes

- C# changes are structural (compile-time verifiable) — no runtime testing needed on macOS
- `Generate-ScriptHashes.ps1` needs Windows VM testing (file I/O + hash computation)
- Hash verification logic in `PowerShellExecutor` needs Windows VM testing with a real `hashes.json`
- Graceful degradation path (missing `hashes.json`) should be tested by deleting the manifest and running the service

## Future Integration Points

- **Distribution API (Phase C):** When `DistributionService` syncs new script files from the API, it regenerates `hashes.json` automatically — same logic as `Generate-ScriptHashes.ps1` but in C#.
- **Deploy scripts:** Should call `Generate-ScriptHashes.ps1` after file copy steps. Exact integration deferred to when deploy scripts are next modified.
