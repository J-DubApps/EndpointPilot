#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#				PS-Manage Logon / Endpoint Configuration Script
#				MAIN.PS1 = MS-Logon-EC.ps1
#
# Description 	This Logon script
#				It is triggered at logon and, optionally, by Windows Scheduled Task to run
#				independent of a Logon event.

#				This logon script is VPN-aware, to ensure needed Logon Scripted tasks are
#				performed regularly for Remote users who may not be working on-prem (LAN).
#
#				Written by Julian West February 2023
#
#				Maintained by McKool Smith SysOps Group and Kraft Kennedy
#
###############################################################################################
#	Change Control Log (add dates and changes here)
###############################################################################################
#
#	Date		Modified by		Description of modification
#----------------------------------------------------------------------------------------------
#
#	04/01/2022	MS (JW)		Forked from MS-Logon.ps1 for firm VPN users.
#   04/15/2022  MS (JW)     Added code to determine general GPS locale (for catching Hotspot abuse)
#   04/16/2022  MS (JW)     Added code to attempt to determine ISP Info
#
############################################################################################
#
###############################################################################################

[CmdletBinding()]
PARAM(
	[parameter(ValueFromPipeline=$true,
				ValueFromPipelineByPropertyName=$true,
				Mandatory=$false)]
	[switch]$TestSharedVarModule=$false
)

#region TEST_MODE_CHECK

# $TestSharedVarModule = $true # Processes the MOD-SHARED.ps1 MODule file, and does nothing else.
# Un-comment the above when wanting to force a Test of the MAIN.PS1 Runtime script, or run the script manually with Parameter Switch "-TestSharedVarModule"
# Script does nothing execept ONLY processes MOD-SHARED.ps1 then exits.  Script will not perform any Endpoint Configuration run, nor will it
# perform any other tasks or create a Scheduled Task or Registry Run entry.  This option allows you to create the Runtime Script, without Deployment Script doing anything else.
# Intended for Sandbox testing on multiple PCs or environments prior to prod deployment.
# Script will place the Runtime Script in the same directory it is run from ( $PSScriptRoot ).

If($TestSharedVarModule -eq $true){
	$RunMode = $false
	$skipScheduledTaskCreation = $true
	$SharedVarModuleCheck - $true
	$triggerRuntimeScriptHere = $False
}

# Set Variables for Location for the Config / Runtime script-placement and script-names
If($DeployRunTimeScriptOnly -ne $true){
	$setRuntimeScriptFolder = Join-Path $Env:ProgramData -ChildPath "PS-MANAGE"
}else{
	$setRuntimeScriptFolder = $PSScriptRoot
}
#endregion TEST_MODE_CHECK

#region SET_RUNTIME_SCRIPT_PATH
$setRuntimeScriptPath = Join-Path $setRuntimeScriptFolder -ChildPath "./PSTART.PS1"
$setPSRuntimeLauncherPath = Join-Path $setRuntimeScriptFolder -ChildPath "./PSTART.vbs"
#endregion SET_RUNTIME_SCRIPT_PATH


#region ScriptBody

# load shared variables and functions from the Component MODule MOD-SHARED.ps1

. .\MOD-SHARED.ps1

WriteLog "Checking Network Path reachability..."

[System.IO.DirectoryInfo]$NetworkPathCheck = $NetworkScriptPath


If (Test-Path -Path $NetworkPathCheck.FullName) {

	WriteLog "Network Test Path is reachable, continuing Logon Script run..."

	} else {

	WriteLog "Network Test Path is NOT reachable, exiting Script!"

	Exit (0)
}

## If we're on VPN + Network shares are reachable, continuing script-run...

# Exit if not running Enterprise Edition
	Check-OperatingSystem




#Call Script Element / Component Modules -

.\MOD-Telemetry.ps1
# .\Module-FileOps.ps1 -param1 value1 -param2 value2

.\MOD-FileOps.ps1
# .\Module-FileOps.ps1 -param1 value1 -param2 value2

.\MOD-RegOps.ps1
# .\Module-FileOps.ps1 -param1 value1 -param2 value2

.\MOD-DSC.ps1
# .\Module-FileOps.ps1 -param1 value1 -param2 value2


.\MOD-HostFile.ps1
# .\Module-FileOps.ps1 -param1 value1 -param2 value2

.\MOD-SchedTsk.ps1
# .\Module-FileOps.ps1 -param1 value1 -param2 value2


#region CLEANUP_AND_EXIT

.\MOD-Maintenance.ps1
# .\Module-FileOps.ps1 -param1 value1 -param2 value2

#For VPN users, refresh the GPO once for User settings
WriteLog "Updating User GPO Settings"
gpupdate /target:user

#Final logging entries & network log placement

	Log-InformationalEvent("MS Logon Script run completed for " + $env:UserName)
    Start-Sleep -Milliseconds 100 #Wait
	WriteLog "Logon Script Complete"

	Copy-Item "$LogFile" -Destination $NetworkLogFile -Force -ErrorAction Ignore | Out-Null

#endregion CLEANUP_AND_EXIT

#endregion ScriptBody

#Exit Script
