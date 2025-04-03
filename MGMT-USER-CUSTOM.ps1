#Requires -Version 5.1
#Requires -PSEdition Desktop
<#
###############################################################################################
#
#		EndpointPilot Configuration tool shared helper script
#		MGMT-USER-CUSTOM.PS1
#
# 	Description 	This file is a shared helper script called by MAIN.PS1 portion of EndpointPilot.
#			It is a spot for Sysadmins to add their own PS Scripting code for custom runs, to accomplish
#			extra things not handled by EndpointPilot and its JSON directive files.
#
#			Please remember Registry and File operations are already performed 
#			by the MGMT-FileOps.ps1 and MGMT-RegOps.ps1 child/helper scripts, to avoid duplication of effort.
#
#			This script runs in user-mode, so you cannot perform system-wide operations here,
#			only user-specific ones.
#
#			Written by Julian West February 2025
#
#
###############################################################################################
#>


# Check to see if this script is being run directly, or if it is being dot-sourced into another script.

if ($MyInvocation.InvocationName -ne '.') {

	# We are running independently of MAIN.PS1, load Shared Modules & Shaed Variable Files
    	# and coninue the rest of the script with your shared variables and functions
    	Import-Module MGMT-Functions.psm1
    	. .\MGMT-SHARED.ps1

} else {

	# We are being called by MAIN.PS1, nothing to load 
}


# If(InGroup 'Enable_Outlook_Modern_Auth'){


    try{

	$resEAD = New-Item -Path "HKCU:\SOFTWARE\Microsoft\Exchange" -Confirm:$False -ErrorAction SilentlyContinue
	$resEAD = New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Exchange" -Name AlwaysUseMSOAuthForAutoDiscover -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue
	$resEAD = New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Exchange" -Name MSOAuthDisabled -Value 0 -PropertyType DWORD -Force -ErrorAction SilentlyContinue

	$resMA = New-Item -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity" -Confirm:$False -ErrorAction SilentlyContinue
	$resMA = New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity" -Name EnableADAL -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue
	$resMA = New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity" -Name DisableADALatopWAMOverride -Value 0 -PropertyType DWORD -Force -ErrorAction SilentlyContinue
	$resMA = New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity" -Name DisableAADWAM -Value 0 -PropertyType DWORD -Force -ErrorAction SilentlyContinue

        WriteLog "Verifying/Setting Modern Auth registry key" # Changed from Write-Output
		WriteLog "Verifying/Setting Modern Auth registry key"
		WriteLog "registry key verified" # Changed from Write-Output
		WriteLog "registry key verified"
    }catch{
        WriteLog "WARN: Failed to add Modern Auth registry keys, skipping to allow GPO to do this..." # Changed from Write-Error
		WriteLog "Failed to add Modern Auth registry keys, skipping to allow GPO to do this..."
        WriteLog "ERROR setting Modern Auth keys: $_" # Changed from Write-Error, log full exception
    }

#}else{
#    WriteLog "User not in Modern Auth deploy group - therefore not adding logon registry key"
#}
