<#

This script creates an example File Operations json file, with test data.
The code creates an array of hashtables, each representing a File Operations entry. It populates the "id", "srcfilename", "sourcepath", "dstfilename", "destinationpath"
and "overwrite" and "comment" elements for each entry.

Then it uses the ConvertTo-Json cmdlet to convert the array to a JSON string, and the Out-File cmdlet to write the string to a
file named "registry.json" in the current directory. This script will generate the json file with the format and structure you described.

As you can see, the script generates three entries, you can adjust the number of entries and the information inside the entries according to your need.

#>



[
    {
        "id": 1,
        "srcfilename": "example1.txt",
        "dstfilename": "example1.txt",
        "sourcePath": "C:\example\folder1",
        "destinationPath": "C:\example\destination1",
        "overwrite": true,
        "copyonce": false,
        "comments": "place comment here"
    },
    {
        "id": 2,
        "srcfilename": "example2.txt",
        "dstfilename": "example123.txt",
        "sourcePath": "C:\example\folder2",
        "destinationPath": "C:\example\destination2",
        "overwrite": false,
        "copyonce": true,
        "comments": "place comment here"
    },
    {
        "id": 3,
        "srcfilename": "example3.txt",
        "dstfilename": "example3.txt",
        "sourcePath": "C:\example\folder3",
        "destinationPath": "C:\example\destination3",
        "overwrite": true,
        "copyonce": false,
        "comments": "place comment here"
    }
]
