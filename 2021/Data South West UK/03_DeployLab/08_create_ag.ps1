. .\00_set-variables.ps1

# Verify Running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    break
}

foreach ($node in $sqlNodes.Keys) {
    Enable-DbaAgHadr -SqlInstance "$node\$SQLInstanceName" -Force -Confirm:$false
}

$node1 = $sqlNodes.Keys | Sort-Object | Select-Object -First 1
$remaininNodes = $sqlNodes.Keys -notmatch $node1
$remaininNodesInstances = @()
foreach ($item in $remaininNodes) {
    $remaininNodesInstances += "$item,$SQLInstancePort"
}

New-DbaDatabase -SqlInstance "$node1,$SQLInstancePort" -Database TestDB `
    -RecoveryModel Full -Owner sqladmin
Backup-DbaDatabase -SqlInstance "$node1,$SQLInstancePort" -Database TestDB `
    -FilePath C:\Temp\TestDB.bak -Type Full -IgnoreFileChecks

$agParams = @{
    Name         = "$name_ag"
    Primary      = "$node1,$SQLInstancePort"
    Secondary    = $remaininNodesInstances
    Database     = "TestDB"
    ClusterType  = "Wsfc"
    SeedingMode  = "Automatic"
    FailoverMode = "Automatic"
    Confirm      = $false
    Verbose      = $true
}
New-DbaAvailabilityGroup @agParams

$CIDR_Bits = ('1' * ($globalSubnet.Split('/')[1])).PadRight(32, "0")

# Split into groups of 8 bits, convert to Ints, join up into a string
$octets = $CIDR_Bits -split '(.{8})' -ne ''
$netmask = ($octets | ForEach-Object -Process { [Convert]::ToInt32($_, 2) }) -join '.'

Add-DbaAgListener -SqlInstance "$node1,$SQLInstancePort" `
    -Name $name_ag_listener -AvailabilityGroup $name_ag `
    -IPAddress $ag_listener_ip -SubnetMask $netmask `
    -Port $SQLInstancePort -Verbose
