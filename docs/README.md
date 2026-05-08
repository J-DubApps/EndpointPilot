# EndpointPilot

## _"Better than a Logon Script..."_

<img src="https://github.com/J-DubApps/EndpointPilot/blob/main/images/Endpoint-Pilot-logo.png" width="250" height="250" />

> [!NOTE]
> This repo isn't currently accepting code contributions. It's public and open source to show progress and
> enable feedback. Once I get it to a feature-complete state, I may start taking code contributions.

### Team Contacts

- Architecture: Julian West
- Security: Julian West
- DevOps: Julian West

### Pre-Requisites:

**Windows Endpoint:**

- Windows 10/11 Enterprise, x64 or ARM64
- PowerShell 5.1 minimum (7+ supported)
- Users need rights to create Scheduled Tasks on their Windows PC Endpoints (this right is granted in GPO or Intune CSP)

**Entra ID Group Targeting (Optional but Recommended):**
EndpointPilot supports Entra ID security group resolution for per-group targeting of directives. This bridges a gap that GPMC cannot: applying ADMX-style policy settings to _specific groups_, not just everyone a GPO is linked to. To enable this:

1. **Register an app** in your Entra tenant (Azure Portal > App registrations)
    - Name: `EndpointPilot Group Reader` (or your preference)
    - Supported account types: Single tenant
    - Redirect URI: `https://login.microsoftonline.com/common/oauth2/nativeclient`
2. **Add API permission**: Microsoft Graph > Delegated > `GroupMember.Read.All` — then grant admin consent
3. **Enable public client flows**: Authentication > Allow public client flows: Yes
4. **Configure EndpointPilot**: Add `EntraClientId` and `EntraTenantId` to `CONFIG.json`

This is a **read-only** delegated permission. The app cannot modify groups, users, or any directory data.

> [!NOTE]
> **Without the Entra app registration**, EndpointPilot still functions — group-based targeting falls back to on-premises AD (via logon token) and local groups. However, BYOD and cloud-only endpoints will be unable to resolve group memberships. If your fleet includes remote workers, Entra-joined devices, or hybrid endpoints that are frequently off-network, the Entra integration is strongly recommended.

### Licensing:

See [**here**](https://github.com/J-DubApps/EndpointPilot?tab=BSD-3-Clause-1-ov-file#) for BSD-3 License info.

### Documentation

| Component              | Documentation                                            | Description                                                                          |
| ---------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **System Agent**       | [SystemAgent.md](../SystemAgent/SystemAgent.md)          | Windows Service for system-level operations and SYSTEM-mode configuration management |
| **JsonEditorTool**     | [JsonEditorTool README](../JsonEditorTool/bin/README.md) | WPF application for editing EndpointPilot JSON directive files with validation       |
| **Deployment Scripts** | [Deploy README](../deploy/README.md)                     | Installation, update, and uninstallation scripts with comprehensive documentation    |

<a id="roadmap"></a>

#### Roadmap:

.
**Full Roadmap is** [**_here_**](https://github.com/J-DubApps/EndpointPilot/blob/main/PlanningDocs/ProjectPlan.md)
<br />

<p align="center">
    <img src="https://github.com/J-DubApps/EndpointPilot/blob/main/images/EndpointPilot.png" width="400" height="600" />
</p>

### FAQ

#### 1. Do you plan to offer some kind of integration for MECM, or is this only going to target AD, Intune, or NinjaOne environments?

#### A: **No MECM add-in or integration capabilities are planned**. Microsoft Endpoint Config Mgr, while a fantastic solution, is approaching 30 years of age. I have managed several MECM environments back when it was called "SMS" and, later, "SCCM" -- and it's my position that: if you have an MECM environment, you already have an AD.local domain of some sort, and _that_ is where EndpointPilot should be deployed if you aren't using the other **EP**-supported endpoint mgmt tools. MECM is a technology in its _descendency_, while Intune is _ascendant_ and where Microsoft is wanting everyone running to MECM to eventually migrate to.
