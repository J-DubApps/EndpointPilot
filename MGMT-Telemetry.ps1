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


WriteLog "Attempting anonymous ISP Geoloction..."

$InOffice = $null

Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
$GeoWatcher.Start() #Begin resolving current locaton

while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
    Start-Sleep -Milliseconds 100 #Wait for discovery.
}

if ($GeoWatcher.Permission -eq 'Denied') {
    WriteLog 'WARN: Access Denied for Location Information. Geolocation skipped.' # Changed from Write-Error
}
else {
    $ISPGeoLocation = $GeoWatcher.Position.Location | Select Latitude, Longitude #Select the relevent results.
    WriteLog "ISP Geoloction Info - $ISPGeoLocation "
}

#extract the Latitude using a capture group
$latmatch = select-string "Latitude=(.*;)" -inputobject $ISPGeoLocation
$latvalue = $latmatch.matches.groups[1].value
$latvalue = $latvalue -replace '[;]', ""
#$latvalue

#extract the Longitude using a capture group
$longmatch = select-string "Longitude=(.*})" -inputobject $ISPGeoLocation
$longvalue = $longmatch.matches.groups[1].value
$longvalue = $longvalue -replace '[}]', ""


if (($latmatch -match '32.8131') -and ($longmatch -match '-96.8112')) {
    #Write-Error 'Access Denied for Location Information'
    WriteLog "PC Endpoint's Physical Location confirmed Dallas Office."
    $InOffice = $True
    #WriteLog "Exiting Script"
    #Exit (0)
}
elseif (($latmatch -match '32.8657') -and ($longmatch -match '-96.7981')) {
    WriteLog "PC Endpoint's Physical Location confirmed Dallas Office."
    $InOffice = $True
}
else {

    #$ISPGeoLocation = $GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevent results.
    #Write-Output "Not Dallas Office"
}

if (($latmatch -match '33.7857') -and ($longmatch -match '-84.5926')) {
    #Write-Error 'Access Denied for Location Information'
    $InOffice = $True
    WriteLog "PC Endpoint's Physical Location confirmed Washington DC Office."
    #WriteLog "Exiting Script"
    #Exit (0)
}
elseif (($latmatch -match '38.9776') -and ($longmatch -match '-77.384')) {

    WriteLog "PC Endpoint's Physical Location confirmed Washington DC Office."
    $InOffice = $True
}
else {

    #$ISPGeoLocation = $GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevent results.
    #Write-Output "Not Dallas Office"
}


# Check if both in the office AND using VPN (for potential Hotspot abuse)

if (($InOffice = $True) -and ($ConnectionType -eq "VPN")) {

    # WriteLog "PC Endpoint is on VPN at the Office! If PC is not a test VM, consider accidental Tethering/Hotspot use!"

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
$IgnoreList = @('.ms-ad', '.1Password', '.android', '.cache', '.fcc', '.junique', '.openjfx', '.vscode', '3D Objects', 'Contacts', 'Desktop', 'Documents', 'Downloads', 'Favorites', 'Links', 'Music', 'MS-Scripts', 'OneDrive', 'OneDrive - McKool Smith', 'ND Office Echo', 'Pictures', 'Saved Games', 'Searches', 'Videos', 'Work Folders')

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
