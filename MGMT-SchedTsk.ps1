#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#				EndpointPilot Configuration tool shared helper script
#				MGMT-SchedTsk.PS1
#
# Description
#				This file is a module called by MAIN.PS1 portion of PS-Manage
#				It places ENDPOINT-PILOT.ps1 into Scheduled Tasks (if user rights permit) with the
#				appropriate triggers (network status change, etc).
#
#				This EndpointPilot helper script ensures that remote workers can still
#				get regular script runs, outside of the usual logon/restart process.
#
#
#				Written by Julian West February 2025
#
#
###############################################################################################

# Check to see if this script is being run directly, or if it is being dot-sourced into another script.

if ($MyInvocation.InvocationName -ne '.') {

	# We are running independently of MAIN.PS1, load Shared Modules & Shaed Variable Files
 	# and coninue the rest of the script with your shared variables and functions
    	Import-Module MGMT-Functions.psm1
    	. .\MGMT-SHARED.ps1

} else {

    # We are being called by MAIN.PS1, nothing to load  
}
