# EndpointPilot — NinjaOne JSON Distribution Model

**Status:** Draft — May 2026
**Scope:** How JSON directive files reach NinjaOne-managed Windows endpoints and how endpoints report status back
**Out of scope:** Intune distribution (separate plan), initial EndpointPilot installation (see Installation Plan)

---

## Problem Statement

EndpointPilot processes JSON directive files (`*-OPS.json`) locally on each endpoint. The core scripts are installed once, but **directive files change over time** as IT admins add, modify, or remove operations (file copies, registry settings, drive mappings, etc.).

The project needs a defined model for:

1. How updated JSON directives reach endpoints at scale
2. How endpoints report execution status back to the admin
3. How targeting works (different configs for different device groups)
4. How this integrates with EndpointPilot's cryptographic signature system

**Design constraint:** No new infrastructure dependencies. NinjaOne is the RMM — use its native capabilities, not S3, Azure Blob, or external CDNs.

---

## Architecture Decision: File Transfer Automation + Custom Field Reporting

### Why File Transfer (not Script Variables or Custom Fields for delivery)

| Mechanism                    | Viable?           | Why / Why Not                                                                                                                                                                  |
| ---------------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **File Transfer Automation** | **Yes — Primary** | Direct file delivery to a known path. Preserves binary content (signatures intact). 200MB limit is ~20,000x larger than our files. Attachable to policies and scheduled tasks. |
| **Script Variables**         | Partial           | All values are strings; no documented size limit on content but designed for parameters, not file payloads. Fragile for multi-KB JSON with special characters.                 |
| **MultiLine Custom Field**   | Partial           | 10,000-char limit covers minified JSON but not signed JSON (signatures add ~1KB per entry). Better suited for status reporting.                                                |
| **WYSIWYG Custom Field**     | No                | 200,000-char limit is generous but WYSIWYG fields are HTML-oriented, not raw text. Encoding issues likely.                                                                     |
| **API pull from endpoint**   | No                | Requires embedding OAuth credentials on every endpoint. Violates security model.                                                                                               |
| **GitHub raw download**      | Backup only       | Requires network access + auth token management. Adds external dependency.                                                                                                     |

### Distribution Flow

```
Admin workstation                    NinjaOne Cloud                     Endpoint
─────────────────                    ──────────────                     ────────

1. Admin edits JSON directives
   (via JsonEditorTool or text editor)

2. Admin signs JSON entries
   (via signing script + certificate)

3. Admin uploads signed JSON files ──► NinjaOne Automation Library
   to NinjaOne File Transfer            (stored as File Transfer
   Automation                            automation assets)

4. Admin attaches File Transfer    ──► Policy / Scheduled Task
   to a policy targeting the             (targeting device group)
   appropriate device group

                                   5. NinjaOne agent pulls files ────► JSON files written to:
                                      on schedule                       %LOCALAPPDATA%\EndpointPilot\
                                                                        (user mode)
                                                                        — or —
                                                                        %PROGRAMDATA%\EndpointPilot\
                                                                        (system mode)

                                                                    6. EndpointPilot scheduled task
                                                                       runs, processes new JSON
                                                                       directives (signature
                                                                       validation enforced)

                                   7. NinjaOne receives status ◄──── 7. EndpointPilot writes
                                      via custom fields + exit code     status to NinjaOne custom
                                                                        fields via Ninja-Property-Set
```

---

## Detailed Design

### 1. JSON File Delivery

**Mechanism:** NinjaOne File Transfer Automation

Each `*-OPS.json` file is uploaded to NinjaOne as a separate File Transfer automation:

- `FILE-OPS.json` → File Transfer automation "EPilot-FileOps-Config"
- `REG-OPS.json` → File Transfer automation "EPilot-RegOps-Config"
- `DRIVE-OPS.json` → File Transfer automation "EPilot-DriveOps-Config"
- `SYSTEM-OPS.json` → File Transfer automation "EPilot-SysOps-Config"
- `CONFIG.json` → File Transfer automation "EPilot-Config" (rarely updated)

**Destination paths:**

| Mode        | Destination                     | NinjaOne Path Variable       |
| ----------- | ------------------------------- | ---------------------------- |
| User mode   | `%LOCALAPPDATA%\EndpointPilot\` | Use `%LOCALAPPDATA%` env var |
| System mode | `%PROGRAMDATA%\EndpointPilot\`  | Use `%PROGRAMDATA%` env var  |

**Naming convention for automations:** `EPilot-{Component}-Config` — consistent prefix enables filtering in the NinjaOne Automation Library.

**Update cadence:** File Transfers are idempotent — NinjaOne overwrites the destination file each run. This is safe because:

- The admin always uploads the complete, signed JSON file
- EndpointPilot validates signatures before processing
- No merge logic needed — the latest file is the source of truth

### 2. Targeting (Different Configs for Different Groups)

NinjaOne policies target **device groups**, which are dynamic (membership calculated at execution time based on criteria like OS version, location, custom field values, etc.).

**Recommended targeting model:**

| Scenario                      | NinjaOne Implementation                                                                                          |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Same config for all endpoints | Single policy with File Transfers, applied to "All Windows Desktops" group                                       |
| Different configs by location | Separate policies per location group, each with location-specific JSON files                                     |
| Different configs by role     | Device groups based on custom field "EndpointRole" (e.g., "Engineering", "Finance"), separate policies per group |
| Per-device overrides          | Device-level custom field containing override JSON (read via `Ninja-Property-Get` at runtime)                    |

**Per-device override mechanism (optional, future):**

For cases where a single endpoint needs a config variation, a MultiLine custom field (`EPilot_ConfigOverride`) could hold a small JSON snippet that EndpointPilot merges with the base file at runtime. This avoids creating a unique File Transfer per device.

```powershell
# Future: read per-device override from NinjaOne custom field
$override = Ninja-Property-Get "EPilot_ConfigOverride"
if ($override) {
    $overrideJson = $override | ConvertFrom-Json
    # Merge with base CONFIG.json
}
```

### 3. Status Reporting Back to NinjaOne

EndpointPilot needs to report execution results back so admins can monitor fleet health from the NinjaOne dashboard.

**Custom fields to create in NinjaOne:**

| Field Name             | Type                     | Scope  | Purpose                                                                     |
| ---------------------- | ------------------------ | ------ | --------------------------------------------------------------------------- |
| `EPilot_LastRunTime`   | DateTime                 | Device | Timestamp of last EndpointPilot execution                                   |
| `EPilot_LastRunStatus` | Text (200 chars)         | Device | "Success", "PartialFailure", "Failed", "SignatureError"                     |
| `EPilot_Version`       | Text (200 chars)         | Device | Installed EndpointPilot version string                                      |
| `EPilot_RunSummary`    | MultiLine (10,000 chars) | Device | JSON summary of last run (operations attempted, succeeded, failed, skipped) |
| `EPilot_SignatureMode` | Text (200 chars)         | Device | Current signature enforcement mode (strict/warn/disabled)                   |
| `EPilot_ConfigHash`    | Text (200 chars)         | Device | Hash of currently deployed CONFIG.json (for drift detection)                |

**PowerShell reporting snippet** (to be added to MAIN.PS1 post-execution):

```powershell
# Report status back to NinjaOne (only when running under NinjaOne agent)
if (Get-Command "Ninja-Property-Set" -ErrorAction SilentlyContinue) {
    Ninja-Property-Set "EPilot_LastRunTime" (Get-Date -Format "o")
    Ninja-Property-Set "EPilot_LastRunStatus" $runStatus
    Ninja-Property-Set "EPilot_Version" $epilotVersion
    Ninja-Property-Set "EPilot_RunSummary" ($runSummary | ConvertTo-Json -Compress)
    Ninja-Property-Set "EPilot_SignatureMode" $signatureConfig.EnforcementMode
    Ninja-Property-Set "EPilot_ConfigHash" $configHash
}
```

**Exit codes** for NinjaOne policy condition monitoring:

| Exit Code | Meaning                                        | NinjaOne Action  |
| --------- | ---------------------------------------------- | ---------------- |
| 0         | All operations succeeded                       | None (healthy)   |
| 1         | One or more operations failed                  | Alert (Warning)  |
| 2         | Signature validation failure                   | Alert (Critical) |
| 3         | Missing or corrupt JSON directives             | Alert (Critical) |
| 4         | EndpointPilot core error (module load failure) | Alert (Critical) |

**NinjaOne policy condition:** Create a Script Result Condition that triggers on exit code != 0, with severity mapped to the code.

### 4. Signature Preservation

NinjaOne File Transfer delivers files as binary blobs — no transformation, no encoding changes. This means:

- Cryptographic signatures in `*-OPS.json` files are preserved exactly
- No re-signing is needed after distribution
- The admin signs once on their workstation; endpoints validate the same signature

**Workflow integrity chain:**

```
Admin signs JSON ──► Upload to NinjaOne ──► Binary delivery to endpoint ──► Signature validation passes
```

This is a key advantage over mechanisms like Script Variables or Custom Fields, where string encoding could corrupt signature data.

### 5. Version / Drift Detection

**Problem:** How does an admin know if all endpoints have the latest JSON config?

**Solution:** Hash-based drift detection.

1. Admin's signing script calculates a SHA-256 hash of each JSON file and records it
2. EndpointPilot on each endpoint calculates the hash of its local JSON files
3. The hash is reported to NinjaOne via `EPilot_ConfigHash` custom field
4. Admin (or a NinjaOne monitoring script) compares endpoint hashes against the expected hash

```powershell
# Calculate config hash for drift detection
$configContent = Get-Content -Raw -Path (Join-Path $PSScriptRoot "CONFIG.json")
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($configContent))
$configHash = [BitConverter]::ToString($hashBytes) -replace '-', ''
```

**NinjaOne dashboard view:** Filter devices where `EPilot_ConfigHash` != expected hash to find endpoints with stale configs. This can also be automated via a NinjaOne condition that compares the field to an org-level custom field holding the expected hash.

---

## Admin Workflow — Day-to-Day Operations

### Updating a JSON Directive

1. **Edit** the `*-OPS.json` file on the admin workstation (via JsonEditorTool or text editor)
2. **Sign** the modified entries using the signing certificate
3. **Validate** locally: `.\Validate-JsonSchema.ps1 -ValidateAll`
4. **Upload** the signed JSON file to the corresponding NinjaOne File Transfer automation
5. **Wait** for the next scheduled run (or trigger an ad-hoc run for testing)
6. **Verify** via NinjaOne dashboard: check `EPilot_LastRunStatus` and `EPilot_ConfigHash` custom fields

### Adding a New Endpoint Group

1. **Create** a NinjaOne device group with the targeting criteria
2. **Create** group-specific `*-OPS.json` files (signed)
3. **Create** File Transfer automations for each JSON file
4. **Create** a policy targeting the device group, attach the File Transfers + EndpointPilot scheduled script
5. **Monitor** rollout via custom fields

### Responding to a Failed Run

1. **NinjaOne alert** fires (exit code != 0)
2. **Check** `EPilot_RunSummary` custom field for the device — shows which operations failed and why
3. **Check** `EPilot_SignatureMode` — if "strict" and signature failures occurred, verify signing certificate status
4. **Remediate** by fixing the JSON directive and re-pushing, or by running an ad-hoc script on the affected device

---

## NinjaOne Configuration Checklist

### Custom Fields to Create

- [ ] `EPilot_LastRunTime` — DateTime, Device scope, Automation read/write enabled
- [ ] `EPilot_LastRunStatus` — Text, Device scope, Automation read/write enabled
- [ ] `EPilot_Version` — Text, Device scope, Automation read/write enabled
- [ ] `EPilot_RunSummary` — MultiLine, Device scope, Automation read/write enabled
- [ ] `EPilot_SignatureMode` — Text, Device scope, Automation read/write enabled
- [ ] `EPilot_ConfigHash` — Text, Device scope, Automation read/write enabled
- [ ] `EPilot_ExpectedConfigHash` — Text, Organization scope (for drift comparison)

### File Transfer Automations to Create

- [ ] `EPilot-FileOps-Config` → delivers `FILE-OPS.json`
- [ ] `EPilot-RegOps-Config` → delivers `REG-OPS.json`
- [ ] `EPilot-DriveOps-Config` → delivers `DRIVE-OPS.json`
- [ ] `EPilot-SysOps-Config` → delivers `SYSTEM-OPS.json`
- [ ] `EPilot-Config` → delivers `CONFIG.json`

### Policy / Scheduled Task

- [ ] Create device group for test endpoints
- [ ] Create policy with File Transfers + EndpointPilot execution script
- [ ] Set schedule (recommended: every 4 hours for testing, daily for production)
- [ ] Create Script Result Condition for exit code != 0 with appropriate alerting

### Alerting

- [ ] Exit code 2 (signature failure) → Critical alert + ticket
- [ ] Exit code 3 (missing JSON) → Critical alert
- [ ] Exit code 1 (operation failure) → Warning alert
- [ ] Drift detection: `EPilot_ConfigHash` != `EPilot_ExpectedConfigHash` → Warning alert

---

## Future Considerations

### Intune Distribution (Separate Plan)

The same JSON files can be distributed via Intune using Win32 app packages (`.intunewin`) or Intune Proactive Remediations (detection script checks hash, remediation script pulls latest). The reporting model differs — Intune uses compliance policies and device configuration profiles rather than custom fields.

### CONFIG.json via Custom Field (Alternative)

For organizations that want to manage `CONFIG.json` skip flags dynamically without re-uploading files, the skip flags could be read from an organization-level NinjaOne custom field at runtime. This enables instant config changes without waiting for a File Transfer cycle.

### Hybrid NinjaOne + Intune

Some organizations may manage the same fleet with both NinjaOne and Intune. EndpointPilot should detect which management agent is present and report to the appropriate channel. The `Ninja-Property-Set` command check (shown in the reporting snippet) already handles this gracefully — it's a no-op when NinjaOne agent isn't present.
