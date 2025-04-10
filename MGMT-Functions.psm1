# Script Module file for EndpointPilot
#
# Cmdlet aliases
#

Set-Alias -Name 'Get-Permissions' -Value 'Get-Permission'

Export-ModuleMember -Function InGroup, InGroupGP, Get-Permission, IsCurrentProcessArm64, Get-RegistryValue, Import-RegKey, Get-DsRegStatusInfo, Measure-DownloadSpeed, Measure-UploadSpeed, Get-LoggedInUser, Get-TextWithin, Get-WorkstationUsageStatus, Copy-File, Copy-Directory, Move-Files, Move-Directory, Send-SmtpMail
Export-ModuleMember -Alias Get-Permissions

#region FUNCTIONS

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

    # Set-StrictMode -Version 'Latest'

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

function IsCurrentProcessArm64 {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public static class Process
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern Int32 IsWow64Process2(
            IntPtr process,
            out ushort processMachine,
            out ushort nativeMachine);

        [DllImport("kernel32.dll")]
        private static extern IntPtr GetCurrentProcess();

        [StructLayout(LayoutKind.Sequential, Pack = 8)]
        private struct SYSTEM_INFO
        {
            public UInt16 wProcessorArchitecture;
            UInt16 reserved;
            Int32  dwPageSize;
            IntPtr lpMinimumApplicationAddress;
            IntPtr lpMaximumApplicationAddress;
            IntPtr dwActiveProcessorMask;
            Int32  dwNumberOfProcessors;
            Int32  dwProcessorType;
            Int32  dwAllocationGranularity;
            UInt16 wProcessorLevel;
            UInt16 wProcessorRevision;
        };

        [DllImport("kernel32.dll")]
        private static extern void GetNativeSystemInfo(out SYSTEM_INFO systeminfo);

        public static bool IsArm64()
        {
            const UInt16 PROCESSOR_ARCHITECTURE_ARM64 = 12;
            SYSTEM_INFO systeminfo;
            GetNativeSystemInfo(out systeminfo);

            if (systeminfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_ARM64)
            {
                const UInt16 IMAGE_FILE_MACHINE_UNKNOWN = 0;
                UInt16 processMachine = 0, nativeMachine = 0;
                Int32 retval = IsWow64Process2(GetCurrentProcess(), out processMachine, out nativeMachine);
                if (retval != 0 && processMachine == IMAGE_FILE_MACHINE_UNKNOWN)
                {
                    return true;
                }
            }

            return false;
        }
    }
"@

    Return [Process]::IsArm64()
}

Function Get-RegistryValue($RegPath, $Property) {
	##########################################################################
	##	Retrives a requested Registry value
	##########################################################################
	Try {
		$Item = Get-ItemProperty -Path $RegPath -Name $Property -ErrorAction Stop
		$ItemProperty = $Item | Select -ExpandProperty $Property

		Return $ItemProperty
	}
	Catch {
		Return $false
	}
}

Function Get-OperatingSystem() {
	##########################################################################
	##	Checks what version of Windows the machine is running
	##	and quits if it is on an unsupported platform
	##########################################################################

		# Get OS version information
		$OSInfo = Get-CimInstance Win32_OperatingSystem
		$OSVersion = $OSInfo.Version
		$BuildNumber = [int]$OSInfo.BuildNumber
	
		# Determine OS based on version and build number
		if ($OSVersion -like "10.0*" -and $BuildNumber -lt 22000) {
			$OSDetectedversion = "Windows 10"
		} elseif ($OSVersion -like "10.0*" -and $BuildNumber -ge 22000) {
			# Windows 11 starts with build number 22000 and above
			$OSDetectedversion = "Windows 11"
			# $OSDetectedversion = "Windows 11"
		} else {
			$OSDetectedversion = "Unknown OS"
		}
	
		# Return the detected OS
		return $OSDetectedversion
	}
	
	

function Get-DsRegStatusInfo {
	[CmdletBinding(ConfirmImpact = 'None')]
	[OutputType([psobject])]
	param ()

	begin {
		$DsRegCmdPlain = (& "$env:windir\system32\dsregcmd.exe" /status)
		$DsRegStatusInfo = (New-Object -TypeName PSObject)
	}

	process {
		$DsRegCmdPlain | Select-String -Pattern ' *[A-z]+ : [A-z]+ *' | ForEach-Object -Process {
			$null = (Add-Member -InputObject $DsRegStatusInfo -MemberType NoteProperty -Name (([String]$_).Trim() -split ' : ')[0] -Value (([String]$_).Trim() -split ' : ')[1] -ErrorAction SilentlyContinue)
		}
	}

	end {
		$DsRegStatusInfo
	}
}
# PowerShell function to measure download speed
function Measure-DownloadSpeed {
    param (
        [string]$Url = 'https://speed.cloudflare.com/__down'
    )

    $startTime = Get-Date
    # Download a 10MB test file
    $webClient = New-Object System.Net.WebClient
    $null = $webClient.DownloadFile($Url, "$env:TEMP\testfile")
    $endTime = Get-Date

    # Calculate the download time in seconds
    $timeTaken = ($endTime - $startTime).TotalSeconds

    # Calculate speed in Mbps
    $fileSizeInMB = 10
    $downloadSpeed = ($fileSizeInMB * 8) / $timeTaken

    # Clean up the downloaded file
    Remove-Item "$env:TEMP\testfile" -Force

    return [PSCustomObject]@{
        'DownloadSpeedMbps' = [math]::round($downloadSpeed, 2)
        'TimeTakenSeconds'  = [math]::round($timeTaken, 2)
    }
}

# PowerShell function to measure upload speed
function Measure-UploadSpeed {
    param (
        [string]$Url = 'https://speed.cloudflare.com/__up'
    )

    $testData = New-Object byte[] 1048576 # 1MB of data to upload

    $startTime = Get-Date
    $response = Invoke-RestMethod -Uri $Url -Method Post -Body $testData -ContentType 'application/octet-stream'
    $endTime = Get-Date

    # Calculate the upload time in seconds
    $timeTaken = ($endTime - $startTime).TotalSeconds

    # Calculate speed in Mbps
    $uploadSpeed = (1 * 8) / $timeTaken  # 1MB upload in megabits per second

    return [PSCustomObject]@{
        'UploadSpeedMbps'   = [math]::round($uploadSpeed, 2)
        'TimeTakenSeconds'  = [math]::round($timeTaken, 2)
    }
}


##########################################################################
##	Gets current logged-in User info including if user is RDP vs Console
##########################################################################
Function Get-LoggedInUser () {
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
		[Alias("CN", "Name", "MachineName")]
		[string[]]$ComputerName = $ENV:ComputerName
	)

	PROCESS {
		foreach ($computer in $ComputerName) {
			try {
				Write-Information "Testing connection to $computer" -Tags 'Process'
				if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
					$Users = quser.exe /server:$computer 2>$null | select -Skip 1

					if (!$?) {
						Write-Information "Error with quser.exe" -Tags 'Process'
						if ($Global:Error[0].Exception.Message -eq "") {
							throw $Global:Error[1]
						}
						elseif ($Global:Error[0].Exception.Message -like "No User exists*") {
							Write-Warning "No users logged into $computer"
						}
						else {
							throw $Global:Error[0]
						}
					}

					$LoggedOnUsers = foreach ($user in $users) {
						[PSCustomObject]@{
							PSTypeName        = "AdminTools.LoggedInUser"
							ComputerName      = $computer
							UserName          = (-join $user[1 .. 20]).Trim()
							SessionName       = (-join $user[23 .. 37]).Trim()
							SessionId         = [int](-join $user[38 .. 44])
							State             = (-join $user[46 .. 53]).Trim()
							IdleTime          = (-join $user[54 .. 63]).Trim()
							LogonTime         = [datetime](-join $user[65 .. ($user.Length - 1)])
							LockScreenPresent = $false
							LockScreenTimer   = (New-TimeSpan)
							SessionType       = "TBD"
						}
					}
					try {
						Write-Information "Using WinRM and CIM to grab LogonUI process" -Tags 'Process'
						$LogonUI = Get-CimInstance -ClassName win32_process -Filter "Name = 'LogonUI.exe'" -ComputerName $Computer -Property SessionId, Name, CreationDate -OperationTimeoutSec 1 -ErrorAction Stop
					}
					catch {
						Write-Information "WinRM is not configured for $computer, using Dcom and WMI to grab LogonUI process" -Tags 'Process'
						$LogonUI = Get-WmiObject -Class win32_process -ComputerName $computer -Filter "Name = 'LogonUI.exe'" -Property SessionId, Name, CreationDate -ErrorAction Stop |
						select name, SessionId, @{n = "Time"; e = { [DateTime]::Now - $_.ConvertToDateTime($_.CreationDate) } }
					}

					foreach ($user in $LoggedOnUsers) {
						if ($LogonUI.SessionId -contains $user.SessionId) {
							$user.LockScreenPresent = $True
							$user.LockScreenTimer = ($LogonUI | where SessionId -eq $user.SessionId).Time
						}
						if ($user.State -eq "Disc") {
							$user.State = "Disconnected"
						}
						$user.SessionType = switch -wildcard ($user.SessionName) {
							"Console" { "DirectLogon"; Break }
							"" { "Unkown"; Break }
							"rdp*" { "RDP"; Break }
							default { "" }
						}
						if ($user.IdleTime -ne "None" -and $user.IdleTime -ne ".") {
							if ($user.IdleTime -Like "*+*") {
								$user.IdleTime = New-TimeSpan -Days $user.IdleTime.Split('+')[0] -Hours $user.IdleTime.Split('+')[1].split(":")[0] -Minutes $user.IdleTime.Split('+')[1].split(":")[1]
							}
							elseif ($user.IdleTime -like "*:*") {
								$user.idleTime = New-TimeSpan -Hours $user.IdleTime.Split(":")[0] -Minutes $user.IdleTime.Split(":")[1]
							}
							else {
								$user.idleTime = New-TimeSpan -Minutes $user.IdleTime
							}
						}
						else {
							$user.idleTime = New-TimeSpan
						}

						$user | Add-Member -Name LogOffUser -Value { logoff $this.SessionId /server:$($this.ComputerName) } -MemberType ScriptMethod
						$user | Add-Member -MemberType AliasProperty -Name ScreenLocked -Value LockScreenPresent

						Write-Information "Outputting user object $($user.UserName)" -Tags 'Process'
						$user
					} #foreach
				} #if ping
				else {
					$ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
						[System.Net.NetworkInformation.PingException]::new("$computer is unreachable"),
						'TestConnectionException',
						[System.Management.Automation.ErrorCategory]::ConnectionError,
						$computer
					)
					$PSCmdlet.WriteError($ErrorRecord)
				}
			} #try
			catch [System.Management.Automation.RemoteException] {
				if ($_.Exception.Message -like "*The RPC server is unavailable*") {
					Write-Warning "quser.exe failed on $comptuer, Ensure 'Netlogon Service (NP-In)' firewall rule is enabled"
					$PSCmdlet.WriteError($_)
				}
				else {
					$PSCmdlet.WriteError($_)
				}
			}
			catch [System.Runtime.InteropServices.COMException] {
				Write-Warning "WMI query failed on $computer. Ensure 'Windows Management Instrumentation (WMI-In)' firewall rule is enabled."
				$PSCmdlet.WriteError($_)
			}
			catch {
				Write-Information "Unexpected error occurred with $computer"
				$PSCmdlet.WriteError($_)
			}
		} #foreach
	} #process
}

Function Move-Directory($Path, $NewPath) {
    ##########################################################################
    ##	Exports a file to a new location
    ##########################################################################
    If (Test-Path -Path $Path) {
        Move-Item $Path $NewPath -force
    }
}

Function Copy-Directory($Path, $NewPath, $strExcludedFiles, $strExcludedDirectories) {
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

Function Copy-File($Path, $NewPath) {
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

Function Move-Files($Path, $NewPath) {
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
    ## 
    ## Parameters:
    ##   $RegFile - The path to the registry file to be imported.
    ## 
    ## This function checks if the specified registry file exists at the given 
    ## path. If the file exists, it imports the registry key using the REG 
    ## command with the /reg:32 option, which specifies that the import should 
    ## be done in the 32-bit registry view.
    ##########################################################################
    If (Test-Path -Path $RegFile) {
        REG Import $RegFile /reg:32
    }
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

function InGroupGP {
	############################################################################################
	##	Group check via GPResult tool - Returns True/False for whether the user is in a group
	############################################################################################
	<#
				 .SYNOPSIS
						 Check if the current user is in a specified group using gpresult utility
				 .DESCRIPTION
						 Check if the current user is in a specified group
				 .PARAMETER GroupName
						 The name of the group to check
				 .EXAMPLE
						 # Check if the current user is in the Administrators group
						 $b = InGroup 'Administrators'
						 NOTE: does not yet work with AD groups that have spaces in their name.
			#>


	Param(
		[string]$GroupName
	)

	$InGroup = $null
	$search = $null
	$AD_Group_Name = $GroupName

	$test = gpresult /user $env:username /r | findstr /C:"$AD_Group_Name"  | Out-String
	$search = $test


	#write-host $search  # let's see the raw output of gpresult

	$search = $search -replace "", ""
	$search = $search.trimstart("") -split '\s+'

	if ($search -eq $null) {
		#write-host "string not found"
		$InGroup = $false
		# write-host $InGroup
		Exit
 }


	$search = $search | select-string -simplematch $AD_Group_Name | Out-String

	# write-host $search # check how we're looking before further passes on $search

	$search = $search -replace "`n|`r"

	$search = $search | select-string -pattern "^$AD_Group_Name$" | Out-String

	If (!$search -eq $AD_Group_Name) {
		#write-host "String not found"
		return $false
		Exit
	}
	else {
		return $true
	}

}


function Get-WorkstationUsageStatus {
	############################################################################################
	##	Get WorkstationUsageStatus - see if machine is locked, idle, or active.
	############################################################################################
    Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class User32 {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

            [DllImport("user32.dll")]
            public static extern IntPtr GetForegroundWindow();

            [DllImport("user32.dll", SetLastError = true)]
            public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
            
            [DllImport("user32.dll")]
            public static extern bool IsWindowVisible(IntPtr hWnd);

            [StructLayout(LayoutKind.Sequential)]
            public struct LASTINPUTINFO {
                public uint cbSize;
                public uint dwTime;
            }
        }
"@
    $LastInputInfo = New-Object "User32+LASTINPUTINFO"
    $LastInputInfo.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($LastInputInfo)
    [User32]::GetLastInputInfo([ref]$LastInputInfo) | Out-Null

    $idleSeconds = ([Environment]::TickCount - $LastInputInfo.dwTime) / 1000
    $IdleTime = (New-TimeSpan -Seconds $idleSeconds).TotalSeconds
    $ForegroundWindow = [User32]::GetForegroundWindow()
    $IsLocked = -not [User32]::IsWindowVisible($ForegroundWindow)
    
    return [pscustomobject]@{
        IdleTime = $IdleTime
        IsLocked = $IsLocked
    }
}

function Send-SmtpMail {
    ##########################################################################
	##	Sends a message in email to a specific recipient
	##########################################################################
    param (
        [Parameter(Mandatory=$true)]
        [string]$Recipient,
        
        [Parameter(Mandatory=$true)]
        [string]$Sender,
        
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        
        [Parameter(Mandatory=$true)]
        [string]$Body
    )

    $smtpServer = "10.58.210.221" # Change if your SMTP server is different
    $smtpPort = 25

    $message = New-Object system.net.mail.mailmessage
    $message.from = $Sender
    $message.To.Add($Recipient)
    $message.Subject = $Subject
    $message.Body = $Body

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $smtp.Send($message)
}

#endregion FUNCTIONS
##
##########################################################################
##					End of Functions Section
##########################################################################
