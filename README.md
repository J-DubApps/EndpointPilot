# PS-MANAGE

"Better than a Logon Script"

PowerShell User Profile Configuration Script for Windows endpoints + optimization for Remote Work scenarios. 

PS-MANAGE addresses the following Endpoint Configuration scenarios:

1. When on-prem Logon by the Windows PC Endpoint are rare, and file or registry settings-placement need to occur.  
2. Where timely File-placement, or Registry setting-placement, needs to occur quicker than GPP setting refresh period.
3. Hybrid Domain-Joined PCs where either Intune Configuration Profiles/CSP or Active Directory GPP settings may not apply.

PS-MANAGE shares many facets with traditional Logon Scripts; however, it is *not* a Logon Script.  PS-MANAGE is a User Profile Configuration Script that is designed to run _from_ a location within the user's profile on the local PC, instead of from NETLOGON on a Domain Controller or from a GPO Logon Script.  

PS-MANAGE componetns are staged onto the local user's profile under the path %LOCALAPPDATA%\PS-MANAGE (usually C:\Users\Username\AppData\Local\PS-MANAGE) and is set to be executed as a Windows Scheduled Task at a configured "refresh" period.


Pre-Requisites:

Your users need rights to create Scheduled Tasks on their Windows PC Endpoints (this right is granted in GPO or Intune CSP).
