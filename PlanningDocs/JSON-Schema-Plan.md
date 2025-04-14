# JSON Schema Development Plan for EndpointPilot

## 1. Overview

J-DubApps (me) plan to create JSON schemas for the following files:
- CONFIG.schema.json (for CONFIG.json)
- FILE-OPS.schema.json (for FILE-OPS.json)
- REG-OPS.schema.json (for REG-OPS.json)
- DRIVE-OPS.schema.json (for DRIVE-OPS.json)

These schemas will be stored alongside their corresponding JSON files.

## 2. Schema Structure and Implementation Details

### 2.1 CONFIG.schema.json

This schema will validate the global configuration settings in CONFIG.json.

Key validation points:
- Ensure OrgName is a string
- Validate Refresh_Interval as a positive number
- Ensure network paths follow proper format
- Validate boolean flags

Schema structure:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "EndpointPilot Configuration",
  "description": "Schema for EndpointPilot global configuration settings",
  "type": "object",
  "properties": {
    "OrgName": {
      "type": "string",
      "description": "Organization name"
    },
    "Refresh_Interval": {
      "type": "number",
      "minimum": 0,
      "description": "Refresh interval in minutes"
    },
    "NetworkScriptRootEnabled": {
      "type": "boolean",
      "description": "Whether to enable the network script root"
    },
    "NetworkScriptRootPath": {
      "type": "string",
      "description": "Network path to script root"
    },
    "HttpsScriptRootEnabled": {
      "type": "boolean",
      "description": "Whether to enable the HTTPS script root"
    },
    "HttpsScriptRootPath": {
      "type": "string",
      "description": "HTTPS path to script root"
    },
    "CopyLogFileToNetwork": {
      "type": "boolean",
      "description": "Whether to copy log files to network location"
    },
    "RoamFiles": {
      "type": "boolean",
      "description": "Whether to enable file roaming"
    },
    "NetworkLogFile": {
      "type": "string",
      "description": "Network path for log files"
    },
    "NetworkRoamFolder": {
      "type": "string",
      "description": "Network path for roaming files"
    },
    "SkipFileOps": {
      "type": "boolean",
      "description": "Whether to skip file operations"
    },
    "SkipDriveOps": {
      "type": "boolean",
      "description": "Whether to skip drive operations"
    },
    "SkipRegOps": {
      "type": "boolean",
      "description": "Whether to skip registry operations"
    },
    "SkipRoamOps": {
      "type": "boolean",
      "description": "Whether to skip roaming operations"
    }
  },
  "required": ["OrgName", "Refresh_Interval", "NetworkScriptRootPath"],
  "additionalProperties": false
}
```

### 2.2 FILE-OPS.schema.json

This schema will validate file operations defined in FILE-OPS.json.

Key validation points:
- Ensure id is a unique number
- Validate file paths
- Ensure boolean flags are properly typed
- Validate targeting_type against allowed values

Schema structure:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "EndpointPilot File Operations",
  "description": "Schema for EndpointPilot file operations",
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": {
        "type": "integer",
        "description": "Unique identifier for the file operation"
      },
      "srcfilename": {
        "type": "string",
        "description": "Source filename"
      },
      "dstfilename": {
        "type": "string",
        "description": "Destination filename"
      },
      "sourcePath": {
        "type": "string",
        "description": "Source directory path"
      },
      "destinationPath": {
        "type": "string",
        "description": "Destination directory path"
      },
      "overwrite": {
        "type": "boolean",
        "description": "Whether to overwrite existing files"
      },
      "copyonce": {
        "type": "boolean",
        "description": "Whether to copy the file only once"
      },
      "existCheckLocation": {
        "type": "string",
        "description": "Location to check for existence"
      },
      "existCheck": {
        "type": ["boolean", "string"],
        "description": "Whether to check if file exists"
      },
      "deleteFile": {
        "type": "boolean",
        "description": "Whether to delete the file"
      },
      "targeting_type": {
        "type": "string",
        "enum": ["none", "group", "computer", "user"],
        "description": "Type of targeting to apply"
      },
      "target": {
        "type": "string",
        "description": "Target for the operation"
      },
      "_comment1": {
        "type": "string",
        "description": "Comment field 1"
      },
      "_comment2": {
        "type": "string",
        "description": "Comment field 2"
      }
    },
    "required": ["id", "targeting_type", "target"]
  }
}
```

### 2.3 REG-OPS.schema.json

This schema will validate registry operations defined in REG-OPS.json.

Key validation points:
- Validate registry paths start with valid hives (HKEY_*)
- Ensure regtype is one of the allowed values (string, dword, etc.)
- Validate write_once as a string representation of a boolean
- Ensure proper targeting configuration

Schema structure:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "EndpointPilot Registry Operations",
  "description": "Schema for EndpointPilot registry operations",
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": {
        "type": "string",
        "description": "Unique identifier for the registry operation"
      },
      "name": {
        "type": "string",
        "description": "Registry value name"
      },
      "path": {
        "type": "string",
        "pattern": "^HKEY_[A-Z_]+\\\\.*",
        "description": "Registry key path"
      },
      "value": {
        "type": "string",
        "description": "Registry value"
      },
      "regtype": {
        "type": "string",
        "enum": ["string", "dword", "qword", "binary", "multi-string", "expandable"],
        "description": "Registry value type"
      },
      "write_once": {
        "type": "string",
        "enum": ["true", "false"],
        "description": "Whether to write the registry value only once"
      },
      "delete": {
        "type": "boolean",
        "description": "Whether to delete the registry value"
      },
      "targeting_type": {
        "type": "string",
        "enum": ["none", "group", "computer", "user"],
        "description": "Type of targeting to apply"
      },
      "target": {
        "type": "string",
        "description": "Target for the operation"
      },
      "_comment1": {
        "type": "string",
        "description": "Comment field 1"
      },
      "_comment2": {
        "type": "string",
        "description": "Comment field 2"
      }
    },
    "required": ["id", "name", "path", "regtype", "targeting_type", "target"]
  }
}
```

### 2.4 DRIVE-OPS.schema.json

This schema will validate drive mapping operations defined in DRIVE-OPS.json.

Key validation points:
- Validate driveLetter format (letter followed by colon)
- Ensure drivePath follows UNC path format
- Validate boolean flags
- Ensure proper targeting configuration

Schema structure:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "EndpointPilot Drive Operations",
  "description": "Schema for EndpointPilot drive mapping operations",
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": {
        "type": "integer",
        "description": "Unique identifier for the drive operation"
      },
      "driveLetter": {
        "type": "string",
        "pattern": "^[A-Z]:$",
        "description": "Drive letter with colon"
      },
      "drivePath": {
        "type": "string",
        "pattern": "^\\\\\\\\.*",
        "description": "UNC path for the drive"
      },
      "reconnect": {
        "type": "boolean",
        "description": "Whether to reconnect the drive"
      },
      "delete": {
        "type": "boolean",
        "description": "Whether to delete the drive mapping"
      },
      "hidden": {
        "type": "boolean",
        "description": "Whether to hide the drive"
      },
      "targeting_type": {
        "type": "string",
        "enum": ["none", "group", "computer", "user"],
        "description": "Type of targeting to apply"
      },
      "target": {
        "type": "string",
        "description": "Target for the operation"
      },
      "_comment1": {
        "type": "string",
        "description": "Comment field 1"
      },
      "_comment2": {
        "type": "string",
        "description": "Comment field 2"
      }
    },
    "required": ["id", "driveLetter", "drivePath", "targeting_type", "target"]
  }
}
```

## 3. Integration with PowerShell Scripts

To integrate schema validation into the PowerShell scripts, we'll add validation code to each script that processes JSON files:

```powershell
function Test-JsonAgainstSchema {
    param (
        [string]$JsonFilePath,
        [string]$SchemaFilePath
    )
    
    try {
        $jsonContent = Get-Content -Raw -Path $JsonFilePath
        
        # For PowerShell 6+
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $result = Test-Json -Json $jsonContent -SchemaFile $SchemaFilePath -ErrorAction Stop
            return $result
        }
        # For PowerShell 5.1
        else {
            # Use .NET methods for validation
            Add-Type -AssemblyName System.Web.Extensions
            
            # This is a placeholder - actual implementation would use a .NET JSON Schema validation library
            # such as Newtonsoft.Json.Schema which would need to be installed
            
            return $true
        }
    }
    catch {
        WriteLog "JSON validation error: $_"
        return $false
    }
}

# Example usage in MGMT-FileOps.ps1
$jsonFilePath = ".\FILE-OPS.json"
$schemaFilePath = ".\FILE-OPS.schema.json"

if (Test-JsonAgainstSchema -JsonFilePath $jsonFilePath -SchemaFilePath $schemaFilePath) {
    # Process the JSON file
    $json = Get-Content -Raw -Path $jsonFilePath | ConvertFrom-Json
    # ...rest of the script
}
else {
    WriteLog "Invalid JSON file format. Please check the FILE-OPS.json file against the schema."
    # Handle the error appropriately
}
```

## 4. VS Code Integration

To enable real-time validation in VS Code:

1. Add schema references to JSON files:
   ```json
   {
     "$schema": "./CONFIG.schema.json",
     "OrgName": "Example Org",
     ...
   }
   ```

2. Configure VS Code settings.json:
   ```json
   {
     "json.schemas": [
       {
         "fileMatch": ["CONFIG.json"],
         "url": "./CONFIG.schema.json"
       },
       {
         "fileMatch": ["FILE-OPS.json"],
         "url": "./FILE-OPS.schema.json"
       },
       {
         "fileMatch": ["REG-OPS.json"],
         "url": "./REG-OPS.schema.json"
       },
       {
         "fileMatch": ["DRIVE-OPS.json"],
         "url": "./DRIVE-OPS.schema.json"
       }
     ]
   }
   ```

## 5. Next Steps

1. Switch to Code mode to implement the schema files
2. Create the schema files as outlined above
3. Test the schemas with example files
4. Implement validation in PowerShell scripts
5. Document the schemas and validation process
