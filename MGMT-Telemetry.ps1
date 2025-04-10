###############################################################################################
#
#    EndpointPilot Logon / User Profile Configuration Script Shared Settings helper script
#    MGMT-Telemetry.PS1
#
# Description 	This file is a shared component called by MAIN.PS1 portion of EndpointPilot
#            This helper script determines user general location, Internet Provider
#            and VPN connection status.
#
#            This helper script is required to help EndpointPilot operate in a VPN-aware footing,
#            to ensure needed Scripted tasks are performed regularly for Remote workers
#            who may not be working on-prem (LAN).
#
#            Written by Julian West February 2025
#
#
###############################################################################################

# Check to see if this script is being run directly, or if it is being dot-sourced into another script.

if ($MyInvocation.InvocationName -ne '.') {

    # We are running independently of MAIN.PS1, load Shared Modules & Shaed Variable Files
    # and coninue the rest of the script with your shared variables and functions
    Import-Module MGMT-Functions.psm1
    . .\MGMT-SHARED.ps1

}
else {

    # We are being called by MAIN.PS1, nothing to load 
}

# Check current Workstation Usage Status during this Script run
$workstationUsageStatus = Get-WorkstationUsageStatus
$RunTimeLockedStatus = if ($workstationUsageStatus.IsLocked) { "locked" } else { "unlocked" }

if ($workstationUsageStatus.IsLocked) {
    # Write-Output "The workstation is locked."
	WriteLog "The workstation is locked during this Telemetry Script run."
} else {
    #Write-Output "The workstation is not locked."
	WriteLog "The workstation is being actively-used, and is NOT auto-locked, during this Telemetry Script run."
}

WriteLog "Determining connection type - VPN vs office, and if on Wired/Wireless LAN"

#Get Connection Type
$WirelessConnected = $null
$WiredConnected = $null
$VPNConnected = $null

# Detecting PowerShell version, and call the best cmdlets
if ($PSVersionTable.PSVersion.Major -gt 2) {
    # Using Get-CimInstance for PowerShell version 3.0 and higher
    $WirelessAdapters = Get-CimInstance -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter `
        'NdisPhysicalMediumType = 9'
    $WiredAdapters = Get-CimInstance -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter `
        "NdisPhysicalMediumType = 0 and `
            (NOT InstanceName like '%pangp%') and `
            (NOT InstanceName like '%cisco%') and `
            (NOT InstanceName like '%juniper%') and `
            (NOT InstanceName like '%vpn%') and `
            (NOT InstanceName like 'Hyper-V%') and `
            (NOT InstanceName like 'VMware%') and `
            (NOT InstanceName like 'VirtualBox Host-Only%')"
    $ConnectedAdapters = Get-CimInstance -Class win32_NetworkAdapter -Filter `
        'NetConnectionStatus = 2'
    $VPNAdapters = Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter `
        "Description like '%pangp%' `
            or Description like '%cisco%'  `
            or Description like '%juniper%' `
            or Description like '%vpn%'"
}
else {
    # Needed this script to work on PowerShell 2.0 (don't ask)
    $WirelessAdapters = Get-WmiObject -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter `
        'NdisPhysicalMediumType = 9'
    $WiredAdapters = Get-WmiObject -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter `
        "NdisPhysicalMediumType = 0 and `
            (NOT InstanceName like '%pangp%') and `
            (NOT InstanceName like '%cisco%') and `
            (NOT InstanceName like '%juniper%') and `
            (NOT InstanceName like '%vpn%') and `
            (NOT InstanceName like 'Hyper-V%') and `
            (NOT InstanceName like 'VMware%') and `
            (NOT InstanceName like 'VirtualBox Host-Only%')"
    $ConnectedAdapters = Get-WmiObject -Class win32_NetworkAdapter -Filter `
        'NetConnectionStatus = 2'
    $VPNAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter `
        "Description like '%pangp%' `
            or Description like '%cisco%'  `
            or Description like '%juniper%' `
            or Description like '%vpn%'"
}


Foreach ($Adapter in $ConnectedAdapters) {
    If ($WirelessAdapters.InstanceName -contains $Adapter.Name) {
        $WirelessConnected = $true
    }
}

Foreach ($Adapter in $ConnectedAdapters) {
    If ($WiredAdapters.InstanceName -contains $Adapter.Name) {
        $WiredConnected = $true
    }
}

Foreach ($Adapter in $ConnectedAdapters) {
    If ($VPNAdapters.Index -contains $Adapter.DeviceID) {
        $VPNConnected = $true
    }
}

If (($WirelessConnected -ne $true) -and ($WiredConnected -eq $true)) { $ConnectionType = "WIRED" }
If (($WirelessConnected -eq $true) -and ($WiredConnected -eq $true)) { $ConnectionType = "WIRED AND WIRELESS" }
If (($WirelessConnected -eq $true) -and ($WiredConnected -ne $true)) { $ConnectionType = "WIRELESS" }

WriteLog "Connection type for this PC is: $ConnectionType"

If ($VPNConnected -eq $true) { $ConnectionType = "VPN" }

#Write-Output "Connection type is: $ConnectionType"

## Are we on VPN?

If (($ConnectionType -eq "VPN")) {

    WriteLog "PC is on VPN, continuing Logon Script run..."
    #$ConnectionType

}
else {

    WriteLog "Not on VPN, exiting Script!"
    #$ConnectionType
    Exit (0)
}

WriteLog "Gathering IPv4 Address Information"

$env:HostIP = (
    Get-NetIPConfiguration |
    Where-Object {
        $_.IPv4DefaultGateway -ne $null -and
        $_.NetAdapter.Status -ne "Disconnected"
    }
).IPv4Address.IPAddress

WriteLog "Primary IP Address is $env:HostIP"

try {
    $HostExtIP = (Invoke-WebRequest -uri "https://api.ipify.org/" -UseBasicParsing -TimeoutSec 10).Content
} catch {
    WriteLog "ERROR getting external IP from api.ipify.org: $_"
    $HostExtIP = "Error"
}

WriteLog "External IP Address is $HostExtIP"

try {
    # Note: ipinfo.io might require an API key for reliable/high-volume use.
    $HostISP = (Invoke-RestMethod -Uri "http://ipinfo.io/org" -TimeoutSec 10).Trim()
} catch {
    WriteLog "ERROR getting ISP info from ipinfo.io: $_"
    $HostISP = "Error"
}

WriteLog "Possible Internet Provider is $HostISP"


$Manufacturer = gwmi -q "select Manufacturer from win32_computersystem" | foreach { $_.Manufacturer }
$isVM = $false

If (($Manufacturer -eq "VMware, Inc.")) {

    WriteLog "PC Endpoint is Virtual Machine running in VMware."
    $isVM = $True

}
else {

}


WriteLog "Getting original install date of this machine."
WriteLog ""
$builddate = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\' | select -ExpandProperty InstallDate
$installdate = (Get-Date "1970-01-01 00:00:00.000Z") + ([TimeSpan]::FromSeconds($builddate))

WriteLog "Installation Date of this PC is:  $installdate"

#systeminfo | findstr /C:"Original Install Date" | Out-File -Append -NoClobber -Encoding UTF8 -FilePath "$env:userprofile\LOGON-$env:computername.log"
#gcim Win32_OperatingSystem | select InstallDate | Out-File -Append -NoClobber -Encoding UTF8 -FilePath "$env:userprofile\LOGON-$env:computername.log"
WriteLog ""
$BuildNumber = Get-WmiObject -query "select * from Win32_OperatingSystem" | select BuildNumber
WriteLog "Build Number of this PC is:  $BuildNumber"

WriteLog ""
WriteLog "Checking if this user logon session is RDP or local."
# dsregcmd /status | findstr /C:"SessionIsNotRemote" | Out-File -Append -NoClobber -Encoding UTF8 -FilePath "$env:userprofile\LOGON-$env:computername.log"
# Check if the current user has an active RDP session
$rdpSession = get-loggedinuser | select SessionType | out-string -Stream | Select-String -Pattern "RDP"

if ($RdpSession) {
    WriteLog "$env:USERNAME is currently running this script from an RDP session."
}
else {
    WriteLog "$env:USERNAME is currently running this script from local console session."
}


#Checking uptime
WriteLog ""

# Get the Win32_OperatingSystem WMI class
$os = Get-WmiObject -Class Win32_OperatingSystem

# Parse the LastBootUpTime property into a DateTime object
$lastBootUpTime = $os.ConvertToDateTime($os.LastBootUpTime)

# Print the last boot up time
#Write-Output "Last boot time: $lastBootUpTime"
WriteLog "Last boot time: $lastBootUpTime"

# Calculate and print the uptime
$uptime = New-TimeSpan -Start $lastBootUpTime -End (Get-Date)
#Write-Output "Uptime: $($uptime.Days) days $($uptime.Hours) hours $($uptime.Minutes) minutes $($uptime.Seconds) seconds"
WriteLog "Uptime: $($uptime.Days) days $($uptime.Hours) hours $($uptime.Minutes) minutes $($uptime.Seconds) seconds"

# Get the information of logical disk C:
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"

# Convert the free space in bytes to GB and round it to 2 decimal places
$freeSpaceGB = [math]::Round(($disk.FreeSpace / 1GB), 2)

# Print the free space
WriteLog ""
WriteLog "The free space on the C: drive is $freeSpaceGB GB"

If ($freeSpaceGB -lt 105) {
    # if free space is less than 105 GB, log it

    #$LowDiskSpace = $True
    WriteLog "Low Disk Space detected on $env:computername.  $freeSpaceGB GB free on C: drive."
}

If ($freeSpaceGB -lt 55) {
    # if free space is less than 55 GB, log it

    #$LowDiskSpace = $True
    WriteLog "Low Disk Space detected on $env:computername.  $freeSpaceGB GB free on C: drive."
}

# Next we are going to detect for any extra user-created folders that are Data Loss Risks for those users if their laptop is lost.
# Path to analyze
$FolderPath = "C:\users\$env:username"

# List of folders to ignore, we create an array of strings here which we will use below
$IgnoreList = @('.ms-ad', '.1Password', '.android', '.cache', '.fcc', '.junique', '.openjfx', '.vscode', '3D Objects', 'Contacts', 'Desktop', 'Documents', 'Downloads', 'Favorites', 'Links', 'Music', 'MS-Scripts', 'OneDrive', 'ND Office Echo', 'Pictures', 'Saved Games', 'Searches', 'Videos', 'Work Folders')

# Get all directories in the folder
$Directories = Get-ChildItem -Path $FolderPath -Directory

# Filter the directories
$FilteredDirectories = $Directories | Where-Object { $IgnoreList -notcontains $_.Name }

# Count the filtered directories
$Count = $FilteredDirectories.Count

If ($Count -gt 0) {
    # Output the count
    # Write-Output "Count of sub-folders excluding ignored list: $Count"
    writelog "User-created, non-protected sub-folder count (if not zero) numbers $Count folders for user $env:UserName on $env:computername."
}

#Check Chrome Extensions
# Define the registry path
$extRegistryPath = "HKCU:\Software\Google\Chrome\PreferenceMACs\Default\extensions.settings"
$extOutputFilePath = "$env:userprofile\Chrome-Extensions.txt"

# Clear the output file if it exists
if (Test-Path $extOutputFilePath) {
    Remove-Item $extOutputFilePath
}

# Check if the registry path exists
if (Test-Path $extRegistryPath) {
    # Get all installed extensions
    $extensionscheck = Get-ItemProperty -Path $extRegistryPath

    # Create a custom object to store extension details
    $extensionList = @()
    foreach ($extension in $extensionscheck.PSObject.Properties) {
        $extensionDetails = [PSCustomObject]@{
            ExtensionID = $extension.Name
            Data        = $extension.Value
        }
        $extensionList += $extensionDetails
    }

    # Output the list of extensions to a text file
    $extensionList | Format-Table -AutoSize | Out-File -FilePath $extOutputFilePath
    Write-Output "Chrome extensions have been written to $extOutputFilePath"
} else {
    Write-Output "No Chrome extensions found for the current user." | Out-File -FilePath $extOutputFilePath
}

#region PST_Check
# DETECT PSTs in-use by Outlook (if Outlook is running)
WriteLog ""
Writelog "Looking for user-added PSTs in Outlook Profile..."
#Get the current date and time, computer name, user name and path to share where to save the list of PST files found
$date_time = Get-Date -Format yyyy-MM-dd_HH-mm-ss
$computername = $env:COMPUTERNAME
#$sharepath = "\\server\share"
$username = $env:USERNAME
$outlookrunning = $null

#Test if Outlook is running. Script should only run when Outlook is running. Otherwise a pop-up appears on the user's screen...
try {
	$proc = Get-Process -Name OUTLOOK -ErrorAction Stop

	#Get the version of Office
	$prodver = $proc.ProductVersion
	$outlookrunning = $true
}
catch {
	#"$date_time;$computername;Outlook is not running;N/A;N/A;$username" | Out-File -FilePath ("$env:userprofile\${username}" + "_PST_In-Use.csv") -Append
	WriteLog ""
	Writelog "Outlook is not running."
	WriteLog ""
	$outlookrunning = $false
}

If ($outlookrunning -eq $true){
#Load Outlook object from current user's profile
$Outlook = New-Object -ComObject 'Outlook.Application' -ErrorAction 'Stop'

#Get all Outlook stores of type 3 (PST)
$pstobjects = $outlook.GetNameSpace('MAPI').Stores | Where-Object { $_.ExchangeStoreType -eq 3 }
if ($pstobjects -eq $null) {
	#"$date_time;$computername;No PST files found;N/A;$prodver;$username" | Out-File -FilePath ("$env:userprofile\${username}" + "_No_Detected_PST_In-Use.csv") -Append
	WriteLog ""
	Writelog "No PST files found in Outlook Profile."
	continue
}

#For each PST file found...
foreach ($pstobject in $pstobjects) {
	#get the PST file path
	$filepath = $pstobject.filepath

	<#Remove invalid characters from from file path
    if ($filepath -match ":") {
        $drive = (Split-Path $filepath -Qualifier).Replace(':','')
        $leaf = Split-Path $filepath -NoQualifier
        $unc = Join-Path (Get-PSDrive $drive)[0].DisplayRoot -ChildPath $leaf
        $filepathcleaned = $unc
    } else {
        $filepathcleaned = $pstobject.filepath -replace [regex]::escape('?\UNC\'),''
    }
    #>
	$filepathcleaned = $filepath
	#If the file exists, get the size and output data to a CSV file. The name includes the computer name.
	if (test-path $filepathcleaned) {
		$filesize = (Get-Item $filepathcleaned).length
		$pstInUsereportfilepath = "$env:userprofile\${username}" + "_PST_In-Use.csv"
		$pstInUsereportfilename = "${username}" + "_PST_In-Use.csv"
		$pstdetectfilepath = "$env:userprofile\${username}" + "_pst.csv"
		$pstdetectfilename = "${username}" + "_pst.csv"
		Remove-Item -Path $pstInUsereportfilepath -Force -ErrorAction Ignore | Out-Null
		# "$date_time;$computername;$filepathcleaned;$filesize;$prodver;$username" | Out-File -FilePath ("$sharepath\$computername" + "_PST_files.csv") -Append
		WriteLog ""
		Writelog "PST(s) file(s) found in Outlook Profile."
		WriteLog "$date_time;$computername;$filepathcleaned;$filesize;$prodver;$username"
		"$date_time;$computername;$filepathcleaned;$filesize;$prodver;$username" | Out-File -FilePath ($pstInUsereportfilepath) -Append
	}
}

}
#endregion PST_Check

# Get the information of logical disk C:
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"

# Convert the free space in bytes to GB and round it to 2 decimal places
$freeSpaceGB = [math]::Round(($disk.FreeSpace / 1GB), 2)

# Print the free space
WriteLog ""
WriteLog "The free space on the C: drive is $freeSpaceGB GB"

If ($isVM -eq $false) {
	# Set the path of the Downloads folder
	$downloadsFolderPath = Join-Path -Path $env:userprofile -ChildPath "Downloads"

	if ($freeSpaceGB -lt 55) {
		WriteLog ""
		WriteLog "Low Disk Space detected on $env:computername.  $freeSpaceGB GB free on C: drive."
		"$freeSpaceGB GB free on C: drive. User Downloads folder size has been logged to the log found at: Logon_Script_RunLogs" | out-file "\\mckoolsmith.law\dfs\SOURCE\Tools\FlagFiles\Logon_Script_RunLogs\Free_Space_Reports\Under_50gb\$env:UserName-on-$env:computername.log"
		$LowDiskSpace = $True
	}
 elseif ($freeSpaceGB -lt 105) {
		WriteLog ""
		WriteLog "Low Disk Space detected on $env:computername.  $freeSpaceGB GB free on C: drive."
		"$freeSpaceGB GB free on C: drive. User Downloads folder size has been logged to the log found at: Logon_Script_RunLogs" | out-file "\\mckoolsmith.law\dfs\SOURCE\Tools\FlagFiles\Logon_Script_RunLogs\Free_Space_Reports\Under_100gb\$env:UserName-on-$env:computername.log"
		$LowDiskSpace = $True
	}
	else {
		$LowDiskSpace = $False
	}

	If ($LowDiskSpace -eq $True) {
	 if (Test-Path -Path $downloadsFolderPath) {
			# Calculate the size of the Downloads folder
			$downloadsFolderSize = (Get-ChildItem -Path $downloadsFolderPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB

			# Print the size of the Downloads folder
			WriteLog ""
			WriteLog "Downloads folder size: $([Math]::Round($downloadsFolderSize, 2)) MB"
		}
	}

}

WriteLog "Checking TPM Status for Bitlocker Pre-reqs"
dsregcmd /status | findstr /C:"TpmProtected" | Out-File -Append -NoClobber -Encoding UTF8 -FilePath "$env:userprofile\LOGON-$env:computername.log"
WriteLog ""

#region BitLocker_Status_Check
$BitLockerStatus = $null
$cmd = "(New-Object -ComObject Shell.Application).NameSpace('C:').Self.ExtendedProperty('System.Volume.BitLockerProtection')"
$bitLockerResult = Invoke-Expression -Command $cmd

if ($bitLockerResult -eq "0" -or $bitLockerResult -eq "2") {
	$BitLockerStatus = $false
}
elseif ($bitLockerResult -eq "1") {
	$BitLockerStatus = $true
}

# Check the BitLocker status
if ($BitLockerStatus) {
	#Write-Host "BitLocker protection is enabled."
	WriteLog "BitLocker protection is enabled."
}
else {
	#Write-Host "BitLocker protection is not enabled."
	WriteLog "BitLocker protection is not enabled."
}

#endregion BitLocker_Status_Check

WriteLog ""
WriteLog "Checking for Hybrid Domain Join & Readiness for Intune Mgmt and Windows Hello For Business."
dsregcmd /status | findstr /C:"AzureAdJoined" /C:"DomainJoined" /C:"TenantId" /C:"AzureAdPrt" /C:"NgsSet" /C:"PolicyEnabled" /C:"CertEnrollment" | Out-File -Append -NoClobber -Encoding UTF8 -FilePath "$env:userprofile\LOGON-$env:computername.log"

#Clean-up any old Robocopy Logfiles

Get-ChildItem -Path "$env:userprofile\Start-Robocopy-*" | Where-Object { ($_.LastWriteTime -lt (Get-Date).AddDays(-1)) } | Remove-Item -Force -ErrorAction Ignore | Out-Null
WriteLog ""

WriteLog "Attempting to detect Local and Network printers, and basic Printer Driver information..."
WriteLog ""
# Backup of Discovered Printers to "$env:userprofile\MS-Scripts\Activity_Telemetry\printers.csv" and Logon Script Runtime Log
# Define the array of printer names to ignore
$printerIgnore = @("Adobe PDF", "Litera Compare PDF Publisher", "Microsoft Print to PDF", "OneNote (Desktop)", "Fax", "Send To OneNote 16", "Microsoft XPS Document Writer") # Add the printer names you want to ignore

# Initialize an array to hold printer information
$printerInfo = @()

# Get the list of all printers
$printers = Get-Printer

# Loop through each printer
foreach ($printer in $printers) {
    # Check if the printer is in the ignore list
    if ($printerIgnore -notcontains $printer.Name) {
        # Initialize a hashtable to hold the printer information
        $printerDetails = @{
            PrinterName   = $printer.Name
            DriverName    = $printer.DriverName
            #PrintServer   = ""
        }

        # Check if the printer is a network printer
        #if ($printer.Shared -eq $true -or $printer.PortName -match "^\\\\") {
         #   $printerDetails.PrintServer = $printer.PrinterHostAddress
        #}

        # Add the printer details to the array
        $printerInfo += [pscustomobject]$printerDetails
    }
}

Remove-Item -Path "$env:userprofile\MS-Scripts\Activity_Telemetry\printers.csv" -Force -ErrorAction Ignore | Out-Null

# Export the printer information to a CSV file
$printerInfo | Export-Csv -Path "$env:userprofile\MS-Scripts\Activity_Telemetry\printers.csv" -NoTypeInformation -Force

$printerInfo | Format-Table -AutoSize | Out-File -FilePath "$env:userprofile\LOGON-$env:computername.log" -Append -Encoding UTF8
"`n" | Out-File -FilePath "$env:userprofile\LOGON-$env:computername.log" -Append -Encoding UTF8

WriteLog ""

# If the UEV module is installed, import the module
If (Get-Module -ListAvailable -Name UEV) {
	Import-Module -Name UEV

    # Check for UE-V service
    $status = Get-UevStatus
    If ($status.UevEnabled -ne $True) {
	    WriteLog "UE-V service is NOT enabled."
    } Else {
	    WriteLog "UE-V service is enabled."
    }
} Else {
    WriteLog "UE-V module is NOT installed."
}
