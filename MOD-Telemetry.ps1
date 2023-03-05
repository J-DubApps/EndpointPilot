#Requires -Version 5.1
#Requires -PSEdition Desktop
###############################################################################################
#
#				PS-Manage Logon / User Profile Configuration Script Shared Settings MODule file
#				MOD-Telemetry.PS1
#
# Description 	This file is a shared component called by MAIN.PS1 portion of PS-Manage
#				This script component MODule determines user general location, Internet Provider
#				and VPN connection status.
#
#				This MODule is required to help PS-Manage operate in a VPN-aware footing, t
#				to ensure needed Scripted tasks are performed regularly for Remote workers
#				who may not be working on-prem (LAN).
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


WriteLog "Determining connection type - VPN vs office, and if on Wired/Wireless LAN"

    #Get Connection Type
    $WirelessConnected = $null
    $WiredConnected = $null
    $VPNConnected = $null

    # Detecting PowerShell version, and call the best cmdlets
    if ($PSVersionTable.PSVersion.Major -gt 2)
    {
        # Using Get-CimInstance for PowerShell version 3.0 and higher
        $WirelessAdapters =  Get-CimInstance -Namespace "root\WMI" -Class MSNdis_PhysicalMediumType -Filter `
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
        $ConnectedAdapters =  Get-CimInstance -Class win32_NetworkAdapter -Filter `
            'NetConnectionStatus = 2'
        $VPNAdapters =  Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter `
            "Description like '%pangp%' `
            or Description like '%cisco%'  `
            or Description like '%juniper%' `
            or Description like '%vpn%'"
    }
    else
    {
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


    Foreach($Adapter in $ConnectedAdapters) {
        If($WirelessAdapters.InstanceName -contains $Adapter.Name)
        {
            $WirelessConnected = $true
        }
    }

    Foreach($Adapter in $ConnectedAdapters) {
        If($WiredAdapters.InstanceName -contains $Adapter.Name)
        {
            $WiredConnected = $true
        }
    }

    Foreach($Adapter in $ConnectedAdapters) {
        If($VPNAdapters.Index -contains $Adapter.DeviceID)
        {
            $VPNConnected = $true
        }
    }

    If(($WirelessConnected -ne $true) -and ($WiredConnected -eq $true)){$ConnectionType="WIRED"}
    If(($WirelessConnected -eq $true) -and ($WiredConnected -eq $true)){$ConnectionType="WIRED AND WIRELESS"}
    If(($WirelessConnected -eq $true) -and ($WiredConnected -ne $true)){$ConnectionType="WIRELESS"}

    WriteLog "Connection type for this PC is: $ConnectionType"

    If($VPNConnected -eq $true){$ConnectionType="VPN"}

    #Write-Output "Connection type is: $ConnectionType"

    ## Are we on VPN?

    If(($ConnectionType -eq "VPN")){

        WriteLog "PC is on VPN, continuing Logon Script run..."
        #$ConnectionType

        } else {

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

$HostExtIP = (Invoke-WebRequest -uri "https://api.ipify.org/").Content

WriteLog "External IP Address is $HostExtIP"

$HostISP = Invoke-RestMethod -Uri "http://ipinfo.io" | foreach { $_.org }

WriteLog "Possible Internet Provider is $HostISP"


$Manufacturer = gwmi -q "select Manufacturer from win32_computersystem" | foreach { $_.Manufacturer }
$isVM = $false

If(($Manufacturer -eq "VMware, Inc.")){

	WriteLog "PC Endpoint is Virtual Machine running in VMware."
    $isVM = $True

	} else {

}


WriteLog "Attempting anonymous ISP Geoloction..."

$InOffice = $null

Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
$GeoWatcher.Start() #Begin resolving current locaton

while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
    Start-Sleep -Milliseconds 100 #Wait for discovery.
}

if ($GeoWatcher.Permission -eq 'Denied'){
    Write-Error 'Access Denied for Location Information'
} else {
	$ISPGeoLocation = $GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevent results.
    WriteLog "ISP Geoloction Info - $ISPGeoLocation "
}

#extract the Latitude using a capture group
$latmatch = select-string "Latitude=(.*;)" -inputobject $ISPGeoLocation
$latvalue = $latmatch.matches.groups[1].value
$latvalue = $latvalue -replace '[;]',""
#$latvalue

#extract the Longitude using a capture group
$longmatch = select-string "Longitude=(.*})" -inputobject $ISPGeoLocation
$longvalue = $longmatch.matches.groups[1].value
$longvalue = $longvalue -replace '[}]',""


if(($latmatch -match '32.8131') -and ($longmatch -match '-96.8112')){
    #Write-Error 'Access Denied for Location Information'
	WriteLog "PC Endpoint's Physical Location confirmed Dallas Office."
    $InOffice = $True
    #WriteLog "Exiting Script"
    #Exit (0)
} elseif(($latmatch -match '32.8657') -and ($longmatch -match '-96.7981')){
	WriteLog "PC Endpoint's Physical Location confirmed Dallas Office."
    $InOffice = $True
}else {

	#$ISPGeoLocation = $GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevent results.
    	#Write-Output "Not Dallas Office"
}

if(($latmatch -match '33.7857') -and ($longmatch -match '-84.5926')){
    #Write-Error 'Access Denied for Location Information'
    $InOffice = $True
	WriteLog "PC Endpoint's Physical Location confirmed Washington DC Office."
    #WriteLog "Exiting Script"
    #Exit (0)
} elseif(($latmatch -match '38.9776') -and ($longmatch -match '-77.384')){

	WriteLog "PC Endpoint's Physical Location confirmed Washington DC Office."
    $InOffice = $True
}else {

	#$ISPGeoLocation = $GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevent results.
    	#Write-Output "Not Dallas Office"
}


# Check if both in the office AND using VPN (for potential Hotspot abuse)

if(($InOffice = $True) -and ($ConnectionType -eq "VPN")){

    # WriteLog "PC Endpoint is on VPN at the Office! If PC is not a test VM, consider accidental Tethering/Hotspot use!"

} else {


}
