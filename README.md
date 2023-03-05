# PS-MANAGE

PowerShell Endpoint Configuration Script for Windows Endpoints + Optimization for Remote Worker Endpoint Scenarios. 

PS-MANAGE addresses the following Endpoint Configuration scenarios:

1. When on-prem Logon by the Windows PC Endpoint are rare, and file or registry settings-placement need to occur.  
2. Where timely File-placement, or Registry setting-placement, needs to occur quicker than GPP setting refresh period.
3. Hybrid Domain-Joined PCs where either Intune Configuration Profiles/CSP or Active Directory GPP settings may not apply.

PS-MANAGE shares many facets with traditional Logon Scripts; however, it is *not* a Logon Script.  PS-MANAGE is an Endpoint Configuration Script




Pre-Requisites:

Your users need rights to create Scheduled Tasks on their Windows PC Endpoints (this right is granted in GPO or Intune CSP).
