# --- OPTIONAL STRICT REQUIREMENTS ---
# Un-comment the 4 lines below if you want to lock this script to run ONLY in PowerShell Desktop (5.1).
# By default, they are commented out, so the script can detect / offer future optional PowerShell 7.x (Core) features.
#
# #Requires -Version 5.1
# #Requires -PSEdition Desktop
# using namespace System.Management.Automation
# using namespace System.Management.Automation.Language
<#
.SYNOPSIS
    --.
.DESCRIPTION
    Kicks off EndpointPilot Script Run, which calls MAIN.PS1. This solution is meant to run by Windows Scheduled Task,
    or can be run via classic AD or GPO. 
.PARAMETER
    --.
.EXAMPLE
    ENDPOINT-PILOT.ps1
.INPUTS
    None. # This script does not accept piped input.  It uses Functions and Variables from the MGMT-SHARED.ps1 script and JSON files.
.OUTPUTS
    None. # This script does not generate any output beyond a runtime log under path set by $LogFile in MGMT-SHARED.ps1 (usually %userprofile%\ps-manage-$env:COMPUTERNAME.log)
.NOTES
Author: Julian West
               BSD 3-Clause License;
               - see License Region at-end of script for more licene infor
                ________________________________________________
               /                                                \
              |    _________________________________________     |
              |   |                                         |    |
              |   |  PS C:\ > WRITE-HOST $ATTRIBUTION	    |    |
              |   |                                         |    |
              |   |         THIS IS A J-DUB SCRIPT          |    |
              |   |                                         |    |
              |   |      https://github.com/J-DubAppss      |    |
              |   |                                         |    |
              |   | 	       julianwest.me                |    |
              |   |             @julian_west                |    |
              |   |                                         |    |
              |   |                                         |    |
              |   |                                         |    |
              |   |                                         |    |
              |   |                                         |    |
              |   |_________________________________________|    |
              |                                                  |
               \_________________________________________________/
                      \___________________________________/
                   ___________________________________________
                _-'    .-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.  --- `-_
             _-'.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.--.  .-.-.`-_
          _-'.-.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-`__`. .-.-.-.`-_
       _-'.-.-.-.-. .-----.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-----. .-.-.-.-.`-_
    _-'.-.-.-.-.-. .---.-. .-------------------------. .-.---. .---.-.-.-.`-_
   :-------------------------------------------------------------------------:
   `---._.-------------------------------------------------------------._.---'
.LINK
    https://julianwest.me
.LINK
    https://github.com/J-DubApps/EndpointPilot/CHANGELOG.TXT
.LINK
    https://github.com/J-DubApps/EndpointPilot
.COMPONENT
    --
.FUNCTIONALITY
    --
#>

# region PowerShell Version and Edition
# Retrieve the current PowerShell version information -- if we're allowed to run under PowerShell Core (top comments left enabled)
# then we want to know if we're running under PowerShell Core or Windows PowerShell 5.1
$psVer = $PSVersionTable.PSVersion
$psEd = $PSVersionTable.PSEdition

# Display version information for debugging purposes
# Write-Output "Detected PowerShell Version: $psVer"
# Write-Output "Detected PowerShell Edition: $psEd"
# Write-Output "-------------------------------"

# Determine the PowerShell version and edition
if ($psEd -eq 'Desktop' -and $psVer.Major -eq 5 -and $psVer.Minor -eq 1) {
    # Write-Output "You are running Windows PowerShell 5.1 (Desktop Edition)."
    $psClassicDesktop = $true
} elseif ($psEd -eq 'Core' -and $psVers.Major -ge 7) {
    # Write-Output "You are running PowerShell Core (version 7.x or newer)."
    $psClassicDesktop = $false
} else {
    # Write-Output "You are running an unrecognized version of PowerShell: $psVer, Edition: $psEd"
}
#endregion PowerShell Version and Edition

# region OS Architecture
# Determine the OS Architecture (x64, x86, or Arm64)
# This code works in both Windows PowerShell 5.1 (Desktop) and PowerShell Core

# If running under WOW64 (32-bit process on a 64-bit OS), $env:PROCESSOR_ARCHITEW6432 will be defined.
if ($env:PROCESSOR_ARCHITEW6432) {
    $arch = $env:PROCESSOR_ARCHITEW6432
} else {
    $arch = $env:PROCESSOR_ARCHITECTURE
}

# Map the raw architecture value to a friendly output.
switch ($arch) {
    "AMD64" { $archFriendly = "x64" }
    "x86"   { $archFriendly = "x86 (32-bit)" }
    "ARM64" { $archFriendly = "Arm64" }
    default { $archFriendly = "Unknown Architecture ($arch)" }
}
# endregion OS Architecture
# Write-Output "Detected Operating System Architecture: $archFriendly"

#region 32bitHandling - if launched from 32bit PowerShell 5.1 on a 64-bit OS
If ($psClassicDesktop -eq $true) {
    if (([IntPtr]::Size -eq 4) -and ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')) {
        # If running in 32-bit PowerShell on a 64-bit OS, launch the 64-bit version of PowerShell
        try {
            &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
        } catch {
            Throw ('Failed to start {0}' -f $PSCOMMANDPATH)
        }
        exit
    } elseif (([IntPtr]::Size -eq 8) -and ($env:PROCESSOR_ARCHITECTURE -eq 'x86')) {
        exit # we are not going to support 32bit PowerShell on 32bit OS
    }
}
#endregion 32bitHandling

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


# Launch EP Main runtime script
.\MAIN.ps1

exit 0

#region LICENSE
<#
      BSD 3-Clause License

      Copyright (c) 2025, Julian West
      All rights reserved.

      Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
      1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
      2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
      3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>
#endregion LICENSE

#region DISCLAIMER
<#
      DISCLAIMER:
      - Use at your own risk, etc.
      - This is open-source software, if you find an issue try to fix it yourself. There is no support and/or warranty in any kind
      - This is a third-party Software
      - The developer of this Software is NOT sponsored by or affiliated with Microsoft Corp (MSFT) or any of its subsidiaries in any way
      - The Software is not supported by Microsoft Corp (MSFT)
      - By using the Software, you agree to the License, Terms, and any Conditions declared and described above
      - If you disagree with any of the Terms, and any Conditions declared: Just delete it and build your own solution
#>
#endregion DISCLAIMER
