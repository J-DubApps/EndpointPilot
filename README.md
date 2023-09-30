# PS-MANAGE

<center>

# _"Better than a Logon Script..."_

</center>

PS-MANAGE is a PowerShell User Profile Configuration Tool for Windows endpoints, with optimization for Remote Work scenarios.

PS-MANAGE addresses the following use-case scenarios:

1. Full or part-time on-prem staff who infrequently log into their PC Endpoint on-prem from the office (Remote Work staff, flexwork, etc).
2. Where timely settings-placement needs to occur at a more reliable cadence than GPP setting refresh intervals.
3. Hybrid Domain-Joined PCs where Intune Configuration Profiles/CSP or Active Directory GPP settings are not always feasible.

PS-MANAGE operates like a traditional Logon Script; however, PS-MANAGE is designed to run primarily _from_ the user's local PC itself, instead of from a Domain Controller NETLOGON share or GPO Logon Script.

PS-MANAGE components are staged onto a PC Endpoint under each user's profile at %LOCALAPPDATA%\PS-MANAGE (C:\Users\Username\AppData\Local\PS-MANAGE) and it executes as a Windows Scheduled Task at a configured "refresh" period.

Pre-Requisites:

Your users need rights to create Scheduled Tasks on their Windows PC Endpoints (this right is granted in GPO or Intune CSP).

Roadmap:

- [ ] Add support for PowerShell Core
- [ ] Add support Windows PC Endpoint System Configuration Mgmt scenarios (currently PS-MANAGE only supports User Profile Config use-case)
- [ ] Devlop a System Agent to run future PS-MANAGE Endpoint Configuration Script features.
