---
updated: 2025-08-19T15:58
---

# EndpointPilot

## _"Better than a Logon Script..."_

<img src="https://github.com/J-DubApps/EndpointPilot/blob/main/images/Endpoint-Pilot-logo.png" width="250" height="250" />

> [!NOTE]
> This repo isn't currently accepting code contributions. It's public and open source to show progress and
> enable feedback for summer '26 soft launch. Once I get it to a feature-complete state, I plan to accept input and contributions. Once that begins, see [CONTRIBUTING.md](CONTRIBUTING.md)

> [!WARNING]
> This solution is ramping toward a 1.0 Beta Release and is **_NOT_** remotely ready for use on ANY live production scenarios. Do NOT install onto your prod PC Endpoints! You have been warned!

**EndpointPilot** (under development summer 2026) **is a PowerShell-based autonoumous Windows PC Endpoint** **_Configuration Management_** solution for PCs operating in **Intune\*\* **or a NinjaOne-managed context**. Configuration of Endpoints is simple and elegant, usig JSON files to direct operations like: file, registry, drive-mappings and other settings-management.  Configuration distributes directly ---> to deployed EP system agents: NinjaOne/Intune are **deployment + telemetry platforms**, while the config pipeline is independent.

One of EndpointPilot's strength is there's no DB (no SQL) overhead: just pure JSON text files with a sensible schema for directing powerful & pre-tooled PowerShell scripts. Files are the source of truth, signed as the trust boundary, while transport of configs plumbing is simple. Secure pushing of EndpointPilot configurations is handled by Client Certificate-based authentication, while API key auth is suitable for evaluation (Cert-based authentication is recommended for production deployments).

<br />
<p align="center">
    <img src="https://github.com/J-DubApps/EndpointPilot/blob/main/images/EndpointPilot.png" width="200" height="425" />
</p>

At first EndpointPilot will only offer Config Mgmt of user profiles on managed Windows Endpoints during its closed Alpha testing. EndpointPilot currently can manage settings in either _on-prem_ **_Office_** or **_Remote-Work scenarios_**. It functions a lot like a logon script, but runs locally via Agent. EndpointPilot's PowerShell code is directed by **_x-OPS.JSON_** directive files, which tells EP's scripts what to do (each line within each **x-OPS.JSON\*** govern the actions each config sript undertakes). A very basic Json Editor GUI Tool is included for managing **_x-OPS.JSON_** JSON directive files. **Think of _EP_ as an alternative to [GPO/GPP](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/group-policy/group-policy-processing) or [Intune Policy CSP](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-configuration-service-provider)**. Because **EP** operates _independent of_ a Windows PC Endpoint's AD, Intune, or NinjaOne status -- so it can be a useful config-mgmt add-on for use with those environments.

### EndpointPilot addresses the following use-case scenarios:

1. Hybrid/Remote staff needing persistent settings applied to their Windows PC endpoints, even when they infrequently restart.
2. Where timely settings-placement needs to occur outside of the logon/restart process, independent of Corporate VPN or visibility status to Intune/NinjaOne.
3. Hybrid Domain-Joined PCs where Intune Configuration Profiles/CSP or Active Directory GPP settings are not always feasible, or need to occur at a different cadence than default.
4. GPO/GPP-processing TTL / latency over a corporate VPN.

EndpointPilot runs locally on the PC endpoint itself, and does not require line-of-sight to Domain Controllers or other legacy corporate infrastructure (Netlogon/GPO/etc). Its runtime components (primarily PowerShell and JSON files) are staged onto a PC endpoint under each user's profile at %LOCALAPPDATA%\EndpointPilot (C:\Users\Username\AppData\Local\EndpointPilot). See [Roadmap](#roadmap) for system-agent (run as SYSTEM) plans.

EndpointPilot's running config and common operations stored in **_three_** (3) _JSON_-formatted **_directive files_**. The key-value pairs in the directive files are processed similar in concept to "_Playbooks_", but are simpler in design and function.

EndpointPilot's JSON config / _directive files_ can be edited via the included .NET app or via any standard text editor ( for those experienced with editing .json files).

EndpointPilot's execution calls several Task-specific "MGMT" _helper_, or child, scripts. These _helper scripts_ are called by MAIN.PS1 and each script's operation is governed by entries in the JSON config / _directive files_.

EndpointPilot can be set to execute as a Windows Scheduled Task at configured "refresh" periods. The **default** "refresh" period sets the Scheduled Task for _every 120 minutes_, and for every _Logon_ event.

### Pre-Requisites:

**Windows Endpoint:**

- Windows 10/11 Enterprise (limited Professional edition support, zero Home Support)
- Support for Windows x64 or ARM64 hardware
- PowerShell 5.1 minimum (7+ supported)

**Entra ID Group Targeting (Optional but Recommended):**
EndpointPilot can resolve Entra ID (Azure AD) security group memberships for per-group targeting of configuration directives — enabling scenarios like "apply this registry setting only to members of the Finance group." This requires:

- An **Entra ID App Registration** in your tenant (read-only, `GroupMember.Read.All` delegated permission)
- Endpoints that are **Entra-joined** or **hybrid-joined** (for PRT-based silent authentication)
- Client ID and Tenant ID configured in EndpointPilot's `CONFIG.json`

> [!IMPORTANT]
> **Without the Entra app registration**, EndpointPilot still works — but group-based targeting is limited to **on-premises AD-joined endpoints** (via logon token) and **local groups**. BYOD and cloud-only endpoints will not be able to resolve group memberships. If your environment is fully cloud-native or hybrid with remote workers, the Entra integration is strongly recommended. See the [deployment docs](docs/README.md) for setup instructions.

### Licensing:

See [**here**](https://github.com/J-DubApps/EndpointPilot?tab=BSD-3-Clause-1-ov-file#) for BSD-3 License info.

### Documentation

For comprehensive documentation, installation guides, and deployment instructions, see [/docs/README.md](docs/README.md).

<a id="roadmap"></a>

#### Roadmap:

- [x] Add support for PowerShell Core (_can be optionally locked to 5.1 via simple modification to launcher script_).
- [ ] Explore System-mode endpoint Config Mgmt scenarios for "MGMT" helper scripts (currently EndpointPilot _only_ supports _User-mode_ profile config use-cases, no SYSTEM or Admin mode operations are currently supported).
- [ ] If System-mode operation scenarios prove securely-feasible, explore developing a System Agent option to offer elevated rights config options.
    **Full Roadmap is** [**_here_**](https://github.com/J-DubApps/EndpointPilot/blob/main/PlanningDocs/ProjectPlan.md)
    <br />


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
