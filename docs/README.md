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

Until we finish a System Agent solution for EndpointPilot, your users need to be granted rights to at *least* **create** Scheduled Tasks on their Windows PC Endpoints (this right is granted in GPO or Intune CSP).  

### Licensing: 

See [**here**](https://github.com/J-DubApps/EndpointPilot?tab=BSD-3-Clause-1-ov-file#) for BSD-3 License info.

### Documentation

| Component | Documentation | Description |
|-----------|---------------|-------------|
| **System Agent** | [SystemAgent.md](../SystemAgent/SystemAgent.md) | Windows Service for system-level operations and SYSTEM-mode configuration management |
| **JsonEditorTool** | [JsonEditorTool README](../JsonEditorTool/bin/README.md) | WPF application for editing EndpointPilot JSON directive files with validation |
| **Deployment Scripts** | [Deploy README](../deploy/README.md) | Installation, update, and uninstallation scripts with comprehensive documentation |

 <a id="roadmap"></a>

#### Roadmap:
.
**Full Roadmap is** [***here***](https://github.com/J-DubApps/EndpointPilot/blob/main/PlanningDocs/ProjectPlan.md) 
<br />
<p align="center">
    <img src="https://github.com/J-DubApps/EndpointPilot/blob/main/images/EndpointPilot.png" width="400" height="600" />
</p>

### FAQ

#### 1. Do you plan to offer some kind of integration for MECM, or is this only going to target AD, Intune, or NinjaOne environments?

#### A: **No MECM add-in or integration capabilities are planned**.  Microsoft Endpoint Config Mgr, while a fantastic solution, is approaching 30 years of age.  I have managed several MECM environments back when it was called "SMS" and, later, "SCCM" -- and it's my position that: if you have an MECM environment, you already have an AD.local domain of some sort, and *that* is where EndpointPilot should be deployed if you aren't using the other **EP**-supported endpoint mgmt tools.  MECM is a technology in its *descendency*, while Intune is *ascendant* and where Microsoft is wanting everyone running to MECM to eventually migrate to.