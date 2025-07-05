# Plan: SYSTEM-OPS.json Schema

## 1. Overview

This document defines the proposed JSON schema for `SYSTEM-OPS.json`. This file will direct the EndpointPilot System Agent, which runs with `SYSTEM` privileges. The schema must be strict and well-defined to ensure security and reliability.

## 2. Guiding Principles

-   **Explicitness:** Operations should be explicit and unambiguous. Avoid generic "run-this-command" operations.
-   **Security:** The schema must prevent command injection or unintended actions. All paths and parameters should be tightly controlled.
-   **Atomicity:** Each operation should be a single, atomic action (e.g., "install one MSI", "set one registry key").
-   **Idempotency:** Where possible, operations should be idempotent. For example, an "install app" operation should succeed if the app is already installed, rather than failing.

## 3. Root Structure

The root of `SYSTEM-OPS.json` will be an array of operation objects.

```json
{
  "$schema": "./SYSTEM-OPS.schema.json",
  "operations": [
    {
      "id": "Install-7Zip",
      "operationType": "installMsi",
      "comment": "Install 7-Zip for all users.",
      "parameters": {
        "sourcePath": "https://www.7-zip.org/a/7z2107-x64.msi",
        "arguments": "/quiet /norestart",
        "expectedVersion": "21.07.0.0"
      }
    },
    {
      "id": "Set-System-RegKey",
      "operationType": "setRegistryValue",
      "comment": "Set a system-wide registry key.",
      "parameters": {
          "path": "HKLM\\Software\\EndpointPilot",
          "name": "AgentVersion",
          "value": "1.0.0",
          "regType": "string"
      }
    }
  ]
}
```

## 4. Proposed Operation Types

Below are initial proposals for the `operationType` enum and their corresponding `parameters`.

---

### A. `installMsi`

-   **Purpose:** Installs an MSI package.
-   **Parameters:**
    -   `sourcePath` (string, required): A URI (HTTPS or local file path) to the `.msi` file.
    -   `arguments` (string, optional): Command-line arguments for the MSI installer (e.g., `/quiet`). Defaults to `/quiet /norestart`.
    -   `expectedVersion` (string, optional): The version of the product to check for. If present, the agent can use this to determine if the installation is necessary.
    -   `checksum` (string, optional): A SHA256 checksum of the installer file to verify its integrity before running.

---

### B. `setRegistryValue`

-   **Purpose:** Creates or modifies a value in the registry. Limited to `HKEY_LOCAL_MACHINE`.
-   **Parameters:**
    -   `path` (string, required): The full registry key path. Must start with `HKLM\\`.
    -   `name` (string, required): The name of the value to set.
    -   `value` (string, required): The data to store in the value.
    -   `regType` (string, required): The type of registry value. Enum: `["string", "expandString", "dword", "qword"]`.

---

### C. `manageService`

-   **Purpose:** Controls a Windows Service.
-   **Parameters:**
    -   `serviceName` (string, required): The short name of the service (e.g., "Spooler").
    -   `state` (string, optional): The desired state. Enum: `["running", "stopped"]`.
    -   `startupType` (string, optional): The desired startup type. Enum: `["automatic", "manual", "disabled"]`.

---

### D. `copyFile`

-   **Purpose:** Copies a file to a system location.
-   **Parameters:**
    -   `sourcePath` (string, required): A URI (HTTPS or local file path) to the source file.
    -   `destinationPath` (string, required): The full path, including filename, for the destination. Must be within an allowed system directory (e.g., `C:\ProgramData\`, `C:\Program Files\`).
    -   `overwrite` (boolean, optional): Whether to overwrite the file if it exists. Defaults to `false`.

## 5. Next Steps

1.  Review and refine the proposed operation types and their parameters.
2.  Consider additional operation types needed for initial use cases (e.g., `uninstallMsi`, `deleteRegistryKey`).
3.  Formalize this plan into a complete `SYSTEM-OPS.schema.json` file.