. .\00_set-variables.ps1

if ($($sqlNodes.Keys) -contains $env:COMPUTERNAME) {
    $servicesToInstall = @(
        'RSAT-AD-PowerShell',
        'Failover-Clustering'
    )
    Install-WindowsFeature -Name $servicesToInstall -IncludeManagementTools -IncludeAllSubFeature
}

if ($($managementNodes.Keys) -contains $env:COMPUTERNAME) {
    $servicesToInstallMGMT = @(
        'Failover-Clustering',
        'RSAT-AD-Tools',
        'RSAT-DHCP',
        'RSAT-DNS-Server'
    )

    Install-WindowsFeature -Name $servicesToInstallMGMT -IncludeManagementTools -IncludeAllSubFeature
}

$interfaceIndex = $(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "Ethernet*" }).InterfaceIndex
Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $($domainControllers.Values)

Set-DnsClient -InterfaceIndex $interfaceIndex -ConnectionSpecificSuffix $domainName -RegisterThisConnectionsAddress:$true -UseSuffixWhenRegistering:$true
Set-DnsClientGlobalSetting -SuffixSearchList "$domainName"

Set-Item –Path WSMan:\localhost\Client\TrustedHosts -Value "*.${domainName}" -Force

$domainAdminCreds = New-Object System.Management.Automation.PSCredential("Administrator@$domainName", ($SafeModeAdminPassword | ConvertTo-SecureString -AsPlainText -Force))
Add-Computer -DomainName $domainName -Credential $domainAdminCreds

Restart-Computer -Force
