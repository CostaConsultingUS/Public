<# 
Set DNS and NTP by code version 3
This code uses Get-Groupdetails.ps1 
The get-groupdetails.ps1 has been edited to run this code so that it does not prompt for username\password, or OME IP

Changes from v2
- Fixed AD foreach block
- Corrected loop variable usage
- Corrected RACADM IP targeting
- Fixed SA NTP2 index
- Wired PasswordState variables

written by: Patrick Costa
Legos by:   Eric Talamantes
            Raajeev Kalyanaraman (Dell's git-lab)
#>

# this is the location of the Get-GroupDetails.ps1 required for the vars
Set-Location C:\Scripts\gitrepo\Powershell\PatrickScripts\WIP\OME

# get idrac lists
$SAServers = .\Get-GroupDetails.ps1 -groupinfo "SAServers"
$NACMC     = .\Get-GroupDetails.ps1 -groupinfo "NACMC"
$SACMC     = .\Get-GroupDetails.ps1 -groupinfo "SACMC"
$NAServers = .\Get-GroupDetails.ps1 -groupinfo "NAServers"

# Modify these 2 vars to define where the VMHosts should point NTP server settings
$SiteCode1 = "xxxxx"
$SiteCode2 = "xxxxx"

# Define DNS server(s) using Active Directory
$ADSiteNASA = Get-ADReplicationSite -Filter { (Name -eq $SiteCode1) -or (Name -eq $SiteCode2) }

$ADDomainControllersNASA = foreach ($site in $ADSiteNASA) {
    Get-ADDomainController -Filter "Site -eq '$($site.Name)'" | Select-Object -ExpandProperty IPv4Address
}

# Define DNS and NTP servers for NA, and SA
$NADNSServers = $ADDomainControllersNASA[0], $ADDomainControllersNASA[1]
$SADNSServers = $ADDomainControllersNASA[1], $ADDomainControllersNASA[0]
$NANTPServers = $ADDomainControllersNASA[0], $ADDomainControllersNASA[1]
$SANTPServers = $ADDomainControllersNASA[1], $ADDomainControllersNASA[0]

# PasswordState configuration
<#Stripped out all the password configurations that we didn for the client. #>

# NA Servers (standard iDRAC)
foreach ($idrac in $NAServers) {
    $name = $idrac.DeviceName
    $IP   = $idrac.IPAddress

    $UP = $AllPW | Where-Object DeviceName -EQ $name

    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ipv4.dns1 $NADNSServers[0]
    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ipv4.dns2 $NADNSServers[1]
    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ntpconfiggroup.ntp1 $NANTPServers[0]
    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ntpconfiggroup.ntp2 $NANTPServers[1]
    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ntpconfiggroup.ntpenable enabled
}

# NA CMC
foreach ($idrac in $NACMC) {
    $name = $idrac.DeviceName
    $IP   = $idrac.IPAddress

    $UP = $AllPW | Where-Object DeviceName -EQ $name

    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfglannetworking -o cfgdnsserver1 $NADNSServers[0]
    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfglannetworking -o cfgdnsserver2 $NADNSServers[1]
    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfgremotehosts -o cfgRhostsNtpServer1 $NANTPServers[0]
    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfgremotehosts -o cfgRhostsNtpServer2 $NANTPServers[1]
    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfgremotehosts -o cfgrhostsntpenable 1
}

# SA Servers (standard iDRAC)
foreach ($idrac in $SAServers) {
    $name = $idrac.DeviceName
    $IP   = $idrac.IPAddress

    $UP = $AllPW | Where-Object DeviceName -EQ $name

    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ipv4.dns1 $SADNSServers[0]
    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ipv4.dns2 $SADNSServers[1]
    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ntpconfiggroup.ntp1 $SANTPServers[0]
    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ntpconfiggroup.ntp2 $SANTPServers[1]
    racadm -r $IP -u $UP.UserName -p $UP.Password set idrac.ntpconfiggroup.ntpenable enabled
}

# SA CMC
foreach ($idrac in $SACMC) {
    $name = $idrac.DeviceName
    $IP   = $idrac.IPAddress

    $UP = $AllPW | Where-Object DeviceName -EQ $name

    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfglannetworking -o cfgdnsserver1 $SADNSServers[0]
    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfglannetworking -o cfgdnsserver2 $SADNSServers[1]
    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfgremotehosts -o cfgRhostsNtpServer1 $SANTPServers[0]
    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfgremotehosts -o cfgRhostsNtpServer2 $SANTPServers[1]
    racadm -r $IP -u $UP.UserName -p $UP.Password config -g cfgremotehosts -o cfgrhostsntpenable 1
}