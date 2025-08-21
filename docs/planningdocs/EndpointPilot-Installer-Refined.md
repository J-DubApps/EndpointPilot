# Refined Plan: Modify EndpointPilot Installation Script

**Goal:** Modify `Install-EndpointPilotAdmin.ps1` to download the project from GitHub, extract it to a temporary staging area (`%windir%\Temp\EPilotTmp`), use that staging area as the source for file copying operations, implement robust error handling, and finally clean up the temporary directory.

**Proposed Steps:**

1.  **Define New Variables:** Introduce variables at the beginning of the script (after parameter definition and admin check) for:
    *   `$githubRepoUrl`: `https://github.com/J-DubApps/EndpointPilot/archive/refs/heads/main.zip`
    *   `$tempDir`: `$env:windir\Temp\EPilotTmp`
    *   `$zipFilePath`: `$tempDir\EndpointPilot.zip`
    *   `$stagingSourcePath`: To be determined after extraction.

2.  **Implement Download and Extraction (with Enhanced Error Handling):**
    *   Insert code after architecture detection (around line 48).
    *   **Create Temp Directory:** Use `New-Item` with `-ErrorAction Stop` and wrap in `try/catch`. If creation fails, write an error and `exit`.
    *   **Download:** Use `Invoke-WebRequest` with `-ErrorAction Stop` and wrap in `try/catch`. Catch specific web exceptions, write detailed errors (including the URL), and `exit`.
    *   **Extract:** Use `Expand-Archive` with `-ErrorAction Stop` and wrap in `try/catch`. Write detailed errors (including the zip path) and `exit`.
    *   **Identify Extracted Folder:** Use `Get-ChildItem` with `-ErrorAction Stop` and wrap in `try/catch` or check for `$null`. If the expected folder isn't found, write an error and `exit`.
    *   **Set Staging Source Path:** Set `$stagingSourcePath` based on the successfully identified extracted folder.

3.  **Modify File Copy Operations:**
    *   Update `$jsonEditorSourcePath` (Lines 65-66) to use `$stagingSourcePath`.
    *   Update `Get-ChildItem` path (Line 80) to use `$stagingSourcePath`.
    *   Keep the check to skip `Install-EndpointPilotAdmin.ps1` (Line 83).

4.  **Implement Cleanup:**
    *   Wrap the main installation logic (approx. lines 55-160) in a `try...finally` block.
    *   Add `Remove-Item -Path $tempDir -Recurse -Force` to the `finally` block, possibly with a check `if (Test-Path $tempDir)` before attempting removal. Add a `Write-Host` message for cleanup.

**Visual Flow:**

```mermaid
graph TD
    A[Start Install Script] --> B{Admin Check};
    B --> C[Detect Arch];
    C --> D[Define Paths: Install Dirs];
    D --> E[Define Paths: Temp Dir, Zip URL];
    E --> F[Create Temp Dir];
    F --> G[Download Zip from GitHub];
    G --> H[Extract Zip to Temp Dir];
    H --> I[Identify Extracted Root (e.g., EndpointPilot-main)];
    I --> J[Set Staging Source Path];
    J --> K[Start Try Block];
    K --> L[Create Install Dirs];
    L --> M{Copy JsonEditorTool?};
    M -- Yes --> N[Copy JsonEditorTool from Staging];
    M -- No --> O;
    N --> O[Copy Script Files from Staging];
    O --> P{Create Shortcut?};
    P -- Yes --> Q[Create Shortcut];
    P -- No --> R;
    Q --> R{Create Uninstaller?};
    R -- Yes --> S[Create Uninstaller];
    R -- No --> T;
    S --> T[End Install Logic];
    T --> U[End Try Block];
    U --> V[Start Finally Block];
    V --> W[Cleanup: Remove Temp Dir];
    W --> X[End Finally Block]
    X --> Y[End Script];

    subgraph Error Handling
        direction LR
        Z(Error during L-T) --> V;
        ErrF(Error Creating Temp) --> Exit;
        ErrG(Error Downloading) --> Exit;
        ErrH(Error Extracting) --> Exit;
        ErrI(Error Finding Folder) --> Exit;
        F -- Error --> ErrF;
        G -- Error --> ErrG;
        H -- Error --> ErrH;
        I -- Error --> ErrI;
    end

    style W fill:#f9f,stroke:#333,stroke-width:2px