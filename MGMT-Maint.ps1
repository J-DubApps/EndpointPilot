<#
################################################################################################
#
#				EndpointPilot Logon / User Profile Configuration Script Shared Settings MODule file
#				MOD-Maintenance.PS1
#
# 	Description 
#				This file is a shared component called by MAIN.PS1 portion of EndpointPilot
#				It is triggered at logon and, optionally, by Windows Scheduled Tasks to run
#				independent of a Logon event.
#
#				This logon script is VPN-aware, to ensure needed Logon Scripted tasks are
#				performed regularly for Remote users who may not be working on-prem (LAN).
#
#				Written by Julian West February 2025
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


WriteLog "Starting duplicate desktop shortcut cleanup..."
###Clean up duplicate Desktop Shortcuts

$DesktopPath = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath "*"
#$DesktopPath

$DuplicateNames = @(
    "*Edge*",
    "*Teams*",
    "*Chrome*",
	"*School*",
	"*Insider*"
)

try {
    Get-ChildItem -Path $DesktopPath -Filter *.lnk -Include $DuplicateNames | Where-Object {$_.Name -like "*-*.lnk"} | ForEach-Object {
        WriteLog "Removing duplicate shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction Stop
    }
} catch {
    WriteLog "ERROR cleaning up duplicate .lnk shortcuts: $_"
}

try {
    Get-ChildItem -Path $DesktopPath -Filter *.url -Include $DuplicateNames | Where-Object {$_.Name -like "*-*.url"} | ForEach-Object {
        WriteLog "Removing duplicate shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction Stop
    }
} catch {
    WriteLog "ERROR cleaning up duplicate .url shortcuts: $_"
}
