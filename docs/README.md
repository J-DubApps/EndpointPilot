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
If your IT security policies forbid Scheduled Task creation privilege, see EndpointPilot-Deploy.PDF for alternate deployment methods.


### Licensing: 

See [**here**](https://github.com/J-DubApps/EndpointPilot?tab=BSD-3-Clause-1-ov-file#) for BSD-3 License info.

 <a id="roadmap"></a>

#### Roadmap:

- [X] Add support for PowerShell Core (*can be optionally locked to 5.1 via simple modification to launcher script*).
- [ ] Explore System-mode endpoint Config Mgmt scenarios for "MGMT" helper scripts (currently EndpointPilot *only* supports *User-mode* profile config use-cases, no SYSTEM or Admin mode operations are currently supported).
- [ ] If System-mode operation scenarios prove securely-feasible, explore developing a System Agent option to offer elevated rights config options.
**Full Roadmap is** [***here***](https://github.com/J-DubApps/EndpointPilot/blob/main/PlanningDocs/ProjectPlan.md) 
<br />
<p align="center">
    <img src="https://github.com/J-DubApps/EndpointPilot/blob/main/images/EndpointPilot.png" width="400" height="600" />
</p>
