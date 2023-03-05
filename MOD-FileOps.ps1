if ($MyInvocation.InvocationName -ne '.') {

	# We are running independently of MAIN.PS1, load the Shared MODule
	# and coninue the rest of the script with your shared variables and functions
	. .\MOD-SHARED.ps1

} else {

    # We are being called by MAIN.PS1, no need to load the Shared MODule
}


<#
The JSON file read by this script contains an array of objects, where each object represents a file to be copied.

The goal of this script is to provide a flexible way to copy files with different options based on the instructions provided in the JSON file.

The object contains properties such as "srcfilename", "dstfilename", "sourcePath", "destinationPath", "overwrite", "copyonce", and "comments".
These properties provide instructions to the PowerShell script on how to perform the file copy operation.

The PowerShell script reads the JSON file using the Get-Content cmdlet and then converts the JSON content to a PowerShell object using the
ConvertFrom-Json cmdlet. The script then loops through each object in the PowerShell object and extracts the file information, such as the source and
destination file paths, and the overwrite and copyonce boolean values.

The script then constructs the full file path for each file using the Join-Path cmdlet, and performs the copy operation according to the overwrite and
copyonce boolean values. If $copyonce is true, the script checks if the destination file already exists and only copies the file if it doesn't exist.
If $overwrite is true, the script checks if the source file is newer than the destination file and only copies the file if it is. If $overwrite is false,
 the script skips the file if the destination file already exists.

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
} catch {
    Write-Host "Error: $_"
}

    # Perform copy actions specified in the JSON file, for each file
    # Observe the '$copyonce' and '$overwrite' boolean actions
    # If $overwrite is 'true' then ONLY overwrite if the $sourceFile is newer than $destinationFile
    if ($existCheckLocation -and $existCheck) {
        $existCheckPath = Join-Path -Path $destinationPath -ChildPath $existCheckLocation
        if (Test-Path -Path $existCheckPath) {
            if ($existCheck -eq "No") {
                return
            }
        } else {
            if ($existCheck -eq "Yes") {
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
        } else {
            # Copy the file if it doesn't exist
            Copy-Item -Path $sourceFile -Destination $destinationFile -Force -ErrorAction Ignore
        }
    } else {
        if ($overwrite) {
            if (Test-Path $destinationFile) {
                $sourceDate = (Get-Item $sourceFile).LastWriteTime
                $destinationDate = (Get-Item $destinationFile).LastWriteTime
                if ($sourceDate -gt $destinationDate) {
                    Copy-Item -Path $sourceFile -Destination $destinationFile -Force -ErrorAction Ignore
                }
            } else {
                # Copy the file if it doesn't exist
                Copy-Item -Path $sourceFile -Destination $destinationFile -ErrorAction Ignore
            }
        } else {
            # Copy the file, but don't overwrite if it already exists
            if (!(Test-Path -Path $destinationFile)) {
                Copy-Item -Path $sourceFile -Destination $destinationFile -ErrorAction Ignore
            }
        }
    }
} catch {
    Write-Host "Error: $_"
}
}
