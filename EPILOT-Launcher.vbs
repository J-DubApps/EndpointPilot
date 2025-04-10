On Error Resume Next

Set WshShell = CreateObject("WScript.Shell") 
Set Filesys=CreateObject("Scripting.FileSystemObject") 

Dim strHomeFolder

' Check if the script is running in a 32-bit or 64-bit environment  
If InStr(1, WshShell.ExpandEnvironmentStrings("%PROCESSOR_ARCHITECTURE%"), "64") > 0 Then

    ' WshShell.Run "echo Running in 64-bit environment", 0
Else
    ' exit the scipt, we only want to run in 64-bit

    Exit
    ' WshShell.Run "echo Running in 32-bit environment", 0
End If

    ' Check if PowerShell Core is installed, and set a boolean variable to true/false if PS Core exists/doesn't exist

Dim strPSCorePath 
strPSCorePath = "C:\Program Files\PowerShell\7\pwsh.exe"
Dim PSCoreExists
PSCoreExists = Filesys.FileExists(strPSCorePath)
If PSCoreExists Then
    ' WshShell.Run "echo PowerShell Core exists", 0
Else
    ' WshShell.Run "echo PowerShell Core does not exist", 0
End If


strHomeFolder = WshShell.ExpandEnvironmentStrings("%PROGRAMDATA%")

' Check if the EndpointPilot folder exists in the ProgramData directory
' If it does, run the PowerShell script
' If it does not, do nothing
' The script is located in the EndpointPilot folder under ProgramData
' The script is called ENDPOINT-PILOT.PS1
' The script is run with the -NonInteractive and -ExecutionPolicy Bypass options
' The script is run in a hidden window (0)
' The script is run with the -File option
' The script is run with the path to the script as an argument

If Filesys.FolderExists(strHomeFolder & "\EndpointPilot\") Then

    If PSCoreExists Then
        ' PSCoreExists is True, so we run the script with PowerShell Core
        'WshShell.Run strPSCorePath & " -NonInteractive -ExecutionPolicy Bypass -File " & strHomeFolder + "\EndpointPilot\ENDPOINT-PILOT.PS1", 0
        WshShell.Run Chr(34) & strPSCorePath & Chr(34) & " -NonInteractive -ExecutionPolicy Bypass -File " & Chr(34) & strHomeFolder & "\EndpointPilot\ENDPOINT-PILOT.PS1" & Chr(34), 0
    Else

        ' PSCoreExists is False, so we run the script with PowerShell 5.1
        WshShell.Run "%windir%\System32\WindowsPowerShell\v1.0\powershell.exe -NonInteractive -ExecutionPolicy Bypass -File " & strHomeFolder + "\EndpointPilot\ENDPOINT-PILOT.PS1", 0
        
    End If

    ' Do Nothing
    ' The folder does not exist, so we do not need to run the script.
End If 


Set WshShell = Nothing
Set Filesys = Nothing