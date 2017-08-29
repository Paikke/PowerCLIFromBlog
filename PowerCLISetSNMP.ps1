# The following blog post describes this script: https://pascalswereld.nl/2014/05/03/powercli-collection-adding-snmp-settings-to-esxi/

#Settings

$vCenterFQDN = Read-Host “Enter vCenter FQDN: “

$ClusterName = Read-Host “Enter Cluster name of hosts that will need to be changed: “

$trapDestination = Read-Host “SNMP Trap Mgmt server hostname: “

$trapCommunity = Read-Host “Trap Community Name: “

$ReadOnlyCommunity = Read-Host “Read Only Community Name: “

 

# Running no need to change under this line

# Connect to the vCenter server

Write-Host “vCenter credentials”

$viServer = Connect-VIServer -Server $vCenterFQDN -Credential (Get-Credential)

 

# Get all hosts in vCenter managed Cluster so we can cycle thru them

$Hosts = Get-Cluster -Name $ClusterName | Get-VMHost

 

# Get ESXi Host credentials

Write-Host “ESXi host credentials”

$EsxCred = Get-Credential

 

# Cycle through each host

ForEach ($VMHost in $Hosts)

{

                # Need to connect to ESXi itself

                $esxconnect = Connect-VIServer -Server $VMHost -Credential $EsxCred

 

                # Get snmp object

                $snmpConn = Get-VMHostSnmp

 

                # Enable snmp

                Set-VMHostSnmp -HostSnmp $snmpConn -Enabled:$true

 

                # Set read-only community

                Set-VMHostSnmp -HostSnmp $snmpConn -ReadOnlyCommunity $ReadOnlyCommunity

 

                # Set trap target host and trap community

                Set-VMHostSnmp -HostSnmp $snmpConn -AddTarget -TargetCommunity $trapCommunity -TargetHost $trapDestination

 

                # Disconnect-VIServer

                Disconnect-VIServer -Server $esxconnect -Confirm:$false

}

 

#disconnect from ESX server

Disconnect-VIServer -Server $viServer -Confirm:$false