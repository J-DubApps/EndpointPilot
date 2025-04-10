###############################################################################################
#
#    EndpointPilot User Profile Mgmt Tool
#    MGMT-SHARED.PS1
#
#        Description 	
#        This file is a shared component called by MAIN.PS1
#        It is triggered at by a Windows Scheduled Task to run independent of a Logon event.
#
#        This solution is VPN-aware, to ensure needed Logon Scripted tasks are
#        performed regularly for Remote users who may not be working on-prem (LAN).
#
#        Written by Julian West February 2025
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
Function Test-ClientEnvironment() {
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

Function Test-OperatingSystem() {
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
    } Elseif ($OS -like "Microsoft Windows 11 Enterprise*") {
        $OSName = "Microsoft Windows 11 Enterprise"
        #$OS
        #$OSName
    } Else {
        Write-WarningEvent("The current operating system, " + $OS + ", is not supported. Exiting the script now.")
        #$OS
        #$OSName
        Exit
    }
}


Function Copy-Directory($Path, $NewPath) {
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

Function Copy-File($Path, $NewPath) {
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

Function Move-Files($Path, $NewPath) {
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

Function Write-InformationalEvent($Message) {
    #########################################################################
    #	Writes an informational event to the event log
    #########################################################################
    $QualifiedMessage = $ClientName + " Script: " + $Message
    Write-EventLog -LogName Application -Source Winlogon -Message $QualifiedMessage -EventId 1001 -EntryType Information
}

Function Write-WarningEvent($Message) {
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

#endregion FUNCTIONS
##
##########################################################################
##				End of PS-Manage Functions Section
##########################################################################
##           	Start of PS-Manage Common Variable Settings
##########################################################################
###

# region PowerShell Version and Edition
# Retrieve the current PowerShell version information -- if we're allowed to run under PowerShell Core (top comments left enabled)
# then we want to know if we're running under PowerShell Core or Windows PowerShell 5.1
$psVer = $PSVersionTable.PSVersion
$psEd = $PSVersionTable.PSEdition

# Display version information for debugging purposes
# Write-Output "Detected PowerShell Version: $psVer"
# Write-Output "Detected PowerShell Edition: $psEd"
# Write-Output "-------------------------------"

# Determine the PowerShell version and edition
if ($psEd -eq 'Desktop' -and $psVer.Major -eq 5 -and $psVer.Minor -eq 1) {
    # Write-Output "You are running Windows PowerShell 5.1 (Desktop Edition)."
    $psClassicDesktop = $true
} elseif ($psEd -eq 'Core' -and $psVers.Major -ge 7) {
    # Write-Output "You are running PowerShell Core (version 7.x or newer)."
    $psClassicDesktop = $false
} else {
    # Write-Output "You are running an unrecognized version of PowerShell: $psVer, Edition: $psEd"
}
#endregion PowerShell Version and Edition

# region OS Architecture
# Determine the OS Architecture (x64, x86, or Arm64)
# This code works in both Windows PowerShell 5.1 (Desktop) and PowerShell Core

# If running under WOW64 (32-bit process on a 64-bit OS), $env:PROCESSOR_ARCHITEW6432 will be defined.
if ($env:PROCESSOR_ARCHITEW6432) {
    $arch = $env:PROCESSOR_ARCHITEW6432
} else {
    $arch = $env:PROCESSOR_ARCHITECTURE
}

# Map the raw architecture value to a friendly output.
switch ($arch) {
    "AMD64" { $archFriendly = "x64" }
    "x86"   { $archFriendly = "x86 (32-bit)" }
    "ARM64" { $archFriendly = "Arm64" }
    default { $archFriendly = "Unknown Architecture ($arch)" }
}
# endregion OS Architecture
# Write-Output "Detected Operating System Architecture: $archFriendly"

#region 32bitHandling - if launched from 32bit PowerShell 5.1 on a 64-bit OS
If ($psClassicDesktop -eq $true) {
    if (([IntPtr]::Size -eq 4) -and ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')) {
        # If running in 32-bit PowerShell on a 64-bit OS, launch the 64-bit version of PowerShell
        try {
            &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
        } catch {
            Throw ('Failed to start {0}' -f $PSCOMMANDPATH)
        }
        exit
    } elseif (([IntPtr]::Size -eq 8) -and ($env:PROCESSOR_ARCHITECTURE -eq 'x86')) {
        exit # we are not going to support 32bit PowerShell on 32bit OS
    }
}
#endregion 32bitHandling

#region Variables

#Declare the Client Variables
#Set Client name, Log File Location etc

$HostName = $env:COMPUTERNAME
$LogFile = "$env:userprofile\LOGON-$env:computername.log"

# Load the configuration from CONFIG.json
$configPath = "CONFIG.json"
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Assign variables from config json
$ClientName = $config.ClientName
$Refresh_Interval = $config.Refresh_Interval    #Seconds
$NetworkScriptRootPath = $config.NetworkScriptRootPath
$CopyLogFileToNetwork = $config.CopyLogFileToNetwork    #Set to $true or $false from Config
# populates the network location, below, if above var is set to $true from Config.  Create that shared folder if it doesn't exist, and make sure the user has write access to it.
$NetworkLogFile = $config.NetworkLogFile
$RoamFiles = $config.RoamFiles #Set to $true if you wish to leverage roaming/syncing certain files (files to sync/roam are specified in ROAM-OPS.json)
# Set the network location, below, if above var is set to $true.  Create that shared folder if it doesn't exist, and make sure the user has write & folder creation rights to it.
$NetworkRoamFolder = $config.NetworkRoamFolder & "\LOGON-$env:UserName-on-$env:computername.log"
$SkipFileOps = $config.SkipFileOps
$SkipDriveOps = $config.SkipDriveOps
$SkipRegOps = $config.SkipRegOps
$SkipRoamOps = $config.SkipRoamOps


# $ClientName = "McKool Smith"
# $Refresh_Interval = 900 #Seconds
# $NetworkScriptRootPath = "\\servername\SHARE\PS-Epilot\"
# $CopyLogFileToNetwork = $false #Set to $true to copy the log file to the network
# Set the network location, below, if above var is set to $true.  Create that shared folder if it doesn't exist, and make sure the user has write access to it.
# $NetworkLogFile = "\\servername\SHARE\Tools\FlagFiles\EPilot_Script_RunLogs\EPilot-$env:UserName-on-$env:computername.log"
# $RoamFiles = $false #Set to $true if you wish to leverage roaming/syncing certain files (files to sync/roam are specified in ROAM-OPS.json)
# Set the network location, below, if above var is set to $true.  Create that shared folder if it doesn't exist, and make sure the user has write & folder creation rights to it.
# $NetworkRoamFolder = "\\servername\SHARE\RoamingFiles"

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
Write-InformationalEvent("MS Logon Script started for " + $env:UserName)



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
