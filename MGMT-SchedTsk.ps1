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

# --- Start of Scheduled Task Logic ---
try {
    WriteLog "Checking/Creating EndpointPilot Scheduled Task..."

    $taskName = "EndpointPilot User Task ($env:USERNAME)"
    $taskDescription = "Runs EndpointPilot configuration script for the current user ($env:USERNAME) at logon and periodically."
    # Assuming ENDPOINT-PILOT.PS1 is in the same directory as this script ($PSScriptRoot)
    # This path might need adjustment based on deployment strategy (e.g., %LOCALAPPDATA%\EndpointPilot)
    $scriptPath = Join-Path $PSScriptRoot "ENDPOINT-PILOT.PS1"
    $powershellExe = "powershell.exe"
    # Ensure the path in -File argument is quoted correctly
    $actionArguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""

    # Check if the target script exists before creating the task
    if (-not (Test-Path $scriptPath)) {
        WriteLog "ERROR: Target script ENDPOINT-PILOT.PS1 not found at '$scriptPath'. Cannot create scheduled task."
        # Optionally, throw an error or return to stop further processing in this script
        return
    }

    # Define Action
    $action = New-ScheduledTaskAction -Execute $powershellExe -Argument $actionArguments

    # Define Triggers
    $triggerLogon = New-ScheduledTaskTrigger -AtLogOn
    # Use Refresh_Interval from MGMT-SHARED.ps1 (loaded from CONFIG.json)
    $repetitionInterval = New-TimeSpan -Seconds $Refresh_Interval
    # Trigger starts now and repeats indefinitely
    $triggerRepeat = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $repetitionInterval -RepetitionDuration ([TimeSpan]::MaxValue)

    # Define Principal (Run as current user, non-elevated)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Limited

    # Define Settings (Example: Don't run on batteries, run only if network available)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$false -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 1) -RunOnlyIfNetworkAvailable

    # Register the task, overwriting if it exists (-Force)
    WriteLog "Registering/Updating Scheduled Task: $taskName"
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggerLogon, $triggerRepeat -Principal $principal -Settings $settings -Description $taskDescription -Force | Out-Null

    WriteLog "Scheduled Task '$taskName' configured successfully."

} catch {
    WriteLog "ERROR configuring Scheduled Task '$taskName': $_"
    # Check for specific access denied error (HRESULT 0x80070005)
    if ($_.Exception.HResult -eq -2147024891 -or $_.Exception.Message -like "*Access is denied*") {
         WriteLog "WARN: Access denied error detected. User '$($env:USERNAME)' may lack permissions to create/modify scheduled tasks. Check GPO/Intune settings."
    }
    # You might want to add more specific error handling here if needed
}
# --- End of Scheduled Task Logic ---
