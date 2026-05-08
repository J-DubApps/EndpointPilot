# Design Spec: Entra ID Graph Integration (Phase 2 of Resolve-GroupMembership)

**Date:** May 8, 2026
**Status:** Approved for implementation
**Scope:** Replace `Test-EntraGroupMembership` stub with real Microsoft Graph `/me/memberOf` calls using MSAL.NET + WAM for silent PRT-based token acquisition

---

## Problem

`Resolve-GroupMembership` has a three-step fallback chain: AD token check, Entra ID check, local group check. Step 2 (Entra) is currently a stub that returns `$null`, meaning any endpoint that isn't domain-joined has no way to resolve cloud security group membership. This affects BYOD, Entra-joined, and hybrid-joined endpoints that are off-network.

## Solution

Wire up `Test-EntraGroupMembership` to call Microsoft Graph using MSAL.NET with the WAM broker for silent, PRT-based token acquisition. MSAL.NET DLLs are bundled with EndpointPilot (no runtime downloads, no PSGallery modules). The admin registers a single app in Entra and puts the client/tenant IDs in CONFIG.json.

## Decisions Made

| Decision          | Choice                | Rationale                                                                                                                                                                                                        |
| ----------------- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Token acquisition | MSAL.NET + WAM broker | Officially supported by Microsoft; WAM is already on every Entra-joined device; PRT-based silent auth without user interaction. Raw PRT cookie flow was considered but rejected as undocumented and fragile.     |
| App registration  | CONFIG.json fields    | Admin registers app once in Entra portal, puts IDs in config. Clean separation of concerns.                                                                                                                      |
| Query pattern     | Fetch-all + cache     | Single `/me/memberOf` call per EP run. Cache all group displayNames. Subsequent checks are O(1) hashtable lookups. Matches existing caching patterns (`$script:JoinStateCache`, `$script:GroupMembershipCache`). |
| Nested groups     | Configurable          | `EntraTransitiveGroups` flag in CONFIG.json. `true` (default) uses `/me/transitiveMemberOf`; `false` uses `/me/memberOf`.                                                                                        |
| Output format     | REG-OPS compatible    | ADMX-sourced settings will produce standard REG-OPS entries with targeting. Entra group resolution is a prerequisite for that targeting to work on cloud-only endpoints.                                         |

---

## Architecture

### Component Diagram

```
CONFIG.json
  ├── EntraClientId          "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  ├── EntraTenantId          "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
  └── EntraTransitiveGroups  true

MGMT-Functions.psm1
  ├── Get-EntraAccessToken()          MSAL → WAM → PRT → access token
  │     └── uses: lib/msal/*.dll       bundled, loaded via Add-Type
  ├── Get-EntraGroupMemberships()     Graph API → cached displayName set
  │     └── uses: $script:EntraGroupCache
  ├── Test-EntraGroupMembership()     matches GroupName against cache
  │     └── returns: $true / $false / $null
  └── Resolve-GroupMembership()       UNCHANGED — already calls Test-EntraGroupMembership
```

### Bundled MSAL Files

Stored at `lib/msal/` relative to the EndpointPilot install root, with platform subdirectories:

```
lib/msal/
  ├── net462/
  │   ├── Microsoft.Identity.Client.dll          (~1.5MB, managed)
  │   └── Microsoft.Identity.Client.Broker.dll   (~100KB, managed)
  ├── runtimes/win-x64/native/
  │   └── msalruntime.dll                        (~800KB, native WAM bridge)
  └── runtimes/win-arm64/native/
      └── msalruntime.dll                        (~800KB, native WAM bridge)
```

The `net462` target matches PowerShell 5.1's .NET Framework 4.6.2+ runtime. The native `msalruntime.dll` is platform-specific and loaded automatically by the managed DLLs based on the process architecture.

These files are sourced from the `Microsoft.Identity.Client` and `Microsoft.Identity.Client.Broker` NuGet packages and checked into the repo under `lib/msal/`. No runtime NuGet resolution needed.

---

## New Functions

### `Get-EntraAccessToken`

**Purpose:** Acquire a Microsoft Graph access token silently using MSAL.NET + WAM broker.

**Parameters:** None. Reads `$global:EntraClientId`, `$global:EntraTenantId` from config (set in MGMT-SHARED.ps1 as global variables, consistent with the existing `$global:DryRunMode` pattern for cross-scope access from module functions).

**Returns:** Access token string, or `$null` if acquisition fails.

**Behavior:**

1. Check that `$global:EntraClientId` and `$global:EntraTenantId` are non-empty. Return `$null` if missing (Entra not configured).
2. Load MSAL DLLs via `Add-Type` if not already loaded (idempotent).
3. Build a `PublicClientApplication` with WAM broker enabled and the configured authority (`https://login.microsoftonline.com/{tenantId}`).
4. Call `AcquireTokenSilent` with scope `https://graph.microsoft.com/GroupMember.Read.All` and the WAM operating system account.
5. If silent acquisition fails (no cached account, expired PRT), catch the `MsalUiRequiredException` and log a warning. Return `$null`.
6. Cache the token result in `$script:EntraTokenCache` for the duration of the EP run.
7. Return the access token string.

**Error handling:**

- `MsalUiRequiredException` — user interaction needed (no PRT, conditional access). Log warning, return `$null`.
- `MsalServiceException` — Entra service error (network, throttle). Log warning with status code, return `$null`.
- Any other exception — log error, return `$null`.
- All failures result in `$null`, which preserves the fallback-chain contract.

**Not exported.** Internal to the module.

### `Get-EntraGroupMemberships`

**Purpose:** Fetch all Entra security group memberships for the current user, cache for the run.

**Parameters:** None.

**Returns:** Hashtable of group display names (keys) for O(1) lookup, or `$null` if the call fails.

**Behavior:**

1. Return `$script:EntraGroupCache` if already populated (cache hit).
2. Call `Get-EntraAccessToken`. Return `$null` if token is `$null`.
3. Build the Graph URL based on `EntraTransitiveGroups` config flag:
    - `true` (default): `https://graph.microsoft.com/v1.0/me/transitiveMemberOf`
    - `false`: `https://graph.microsoft.com/v1.0/me/memberOf`
4. Add query parameters: `$select=displayName,id,@odata.type` and `$top=999`.
5. Call `Invoke-RestMethod` with `Authorization: Bearer {token}` header.
6. Filter results to `#microsoft.graph.group` objects only (exclude directory roles, admin units).
7. Handle pagination: follow `@odata.nextLink` until exhausted.
8. Build hashtable from `displayName` values. Store in `$script:EntraGroupCache`.
9. Log count: `"INFO: Cached {n} Entra group memberships for this run."`
10. Return the hashtable.

**Error handling:**

- HTTP 401 — token expired mid-request (shouldn't happen with fresh token). Log, return `$null`.
- HTTP 403 — app lacks `GroupMember.Read.All`. Log error with specific remediation guidance ("Check app registration API permissions in Entra portal"). Return `$null`.
- HTTP 429 — Graph throttling. Log warning with `Retry-After` header value. Return `$null`.
- Network failure — log warning, return `$null`.

**Not exported.** Internal to the module.

### Updated `Test-EntraGroupMembership`

**Purpose:** Check if the current user is a member of a specific Entra security group.

**Parameters:**

- `GroupName` (string, mandatory) — display name of the group to check.
- `JoinState` (PSCustomObject, mandatory) — from `Get-EndpointJoinState`.

**Returns:** `$true` if member, `$false` if not, `$null` if check could not be performed.

**Behavior:**

1. If `EntraClientId` is empty/not set, return `$null` immediately (Entra not configured — same as current stub).
2. If `$JoinState.AzureAdJoined` is `$false` AND `$JoinState.AzureAdPrt` is `$false`, return `$null` (no Entra context on this device — same as current stub).
3. Call `Get-EntraGroupMemberships`. If `$null`, return `$null` (token or API failure).
4. Check if `$GroupName` exists as a key in the returned hashtable.
5. Return `$true` or `$false`.

**Not exported** (already internal, called by `Resolve-GroupMembership`).

---

## CONFIG.json Changes

### New Fields

| Field                   | Type    | Default | Required | Description                                                                                              |
| ----------------------- | ------- | ------- | -------- | -------------------------------------------------------------------------------------------------------- |
| `EntraClientId`         | string  | `""`    | No       | Entra app registration client ID. Empty string means Entra group checks are disabled.                    |
| `EntraTenantId`         | string  | `""`    | No       | Entra tenant ID. Required when `EntraClientId` is set.                                                   |
| `EntraTransitiveGroups` | boolean | `true`  | No       | When `true`, resolve nested/transitive group memberships. When `false`, resolve direct memberships only. |

### Updated CONFIG.json

```json
{
    "OrgName": "Company Name",
    "Refresh_Interval": 900,
    "NetworkScriptRootPath": "\\\\servername\\SHARE\\PS-EPilot\\",
    "NetworkScriptRootEnabled": false,
    "HttpsScriptRootEnabled": false,
    "HttpsScriptRootPath": "https://servername/SHARE/PS-EPilot/",
    "CopyLogFileToNetwork": false,
    "RoamFiles": false,
    "NetworkLogFile": "\\\\servername\\SHARE\\Tools\\FlagFiles\\EPilot_Script_RunLogs",
    "NetworkRoamFolder": "\\\\servername\\SHARE\\RoamingFiles",
    "SkipFileOps": false,
    "SkipDriveOps": false,
    "SkipRegOps": false,
    "SkipRoamOps": false,
    "DryRun": false,
    "EnterpriseOnly": false,
    "EntraClientId": "",
    "EntraTenantId": "",
    "EntraTransitiveGroups": true
}
```

### CONFIG.schema.json Additions

```json
"EntraClientId": {
  "type": "string",
  "description": "Entra ID app registration client ID for Graph API group membership checks. Leave empty to disable Entra group checks."
},
"EntraTenantId": {
  "type": "string",
  "description": "Entra ID tenant ID. Required when EntraClientId is configured."
},
"EntraTransitiveGroups": {
  "type": "boolean",
  "description": "When true (default), resolve nested/transitive Entra group memberships. When false, resolve direct memberships only."
}
```

---

## Entra App Registration Requirements

The admin performs this setup once per tenant:

1. **Azure Portal** > App registrations > New registration
    - Name: `EndpointPilot Group Reader` (or similar)
    - Supported account types: Single tenant
    - Redirect URI: `https://login.microsoftonline.com/common/oauth2/nativeclient` (public client)
2. **API permissions** > Add a permission > Microsoft Graph > Delegated
    - `GroupMember.Read.All` — read group memberships
    - Grant admin consent for the tenant
3. **Authentication** > Allow public client flows: Yes (enables WAM broker)
4. Copy the **Application (client) ID** and **Directory (tenant) ID** into CONFIG.json

This is a read-only, delegated permission. The app cannot modify groups, users, or any directory data.

---

## Caching Strategy

Three cache layers, all scoped to a single EP run:

| Cache             | Variable                       | Populated By                | Contents                                    |
| ----------------- | ------------------------------ | --------------------------- | ------------------------------------------- |
| Join state        | `$script:JoinStateCache`       | `Get-EndpointJoinState`     | dsregcmd parsed state (existing)            |
| Access token      | `$script:EntraTokenCache`      | `Get-EntraAccessToken`      | MSAL token result (token + expiry)          |
| Group memberships | `$script:EntraGroupCache`      | `Get-EntraGroupMemberships` | Hashtable of displayName keys               |
| Per-group result  | `$script:GroupMembershipCache` | `Resolve-GroupMembership`   | IsMember/Source/Reason per group (existing) |

No cache persists across EP runs. MSAL's internal token cache (in-memory) may retain the refresh token for the duration of the process, but since EP runs are short-lived scheduled tasks, this is effectively per-run.

---

## MGMT-SHARED.ps1 Changes

Add config value extraction for the new fields. These use `$global:` scope (like `$global:DryRunMode`) because `Get-EntraAccessToken` runs inside the MGMT-Functions.psm1 module scope and needs cross-scope access:

```powershell
$global:EntraClientId = if ($config.EntraClientId) { $config.EntraClientId } else { "" }
$global:EntraTenantId = if ($config.EntraTenantId) { $config.EntraTenantId } else { "" }
$global:EntraTransitiveGroups = if ($null -ne $config.EntraTransitiveGroups) { $config.EntraTransitiveGroups } else { $true }
```

---

## Dry-Run Behavior

`Get-EntraAccessToken` and `Get-EntraGroupMemberships` are **read-only operations** — they don't mutate anything on the endpoint or in Entra. Therefore they execute normally in dry-run mode. The dry-run guard is already in the consuming code (DriveOps, FileOps, RegOps) which skips the actual operation, not the group check.

Log messages during dry-run include the `[DRY-RUN]` prefix as usual, so the admin can see that group resolution was attempted and what it returned.

---

## Test Plan

### 1. Smoke Test Script: `tests/smoke/Smoke-EntraGraph.ps1`

A standalone script Julian runs on the Windows VM to validate MSAL + Graph integration before it's wired into the full EP flow.

Tests:

- MSAL DLL loading (`Add-Type` succeeds)
- WAM broker initialization (PublicClientApplication builds without error)
- Token acquisition (silent via PRT — requires Entra-joined VM)
- Graph API call (`/me/transitiveMemberOf` returns data)
- Group displayName extraction and cache population
- Known group membership check (positive and negative)
- Fallback behavior when EntraClientId is empty
- Fallback behavior on non-Entra device (workplace-joined only)

### 2. Integration with Existing Smoke Test

Extend `tests/smoke/Smoke-DriveOps-GroupCheck.ps1` with Entra-targeted test cases once the smoke test above passes.

### 3. VM Requirements for Testing

- Windows 11 VM that is **Entra-joined** (not just workplace-joined) — needs a full PRT for WAM silent auth
- A test Entra security group with the VM user as a member
- The EndpointPilot app registration created in the Entra tenant
- Current test VM is workplace-joined only — may need an Entra-joined VM for full validation

---

## Failure Modes and Fallback Behavior

| Scenario                           | What Happens                                | User-Visible Effect                                     |
| ---------------------------------- | ------------------------------------------- | ------------------------------------------------------- |
| `EntraClientId` empty              | `Test-EntraGroupMembership` returns `$null` | Falls through to local group check (same as today)      |
| Device not Entra-joined, no PRT    | Returns `$null`                             | Falls through to local group check                      |
| MSAL DLLs missing from `lib/msal/` | `Add-Type` fails, logged, returns `$null`   | Falls through; log message guides remediation           |
| PRT expired or no cached account   | `MsalUiRequiredException`, returns `$null`  | Falls through; log suggests re-signing in               |
| App lacks `GroupMember.Read.All`   | HTTP 403 from Graph, returns `$null`        | Falls through; log message names the missing permission |
| Graph API throttled (429)          | Returns `$null`                             | Falls through; retries on next EP run                   |
| Network unreachable                | `Invoke-RestMethod` fails, returns `$null`  | Falls through to local group check                      |
| Group name not in Entra            | Returns `$false` (definitive)               | Directive is skipped with clear reason                  |
| Group name found in Entra          | Returns `$true` (definitive)                | Directive executes                                      |

In every failure case, the existing fallback chain ensures the endpoint still gets _some_ group resolution (local groups) or a clear "no authority available" message. No failure in the Entra path blocks EP execution.

---

## Files Modified

| File                               | Change                                                                                                                                                                 |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MGMT-Functions.psm1`              | Replace `Test-EntraGroupMembership` stub. Add `Get-EntraAccessToken`, `Get-EntraGroupMemberships`. Add `$script:EntraTokenCache`, `$script:EntraGroupCache` variables. |
| `MGMT-SHARED.ps1`                  | Add `$EntraClientId`, `$EntraTenantId`, `$EntraTransitiveGroups` config extraction.                                                                                    |
| `CONFIG.json`                      | Add `EntraClientId`, `EntraTenantId`, `EntraTransitiveGroups` fields.                                                                                                  |
| `CONFIG.schema.json`               | Add schema definitions for new fields.                                                                                                                                 |
| `lib/msal/`                        | New directory with bundled MSAL.NET DLLs (net462 + native runtimes).                                                                                                   |
| `tests/smoke/Smoke-EntraGraph.ps1` | New smoke test script for VM validation.                                                                                                                               |

## Files NOT Modified

| File                      | Why                                                                                                                        |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `Resolve-GroupMembership` | Already wired correctly — calls `Test-EntraGroupMembership` and handles `$null`/`$true`/`$false` returns.                  |
| `Get-EndpointJoinState`   | Already detects `AzureAdJoined` and `AzureAdPrt`.                                                                          |
| `Export-ModuleMember`     | New functions are internal — not exported.                                                                                 |
| `MAIN.PS1`                | No changes needed — group resolution is called by helpers (DriveOps, etc.), not by the orchestrator.                       |
| `deploy/` scripts         | MSAL DLLs are in `lib/msal/` which is inside the install directory. Existing install scripts copy the full directory tree. |

---

## Open Questions (None)

All design questions were resolved during brainstorming. Implementation can proceed.
