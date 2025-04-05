# EndpointPilot

## _"Better than a Logon Script..."_

<img src="https://github.com/J-DubApps/EndpointPilot/blob/main/images/Endpoint-Pilot-logo.png" width="300" height="300" />



**EndpointPilot** is a PowerShell-based autonoumous Windows Endpoint Configuration solution for PCs operating in an AD, Intune, or NinjaOne-managed context, with optimization for keeping user profiles managed in in Office and Remote Work scenarios. It functions a lot like a logon script, but runs locally via a Scheduled Task-and at specified intervals.

### EndpointPilot addresses the following use-case scenarios:

1. Hybrid/Remote staff who infrequently restart their mobile Windows endpoints.
2. Where timely settings-placement needs to occur outside of the logon/restart process, independent of Corporate VPN or Intune-visibility status.
3. Hybrid Domain-Joined PCs where Intune Configuration Profiles/CSP or Active Directory GPP settings are not always feasible, or need to occur at a higher cadence than default.

EndpointPilot runs locally on the PC endpoint itself, as a repeating Scheduled Task, so it does not require line-of-sight to a Domain Controller NETLOGON share or a Logon Script GPO. Its runtime components are staged onto a PC endpoint under each user's profile at %LOCALAPPDATA%\EndpointPilot (C:\Users\Username\AppData\Local\EndpointPilot).  See [Roadmap](#roadmap) for system-agent (run as SYSTEM) plans.

EndpointPilot's running config and common operations stored in ***three*** (3) *JSON*-formatted ***directive files***.  The key-value pairs in the directive files are processed similar in concept to "*Playbooks*", but are simpler in design and function.  

EndpointPilot's JSON config / *directive files* can be edited via the included .NET app or via any standard text editor ( for those experienced with editing .json files).

EndpointPilot's execution calls several Task-specific "MGMT" *helper*, or child, scripts.  These *helper scripts* are called by MAIN.PS1 and each script's operation is governed by entries in the JSON config / *directive files*.

EndpointPilot can be set to execute as a Windows Scheduled Task at configured "refresh" periods.  The **default** "refresh" period sets the Scheduled Task for *every 120 minutes*, and for every *Logon* event.

### Pre-Requisites:

Your users need to be granted rights to at *least* **create** Scheduled Tasks on their Windows PC Endpoints (this right is granted in GPO or Intune CSP).  
If your IT security policies forbid Scheduled Task creation privilege, see EndpointPilot-Deploy.PDF for alternate deployment methods.


### Licensing: 

See [**here**](https://github.com/J-DubApps/EndpointPilot?tab=BSD-3-Clause-1-ov-file#) for BSD-3 License info.

 <a id="roadmap"></a>

#### Roadmap:

- [X] Add support for PowerShell Core (*can be optionally locked to 5.1 via simple modification to launcher script*).
- [ ] Explore System-mode endpoint Config Mgmt scenarios for "MGMT" helper scripts (currently EndpointPilot *only* supports *User-mode* profile config use-cases, no SYSTEM or Admin mode operations are currently supported).
- [ ] If System-mode operation scenarios prove securely-feasible, explore developing a System Agent option to offer elevated rights config options.
**Full Roadmap is** [***here***](https://github.com/J-DubApps/EndpointPilot/blob/main/ProjectPlan.md) 
<br />
<p align="center">
    <img src="https://github.com/J-DubApps/EndpointPilot/blob/main/images/EndpointPilot.jpg" width="500" height="500" />
</p>
