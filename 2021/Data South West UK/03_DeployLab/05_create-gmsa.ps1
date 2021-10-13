
. .\00_set-variables.ps1

$nodeList = @($sqlNodes.Keys)

$dc = (Get-ADDomainController -Filter *).Name
$fqdn = Get-ADDomain -Server $dc

$serviceAccounts = @(
    $EngineAccountName,
    $AgentAccountName
)

$allowedHosts = Get-ADComputer -Filter * -Server $fqdn.Forest | Where-Object { $_.Name -in $nodeList }
$domainAdminCreds = New-Object System.Management.Automation.PSCredential("Administrator@$domainName", ($SafeModeAdminPassword | ConvertTo-SecureString -AsPlainText -Force))

foreach ($service in $serviceAccounts) {
    try {
        New-ADServiceAccount -Name $service -PrincipalsAllowedToRetrieveManagedPassword $allowedHosts -Enabled:$true `
            -DNSHostName "${service}.$($fqdn.Forest)" -SamAccountName $service -ManagedPasswordIntervalInDays 30 `
            -Description "gMSA for the $($SQLInstanceName) instance $($service) on $($ClusterCNO) Cluster" `
            -TrustedForDelegation:$true `
            -KerberosEncryptionType AES128, AES256 `
            -Server $fqdn.Forest `
            -Credential $domainAdminCreds
    }
    catch {
    }
}
