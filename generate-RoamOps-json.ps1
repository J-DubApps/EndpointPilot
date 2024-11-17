<#

This script creates an example File Operations json file, with example/test data.

This script reads in PS-MANAGE's File Operations example/test JSON data as a string, and converts it to a PowerShell object using ConvertFrom-Json.

Then the script converts the PowerShell object back to JSON using ConvertTo-Json, resulting in a default example/test JSON file written to "Roam-Ops.json" using Out-File. The -Depth parameter is set to 100 to ensure that all properties of the PowerShell object.

As for the key-value pairs in this default example/test json file: it contains the "id", "srcfilename", "sourcepath", "dstfilename", "destinationpath" and "overwrite" and "commentx" elements for each entry.  It also includes file deletion and file existence check elements (for item-level targeting similar to GPP).

As you can see, the script generates four entries, you can adjust the number of entries and the information inside the entries according to your need, and re-generate this file as-needed.

#>


# Define the JSON data as a PowerShell object
$jsonData = @'
[
    {
        "id": 001,
        "srcfilename": "example1.txt",
        "dstfilename": "example1.txt",
        "sourcePath": "C:\\example\\folder1",
        "destinationPath": "C:\\example\\destination1",
        "overwrite": true,
        "copyonce": false,
        "existCheckLocation": "C:\\example\\existcheckfile.txt",
        "existCheck": false,
        "deleteFile": false,
        "_comment1": "This is File Copy",
        "_comment2": "If existCheckLocation *and* existCheck are not blank, then existCheck must either be yes (check if exist) or no (check if *not* exist)"
    },
    {
        "id": 002,
        "srcfilename": "example2.txt",
        "dstfilename": "example123.txt",
        "sourcePath": "C:\\example\\folder2",
        "destinationPath": "C:\\example\\destination2",
        "overwrite": false,
        "copyonce": true,
        "existCheckLocation": "",
        "existCheck": false,
        "deleteFile": false,
        "_comment1": "This is a CopyOnce Example, with no Existence Check performed.  File will copy once.",
        "_comment2": ""
    },
    {
        "id": 003,
        "srcfilename": "example3.txt",
        "dstfilename": "example3.txt",
        "sourcePath": "C:\\example\\folder3",
        "destinationPath": "C:\\example\\destination3",
        "overwrite": true,
        "copyonce": false,
        "existCheckLocation": "C:\\example\\existcheckfolder",
        "existCheck": true,
        "deleteFile": false,
        "_comment1": "place comment here",
        "_comment2": ""
    },
    {
        "id": 004,
        "srcfilename": "",
        "dstfilename": "example4.txt",
        "sourcePath": "",
        "destinationPath": "C:\\example\\destination4",
        "overwrite": false,
        "copyonce": false,
        "existCheckLocation": "",
        "existCheck": "",
        "deleteFile": true,
        "_comment1": "place comment here",
        "_comment2": "place comment here"
    }
]
'@

# Specify the file path for the output file
$file = "Roam-Ops.json"

# Check if the file already exists and prompt the user before overwriting it
if (Test-Path $file) {
    $overwrite = Read-Host "The file $file already exists. Do you want to overwrite it? (Y/N)"
    if ($overwrite -ne "Y") {
        Write-Host "File creation canceled."
        exit
    }
}

# Convert the JSON data to a PowerShell object
$jsonObject = ConvertFrom-Json $jsonData

# Convert the PowerShell object back to JSON with formatting
ConvertTo-Json $jsonObject -Depth 100 | Out-File -Encoding UTF8 -FilePath $file

Write-Host "File created: $file"
