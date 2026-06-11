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
	[switch]$TestSharedVarModule = $false,
	[switch]$DryRun = $false
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
	$SharedVarModuleCheck = $true
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
$setRuntimeScriptPath = Join-Path $setRuntimeScriptFolder -ChildPath "./ENDPOINT-PILOT.PS1"
$setPSRuntimeLauncherPath = Join-Path $setRuntimeScriptFolder -ChildPath "./EPILOT-Launcher.vbs"
#endregion SET_RUNTIME_SCRIPT_PATH


#region ScriptBody

# load the shared functions module

Import-Module (Join-Path $PSScriptRoot "MGMT-Functions.psm1") -Force

# load shared variables and non independent functions from the MGMT-SHARED.ps1 file

. .\MGMT-SHARED.ps1

if ($NetworkScriptRootEnabled -eq $true -and -not [string]::IsNullOrWhiteSpace($NetworkScriptRootPath)) {
	WriteLog "Checking Network Path reachability..."

	[System.IO.DirectoryInfo]$NetworkPathCheck = $NetworkScriptRootPath

	If (Test-Path -Path $NetworkPathCheck.FullName) {
		WriteLog "Network Test Path is reachable, continuing Logon Script run..."
	}
	else {
		WriteLog "Network Test Path is NOT reachable, exiting Script!"
		Exit (0)
	}
} else {
	WriteLog "Network script root is disabled or not configured, skipping network path check."
}

## If we're on VPN + Network shares are reachable, continuing script-run...

# Exit if not running Enterprise Edition
Get-OperatingSystemApproved


#Call Script Element / Component Modules -

#region RUN_STATUS_ACCUMULATOR
# Per-helper results collected here feed the EPilot_LastRunStatus / EPilot_RunSummary
# NinjaOne custom fields at end-of-run. Values: Success, Skipped, or "Failed: <message>".
$global:EPilotRunResults = [ordered]@{}

function Invoke-EPilotHelper {
	param(
		[Parameter(Mandatory)]
		[string]$Name,

		[switch]$Skip
	)
	$helperScript = ('.\MGMT-{0}.ps1' -f $Name)
	if ($Skip) {
		$global:EPilotRunResults[$Name] = 'Skipped'
		WriteLog ('{0} skipped via CONFIG flag.' -f $helperScript)
		return
	}
	try {
		& $helperScript
		$global:EPilotRunResults[$Name] = 'Success'
	}
	catch {
		$global:EPilotRunResults[$Name] = ('Failed: {0}' -f $_.Exception.Message)
		WriteLog "ERROR executing ${helperScript}: $_" # Log full exception details
	}
}
#endregion RUN_STATUS_ACCUMULATOR

Invoke-EPilotHelper -Name 'Telemetry'
Invoke-EPilotHelper -Name 'FileOps' -Skip:($SkipFileOps -eq $true)
Invoke-EPilotHelper -Name 'RegOps' -Skip:($SkipRegOps -eq $true)
Invoke-EPilotHelper -Name 'DriveOps' -Skip:($SkipDriveOps -eq $true)
Invoke-EPilotHelper -Name 'RoamOps' -Skip:($SkipRoamOps -eq $true)
Invoke-EPilotHelper -Name 'USER-CUSTOM'

# .\MGMT-HostFile.ps1
# .\MGMT-HostFile.ps1 -param1 value1 -param2 value2

Invoke-EPilotHelper -Name 'SchedTsk'


#region CLEANUP_AND_EXIT

Invoke-EPilotHelper -Name 'Maint'

#For VPN users, refresh the GPO once for User settings
if ($global:DryRunMode) {
	WriteLog "Would run gpupdate"
} else {
	WriteLog "Updating GPO Settings"
	If ($runningAsSystem -eq $True) {
		gpupdate /target:computer
	}
	else {
		gpupdate /target:user
	}
}

# gpupdate /target:user

#Final logging entries & network log placement

Write-InformationalEvent("EndpointPilot run completed for " + $env:UserName)
Start-Sleep -Milliseconds 100 #Wait
WriteLog "EndPointPilot Run Complete"

#region NINJAONE_REPORTING
# Roll up per-helper results and report to NinjaOne custom fields.
# Send-EPilotNinjaReport no-ops (with a log line) when no NinjaOne agent was
# detected at launch, and only logs intended writes in dry-run mode.
$failedCount = 0
$ranCount = 0
foreach ($helperName in $global:EPilotRunResults.Keys) {
	$helperResult = $global:EPilotRunResults[$helperName]
	if ($helperResult -like 'Failed*') { $failedCount++ }
	if ($helperResult -ne 'Skipped') { $ranCount++ }
}
if ($failedCount -eq 0) {
	$runStatus = 'Success'
} elseif ($failedCount -lt $ranCount) {
	$runStatus = 'PartialFailure'
} else {
	$runStatus = 'Failed'
}
WriteLog ('Run status rollup: {0} ({1} of {2} executed helpers failed).' -f $runStatus, $failedCount, $ranCount)

try {
	Send-EPilotNinjaReport -RunStatus $runStatus -RunSummary $global:EPilotRunResults
}
catch {
	WriteLog "ERROR during NinjaOne custom field reporting: $_"
}
#endregion NINJAONE_REPORTING

If ($CopyLogFileToNetwork -eq $true) {
	if ($global:DryRunMode) {
		WriteLog "Would copy log file to network"
	} else {
		$NetworkLogFile = Join-Path $NetworkScriptRootPath -ChildPath "$LogFileName"
		Copy-Item "$LogFile" -Destination $NetworkLogFile -Force -ErrorAction Ignore | Out-Null
	}
}

# Copy-Item "$LogFile" -Destination $NetworkLogFile -Force -ErrorAction Ignore | Out-Null

#endregion CLEANUP_AND_EXIT

#endregion ScriptBody

#Exit Script

Exit
