<#

This script creates an array of hashtables, each representing a registry entry. It populates the "id", "name", "path", "value", "regtype" and "delete" elements
for each entry. Then it uses the ConvertTo-Json cmdlet to convert the array to a JSON string, and the Out-File cmdlet to write the string to a
file named "registry.json" in the current directory. This script will generate the json file with the format and structure you described.

As you can see, the script generates three entries, you can adjust the number of entries and the information inside the entries according to your need.

#>


$json = @(
    @{
        id = "1"
        name = "key1"
        path = "HKEY_CURRENT_USER\Software\key1"
        value = "value1"
        regtype = "string"
        delete = $false
    },
    @{
        id = "2"
        name = "key2"
        path = "HKEY_LOCAL_MACHINE\Software\key2"
        value = "1"
        regtype = "dword"
        delete = $false
    },
    @{
        id = "3"
        name = "key3"
        path = "HKEY_CURRENT_USER\Software\key3"
        value = "0"
        regtype = "dword"
        delete = $false
    }
)
$json | ConvertTo-Json | Out-File .\regops.json
