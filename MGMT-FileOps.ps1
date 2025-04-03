#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#	    EndpointPilot Configuration tool shared helper script
#			MOD-FileOps.PS1
#
#  Description
#    This file is a module called by MAIN.PS1 portion of EndpointPilot
#    It places ENDPOINT-PILOT.ps1 into Scheduled Tasks (if user rights permit) with the
#    appropriate triggers (network status change, etc).
#
#    This EndpointPilot helper script loads File-Ops.json data into an array of objects,
#    where each object represents information about copying/deleting files (and Targeting options).
#    The script then loops through each separate dataset to perform the required tasks designated in
#    File-Ops.json.
#
#
#				Written by Julian West February 2025
#
#
###############################################################################################

# Check to see if this script is being run directly, or if it is being dot-sourced into another script.

if ($MyInvocation.InvocationName -ne '.') {
  
      # We are running independently of MAIN.PS1, load Shared Modules & Shaed Variable Files
        # and coninue the rest of the script with your shared variables and functions
        Import-Module MGMT-Functions.psm1
        . .\MGMT-SHARED.ps1

}
else {

    # We are being called by MAIN.PS1, nothing to load 
}




<#
The goal of this script is to provide a flexible way to copy files with different options, based on the instructions provided
in the File-Ops.json file.
It is a replacement for Microsoft Group Policy Preferences (GPP) File Copy operations.

The object contains properties such as "srcfilename", "dstfilename", "sourcePath", "destinationPath", "overwrite", "copyonce", and "comments".
These properties provide instructions to the PowerShell script on how to perform the file copy operation.

If $overwrite is true, the script checks if the source file is newer than the destination file and only copies the file if it is. If $overwrite is false, the script skips the file if the destination file already exists.

#>


# Read JSON file
$json = Get-Content -Raw -Path ".\file-ops.json" | ConvertFrom-Json

# Loop through each entry in the json file
$json | ForEach-Object {
    # Extract File information from JSON
    $srcfilename = $_.srcfilename
    $dstfilename = $_.dstfilename
    $sourcePath = $_.sourcePath
    $destinationPath = $_.destinationPath
    $overwrite = $_.overwrite
    $copyonce = $_.copyonce
    $existCheckLocation = $_.existCheckLocation
    $existCheck = $_.existCheck
    $deleteFile = $_.deleteFile

    # Construct full file path for each file
    if ($srcfilename -and $sourcePath) {
        $sourceFile = Join-Path -Path $sourcePath -ChildPath $srcfilename
    }
    if ($dstfilename -and $destinationPath) {
        $destinationFile = Join-Path -Path $destinationPath -ChildPath $dstfilename
    }

    try {
        # Delete file if specified in the JSON file
        if (-not $srcfilename -and $deleteFile -and $deleteFile -eq $true) {
            Remove-Item -Path $destinationFile -Force -ErrorAction Ignore
            return
        }
    }
    catch {
        WriteLog "ERROR processing file operation (delete check): $_" # Log full exception details
    }

    # Perform copy actions specified in the JSON file, for each file
    # Observe the '$copyonce' and '$overwrite' boolean actions
    # If $overwrite is 'true' then ONLY overwrite if the $sourceFile is newer than $destinationFile
    if ($existCheckLocation) {
        $existCheckPath = Join-Path -Path $destinationPath -ChildPath $existCheckLocation
        if (Test-Path -Path $existCheckPath) {
            if ($existCheck -eq $false) {
                return
            }
        }
        else {
            if ($existCheck -eq $true) {
                return
            }
        }
    }

    # Perform copy actions specified in the JSON file, for each file
    # Observe the '$copyonce' and '$overwrite' boolean actions
    # If $overwrite is 'true' then ONLY overwrite if the $sourceFile is newer than $destinationFile

    try {
        if ($copyonce) {
            if (Test-Path -Path $destinationFile) {
                # Write-Host "File already exists, skipping copy"
            }
            else {
                # Copy the file if it doesn't exist
                Copy-Item -Path $sourceFile -Destination $destinationFile -Force -ErrorAction Ignore
            }
        }
        else {
            if ($overwrite) {
                if (Test-Path $destinationFile) {
                    $sourceDate = (Get-Item $sourceFile).LastWriteTime
                    $destinationDate = (Get-Item $destinationFile).LastWriteTime
                    if ($sourceDate -gt $destinationDate) {
                        Copy-Item -Path $sourceFile -Destination $destinationFile -Force -ErrorAction Ignore
                    }
                }
                else {
                    # Copy the file if it doesn't exist
                    Copy-Item -Path $sourceFile -Destination $destinationFile -ErrorAction Ignore
                }
            }
            else {
                # Copy the file, but don't overwrite if it already exists
                if (!(Test-Path -Path $destinationFile)) {
                    Copy-Item -Path $sourceFile -Destination $destinationFile -ErrorAction Ignore
                }
            }
        }
    }
    catch {
        WriteLog "ERROR processing file operation (copy): $_" # Log full exception details
    }
}
