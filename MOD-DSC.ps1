#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#				PS-Manage Logon / Endpoint Configuration Script Shared Settings MODule file
#				MOD-DSC.PS1
#
# Description 	This file is a shared component called by MAIN.PS1 portion of PS-Manage
#				It performs DSC, Desired State Configuration, routines required to
#				place the Endpoint or Apps into a specific standardized Configuration Baseline.
#
#				This MODule should *not* perform standard Registry Modifications, or File Copies
#				as those should be performed by the MOD-FileOps.ps1 and MOD-RegOps.ps1 MODules
#				along with their requisite JSON files.
#
#				Written by Julian West February 2023
#
#
###############################################################################################


# Check to see if this script is being run directly, or if it is being dot-sourced into another script.

if ($MyInvocation.InvocationName -ne '.') {

	# We are running independently of MAIN.PS1, load the Shared MODule
	# and coninue the rest of the script with your shared variables and functions
	. .\MOD-SHARED.ps1

} else {

    # We are being called by MAIN.PS1, no need to load the Shared MODule
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

        Write-Output "Verifying/Setting Modern Auth registry key"
		WriteLog "Verifying/Setting Modern Auth registry key"
		Write-Output "registry key verified"
		WriteLog "registry key verified"
    }catch{
        Write-Error "Failed to add Modern Auth registry keys, skipping to allow GPO to do this..." -ErrorAction Continue
		WriteLog "Failed to add Modern Auth registry keys, skipping to allow GPO to do this..."
        Write-Error $_ -ErrorAction Continue
    }

#}else{
#    WriteLog "User not in Modern Auth deploy group - therefore not adding logon registry key"
#}
