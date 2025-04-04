# EndpointPilot JSON Schema Documentation

This document provides information on how to use the JSON schemas for validating EndpointPilot directive files.

## Overview

EndpointPilot uses JSON files for configuration and directives. To ensure these files are properly formatted and contain valid data, JSON schemas have been created for validation. These schemas define the structure, data types, and constraints for each JSON file.

The following schemas are available:

- `CONFIG.schema.json` - For validating `CONFIG.json`
- `FILE-OPS.schema.json` - For validating `FILE-OPS.json`
- `REG-OPS.schema.json` - For validating `REG-OPS.json`
- `DRIVE-OPS.schema.json` - For validating `DRIVE-OPS.json`

## Using the Validation Script

A PowerShell script (`Validate-JsonSchema.ps1`) is provided to validate JSON files against their schemas.

### Prerequisites

- PowerShell 5.1 or higher (PowerShell 6+ recommended for full schema validation)
- EndpointPilot JSON files and their corresponding schema files

### Usage

#### Validate a Specific JSON File

```powershell
.\Validate-JsonSchema.ps1 -JsonFilePath FILE-OPS.json -SchemaFilePath FILE-OPS.schema.json
```

#### Validate All EndpointPilot JSON Files

```powershell
.\Validate-JsonSchema.ps1 -ValidateAll
```

### Validation Results

The script will output validation results for each file:

- Green message: The JSON file is valid according to its schema
- Red message: The JSON file is NOT valid according to its schema (with error details)
- Yellow message: Warning or informational message

### PowerShell 5.1 Limitations

If you're using PowerShell 5.1, the script will only perform basic JSON syntax validation, not full schema validation. For full schema validation, use PowerShell 6+ or install a third-party module.

## Integrating Schema Validation into Your Workflow

### Manual Validation

Before deploying or updating EndpointPilot configuration files, run the validation script to ensure they are properly formatted.

### Automated Validation

You can integrate the validation script into your deployment process:

1. Add validation checks before deploying configuration files
2. Include validation in CI/CD pipelines
3. Create pre-commit hooks to validate JSON files before committing changes

### VS Code Integration

To enable real-time validation in VS Code:

1. Add schema references to your JSON files:

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

## Schema Details

### CONFIG.schema.json

Validates the global configuration settings in `CONFIG.json`.

#### Required Properties

- `OrgName` - Organization name (string)
- `Refresh_Interval` - Refresh interval in minutes (number)
- `NetworkScriptRootPath` - Network path to script root (string)

#### Optional Properties

- `CopyLogFileToNetwork` - Whether to copy log files to network location (boolean)
- `RoamFiles` - Whether to enable file roaming (boolean)
- `NetworkLogFile` - Network path for log files (string)
- `NetworkRoamFolder` - Network path for roaming files (string)
- `SkipFileOps` - Whether to skip file operations (boolean)
- `SkipDriveOps` - Whether to skip drive operations (boolean)
- `SkipRegOps` - Whether to skip registry operations (boolean)
- `SkipRoamOps` - Whether to skip roaming operations (boolean)

### FILE-OPS.schema.json

Validates file operations defined in `FILE-OPS.json`.

#### Required Properties for Each Operation

- `id` - Unique identifier for the file operation (integer or string)
- `targeting_type` - Type of targeting to apply (string: "none", "group", "computer", "user")
- `target` - Target for the operation (string)

For file copy operations:
- `srcfilename` - Source filename (string)
- `dstfilename` - Destination filename (string)
- `sourcePath` - Source directory path (string)
- `destinationPath` - Destination directory path (string)

For file delete operations:
- `destinationPath` - Destination directory path (string)
- `dstfilename` - Destination filename (string)

#### Optional Properties

- `overwrite` - Whether to overwrite existing files (boolean)
- `copyonce` - Whether to copy the file only once (boolean)
- `existCheckLocation` - Location to check for existence (string)
- `existCheck` - Whether to check if file exists (boolean)
- `deleteFile` - Whether to delete the file (boolean)
- `_comment1` and `_comment2` - Comment fields (string)

### REG-OPS.schema.json

Validates registry operations defined in `REG-OPS.json`.

#### Required Properties for Each Operation

- `id` - Unique identifier for the registry operation (string)
- `name` - Registry value name (string)
- `path` - Registry key path (string, must start with "HKEY_")
- `regtype` - Registry value type (string: "string", "dword", "qword", "binary", "multi-string", "expandable")
- `targeting_type` - Type of targeting to apply (string: "none", "group", "computer", "user")
- `target` - Target for the operation (string)

For registry value creation/modification:
- `value` - Registry value (string)

#### Optional Properties

- `write_once` - Whether to write the registry value only once (string: "true" or "false")
- `delete` - Whether to delete the registry value (boolean)
- `_comment1` and `_comment2` - Comment fields (string)

### DRIVE-OPS.schema.json

Validates drive mapping operations defined in `DRIVE-OPS.json`.

#### Required Properties for Each Operation

- `id` - Unique identifier for the drive operation (integer or string)
- `driveLetter` - Drive letter with colon (string, pattern: "^[A-Z]:$")
- `drivePath` - UNC path for the drive (string, pattern: "^\\\\\\\\.*")
- `targeting_type` - Type of targeting to apply (string: "none", "group", "computer", "user")
- `target` - Target for the operation (string)

#### Optional Properties

- `reconnect` - Whether to reconnect the drive (boolean)
- `delete` - Whether to delete the drive mapping (boolean)
- `hidden` - Whether to hide the drive (boolean)
- `_comment1` and `_comment2` - Comment fields (string)

## Best Practices

1. **Always validate before deployment**: Run the validation script before deploying configuration files to ensure they are properly formatted.

2. **Use descriptive comments**: Utilize the `_comment1` and `_comment2` fields to document the purpose of each operation.

3. **Maintain unique IDs**: Ensure each operation has a unique ID to avoid conflicts.

4. **Follow naming conventions**: Use consistent naming for files and paths.

5. **Keep schemas updated**: If you modify the structure of your JSON files, update the schemas accordingly.

## Troubleshooting

### Common Validation Errors

- **Missing required property**: Ensure all required properties are present in your JSON files.
- **Invalid data type**: Check that property values have the correct data type (string, number, boolean).
- **Pattern mismatch**: Ensure values match the required patterns (e.g., registry paths, drive letters).
- **Invalid enum value**: Check that enum values are one of the allowed options.

### Schema Validation Not Working

- Ensure the schema files are in the correct location
- Check that the JSON files are properly formatted
- Verify you're using PowerShell 6+ for full schema validation
- Check for any error messages in the validation output