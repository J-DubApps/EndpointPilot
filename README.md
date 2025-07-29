# EndpointPilot

## _"Better than a Logon Script..."_

<img src="https://github.com/J-DubApps/EndpointPilot/blob/main/images/Endpoint-Pilot-logo.png" width="250" height="250" />


> [!NOTE]
> This repo isn't currently accepting code contributions. It's public and open source to show progress and
> enable feedback for summer '25 soft launch. Once I get it to a feature-complete state, I plan to accept input and contributions.  Once that begins, see [CONTRIBUTING.md](CONTRIBUTING.md)

> [!WARNING]
> This solution is ramping toward a 1.0 Beta Release and is ***NOT*** remotely ready for use on ANY live production scenarios. Do NOT install onto your prod PC Endpoints! You have been warned!

**EndpointPilot** (under development summer 2025) **is a PowerShell-based autonoumous Windows PC Endpoint** ***Configuration Management*** **solution for PCs operating in an Active Directory**, **Intune**, **or a NinjaOne-managed context**.  It uses JSON files to define operations like file, registry, and system settings management.  

At first EndpointPilot will only offer Config Mgmt of user profiles on managed Windows Endpoints during its closed Alpha testing.  EndpointPilot is able to manage settings in either *on-prem* ***Office*** or ***Remote-Work scenarios***. It functions a lot like a logon script, but runs locally via Agent (or Scheduled Task, in some configurations).  EndpointPilot's PowerShell code is directed by ***x-OPS.JSON*** directive files, which tells EP's scripts what to do (each line within each **x-OPS.JSON*** govern the actions each config sript undertakes).  A Json Editor GUI Tool is included for managing ***x-OPS.JSON*** JSON directive file.  **Think of *EP* as an alternative to [GPO/GPP](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/group-policy/group-policy-processing) or [Intune Policy CSP](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-configuration-service-provider)**.  Because **EP** operates *independent of* a Windows PC Endpoint's AD, Intune, or NinjaOne status -- so it can be a great config-mgmt add-on for use with those environments.

### EndpointPilot addresses the following use-case scenarios:

1. Hybrid/Remote staff needing persistent sysadmin settings on their Windows PC endpoints, even when they infrequently restart.
2. Where timely settings-placement needs to occur outside of the logon/restart process, independent of Corporate VPN or Intune-visibility status.
3. Hybrid Domain-Joined PCs where Intune Configuration Profiles/CSP or Active Directory GPP settings are not always feasible, or need to occur at a different cadence than default.
4. GPO/GPP-processing is slow over a cloud-based VPN. 

EndpointPilot runs locally on the PC endpoint itself, as a repeating Scheduled Task, so it does not require line-of-sight to a Domain Controller NETLOGON share or a Logon Script GPO. Its runtime components (primarily PowerShell and JSON files) are staged onto a PC endpoint under each user's profile at %LOCALAPPDATA%\EndpointPilot (C:\Users\Username\AppData\Local\EndpointPilot).  See [Roadmap](#roadmap) for system-agent (run as SYSTEM) plans.

EndpointPilot's running config and common operations stored in ***three*** (3) *JSON*-formatted ***directive files***.  The key-value pairs in the directive files are processed similar in concept to "*Playbooks*", but are simpler in design and function.  

EndpointPilot's JSON config / *directive files* can be edited via the included .NET app or via any standard text editor ( for those experienced with editing .json files).

EndpointPilot's execution calls several Task-specific "MGMT" *helper*, or child, scripts.  These *helper scripts* are called by MAIN.PS1 and each script's operation is governed by entries in the JSON config / *directive files*.

EndpointPilot can be set to execute as a Windows Scheduled Task at configured "refresh" periods.  The **default** "refresh" period sets the Scheduled Task for *every 120 minutes*, and for every *Logon* event.

### Pre-Requisites:

Until we finish a System Agent solution for EndpointPilot, your users need to be granted rights to at *least* **create** Scheduled Tasks on their Windows PC Endpoints (this right is granted in GPO or Intune CSP).


### Licensing: 

See [**here**](https://github.com/J-DubApps/EndpointPilot?tab=BSD-3-Clause-1-ov-file#) for BSD-3 License info.

### Documentation

For comprehensive documentation, installation guides, and deployment instructions, see [/docs/README.md](docs/README.md).

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

---

## Disclaimer

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
