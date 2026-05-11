# SystemAgent Pre-Build Cleanup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two bugs (script allowlist gap, malicious pattern false positives) and clean up two structural issues (misplaced config model, legacy interface methods) in preparation for the Distribution API build.

**Architecture:** Replace `PowerShellExecutor`'s hardcoded allowlist + pattern blocklist with a SHA-256 hash manifest (`hashes.json`). Extract `EndpointPilotConfig` to `Models/` with all missing CONFIG.json fields. Trim `ISchedulerService` to its actually-used surface.

**Tech Stack:** .NET 8 / C# (SystemAgent), PowerShell 5.1+ (hash generator utility)

**Spec:** `docs/specs/2026-05-10-systemagent-prebuild-cleanup-design.md`

---

## File Map

| File                                         | Action     | Responsibility                                                                    |
| -------------------------------------------- | ---------- | --------------------------------------------------------------------------------- |
| `SystemAgent/Models/EndpointPilotConfig.cs`  | **Create** | Config model extracted from SchedulerService + missing fields + Distribution stub |
| `SystemAgent/Models/ScriptHashManifest.cs`   | **Create** | Deserialization model for `hashes.json`                                           |
| `SystemAgent/Services/PowerShellExecutor.cs` | **Modify** | Remove allowlist + blocklist, add hash manifest loading + verification            |
| `SystemAgent/Services/ISchedulerService.cs`  | **Modify** | Remove 4 legacy method signatures                                                 |
| `SystemAgent/Services/SchedulerService.cs`   | **Modify** | Remove 4 legacy implementations + inline EndpointPilotConfig class                |
| `scripts/Generate-ScriptHashes.ps1`          | **Create** | Utility to generate `hashes.json` from installed scripts                          |

---

## Task 1: Create `ScriptHashManifest` Model

**Files:**

- Create: `SystemAgent/Models/ScriptHashManifest.cs`

- [ ] **Step 1: Create the model file**

```csharp
using Newtonsoft.Json;

namespace EndpointPilot.SystemAgent.Models;

/// <summary>
/// Deserialization model for hashes.json — maps script filenames to their SHA-256 hashes.
/// Used by PowerShellExecutor to verify script integrity before execution.
/// </summary>
public class ScriptHashManifest
{
    [JsonProperty("generatedAt")]
    public DateTime GeneratedAt { get; set; }

    [JsonProperty("hashAlgorithm")]
    public string HashAlgorithm { get; set; } = "SHA-256";

    [JsonProperty("scripts")]
    public Dictionary<string, string> Scripts { get; set; } = new();
}
```

- [ ] **Step 2: Verify file compiles in isolation**

Open `SystemAgent/Models/ScriptHashManifest.cs` in editor and confirm: correct namespace, no red squiggles on the `using` or `JsonProperty` attributes (Newtonsoft.Json is already a project dependency in `EndpointPilot.SystemAgent.csproj`).

- [ ] **Step 3: Commit**

```bash
git add SystemAgent/Models/ScriptHashManifest.cs
git commit -m "feat(SystemAgent): add ScriptHashManifest model for hashes.json"
```

---

## Task 2: Extract and Expand `EndpointPilotConfig` Model

**Files:**

- Create: `SystemAgent/Models/EndpointPilotConfig.cs`
- Modify: `SystemAgent/Services/SchedulerService.cs:264-288` (remove inline class)

- [ ] **Step 1: Create the extracted model file**

This model matches every field in `CONFIG.json` and `CONFIG.schema.json`, plus a `Distribution` stub for Phase B.

```csharp
using Newtonsoft.Json;

namespace EndpointPilot.SystemAgent.Models;

/// <summary>
/// Configuration model for EndpointPilot CONFIG.json.
/// Deserialized by SchedulerService and (future) DistributionService.
/// </summary>
public class EndpointPilotConfig
{
    [JsonProperty("OrgName")]
    public string OrgName { get; set; } = string.Empty;

    [JsonProperty("Refresh_Interval")]
    public int Refresh_Interval { get; set; } = 30;

    [JsonProperty("NetworkScriptRootPath")]
    public string NetworkScriptRootPath { get; set; } = string.Empty;

    [JsonProperty("NetworkScriptRootEnabled")]
    public bool NetworkScriptRootEnabled { get; set; } = false;

    [JsonProperty("HttpsScriptRootEnabled")]
    public bool HttpsScriptRootEnabled { get; set; } = false;

    [JsonProperty("HttpsScriptRootPath")]
    public string HttpsScriptRootPath { get; set; } = string.Empty;

    [JsonProperty("CopyLogFileToNetwork")]
    public bool CopyLogFileToNetwork { get; set; } = false;

    [JsonProperty("RoamFiles")]
    public bool RoamFiles { get; set; } = false;

    [JsonProperty("NetworkLogFile")]
    public string NetworkLogFile { get; set; } = string.Empty;

    [JsonProperty("NetworkRoamFolder")]
    public string NetworkRoamFolder { get; set; } = string.Empty;

    [JsonProperty("SkipFileOps")]
    public bool SkipFileOps { get; set; } = false;

    [JsonProperty("SkipDriveOps")]
    public bool SkipDriveOps { get; set; } = false;

    [JsonProperty("SkipRegOps")]
    public bool SkipRegOps { get; set; } = false;

    [JsonProperty("SkipRoamOps")]
    public bool SkipRoamOps { get; set; } = false;

    [JsonProperty("DryRun")]
    public bool DryRun { get; set; } = false;

    [JsonProperty("EnterpriseOnly")]
    public bool EnterpriseOnly { get; set; } = false;

    [JsonProperty("EntraClientId")]
    public string EntraClientId { get; set; } = string.Empty;

    [JsonProperty("EntraTenantId")]
    public string EntraTenantId { get; set; } = string.Empty;

    [JsonProperty("EntraTransitiveGroups")]
    public bool EntraTransitiveGroups { get; set; } = true;

    [JsonProperty("Distribution")]
    public DistributionConfig? Distribution { get; set; }
}

/// <summary>
/// Distribution API client configuration. Stub for Phase B — fields TBD during API design.
/// </summary>
public class DistributionConfig
{
    [JsonProperty("apiUrl")]
    public string ApiUrl { get; set; } = string.Empty;

    [JsonProperty("pollIntervalMinutes")]
    public int PollIntervalMinutes { get; set; } = 60;
}
```

- [ ] **Step 2: Remove the inline `EndpointPilotConfig` class from `SchedulerService.cs`**

Delete lines 265-288 of `SchedulerService.cs` — the entire block starting with `/// <summary>` above `public class EndpointPilotConfig` through the closing brace.

- [ ] **Step 3: Add using directive to `SchedulerService.cs`**

At the top of `SchedulerService.cs`, the existing `using EndpointPilot.SystemAgent.Models;` import is already present (line 1). Verify it's there — this gives `SchedulerService` access to the extracted `EndpointPilotConfig` class. No change needed if the using already exists.

- [ ] **Step 4: Verify no other files reference the old location**

Search the project for `EndpointPilotConfig` references. Only `SchedulerService.cs` uses it (in `LoadConfigurationAsync`). The using directive from Step 3 resolves the new location.

```bash
grep -rn "EndpointPilotConfig" SystemAgent/ --include="*.cs"
```

Expected: references in `SchedulerService.cs` (resolved by using) and `Models/EndpointPilotConfig.cs` (the new file).

- [ ] **Step 5: Commit**

```bash
git add SystemAgent/Models/EndpointPilotConfig.cs SystemAgent/Services/SchedulerService.cs
git commit -m "refactor(SystemAgent): extract EndpointPilotConfig to Models/ with missing fields"
```

---

## Task 3: Replace Allowlist + Blocklist with Hash Verification in `PowerShellExecutor`

**Files:**

- Modify: `SystemAgent/Services/PowerShellExecutor.cs`

This is the largest change. The `_allowedScripts` HashSet, `ContainsMaliciousPatterns()` method, and all pattern strings are removed. Replaced with hash manifest loading and SHA-256 verification.

- [ ] **Step 1: Remove the `_allowedScripts` field and its initialization**

In `PowerShellExecutor.cs`, remove the `_allowedScripts` field declaration (line 16) and its initialization block in the constructor (lines 24-35). Replace with hash manifest fields:

Replace:

```csharp
    private readonly HashSet<string> _allowedScripts;

    public PowerShellExecutor(ILogger<PowerShellExecutor> logger)
    {
        _logger = logger;
        _endpointPilotPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "EndpointPilot");

        // Initialize allowed scripts - only EndpointPilot scripts from secure locations
        _allowedScripts = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            Path.Combine(_endpointPilotPath, "MAIN.PS1"),
            Path.Combine(_endpointPilotPath, "MGMT-FileOps.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-RegOps.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-DriveOps.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-RoamOps.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-SchedTsk.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-Telemetry.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-USER-CUSTOM.ps1"),
            Path.Combine(_endpointPilotPath, "MGMT-Maint.ps1")
        };
    }
```

With:

```csharp
    private readonly string _hashManifestPath;
    private ScriptHashManifest? _hashManifest;

    public PowerShellExecutor(ILogger<PowerShellExecutor> logger)
    {
        _logger = logger;
        _endpointPilotPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "EndpointPilot");
        _hashManifestPath = Path.Combine(_endpointPilotPath, "hashes.json");
        LoadHashManifest();
    }
```

- [ ] **Step 2: Add `LoadHashManifest` method and update using directives**

Add `using EndpointPilot.SystemAgent.Models;` and `using System.Security.Cryptography;` to the top of the file (alongside existing usings). Then add the `LoadHashManifest` method to `PowerShellExecutor`:

```csharp
    private void LoadHashManifest()
    {
        try
        {
            if (!File.Exists(_hashManifestPath))
            {
                _logger.LogWarning(
                    "Script hash manifest not found at {ManifestPath}. " +
                    "Falling back to location-based validation only. " +
                    "Run Generate-ScriptHashes.ps1 to enable hash verification.",
                    _hashManifestPath);
                _hashManifest = null;
                return;
            }

            var json = File.ReadAllText(_hashManifestPath);
            _hashManifest = Newtonsoft.Json.JsonConvert.DeserializeObject<ScriptHashManifest>(json);

            if (_hashManifest?.Scripts == null || _hashManifest.Scripts.Count == 0)
            {
                _logger.LogWarning("Script hash manifest is empty or invalid. Falling back to location-based validation only.");
                _hashManifest = null;
                return;
            }

            _logger.LogInformation(
                "Loaded script hash manifest with {Count} entries (generated {GeneratedAt})",
                _hashManifest.Scripts.Count, _hashManifest.GeneratedAt);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading script hash manifest. Falling back to location-based validation only.");
            _hashManifest = null;
        }
    }
```

- [ ] **Step 3: Add `ComputeFileHashAsync` method**

Add this private method to `PowerShellExecutor`:

```csharp
    private static async Task<string> ComputeFileHashAsync(string filePath)
    {
        using var sha256 = SHA256.Create();
        await using var stream = File.OpenRead(filePath);
        var hash = await sha256.ComputeHashAsync(stream);
        return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
    }
```

- [ ] **Step 4: Rewrite `ValidateScriptSafetyAsync`**

Replace the entire existing `ValidateScriptSafetyAsync` method (lines 286-327) with:

```csharp
    public async Task<bool> ValidateScriptSafetyAsync(string scriptPath)
    {
        try
        {
            if (!File.Exists(scriptPath))
            {
                _logger.LogWarning("Script file does not exist: {ScriptPath}", scriptPath);
                return false;
            }

            if (!IsSecureLocation(Path.GetDirectoryName(scriptPath)))
            {
                _logger.LogWarning("Script not in secure location: {ScriptPath}", scriptPath);
                return false;
            }

            if (_hashManifest == null)
            {
                _logger.LogDebug("No hash manifest loaded — accepting script from secure location: {ScriptPath}", scriptPath);
                return true;
            }

            var fileName = Path.GetFileName(scriptPath);
            if (!_hashManifest.Scripts.TryGetValue(fileName, out var expectedHash))
            {
                _logger.LogWarning("Script not found in hash manifest: {FileName}", fileName);
                return false;
            }

            var actualHash = await ComputeFileHashAsync(scriptPath);
            if (!string.Equals(actualHash, expectedHash, StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning(
                    "Script hash mismatch for {FileName}. Expected: {Expected}, Actual: {Actual}",
                    fileName, expectedHash, actualHash);
                return false;
            }

            _logger.LogDebug("Script hash verified: {FileName}", fileName);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating script safety: {ScriptPath}", scriptPath);
            return false;
        }
    }
```

- [ ] **Step 5: Remove `ContainsMaliciousPatterns` method**

Delete the entire `ContainsMaliciousPatterns` method (lines 370-392):

```csharp
    // DELETE THIS ENTIRE METHOD:
    private static bool ContainsMaliciousPatterns(string content)
    {
        // Basic pattern matching for obviously malicious content
        var maliciousPatterns = new[]
        {
            "Invoke-Expression",
            "IEX ",
            "DownloadString",
            "DownloadFile",
            "Net.WebClient",
            "System.Net.WebClient",
            "Invoke-RestMethod",
            "Invoke-WebRequest",
            "Start-Process.*cmd.*",
            "cmd.exe.*\\/c",
            "powershell.*-EncodedCommand",
            "FromBase64String",
            "System.Convert::FromBase64String"
        };

        return maliciousPatterns.Any(pattern =>
            content.Contains(pattern, StringComparison.OrdinalIgnoreCase));
    }
```

- [ ] **Step 6: Verify remaining code compiles**

Confirm that `ValidateScriptSafetyAsync` no longer references `_allowedScripts` or `ContainsMaliciousPatterns`. The three callers (`ExecuteAsSystemAsync`, `ExecuteAsUserAsync`, `ExecuteAsElevatedAsync`) call `ValidateScriptSafetyAsync` — their call sites don't change.

```bash
grep -n "_allowedScripts\|ContainsMaliciousPatterns\|maliciousPatterns" SystemAgent/Services/PowerShellExecutor.cs
```

Expected: no matches.

- [ ] **Step 7: Commit**

```bash
git add SystemAgent/Services/PowerShellExecutor.cs
git commit -m "fix(SystemAgent): replace script blocklist with SHA-256 hash manifest verification

Removes static allowlist (which was missing ENDPOINT-PILOT.PS1) and
pattern blocklist (which false-positived on Invoke-RestMethod used by
Entra integration). Scripts are now verified against hashes.json.
Gracefully degrades to location-only validation when manifest is absent."
```

---

## Task 4: Clean Up `ISchedulerService` Legacy Methods

**Files:**

- Modify: `SystemAgent/Services/ISchedulerService.cs`
- Modify: `SystemAgent/Services/SchedulerService.cs`

- [ ] **Step 1: Remove 4 legacy method signatures from `ISchedulerService.cs`**

Remove these four method declarations and their XML doc comments from the interface:

```csharp
    // DELETE: lines 24-32 (ScheduleUserOperationsAsync)
    /// <summary>
    /// Schedules user-mode operations to run at specified intervals
    /// </summary>
    /// <param name="interval">Interval between runs</param>
    /// <param name="cancellationToken">Cancellation token</param>
    Task ScheduleUserOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default);

    // DELETE: lines 34-42 (ScheduleSystemOperationsAsync)
    /// <summary>
    /// Schedules system-mode operations to run at specified intervals
    /// </summary>
    /// <param name="interval">Interval between runs</param>
    /// <param name="cancellationToken">Cancellation token</param>
    Task ScheduleSystemOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default);

    // DELETE: lines 50-57 (ExecuteUserOperationsNowAsync)
    /// <summary>
    /// Forces an immediate execution of user operations
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    Task ExecuteUserOperationsNowAsync(CancellationToken cancellationToken = default);

    // DELETE: lines 59-66 (ExecuteSystemOperationsNowAsync)  (renumbered — was after ExecuteUserOperationsNowAsync)
    /// <summary>
    /// Forces an immediate execution of system operations
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    Task ExecuteSystemOperationsNowAsync(CancellationToken cancellationToken = default);
```

The retained interface should be:

```csharp
namespace EndpointPilot.SystemAgent.Services;

public interface ISchedulerService
{
    Task StartAsync(CancellationToken cancellationToken = default);

    Task StopAsync(CancellationToken cancellationToken = default);

    Task ScheduleDualContextOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default);

    Task ExecuteDualContextOperationsNowAsync(CancellationToken cancellationToken = default);

    Dictionary<string, DateTime> GetNextExecutionTimes();
}
```

- [ ] **Step 2: Remove 4 legacy method implementations from `SchedulerService.cs`**

Remove these four methods from `SchedulerService` (lines 189-223):

```csharp
    // DELETE: ScheduleUserOperationsAsync (lines 189-194)
    public async Task ScheduleUserOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Legacy ScheduleUserOperationsAsync called - redirecting to dual-context scheduling");
        await ScheduleDualContextOperationsAsync(interval, cancellationToken);
    }

    // DELETE: ScheduleSystemOperationsAsync (lines 199-204)
    public async Task ScheduleSystemOperationsAsync(TimeSpan interval, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Legacy ScheduleSystemOperationsAsync called - dual-context already handles this");
        await Task.CompletedTask;
    }

    // DELETE: ExecuteUserOperationsNowAsync (lines 209-214)
    public async Task ExecuteUserOperationsNowAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Legacy ExecuteUserOperationsNowAsync called - executing dual-context");
        await ExecuteDualContextOperationsNowAsync(cancellationToken);
    }

    // DELETE: ExecuteSystemOperationsNowAsync (lines 219-224)
    public async Task ExecuteSystemOperationsNowAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Legacy ExecuteSystemOperationsNowAsync called - dual-context already handles this");
        await Task.CompletedTask;
    }
```

- [ ] **Step 3: Verify no callers reference removed methods**

```bash
grep -rn "ScheduleUserOperationsAsync\|ScheduleSystemOperationsAsync\|ExecuteUserOperationsNowAsync\|ExecuteSystemOperationsNowAsync" SystemAgent/ --include="*.cs"
```

Expected: no matches. `AgentWorker.cs` only calls `StartAsync`, `StopAsync`, and `GetNextExecutionTimes`.

- [ ] **Step 4: Commit**

```bash
git add SystemAgent/Services/ISchedulerService.cs SystemAgent/Services/SchedulerService.cs
git commit -m "refactor(SystemAgent): remove 4 legacy ISchedulerService redirect methods

ScheduleUserOperationsAsync, ScheduleSystemOperationsAsync,
ExecuteUserOperationsNowAsync, ExecuteSystemOperationsNowAsync were
no-ops or redirects to DualContext equivalents. No callers outside
SchedulerService itself."
```

---

## Task 5: Create `Generate-ScriptHashes.ps1` Utility

**Files:**

- Create: `scripts/Generate-ScriptHashes.ps1`

- [ ] **Step 1: Write the script**

```powershell
<#
.SYNOPSIS
    Generates hashes.json manifest for EndpointPilot script integrity verification.

.DESCRIPTION
    Scans the EndpointPilot install directory for .ps1 and .psm1 files, computes
    SHA-256 hashes, and writes a hashes.json manifest. The SystemAgent's
    PowerShellExecutor uses this manifest to verify script integrity before execution.

    Run this script after installing or updating EndpointPilot scripts.

.PARAMETER InstallPath
    Path to the EndpointPilot install directory.
    Default: $env:ProgramData\EndpointPilot

.PARAMETER OutputPath
    Path to write the hashes.json manifest.
    Default: $InstallPath\hashes.json

.EXAMPLE
    .\Generate-ScriptHashes.ps1
    Generates hashes.json in the default install location.

.EXAMPLE
    .\Generate-ScriptHashes.ps1 -InstallPath "C:\Test\EndpointPilot" -OutputPath "C:\Test\hashes.json"
    Generates hashes.json for a custom install location.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallPath = (Join-Path $env:ProgramData "EndpointPilot"),

    [Parameter()]
    [string]$OutputPath
)

if (-not $OutputPath) {
    $OutputPath = Join-Path $InstallPath "hashes.json"
}

if (-not (Test-Path $InstallPath)) {
    Write-Error "Install path does not exist: $InstallPath"
    exit 1
}

$scriptFiles = Get-ChildItem -Path $InstallPath -Include "*.ps1", "*.psm1" -File
if ($scriptFiles.Count -eq 0) {
    Write-Warning "No .ps1 or .psm1 files found in: $InstallPath"
    exit 1
}

$hashes = [ordered]@{}
foreach ($file in ($scriptFiles | Sort-Object Name)) {
    $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashes[$file.Name] = $hash
    Write-Verbose "  $($file.Name): $hash"
}

$manifest = [ordered]@{
    generatedAt   = (Get-Date -Format "o")
    hashAlgorithm = "SHA-256"
    scripts       = $hashes
}

$json = $manifest | ConvertTo-Json -Depth 3
Set-Content -Path $OutputPath -Value $json -Encoding UTF8

Write-Host "Generated hashes.json with $($hashes.Count) entries at: $OutputPath"
```

- [ ] **Step 2: Commit**

```bash
git add scripts/Generate-ScriptHashes.ps1
git commit -m "feat: add Generate-ScriptHashes.ps1 utility for script integrity manifest

Creates hashes.json with SHA-256 hashes of all .ps1/.psm1 files in the
EndpointPilot install directory. Used by SystemAgent PowerShellExecutor
to verify script integrity before execution. Deploy scripts should call
this after copying/updating script files."
```

---

## Task 6: Final Verification

- [ ] **Step 1: Verify no stale references remain**

```bash
grep -rn "_allowedScripts\|ContainsMaliciousPatterns\|maliciousPatterns" SystemAgent/ --include="*.cs"
grep -rn "ScheduleUserOperationsAsync\|ScheduleSystemOperationsAsync\|ExecuteUserOperationsNowAsync\|ExecuteSystemOperationsNowAsync" SystemAgent/ --include="*.cs"
```

Expected: zero matches for both.

- [ ] **Step 2: Verify model consistency**

```bash
grep -rn "EndpointPilotConfig" SystemAgent/ --include="*.cs"
```

Expected: references in `Models/EndpointPilotConfig.cs` (definition) and `Services/SchedulerService.cs` (usage via `using EndpointPilot.SystemAgent.Models`).

- [ ] **Step 3: Review complete diff**

```bash
git diff HEAD~5 --stat
git diff HEAD~5
```

Confirm all changes are accounted for: 2 new model files, 1 new script, 3 modified service files.

- [ ] **Step 4: Tag for VM testing**

The following need Windows VM testing:

- `Generate-ScriptHashes.ps1`: run on VM, verify `hashes.json` output format
- SystemAgent with `hashes.json` present: verify scripts pass hash validation
- SystemAgent without `hashes.json`: verify graceful degradation (location-only, warning logged)
- SystemAgent with tampered script: verify hash mismatch rejection
