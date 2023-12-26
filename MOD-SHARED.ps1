#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#		PS-Manage Logon / User Profile Mgmt Script Shared Settings MODule file
#		MOD-SHARED.PS1
#
#        Description 	
#        This file is a shared component called by MAIN.PS1 portion of PS-Manage
#        It is triggered at logon and, optionally, by Windows Scheduled Tasks to run
#        independent of a Logon event.
#
#        This logon script is VPN-aware, to ensure needed Logon Scripted tasks are
#        performed regularly for Remote users who may not be working on-prem (LAN).
#
#        Written by Julian West February 2023
#
#
###############################################################################################

# Check to see if this script is being run directly, or if it is being dot-sourced into another script.

if ($MyInvocation.InvocationName -ne '.') {
    Write-Warning 'This script should be dot-sourced into another script, not run independently.'
    return
}

# rest of the script contains shared variables and functions for use in MAIN.PS1 and other scripts


#region FUNCTIONS
Function Check-ClientEnvironment() {
    ##########################################################################
    ##	Checks if the machine is connected to the client domain
    ##	and if so if it is connected to a PC or to a Citrix machine
    ##########################################################################

    #Check if the Computer is in a Workstations directory

    #If([string]$objComputer -like "*BRWorkstations*"){
    #	$PCType = "Workstation"
    #	}
    #Else{
    #	Log-WarningEvent("Non-compliant desktop environment detected. Quitting the script now.")
    #	Exit
    #	}
}

Function Check-OperatingSystem() {
    ##########################################################################
    ##	Checks what version of Windows the machine is running
    ##	and quits if it is on an unsupported platform
    ##########################################################################
    $wmiOS = Get-WmiObject -Class Win32_OperatingSystem;
    $OS = $wmiOS.caption

    If ($OS -like "Microsoft Windows 10 Enterprise*") {
        $OSName = "Microsoft Windows 10 Enterprise"
        #$OS
        #$OSName
    }
    Elseif ($OS -like "Microsoft Windows 11 Enterprise*") {
        $OSName = "Microsoft Windows 11 Enterprise"
        #$OS
        #$OSName
    }
    Else {
        Log-WarningEvent("The current operating system, " + $OS + ", is not supported. Exiting the script now.")
        #$OS
        #$OSName
        Exit
    }
}


Function Cp-Directory($Path, $NewPath) {
    ##########################################################################
    ##	Copies a directory/folder to a new location
    ##########################################################################
    If (Test-Path -Path $Path) {
        $cmd = "Robocopy """ + $Path + """ """ + $NewPath + """ /XF " + $strExcludedFiles + " /XD " + $strExcludedDirectories + " /XO /COPY:DAT /R:0 /W:1 /S /E"
        #$wshell = New-Object -ComObject Wscript.Shell
        #$wshell.Popup($cmd,0,"Done",0x1)
        Invoke-Expression $cmd
    }
}

Function Cp-File($Path, $NewPath) {
    ##########################################################################
    ##	Copies a file or a set of files to a new location
    ##########################################################################
    If (Test-Path -Path $Path) {
        #$cmd = $Robocopy + " " + $Path + " " +  $NewPath + " /XO /COPY:DAT /R:0 /W:1"
        #write-host $cmd
        Robocopy $Path $NewPath /XO /COPY:DAT /R:0 /W:1 | Out-Null
        #& $cmd
        #Copy-Item $Path $NewPath -force
    }
}

Function Mv-Files($Path, $NewPath) {
    ##########################################################################
    ##	Moves a file or a set of files to a new location
    ##########################################################################
    If (Test-Path -Path $Path) {
        #$cmd = $Robocopy + " " + $Path + " " +  $NewPath + " /XO /COPY:DAT /R:0 /W:1"
        #write-host $cmd
        Robocopy $Path $NewPath /XO /COPY:DAT /R:0 /W:1 | Out-Null
        #& $cmd
        #Copy-Item $Path $NewPath -force
    }
}

Function Import-RegKey($RegFile) {
    ##########################################################################
    ##	Imports a Registry Key to the local machine
    ##########################################################################
    If (Test-Path -Path $RegFile) {
        REG Import $RegFile /reg:32
    }
}

Function Log-InformationalEvent($Message) {
    #########################################################################
    #	Writes an informational event to the event log
    #########################################################################
    $QualifiedMessage = $ClientName + " Script: " + $Message
    Write-EventLog -LogName Application -Source Winlogon -Message $QualifiedMessage -EventId 1001 -EntryType Information
}

Function Log-WarningEvent($Message) {
    #########################################################################
    # Writes a warning event to the event log
    #########################################################################
    $QualifiedMessage = $ClientName + " Script:" + $Message
    Write-EventLog -LogName Application -Source Winlogon -Message $QualifiedMessage -EventId 1001 -EntryType Warning
}

Function Move-Directory($Path, $NewPath) {
    ##########################################################################
    ##	Exports a file to a new location
    ##########################################################################
    If (Test-Path -Path $Path) {
        Move-Item $Path $NewPath -force
    }
}


Function WriteLog($LogString) {
    ##########################################################################
    ##	Writes Run info to a logfile set in $LogFile variable
    ##########################################################################

    #Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
}

function Get-TextWithin {
    <#
      .SYNOPSIS
          Get the text between two surrounding characters (e.g. brackets, quotes, or custom characters)
      .DESCRIPTION
          Use RegEx to retrieve the text within enclosing characters.
    .PARAMETER Text
          The text to retrieve the matches from.
      .PARAMETER WithinChar
          Single character, indicating the surrounding characters to retrieve the enclosing text for.
          If this paramater is used the matching ending character is "guessed" (e.g. '(' = ')')
      .PARAMETER StartChar
          Single character, indicating the start surrounding characters to retrieve the enclosing text for.
      .PARAMETER EndChar
          Single character, indicating the end surrounding characters to retrieve the enclosing text for.
      .EXAMPLE
          # Retrieve all text within single quotes
      $s=@'
here is 'some data'
here is "some other data"
this is 'even more data'
'@
           Get-TextWithin $s "'"
  .EXAMPLE
  # Retrieve all text within custom start and end characters
  $s=@'
here is /some data\
here is /some other data/
this is /even more data\
'@
  Get-TextWithin $s -StartChar / -EndChar \
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
            ValueFromPipeline = $true,
            Position = 0)]
        $Text,
        [Parameter(ParameterSetName = 'Single', Position = 1)]
        [char]$WithinChar = '"',
        [Parameter(ParameterSetName = 'Double')]
        [char]$StartChar,
        [Parameter(ParameterSetName = 'Double')]
        [char]$EndChar
    )
    $htPairs = @{
        '(' = ')'
        '[' = ']'
        '{' = '}'
        '<' = '>'
    }
    if ($PSBoundParameters.ContainsKey('WithinChar')) {
        $StartChar = $EndChar = $WithinChar
        if ($htPairs.ContainsKey([string]$WithinChar)) {
            $EndChar = $htPairs[[string]$WithinChar]
        }
    }
    $pattern = @"
(?<=\$StartChar).+?(?=\$EndChar)
"@
    [regex]::Matches($Text, $pattern).Value
}


function InGroup {
    ##########################################################################
    ##	Group check - Returns True/False for whether the user is in a group
    ##########################################################################
    <#
      .SYNOPSIS
          Check if the current user is in a specified group
      .DESCRIPTION
          Check if the current user is in a specified group
      .PARAMETER GroupName
          The name of the group to check
      .EXAMPLE
          # Check if the current user is in the Administrators group
          $b = InGroup 'Administrators'
  #>
    Param(
        [string]$GroupName
    )

    if ($GroupName) {
        $mytoken = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $me = New-Object System.Security.Principal.WindowsPrincipal($mytoken)
        return $me.IsInRole($GroupName)
    }
    else {
        $user_token = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $groups = New-Object System.Collections.ArrayList
        foreach ($group in $user_token.Groups) {
            [void] $groups.Add( $group.Translate("System.Security.Principal.NTAccount") )
        }
        return $groups
    }
}

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Get-Permission {
    <#
    .SYNOPSIS
    Gets the permissions (access control rules) for a file, directory, registry key, or certificate's private key/key container.

    .DESCRIPTION
    Permissions for a specific identity can also be returned. Access control entries are for a path's discretionary access control list.

    To return inherited permissions, use the `Inherited` switch. Otherwise, only non-inherited (i.e. explicit) permissions are returned.

    Certificate permissions are only returned if a certificate has a private key/key container. If a certificate doesn't have a private key, `$null` is returned.

    .OUTPUTS
    System.Security.AccessControl.AccessRule.

    .LINK
    Carbon_Permission

    .LINK
    Get-Permission

    .LINK
    Grant-Permission

    .LINK
    Protect-Acl

    .LINK
    Revoke-Permission

    .LINK
    Test-Permission

    .EXAMPLE
    Get-Permission -Path 'C:\Windows'

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the non-inherited rules on `C:\windows`.

    .EXAMPLE
    Get-Permission -Path 'hklm:\Software' -Inherited

    Returns `System.Security.AccessControl.RegistryAccessRule` objects for all the inherited and non-inherited rules on `hklm:\software`.

    .EXAMPLE
    Get-Permission -Path 'C:\Windows' -Idenity Administrators

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the `Administrators'` rules on `C:\windows`.

    .EXAMPLE
    Get-Permission -Path 'Cert:\LocalMachine\1234567890ABCDEF1234567890ABCDEF12345678'

    Returns `System.Security.AccessControl.CryptoKeyAccesRule` objects for certificate's `Cert:\LocalMachine\1234567890ABCDEF1234567890ABCDEF12345678` private key/key container. If it doesn't have a private key, `$null` is returned.
    #>
    [CmdletBinding()]
    [OutputType([System.Security.AccessControl.AccessRule])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The path whose permissions (i.e. access control rules) to return. File system, registry, or certificate paths supported. Wildcards supported.
        $Path,

        [string]
        # The identity whose permissiosn (i.e. access control rules) to return.
        $Identity,

        [Switch]
        # Return inherited permissions in addition to explicit permissions.
        $Inherited
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $account = $null
    if ( $Identity ) {
        $account = Test-Identity -Name $Identity -PassThru
        if ( $account ) {
            $Identity = $account.FullName
        }
    }

    if ( -not (Test-Path -Path $Path) ) {
        Write-Error ('Path ''{0}'' not found.' -f $Path)
        return
    }

    Invoke-Command -ScriptBlock {
        Get-Item -Path $Path -Force |
        ForEach-Object {
            if ( $_.PSProvider.Name -eq 'Certificate' ) {
                if ( $_.HasPrivateKey -and $_.PrivateKey ) {
                    $_.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity
                }
            }
            else {
                $_.GetAccessControl([Security.AccessControl.AccessControlSections]::Access)
            }
        }
    } |
    Select-Object -ExpandProperty Access |
    Where-Object {
        if ( $Inherited ) {
            return $true
        }
        return (-not $_.IsInherited)
    } |
    Where-Object {
        if ( $Identity ) {
            return ($_.IdentityReference.Value -eq $Identity)
        }

        return $true
    }
}

Set-Alias -Name 'Get-Permissions' -Value 'Get-Permission'


#endregion FUNCTIONS
##
##########################################################################
##				End of PS-Manage Functions Section
##########################################################################
##           	Start of PS-Manage Common Variable Settings
##########################################################################
###

#region Variables

#Declare the Client Variables
#Set Client name, Log File Location etc

$ClientName = "McKool Smith"
$HostName = $env:COMPUTERNAME
$Refresh_Interval = 900 #Seconds
$NetworkScriptPath = "\\McKoolSmith.Law\SysVol\McKoolSmith.Law\Policies\"
$LogFile = "$env:userprofile\LOGON-$env:computername.log"
$CopyLogFileToNetwork = $false #Set to $true to copy the log file to the network
# Set the network location, below, if above var is set to $true.  Create that shared folder if it doesn't exist, and make sure the user has write access to it.
$NetworkLogFile = "\\servername\SHARE\Tools\FlagFiles\Logon_Script_RunLogs\LOGON-$env:UserName-on-$env:computername.log"
$RoamFiles = $false #Set to $true if you wish to leverage roaming/syncing certain files (files to sync/roam are specified in ROAM-OPS.json)
# Set the network location, below, if above var is set to $true.  Create that shared folder if it doesn't exist, and make sure the user has write & folder creation rights to it.
$NetworkRoamFolder = "\\servername\SHARE\RoamingFiles"

#region Check
#region Defaults
$SCT = 'SilentlyContinue'
Get-ChildItem -Path $LogFile | Remove-Item -Force -ErrorAction Ignore | Out-Null
$ErrorActionPreference = "Continue"
#Set the Robocopy location
$Robocopy = "C:\Windows\System32\Robocopy.exe"
#endregion Defaults

#Collect the Computer distinguished name
$filter = "(&(objectCategory=computer)(objectClass=computer)(cn=$env:COMPUTERNAME))"
$objComputer = ([adsisearcher]$filter).FindOne().Properties.distinguishedname


#endregion variables

#region ScriptBody_MOD-SHARED

#Log Runtime start
WriteLog "Logon Script Run Start"

#Create Event Viewer entry for the start of the script
Log-InformationalEvent("MS Logon Script started for " + $env:UserName)



# Clean-up
$RegistryRoot = $null

# Figure out if we have an existing PowerShell Registry Provider mapping
$paramGetPSDrive = @{
    ErrorAction   = $SCT
    WarningAction = $SCT
}
#endregion Check


#Set Excluded Files and Directories
$strExcludedDirectories =	"`"! Don't delete me! I'm helping Palo Alto hunt for ransomware!`"" + " " +
"`"Windows`"" + " " +
"`"My Documents`"" + " " +
"`"Documents`"" + " " +
"`"MigrationSettings`"" + " " +
"`"*_canary*`""

#$wshell = New-Object -ComObject Wscript.Shell
#$wshell.Popup("Excluded Directories: " + $strExcludedDirectories,0,"Done",0x1)


$strExcludedFiles = "`"*.isn`"" + " " +
"`"*.iso`"" + " " +
"`"*_canary*`""

#$wshell.Popup("Excluded Files: " + $strExcludedFiles,0,"Done",0x1)

#endregion ScriptBody_MOD-SHARED
