#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#				PS-Manage Logon / Endpoint Configuration Script Shared Settings MODule file
#				MOD-SchedTsk.PS1
#
# Description 	This file is a shared component called by MAIN.PS1 portion of PS-Manage
#				It places PSTART.ps1 into Scheduled Tasks (if user rights permit) with the
#				appropriate triggers (network status change, etc).
#
#				This PS-Manage MODule file helps ensure that remote workers on VPN will still
#				get routine Endpoint Configuration Script runs.
#
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
