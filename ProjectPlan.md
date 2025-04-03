# Project Plan: EndpointPilot

## 1. Introduction

*   **Project Goal:** A PowerShell/JSON-based local endpoint configuration tool, replacing traditional logon scripts, optimized for hybrid/remote scenarios.
*   **Document Purpose:** To outline the current state, identify strengths and areas for improvement, and propose a roadmap for future development.

## 2. Current Architecture Overview

*   **Core Components:**
    *   `ENDPOINT-PILOT.PS1`: Initial launcher (handles ARM64).
    *   `MAIN.PS1`: Main orchestrator script.
    *   `CONFIG.json`: Global configuration settings.
    *   `MGMT-Functions.psm1`: Shared PowerShell functions (`InGroup`, `Get-Permission`, `IsCurrentProcessArm64`).
    *   `MGMT-SHARED.ps1`: Shared variables (from `CONFIG.json`), utility functions (`Test-OperatingSystem`, `Copy-Directory`, `WriteLog`, etc.), Robocopy usage, initial setup.
    *   `MGMT-*.ps1` Helper Scripts: Modular scripts for specific tasks (File Ops, Reg Ops, Drive Ops, Roaming Ops, Telemetry, Scheduled Task, Maintenance, Custom).
    *   `*-OPS.json` Directive Files: JSON files containing specific instructions for the corresponding `MGMT-*.ps1` script.
*   **Execution Flow:**
    ```mermaid
    graph LR
        A[Scheduled Task / GPO] --> B(ENDPOINT-PILOT.PS1);
        B --> C(MAIN.PS1);
        C -- Reads --> D(CONFIG.json);
        C -- Imports --> E(MGMT-Functions.psm1);
        C -- Imports --> F(MGMT-SHARED.ps1);
        C -- Calls based on Config --> G(MGMT-FileOps.ps1);
        C -- Calls based on Config --> H(MGMT-RegOps.ps1);
        C -- Calls based on Config --> I(MGMT-DriveOps.ps1);
        C -- Calls based on Config --> J(MGMT-RoamOps.ps1);
        C -- Calls --> K(MGMT-Telemetry.ps1);
        C -- Calls --> L(MGMT-USER-CUSTOM.ps1);
        C -- Calls --> M(MGMT-SchedTsk.ps1);
        C -- Calls --> N(MGMT-Maint.ps1);
        G -- Reads --> O(FILE-OPS.json);
        H -- Reads --> P(REG-OPS.json);
        I -- Reads --> Q(DRIVE-OPS.json);
        J -- Reads --> R(ROAM-OPS.json);
    ```

## 3. Strengths

*   **Modular Design:** Separation of concerns using dedicated helper scripts (`MGMT-*.ps1`).
*   **Configuration Driven:** High flexibility through JSON directive files (`*-OPS.json`) and main config (`CONFIG.json`).
*   **Targeted Use Case:** Addresses specific needs of hybrid/remote environments where traditional methods fall short.
*   **Extensibility:** Relatively easy to add new operation types by creating new `MGMT-*.ps1` / `*-OPS.json` pairs.
*   **PowerShell Native:** Leverages existing Windows administration skills and tools. Uses standard tools like `Robocopy`.

## 4. Areas for Development & Consideration

*   **Error Handling & Logging:** Review and standardize error handling within scripts. Enhance logging for easier debugging (e.g., more detailed messages, structured logging).
*   **Testing:** Implement automated testing using Pester for PowerShell scripts to ensure reliability and prevent regressions. Define a clear testing strategy.
*   **Security:**
    *   Review script execution policies and potential security implications, especially if considering system-level operations.
    *   Assess risks associated with storing configuration/directives in potentially user-accessible JSON files.
    *   Consider code signing for scripts.
*   **JSON Management:**
    *   Develop JSON schemas for validation to prevent errors from malformed directive files.
    *   Explore tooling or UI (like the mentioned .NET app) to simplify JSON editing and reduce errors.
*   **PowerShell Core Support:** Plan the transition/support for PowerShell 7+ as per the roadmap. Identify necessary code changes (cmdlet compatibility, etc.).
*   **System-Mode Agent:** Detail the plan for exploring system-level operations. Define use cases, security model, implementation approach (e.g., separate agent, elevated task).
*   **Code Maintainability:** Refactor `MGMT-SHARED.ps1` if it becomes too large. Ensure consistent coding style and add more inline documentation/comments.
*   **Documentation:** Expand `README.md` or create separate documentation detailing the JSON schema for each directive file, script parameters, and deployment steps.
*   **Hybrid Join State Detection:** Investigate using `dsregcmd /status` or similar methods to reliably detect the endpoint's join state (AD-joined, Entra ID-joined, Hybrid-joined). Adapt script logic (e.g., fetching computer identity, applying conditional configurations) based on the detected state to reduce reliance on purely AD-based lookups (`adsisearcher`).
*   **OS Limitation:** Note the current restriction to Windows 10/11 Enterprise in `Test-OperatingSystem` if broader support is a goal.
*   **Variable Expansion:** Ensure consistent use and documentation of the `Expand-ConfigString` capability for environment variables in JSON/config strings.

## 5. Proposed Roadmap

*   **Phase 1 (Short-Term):**
    *   [ ] Enhance Error Handling & Logging across all scripts.
    *   [ ] Develop JSON Schemas for all `*-OPS.json` files.
    *   [ ] Implement basic Pester tests for core functions (`MGMT-Functions.psm1`, `MGMT-SHARED.ps1`) and `MAIN.PS1`.
    *   [ ] Improve inline code documentation and comments.
    *   [ ] Update `README.md` with JSON schema details and OS limitations.
*   **Phase 2 (Medium-Term):**
    *   [ ] Investigate and implement PowerShell Core compatibility.
    *   [ ] Develop or integrate a tool/UI for easier JSON configuration management.
    *   [ ] Expand Pester test coverage significantly (Helper scripts).
    *   [ ] Implement code signing for scripts.
    *   [ ] Implement Hybrid Join State detection and adapt script logic.
*   **Phase 3 (Long-Term):**
    *   [ ] Research and prototype System-Mode agent/operations.
    *   [ ] Refine architecture based on feedback and usage patterns.
    *   [ ] Explore advanced targeting options (e.g., based on AD/Entra group, WMI filters).
    *   [ ] Investigate broadening OS support beyond Win 10/11 Enterprise.

## 6. Development Process

*   Continue using Git for version control.
*   Define branching strategy (e.g., Gitflow: main, develop, feature/*, release/*, hotfix/*).
*   Outline testing procedures (manual checks for UI/workflow, Pester for unit/integration tests).