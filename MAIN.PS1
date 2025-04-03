#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#			EndpointPilot User Profile Configuration Tool
#			MAIN.PS1
#
# 	Description 	
#	This management script is triggered by ENDPOINT-PILOT.PS1. This solution runs at logon via classic AD or GPO,
#	or, optionally, runs by Windows Scheduled Task to run independent of a Logon event.
#
#	MAIN.PS1 calls EP components, incl MGMT-Functions module, and "MGMT" Task Scripts	
#
#	MAIN.PS1 is designed to be called by ENDPOINT-PILOT.PS1 for production runs, and can be called 
#	independently for TEST non-prod runs.
#
#	This solution is VPN-aware to ensure needed Scripted tasks are
#	performed regularly for Remote users who may not be working on-prem (LAN).
#
#	Written by Julian West February 2025
#
#
###############################################################################################
#	Change Control Log (add dates and changes here)
###############################################################################################
#
#	Date		Modified by		Description of modification
#----------------------------------------------------------------------------------------------
#
#	02/16/2023	Julian West		Established PS Manage Main Script MAIN.PS1
#
############################################################################################
#
###############################################################################################

[CmdletBinding()]
PARAM(
	[parameter(ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true,
		Mandatory = $false)]
	[switch]$TestSharedVarModule = $false
)

#region TEST_MODE_CHECK

# $TestSharedVarModule = $true # Processes the MGMT-SHARED.ps1 script file, and does nothing else.
# Un-comment the above when wanting to force a Test of the MAIN.PS1 Runtime script, or run the script manually with Parameter Switch "-TestSharedVarModule"
# Script does nothing execept ONLY processes MGMT-SHARED.ps1 then exits.  Script will not perform any Endpoint Configuration run, nor will it
# perform any other tasks or create a Scheduled Task or Registry Run entry.  This option allows you to create the Runtime Script, without Deployment Script doing anything else.
# Intended for Sandbox testing on multiple PCs or environments prior to prod deployment.
# Script will place the Runtime Script in the same directory it is run from ( $PSScriptRoot ).

#Uncomment for debug logs:

#Start-Transcript -Path (Join-Path $Env:temp -ChildPath "debug.log") -Append -Confirm:$False

if($Env:USERPROFILE.EndsWith("system32\config\systemprofile")){

    $runningAsSystem = $True

    # Write-Output "Running as SYSTEM"

}else{

    $runningAsSystem = $False

    # Write-Output "Running as $($env:USERNAME)"

}

If ($TestSharedVarModule -eq $true) {
	$RunMode = $false
	$skipScheduledTaskCreation = $true
	$SharedVarModuleCheck - $true
	$triggerRuntimeScriptHere = $False
}

# Set Variables for Location for the Config / Runtime script-placement and script-names
If ($DeployRunTimeScriptOnly -ne $true) {
	$setRuntimeScriptFolder = Join-Path $Env:ProgramData -ChildPath "EndpointPilot"
}
else {
	$setRuntimeScriptFolder = $PSScriptRoot
}
#endregion TEST_MODE_CHECK

#region SET_RUNTIME_SCRIPT_PATH
$setRuntimeScriptPath = Join-Path $setRuntimeScriptFolder -ChildPath "./PSTART.PS1"
$setPSRuntimeLauncherPath = Join-Path $setRuntimeScriptFolder -ChildPath "./PSTART.vbs"
#endregion SET_RUNTIME_SCRIPT_PATH


#region ScriptBody

# load the shared functions module

Import-Module MGMT-Functions.psm1

# load shared variables and non independent functions from the MGMT-SHARED.ps1 file

. .\MGMT-SHARED.ps1

WriteLog "Checking Network Path reachability..."

[System.IO.DirectoryInfo]$NetworkPathCheck = $NetworkScriptPath


If (Test-Path -Path $NetworkPathCheck.FullName) {

	WriteLog "Network Test Path is reachable, continuing Logon Script run..."

}
else {

	WriteLog "Network Test Path is NOT reachable, exiting Script!"

	Exit (0)
}

## If we're on VPN + Network shares are reachable, continuing script-run...

# Exit if not running Enterprise Edition
Test-OperatingSystem




#Call Script Element / Component Modules -

try {
    .\MGMT-Telemetry.ps1
    # .\MGMT-Telemetry.ps1 -param1 value1 -param2 value2
}
catch {
    WriteLog "ERROR executing MGMT-Telemetry.ps1: $($_.Exception.Message)"
}

If ($SkipFileOps -ne $true) {
	   try {
	       .\MGMT-FileOps.ps1
	       # .\MGMT-FileOps.ps1 -param1 value1 -param2 value2
	   }
	   catch {
	       WriteLog "ERROR executing MGMT-FileOps.ps1: $($_.Exception.Message)"
	   }
}

If ($SkipRegOps -ne $true) {
	   try {
	       .\MGMT-RegOps.ps1
	       # .\MGMT-RegOps.ps1 -param1 value1 -param2 value2
	   }
	   catch {
	       WriteLog "ERROR executing MGMT-RegOps.ps1: $($_.Exception.Message)"
	   }
}

If ($SkipDriveOps -ne $true) {
	   try {
	       .\MGMT-DriveOps.ps1
	       # .\MGMT-DriveOps.ps1 -param1 value1 -param2 value2
	   }
	   catch {
	       WriteLog "ERROR executing MGMT-DriveOps.ps1: $($_.Exception.Message)"
	   }
}

If ($SkipRoamOps -ne $true) {
	   try {
	       .\MGMT-RoamOps.ps1
	       # .\MGMT-RoamOps.ps1 -param1 value1 -param2 value2 # Corrected comment
	   }
	   catch {
	       WriteLog "ERROR executing MGMT-RoamOps.ps1: $($_.Exception.Message)"
	   }
}


try {
    .\MGMT-USER-CUSTOM.ps1
    # .\MGMT-USER-CUSTOM.ps1 -param1 value1 -param2 value2 # Corrected comment
}
catch {
    WriteLog "ERROR executing MGMT-USER-CUSTOM.ps1: $($_.Exception.Message)"
}


# .\MGMT-HostFile.ps1
# .\MGMT-HostFile.ps1 -param1 value1 -param2 value2

try {
    .\MGMT-SchedTsk.ps1
    # .\MGMT-SchedTsk.ps1 -param1 value1 -param2 value2
}
catch {
    WriteLog "ERROR executing MGMT-SchedTsk.ps1: $($_.Exception.Message)"
}


#region CLEANUP_AND_EXIT

try {
    .\MGMT-Maint.ps1
    # .\MGMT-Maint.ps1 -param1 value1 -param2 value2
}
catch {
    WriteLog "ERROR executing MGMT-Maint.ps1: $($_.Exception.Message)"
}

#For VPN users, refresh the GPO once for User settings
WriteLog "Updating GPO Settings"

If ($runningAsSystem -eq $True) {
	gpupdate /target:computer
}
else {
	gpupdate /target:user
}

# gpupdate /target:user

#Final logging entries & network log placement

Log-InformationalEvent("EndpointPilot run completed for " + $env:UserName)
Start-Sleep -Milliseconds 100 #Wait
WriteLog "EndPointPilot Run Complete"

If ($CopyLogFileToNetwork -eq $true) {
	$NetworkLogFile = Join-Path $NetworkScriptPath -ChildPath "$LogFileName"
	Copy-Item "$LogFile" -Destination $NetworkLogFile -Force -ErrorAction Ignore | Out-Null
}

# Copy-Item "$LogFile" -Destination $NetworkLogFile -Force -ErrorAction Ignore | Out-Null

#endregion CLEANUP_AND_EXIT

#endregion ScriptBody

#Exit Script

Exit
