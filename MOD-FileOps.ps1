




if ($MyInvocation.InvocationName -ne '.') {

	# We are running independently of MAIN.PS1, load the Shared MODule
	# and coninue the rest of the script with your shared variables and functions
	. .\MOD-SHARED.ps1

} else {

    # We are being called by MAIN.PS1, no need to load the Shared MODule
}




# PS File Copy Script
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

    # Construct full file path for each file
    $sourceFile = Join-Path -Path $sourcePath -ChildPath $srcfilename
    $destinationFile = Join-Path -Path $destinationPath -ChildPath $dstfilename

    # Perform copy actions specied in the JSON file, for each file
    # Observe the '$copyonce' and '$overwrite' boolean actions
    # If $overwrite is 'true' then ONLY overwrite if the $sourceFile is newer than $destinationFile

    if($copyonce){
        if ( Test-Path -Path $destinationFile) {
            # Write-Host "File already exists, skipping copy"
        } else {
            # Copy the file if it doesn't exist
            Copy-Item -Path $sourceFile -Destination $destinationFile -Force
        }
    }
    else  # if '$copyonce' is 'false' then we move on through this inner if statement
    {
        if($overwrite) {
            if (Test-Path $destinationFile) {
              $sourceDate = (Get-Item $sourceFile).LastWriteTime
              $destinationDate = (Get-Item $destinationFile).LastWriteTime
              if ($sourceDate -gt $destinationDate) {
                Copy-Item -Path $sourceFile -Destination $destinationFile
              }
            } else {
            # Copy the file if it doesn't exist
              Copy-Item -Path $sourceFile -Destination $destinationFile
            }
        } else {
    		# Copy the file, but don't overwrite if it already exists

           	# Write-Host "Source file does not exist, skipping copy"

            # Test Code - Leave remarked
            # Copy-Item -Path $sourceFile -Destination $destinationFile -ErrorAction SilentlyContinue
        }
    }
}
