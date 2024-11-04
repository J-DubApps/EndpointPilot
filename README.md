# PS-MANAGE

<center>

# _"Better than a Logon Script..."_

</center>

PS-MANAGE is a PowerShell User Profile Configuration Tool for Windows workstation endpoints, with optimization for Remote Work scenarios. It works like a logon script, but runs as a Scheduled Task for repeated runs.

PS-MANAGE addresses the following use-case scenarios:

1. Staff who infrequently log into their PC Endpoint on-prem at the office (Remote Work staff, flexwork, etc).
2. Where timely settings-placement needs to occur at a shorter cadence than GPP setting refresh intervals.
3. Hybrid Domain-Joined PCs where Intune Configuration Profiles/CSP or Active Directory GPP settings are not always feasible.

PS-MANAGE operates like a traditional Logon Script; however, PS-MANAGE is designed to run primarily _from_ the user's local PC itself, and can run as a repeated Scheduled Task.

PS-MANAGE does not require line-of-sight to a Domain Controller NETLOGON share, and does not require a Logon Script GPO.

PS-MANAGE Configuration and operations are JSON-based.  The JSON config files can be managed either by the "PS-MANAGE-CONFIG" .NET app, or text editor.

PS-MANAGE script operations are split into Task-specific "MGMT" sub-scripts, all called by MAIN.PS1.  

PS-MANAGE components are staged onto a PC Endpoint under each user's profile at %LOCALAPPDATA%\PS-MANAGE (C:\Users\Username\AppData\Local\PS-MANAGE) and it executes as a Windows Scheduled Task at a configured "refresh" period.

Pre-Requisites:

Your users need rights to create Scheduled Tasks on their Windows PC Endpoints (this right is granted in GPO or Intune CSP).  
If your IT security policies forbid Scheduled Task creation privilege, see PS-MANAGE-Deploy.PDF for alternate deployment methods.

Roadmap:

- [ ] Add support for PowerShell Core
- [ ] Add support Windows PC Endpoint System Configuration Mgmt scenarios (currently PS-MANAGE only supports User Mode configuration use-case, not SYSTEM or Admin mode use cases)
- [ ] Devlop a System Agent to run some PS-MANAGE features with elevated rights.  Securely.
