# EndpointPilot

## _"Better than a Logon Script..."_

<img src="https://github.com/J-DubApps/EndpointPilot/blob/main/endpointpilot-logo.jpg" width="200" height="200" />



**EndpointPilot** is a PowerShell-based User Profile Configuration Tool for Windows endpoints operating in an AD or Intune-managed context, with optimization for Remote Work scenarios. It works like a logon script, but is designed to be run locally at various intervals via a Scheduled Task.

### EndpointPilot addresses the following use-case scenarios:

1. Staff who infrequently log into their mobile Windows endpoint while at the office (Hybrid/Remote Work staff, etc).
2. Where timely settings-placement needs to occur at a shorter cadence than waiting for a logon/restart.
3. Hybrid Domain-Joined PCs where Intune Configuration Profiles/CSP or Active Directory GPP settings are not always feasible.

EndpointPilot operates like a traditional Logon Script; however, it runs locally on the PC endpoint itself, as a repeating Scheduled Task.

EndpointPilot does not require line-of-sight to a Domain Controller NETLOGON share or a Logon Script GPO.

EndpointPilot running config and operations are JSON-based.  JSON config entries are managed either by the included "EP-CONFIG" .NET app, or any standard text editor.

EndpointPilot script operations are divided into Task-specific "MGMT" sub-scripts, all called by MAIN.PS1.  

EndpointPilot components are staged onto a PC endpoint under each user's profile at %LOCALAPPDATA%\EndpointPilot (C:\Users\Username\AppData\Local\EndpointPilot) and it can be set to execute as a Windows Scheduled Task at a configured "refresh" period.

Pre-Requisites:

Your users need to be granted rights to at *least* **create** Scheduled Tasks on their Windows PC Endpoints (this right is granted in GPO or Intune CSP).  
If your IT security policies forbid Scheduled Task creation privilege, see EndpointPilot-Deploy.PDF for alternate deployment methods.

Roadmap:

- [ ] Add support for PowerShell Core (*currently locked to 5.1*)
- [ ] Add support System Configuration Mgmt scenarios (currently EndpointPilot only supports *User Mode* profile config use-cases, no SYSTEM or Admin mode use-cases are currently supported)
- [ ] Devlop a System Agent to run some EndpointPilot features with elevated rights.  Securely.

<br />
<p align="center">
    <img src="https://github.com/J-DubApps/EndpointPilot/blob/main/EndpointPilot.jpg" width="500" height="500" />
</p>