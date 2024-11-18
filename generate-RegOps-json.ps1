<#

This script creates an array of hashtables, each representing a registry entry. It populates the "id", "name", "path", "value", "regtype" and "delete" elements
for each entry. Then it uses the ConvertTo-Json cmdlet to convert the array to a JSON string, and the Out-File cmdlet to write the string to a
file named "registry.json" in the current directory. This script will generate the json file with the format and structure you described.

As you can see, the script generates three entries, you can adjust the number of entries and the information inside the entries according to your need.

#>


$jsonData = @(
    @{
        id = "001"
        name = "key1"
        path = "HKEY_CURRENT_USER\Software\key1"
        value = "value1"
        regtype = "string"
        delete = $false,
        "_comment1": "This is a registry entry",
        "_comment2": "Secondary Comment"
    },
    @{
        id = "002"
        name = "key2"
        path = "HKEY_LOCAL_MACHINE\Software\key2"
        value = "1"
        regtype = "dword"
        delete = $false,
        "_comment1": "This is a registry entry",
        "_comment2": "Secondary Comment"
    },
    @{
        id = "003"
        name = "key3"
        path = "HKEY_CURRENT_USER\Software\key3"
        value = "0"
        regtype = "dword"
        delete = $false,
        "_comment1": "This is a registry entry",
        "_comment2": "Secondary Comment"
    }
)

# Specify the file path for the output file
$file = "Reg-Ops.json"

# $jsonData | ConvertTo-Json | Out-File .\$filePath

# Check if the file already exists
if (Test-Path $file) {
    Write-Host "WARNING: This will erase any existing contents within the existing file '$file'."
    $response = Read-Host "Do you wish to continue (y/N)?"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Operation canceled. The file was not overwritten."
        exit
    }
}

# Convert the JSON data to a PowerShell object
$jsonObject = ConvertFrom-Json $jsonData

# Convert the PowerShell object back to JSON with formatting
ConvertTo-Json $jsonObject -Depth 100 | Out-File -Encoding UTF8 -FilePath $file

Write-Host "File created: $file"

