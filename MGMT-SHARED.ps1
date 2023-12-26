#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#    PS-Manage Logon / User Profile Mgmt Script Shared Settings Script
#    MGMT-SHARED.PS1
#
#        Description 	
#        This file is a shared component called by MAIN.PS1
#        It is triggered at logon and, optionally, by Windows Scheduled Tasks to run
#        independent of a Logon event.
#
#        This logon script is VPN-aware, to ensure needed Logon Scripted tasks are
#        performed regularly for Remote users who may not be working on-prem (LAN).
#
#        Written by Julian West February 2023
#
#
###############################################################################################

# Check to see if this script is being run directly, or if it is being dot-sourced into another script.

if ($MyInvocation.InvocationName -ne '.') {
    Write-Warning 'This script should be dot-sourced into another script, not run independently.'
    return
}

# rest of the script contains shared variables and functions for use in MAIN.PS1 and other scripts


#region FUNCTIONS
Function Check-ClientEnvironment() {
    ##########################################################################
    ##	Checks if the machine is connected to the client domain
    ##	and if so if it is connected to a PC or to a Citrix machine
    ##########################################################################

    #Check if the Computer is in a Workstations directory

    #If([string]$objComputer -like "*BRWorkstations*"){
    #	$PCType = "Workstation"
    #	}
    #Else{
    #	Log-WarningEvent("Non-compliant desktop environment detected. Quitting the script now.")
    #	Exit
    #	}
}

Function Check-OperatingSystem() {
    ##########################################################################
    ##	Checks what version of Windows the machine is running
    ##	and quits if it is on an unsupported platform
    ##########################################################################
    $wmiOS = Get-WmiObject -Class Win32_OperatingSystem;
    $OS = $wmiOS.caption

    If ($OS -like "Microsoft Windows 10 Enterprise*") {
        $OSName = "Microsoft Windows 10 Enterprise"
        #$OS
        #$OSName
    }
    Elseif ($OS -like "Microsoft Windows 11 Enterprise*") {
        $OSName = "Microsoft Windows 11 Enterprise"
        #$OS
        #$OSName
    }
    Else {
        Log-WarningEvent("The current operating system, " + $OS + ", is not supported. Exiting the script now.")
        #$OS
        #$OSName
        Exit
    }
}


Function Cp-Directory($Path, $NewPath) {
    ##########################################################################
    ##	Copies a directory/folder to a new location
    ##########################################################################
    If (Test-Path -Path $Path) {
        $cmd = "Robocopy """ + $Path + """ """ + $NewPath + """ /XF " + $strExcludedFiles + " /XD " + $strExcludedDirectories + " /XO /COPY:DAT /R:0 /W:1 /S /E"
        #$wshell = New-Object -ComObject Wscript.Shell
        #$wshell.Popup($cmd,0,"Done",0x1)
        Invoke-Expression $cmd
    }
}

Function Cp-File($Path, $NewPath) {
    ##########################################################################
    ##	Copies a file or a set of files to a new location
    ##########################################################################
    If (Test-Path -Path $Path) {
        #$cmd = $Robocopy + " " + $Path + " " +  $NewPath + " /XO /COPY:DAT /R:0 /W:1"
        #write-host $cmd
        Robocopy $Path $NewPath /XO /COPY:DAT /R:0 /W:1 | Out-Null
        #& $cmd
        #Copy-Item $Path $NewPath -force
    }
}

Function Mv-Files($Path, $NewPath) {
    ##########################################################################
    ##	Moves a file or a set of files to a new location
    ##########################################################################
    If (Test-Path -Path $Path) {
        #$cmd = $Robocopy + " " + $Path + " " +  $NewPath + " /XO /COPY:DAT /R:0 /W:1"
        #write-host $cmd
        Robocopy $Path $NewPath /XO /COPY:DAT /R:0 /W:1 | Out-Null
        #& $cmd
        #Copy-Item $Path $NewPath -force
    }
}

Function Import-RegKey($RegFile) {
    ##########################################################################
    ##	Imports a Registry Key to the local machine
    ##########################################################################
    If (Test-Path -Path $RegFile) {
        REG Import $RegFile /reg:32
    }
}

Function Log-InformationalEvent($Message) {
    #########################################################################
    #	Writes an informational event to the event log
    #########################################################################
    $QualifiedMessage = $ClientName + " Script: " + $Message
    Write-EventLog -LogName Application -Source Winlogon -Message $QualifiedMessage -EventId 1001 -EntryType Information
}

Function Log-WarningEvent($Message) {
    #########################################################################
    # Writes a warning event to the event log
    #########################################################################
    $QualifiedMessage = $ClientName + " Script:" + $Message
    Write-EventLog -LogName Application -Source Winlogon -Message $QualifiedMessage -EventId 1001 -EntryType Warning
}

Function Move-Directory($Path, $NewPath) {
    ##########################################################################
    ##	Exports a file to a new location
    ##########################################################################
    If (Test-Path -Path $Path) {
        Move-Item $Path $NewPath -force
    }
}


Function WriteLog($LogString) {
    ##########################################################################
    ##	Writes Run info to a logfile set in $LogFile variable
    ##########################################################################

    #Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
}

function Get-TextWithin {
    <#
      .SYNOPSIS
          Get the text between two surrounding characters (e.g. brackets, quotes, or custom characters)
      .DESCRIPTION
          Use RegEx to retrieve the text within enclosing characters.
    .PARAMETER Text
          The text to retrieve the matches from.
      .PARAMETER WithinChar
          Single character, indicating the surrounding characters to retrieve the enclosing text for.
          If this paramater is used the matching ending character is "guessed" (e.g. '(' = ')')
      .PARAMETER StartChar
          Single character, indicating the start surrounding characters to retrieve the enclosing text for.
      .PARAMETER EndChar
          Single character, indicating the end surrounding characters to retrieve the enclosing text for.
      .EXAMPLE
          # Retrieve all text within single quotes
      $s=@'
here is 'some data'
here is "some other data"
this is 'even more data'
'@
           Get-TextWithin $s "'"
  .EXAMPLE
  # Retrieve all text within custom start and end characters
  $s=@'
here is /some data\
here is /some other data/
this is /even more data\
'@
  Get-TextWithin $s -StartChar / -EndChar \
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
            ValueFromPipeline = $true,
            Position = 0)]
        $Text,
        [Parameter(ParameterSetName = 'Single', Position = 1)]
        [char]$WithinChar = '"',
        [Parameter(ParameterSetName = 'Double')]
        [char]$StartChar,
        [Parameter(ParameterSetName = 'Double')]
        [char]$EndChar
    )
    $htPairs = @{
        '(' = ')'
        '[' = ']'
        '{' = '}'
        '<' = '>'
    }
    if ($PSBoundParameters.ContainsKey('WithinChar')) {
        $StartChar = $EndChar = $WithinChar
        if ($htPairs.ContainsKey([string]$WithinChar)) {
            $EndChar = $htPairs[[string]$WithinChar]
        }
    }
    $pattern = @"
(?<=\$StartChar).+?(?=\$EndChar)
"@
    [regex]::Matches($Text, $pattern).Value
}


#endregion FUNCTIONS
##
##########################################################################
##				End of PS-Manage Functions Section
##########################################################################
##           	Start of PS-Manage Common Variable Settings
##########################################################################
###

#region Variables

#Declare the Client Variables
#Set Client name, Log File Location etc

$ClientName = "McKool Smith"
$HostName = $env:COMPUTERNAME
$Refresh_Interval = 900 #Seconds
$NetworkScriptPath = "\\McKoolSmith.Law\SysVol\McKoolSmith.Law\Policies\"
$LogFile = "$env:userprofile\LOGON-$env:computername.log"
$CopyLogFileToNetwork = $false #Set to $true to copy the log file to the network
# Set the network location, below, if above var is set to $true.  Create that shared folder if it doesn't exist, and make sure the user has write access to it.
$NetworkLogFile = "\\servername\SHARE\Tools\FlagFiles\Logon_Script_RunLogs\LOGON-$env:UserName-on-$env:computername.log"
$RoamFiles = $false #Set to $true if you wish to leverage roaming/syncing certain files (files to sync/roam are specified in ROAM-OPS.json)
# Set the network location, below, if above var is set to $true.  Create that shared folder if it doesn't exist, and make sure the user has write & folder creation rights to it.
$NetworkRoamFolder = "\\servername\SHARE\RoamingFiles"

Set-Alias -Name 'Get-Permissions' -Value 'Get-Permission'

#region Check
#region Defaults
$SCT = 'SilentlyContinue'
Get-ChildItem -Path $LogFile | Remove-Item -Force -ErrorAction Ignore | Out-Null
$ErrorActionPreference = "Continue"
#Set the Robocopy location
$Robocopy = "C:\Windows\System32\Robocopy.exe"
#endregion Defaults

#Collect the Computer distinguished name
$filter = "(&(objectCategory=computer)(objectClass=computer)(cn=$env:COMPUTERNAME))"
$objComputer = ([adsisearcher]$filter).FindOne().Properties.distinguishedname


#endregion variables

#region ScriptBody_MGMT-SHARED

#Log Runtime start
WriteLog "Logon Script Run Start"

#Create Event Viewer entry for the start of the script
Log-InformationalEvent("MS Logon Script started for " + $env:UserName)



# Clean-up
$RegistryRoot = $null

# Figure out if we have an existing PowerShell Registry Provider mapping
$paramGetPSDrive = @{
    ErrorAction   = $SCT
    WarningAction = $SCT
}
#endregion Check


#Set Excluded Files and Directories
$strExcludedDirectories =	"`"! Don't delete me! I'm helping Palo Alto hunt for ransomware!`"" + " " +
"`"Windows`"" + " " +
"`"My Documents`"" + " " +
"`"Documents`"" + " " +
"`"MigrationSettings`"" + " " +
"`"*_canary*`""

#$wshell = New-Object -ComObject Wscript.Shell
#$wshell.Popup("Excluded Directories: " + $strExcludedDirectories,0,"Done",0x1)


$strExcludedFiles = "`"*.isn`"" + " " +
"`"*.iso`"" + " " +
"`"*_canary*`""

#$wshell.Popup("Excluded Files: " + $strExcludedFiles,0,"Done",0x1)

#endregion ScriptBody_MGMT-SHARED
