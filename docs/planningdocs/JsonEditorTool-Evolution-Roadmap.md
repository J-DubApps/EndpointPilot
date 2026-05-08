# JsonEditorTool Evolution Roadmap

**Created:** May 8, 2026
**Status:** Planning (not active sprint work)
**Prerequisite:** Current sprint fundamentals complete (Entra ID Graph integration, FileOps/RegOps targeting retrofit, full dry-run validation)

This document captures the next major phases for the JsonEditorTool beyond its current WPF/.NET 8 implementation. The original build plan is in [EndpointPilot-JSON-Editor-Plan.md](EndpointPilot-JSON-Editor-Plan.md).

---

## Phase A: Code Review of Existing JsonEditorTool

**Priority:** First — do this before adding new capabilities.

The WPF solution (`JsonEditorTool/EndpointPilotJsonEditor.sln`) was built in 2025. Before extending it, conduct a thorough code review covering:

- **Architecture health:** MVVM separation, ViewModel base class usage, command patterns (`RelayCommand`), data binding hygiene
- **Schema validation:** How `Newtonsoft.Json.Schema` is wired up, whether validation errors surface clearly in the UI
- **Signing integration:** Review `JsonEditorToolSigningIntegration.Tests.cs` — does the editor properly support the SHA-256/RSA-2048 signing workflow?
- **Missing editor coverage:** DriveOps editor (`DriveOpsEditorViewModel.cs`) exists but was built against the old placeholder. Now that MGMT-DriveOps.ps1 is fully implemented with targeting, hidden drives, and reconnect semantics, the editor likely needs updates to match.
- **Code quality:** Null handling, async patterns, error states, test coverage gaps
- **Dependency currency:** .NET version, NuGet package versions, any deprecated APIs

### Current Solution Structure

```
JsonEditorTool/
├── EndpointPilotJsonEditor.sln
├── EndpointPilotJsonEditor.App/          # WPF UI layer
│   ├── ViewModels/                       # ConfigEditor, FileOps, RegOps, DriveOps, Main
│   ├── Views/
│   ├── Converters/
│   └── MainWindow.xaml
├── EndpointPilotJsonEditor.Core/         # Business logic
│   ├── Models/
│   └── Services/
├── JsonEditorToolSigningIntegration.Tests.cs
├── bin/                                  # Pre-built binaries (x64, ARM64)
└── publish/                              # Publish artifacts
```

---

## Phase B: ADMX Ingestion for HKCU Registry Management

**Priority:** Second — after code review, this is the major feature addition.

### Concept

Windows Group Policy uses ADMX/ADML files to define registry-backed policy settings. Many HKCU policies are simple registry writes (e.g., disabling OneDrive sync, setting browser homepage, configuring Office telemetry). EndpointPilot already manages HKCU registry via REG-OPS.json — but admins currently need to manually look up the registry paths and values from ADMX documentation.

### Vision: GPMC-Like Management With Per-Group Targeting

The intent is to replicate, in principle, what GPMC provides for domain-joined environments — but for BYOD and non-AD-joined endpoints that GPO can't reach. Critically, this goes **beyond** what GPMC offers natively:

**The GPMC targeting gap:** When an admin configures a policy via ADMX in the Group Policy Management Console, that policy applies to _every user/computer_ the GPO is linked to. GPMC has no built-in mechanism to say "apply this ADMX-defined setting to Group X only." Achieving per-group targeting in native GPO requires dropping down to Group Policy Preferences (GPP) and manually creating registry entries with item-level targeting — a completely separate workflow from the ADMX policy UI.

**What EndpointPilot bridges:** ADMX-sourced settings are translated into REG-OPS directives, which already support `targeting_type` and `target` fields via `Resolve-GroupMembership`. This means an admin can:

- Browse ADMX policies in the editor (human-readable names, descriptions, categories)
- Select a policy and configure its value
- Assign it to a specific group, user, or computer — directly in the same workflow
- The output is a standard REG-OPS entry with `admx_source` metadata for traceability

This is something GPMC cannot do in a single workflow. EndpointPilot unifies the "what setting" (ADMX) and "who gets it" (targeting) into one directive, eliminating the ADMX-vs-GPP split that forces admins into two different tools and mental models.

### What This Adds

1. **ADMX parser module** — new PowerShell module or C# library that reads `.admx` + `.adml` files and extracts:
    - Policy name and description (from ADML localization)
    - Registry key path and value name
    - Expected value type and allowed values (enum, boolean, decimal, string)
    - Category hierarchy (for UI organization)

2. **Output format: REG-OPS directives with ADMX metadata** — ADMX-sourced settings produce standard REG-OPS entries (not a separate module). This is the right approach because:
    - The runtime execution is identical — it's a registry write either way
    - Targeting via `Resolve-GroupMembership` works unchanged
    - Signature validation works unchanged
    - The ADMX origin is preserved via metadata fields (`admx_source`, `admx_policy_name`, `admx_category`) for traceability and editor round-tripping
    - Admins can mix hand-crafted and ADMX-sourced entries in the same REG-OPS.json

3. **JsonEditorTool integration** — new editor view or panel that:
    - Lets the admin browse/search ADMX policies by category and name
    - Shows the human-readable description (from ADML)
    - Generates the correct REG-OPS directive with pre-filled registry path, value name, type, **and targeting fields**
    - Validates the value against ADMX-defined constraints (enum, range, etc.)
    - Distinguishes ADMX-sourced entries visually in the REG-OPS list (icon, badge, or grouping)

### Scope Boundaries

- **HKCU only** — HKLM policies require SYSTEM context (System Agent) and are a separate concern
- **Not a GPO replacement** — this does not process GPO links, inheritance, or RSoP. It translates ADMX definitions into targeted EndpointPilot registry directives for environments where GPO isn't reachable
- **No ADMX authoring** — we consume Microsoft's ADMX files, we don't create custom ones
- **Standard ADMX sources:** Windows built-in (`%SystemRoot%\PolicyDefinitions`), Office ADMX templates, Chrome/Edge ADMX templates

### Research Needed

- ADMX XML schema structure (Microsoft docs)
- Whether a .NET ADMX parsing library already exists or if we roll our own
- How to handle ADMX version drift (Windows build-specific policies)
- Whether ADML localization files are always paired or optional

---

## Phase C: Web-Based JsonEditorTool

**Priority:** Longest-term — after the WPF app reaches feature-complete status (post-ADMX integration).

### Concept

Deploy a web-based version of the JsonEditorTool for scenarios where admins don't have or want the WPF desktop app — browser-based editing accessible from any device.

### Initial Thinking

- **Tech stack TBD** — Blazor Server/WASM (reuses C# Core library) vs. standalone web app (React/Vue + API)
- **Hosting model TBD** — self-hosted alongside NinjaOne, Azure Static Web App, or bundled with a lightweight API server
- **Signing workflow impact** — crypto signing currently uses local certificate store. A web version needs a different approach (upload cert? server-side signing? deferred signing with export?)
- **Offline capability** — consider PWA for environments with intermittent connectivity

### Prerequisites Before Starting

- WPF app code review complete (Phase A)
- ADMX ingestion working in WPF app (Phase B)
- Core library (`EndpointPilotJsonEditor.Core`) is cleanly separated from WPF-specific code — if not, refactor before attempting web port
- Decision on whether web version replaces or supplements the WPF app

### Not In Scope Yet

- Multi-user editing or collaboration
- Direct NinjaOne API integration (push directives from editor to NinjaOne)
- Version control integration (git commit from editor)

---

## Dependencies and Sequencing

```
Current Sprint (May 2026)
  └─ Entra ID Graph, FileOps/RegOps targeting, dry-run validation
      └─ Phase A: JsonEditorTool code review
          └─ Phase B: ADMX ingestion (parser + editor UI + new/extended OPS module)
              └─ Phase C: Web-based editor (after WPF is feature-complete)
```

Each phase should produce its own detailed planning doc before implementation begins.
