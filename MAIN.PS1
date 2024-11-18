#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#			PS-MANAGE User Profile Configuration Script
#			MAIN.PS1
#
# 	Description 	
#	This management script is triggered at logon and, optionally, by Windows Scheduled Task to run
#	independent of a Logon event.
#
#	MAIN.PS1 calls PS-MANAGE components, incl MGMT-Functions module, and "MGMT" Task Scripts	
#
#	MAIN.PS1 is designed to be called by PS-MANAGE.PS1 for production runs, and can be called 
#	independently for TEST non-prod runs.
#
#	This solution is VPN-aware to ensure needed Scripted tasks are
#	performed regularly for Remote users who may not be working on-prem (LAN).
#
#	Written by Julian West February 2023
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

If ($TestSharedVarModule -eq $true) {
	$RunMode = $false
	$skipScheduledTaskCreation = $true
	$SharedVarModuleCheck - $true
	$triggerRuntimeScriptHere = $False
}

# Set Variables for Location for the Config / Runtime script-placement and script-names
If ($DeployRunTimeScriptOnly -ne $true) {
	$setRuntimeScriptFolder = Join-Path $Env:ProgramData -ChildPath "PS-MANAGE"
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
Check-OperatingSystem




#Call Script Element / Component Modules -

.\MGMT-Telemetry.ps1
# .\MGMT-Telemetry.ps1 -param1 value1 -param2 value2

If($SkipFileOps -ne $true) {
	.\MGMT-FileOps.ps1
	# .\MGMT-FileOps.ps1 -param1 value1 -param2 value2
}

If($SkipRegOps -ne $true) {
	.\MGMT-RegOps.ps1
	# .\MGMT-RegOps.ps1 -param1 value1 -param2 value2
}

If($SkipDriveOps -ne $true) {
	.\MGMT-DriveOps.ps1
	# .\MGMT-DriveOps.ps1 -param1 value1 -param2 value2
}

If($SkipRoamOps -ne $true) {
	.\MGMT-RoamOps.ps1
	# .\MGMT-DriveOps.ps1 -param1 value1 -param2 value2
}


.\MGMT-DSC.ps1
# .\MGMT-DSC.ps1 -param1 value1 -param2 value2


.\MGMT-HostFile.ps1
# .\MGMT-HostFile.ps1 -param1 value1 -param2 value2

.\MGMT-SchedTsk.ps1
# .\MGMT-SchedTsk.ps1 -param1 value1 -param2 value2


#region CLEANUP_AND_EXIT

.\MGMT-Maint.ps1
# .\MGMT-Maint.ps1 -param1 value1 -param2 value2

#For VPN users, refresh the GPO once for User settings
WriteLog "Updating User GPO Settings"
gpupdate /target:user

#Final logging entries & network log placement

Log-InformationalEvent("PS Manage script run completed for " + $env:UserName)
Start-Sleep -Milliseconds 100 #Wait
WriteLog "Logon Script Complete"

Copy-Item "$LogFile" -Destination $NetworkLogFile -Force -ErrorAction Ignore | Out-Null

#endregion CLEANUP_AND_EXIT

#endregion ScriptBody

#Exit Script
