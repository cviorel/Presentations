. .\00_set-variables.ps1

# Verify Running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    break
}

#region Check Repos
if (!(Get-PSRepository)) {
    try {
        Register-PSRepository -Default
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    catch {
    }
}

if (!(Get-Module dbatools -ListAvailable)) {
    Install-Module dbatools -Force
}

if (!(Get-Module -Name dbatools)) {
    Import-Module dbatools -Force
}
#endregion Check Repos

#region SQL Install
$Credentials = New-Object System.Management.Automation.PSCredential("Administrator", ($SafeModeAdminPassword | ConvertTo-SecureString -AsPlainText -Force))
$saCredential = New-Object System.Management.Automation.PSCredential("sa", ($sa_password | ConvertTo-SecureString -AsPlainText -Force))

$config = @{
    SqlInstance                   = $sqlNodes.Keys
    Version                       = 2019
    InstanceName                  = "$SQLInstanceName"
    Port                          = "$SQLInstancePort"
    Configuration                 = @{
        SQLCOLLATION          = $sqlCollation
        AGTSVCACCOUNT         = "${domainNameShort}\${AgentAccountName}`$"
        SQLSVCACCOUNT         = "${domainNameShort}\${EngineAccountName}`$"
        BROWSERSVCSTARTUPTYPE = "Disabled"
        SQLTELSVCSTARTUPTYPE  = "Disabled"
    }
    Feature                       = "Engine"
    SaCredential                  = $saCredential
    AuthenticationMode            = "Mixed"
    DataPath                      = "C:\$SQLInstanceName\SQLData"
    LogPath                       = "C:\$SQLInstanceName\SQLLog"
    TempPath                      = "C:\$SQLInstanceName\TempDB"
    BackupPath                    = "C:\$SQLInstanceName\SQLBackup"
    AdminAccount                  = "$SQLSYSADMINACCOUNTS"
    PerformVolumeMaintenanceTasks = $true
    Verbose                       = $false
    Confirm                       = $false
    SaveConfiguration             = "C:\Temp"
    Path                          = $setupPath
}

Install-DbaInstance @config -Credential $Credentials
#endregion SQL Install

#region SQL Post Install
$scriptBlockSQLPostInstall = {
    $IPforSQL = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "Ethernet*" }).IPAddress

    # If the node is already part of a Cluster and it's owner of some resources, it will have multiple IPs
    # We need to get the actual IP of the node
    if (($IPforSQL).Count -gt 1) {
        $ipFromDNS = (Resolve-DnsName $env:COMPUTERNAME).IP4Address
        $IPforSQL = $ipFromDNS | Where-Object { $_ -in $IPforSQL }
    }

    if ($null -eq $IPforSQL) {
        Write-Warning ':: Could not determine the IP address for Ethernet0'
        Break
    }

    # Enable the TCP protocol
    $null = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")
    $smo = 'Microsoft.SqlServer.Management.Smo.'
    $wmi = New-Object ($smo + 'Wmi.ManagedComputer').
    $uri = "ManagedComputer[@Name='$env:COMPUTERNAME']/ServerInstance[@Name='$using:SQLInstanceName']/ServerProtocol[@Name='Tcp']"
    $tcp = $wmi.GetSmoObject($uri)
    $tcp.IsEnabled = $true
    $tcp.Alter()
    $tcp

    foreach ($address in $tcp.IPAddresses) {
        if ($address.IPAddress.IPAddressToString -eq $IPforSQL) {
            $address.IPAddressProperties["Enabled"].Value = $True
            $address.IPAddressProperties["TcpPort"].Value = "$using:SQLInstancePort"
            $address.IPAddressProperties["TcpDynamicPorts"].Value = ""
        }
    }
    $tcp.Alter()

    # Enable/Disable ListenOnAllIPs TCP protocol property
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$using:SQLInstanceName\MSSQLServer\SuperSocketNetLib\Tcp" -Name ListenOnAllIPs -Value 0

    $properties = Get-CimInstance -Namespace root/Microsoft/SqlServer/ComputerManagement15 -ClassName ServerNetworkProtocolProperty -Filter "InstanceName='$using:SQLInstanceName' and ProtocolName = 'Tcp' and IPAddressName='IPAll'"
    $properties | Where-Object { $_.PropertyName -eq 'TcpDynamicPorts' } | Invoke-CimMethod -Name SetStringValue -Arguments @{ StrValue = '' }

    # Set DAC to use custom static port
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.$using:SQLInstanceName\MSSQLServer\SuperSocketNetLib\AdminConnection\Tcp" -Name TcpDynamicPorts -Value $using:dacSQLInstancePort

    $SQLServices = (Get-Service | Where-Object { $_.Name -match "MSSQL[$]$using:SQLInstanceName|SQLAgent[$]$using:SQLInstanceName" }).Name
    foreach ($service in $SQLServices) {
        Start-Process -FilePath "$env:windir\System32\sc.exe" -ArgumentList "config $service start= delayed-auto" -NoNewWindow -Wait
    }

    # Enabling SQL Server Ports
    New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound –Protocol TCP -LocalPort $using:SQLInstancePort -Action Allow
    New-NetFirewallRule -DisplayName "SQL Admin Connection" -Direction Inbound –Protocol TCP -LocalPort $using:dacSQLInstancePort -Action Allow
    New-NetFirewallRule -DisplayName "SQL AG" -Direction Inbound –Protocol TCP –LocalPort 5022 -Action Allow

    # Enable Windows Firewall
    Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction Allow -NotifyOnListen True -AllowUnicastResponseToMulticast True
}

foreach ($node in $sqlNodes.Keys) {
    $session = New-PSSession -ComputerName $node
    Invoke-Command -Session $session -ScriptBlock $scriptBlockSQLPostInstall
    $session | Remove-PSSession
}
#endregion SQL Post Install

#region Disable Named Pipes
foreach ($node in $sqlNodes.Keys) {
    (Get-DbaInstanceProtocol -ComputerName $node | Where-Object { $_.DisplayName -eq 'Named Pipes' }).Disable()
}
#endregion Disable Named Pipes

#region NTFSPermissions
foreach ($node in $sqlNodes.Keys) {
    $sqlserviceuser += (Get-DbaService -ComputerName $node -InstanceName $SQLInstanceName -Type Engine).StartName
    $sqlagentuser += (Get-DbaService -ComputerName $node -InstanceName $SQLInstanceName -Type Agent).StartName
}
$sqlagentuser = $sqlagentuser | Select-Object -Unique
$sqlserviceuser = $sqlserviceuser | Select-Object -Unique

$scriptBlockNTFSPermissions = {
    $directories = @(
        "$($using:config.DataPath)"
        "$($using:config.LogPath)"
        "$($using:config.TempPath)"
        "$($using:config.BackupPath)"
    )

    foreach ($dir in $directories) {
        # Take a backup of the inital ACLs
        $sanitizedDir = $dir -replace '[^-\w\.]', '_'
        Start-Process -FilePath "icacls.exe" -ArgumentList "$dir /save c:\Temp\${sanitizedDir}.txt /T /C" -NoNewWindow -Wait

        Start-Process -FilePath "icacls.exe" -ArgumentList "$dir /remove Everyone /T" -NoNewWindow -Wait
        Start-Process -FilePath "icacls.exe" -ArgumentList "$dir /remove ""Creator Owner"" /T" -NoNewWindow -Wait
        Start-Process -FilePath "icacls.exe" -ArgumentList "$dir /remove BUILTIN\Users /T" -NoNewWindow -Wait
        Start-Process -FilePath "icacls.exe" -ArgumentList "$dir /grant:rx ""$using:sqlserviceuser"":(OI)(CI)(F) /C" -NoNewWindow -Wait
        Start-Process -FilePath "icacls.exe" -ArgumentList "$dir /grant:rx ""$using:sqlagentuser"":(OI)(CI)(F) /C" -NoNewWindow -Wait
    }
}

foreach ($node in $sqlNodes.Keys) {
    Invoke-Command -Computer $node -ScriptBlock $scriptBlockNTFSPermissions
}
#endregion NTFSPermissions

#region Best Practices
foreach ($node in $sqlNodes.Keys) {
    $sqlInstance = "$node,$SQLInstancePort"
    Set-DbaSpConfigure -SqlInstance $sqlInstance -ConfigName CostThresholdForParallelism -Value 50
    Set-DbaSpConfigure -SqlInstance $sqlInstance -ConfigName DefaultBackupCompression -Value 1
    Set-DbaSpConfigure -SqlInstance $sqlInstance -ConfigName OptimizeAdhocWorkloads -Value 1
    Set-DbaSpConfigure -SqlInstance $sqlInstance -ConfigName RemoteDacConnectionsEnabled -Value 1
    Set-DbaSpConfigure -SqlInstance $sqlInstance -ConfigName ShowAdvancedOptions -Value 1
    Set-DbaMaxMemory -SqlInstance $sqlInstance
    Set-DbaErrorLogConfig -SqlInstance $sqlInstance -LogCount 25 -LogSize 102400 # 100 MB

    # Suppress all successful backups in SQL server error log
    Set-DbaStartupParameter -SqlInstance "$node\$SQLInstanceName" -TraceFlag 3226 -Confirm:$false -Force

    # Rename and disable SA
    Get-DbaLogin -SqlInstance $sqlInstance -Login 'sa' | Set-DbaLogin -NewName 'sqladmin' -Disable

    $query = @'
SELECT 'KILL ' + CONVERT(VARCHAR(10), l.request_session_id) as tSQL
FROM sys.databases d
	,sys.dm_tran_locks l
WHERE d.database_id = l.resource_database_id
	AND d.name = 'model'
'@

    Set-DbaDbRecoveryModel -SqlInstance $sqlInstance -Database model -RecoveryModel Simple -Confirm:$false
    Invoke-DbaQuery -SqlInstance $sqlInstance -Query 'REVOKE CONNECT TO GUEST' -Database model
    $killQuery = (Invoke-DbaQuery -SqlInstance $sqlInstance -Query $query -Database master).tSQL
    if ($null -ne $killQuery) {
        Invoke-DbaQuery -SqlInstance $sqlInstance -Query $killQuery -Database master
    }

    New-DbaDatabase -SqlInstance $sqlInstance -Database DBA -RecoveryModel Simple -Owner 'sqladmin'
    Invoke-DbaQuery -SqlInstance $sqlInstance -Query 'REVOKE CONNECT TO GUEST' -Database DBA

    Install-DbaMaintenanceSolution -SqlInstance $sqlInstance -ReplaceExisting -CleanupTime 48 -InstallJobs -Database DBA
    Install-DbaWhoIsActive -SqlInstance $sqlInstance -Database DBA

    #region DBA Reports Category
    $existingJobCategory = Get-DbaAgentJobCategory -SqlInstance $sqlInstance -Category 'DBA Reports'
    if (!($existingJobCategory)) {
        New-DbaAgentJobCategory -SqlInstance $sqlInstance -Category 'DBA Reports' -CategoryType LocalJob -Force
    }
    #endregion DBA Reports Category

    #region DBA Recycle SQL Error Log
    $recycleJobName = 'DBA Recycle SQL Error Log'

    $recycleJobNameExists = Get-DbaAgentJob -SqlInstance $sqlInstance -Job $recycleJobName
    if ($recycleJobNameExists) {
        $recycleJobNameExists | Remove-DbaAgentJob
    }

    New-DbaAgentJob -SqlInstance $sqlInstance -Job $recycleJobName `
        -Description 'Recycle SQL Error Log' -OwnerLogin sqladmin -Category 'DBA Reports'

    New-DbaAgentJobStep -SqlInstance $sqlInstance -Job $recycleJobName `
        -StepName 'Recycle SQL Error Log' -Subsystem TransactSql -Database master -Command 'EXEC sp_cycle_errorlog'

    New-DbaAgentSchedule -SqlInstance $sqlInstance -Job $recycleJobName `
        -Schedule 'Every midnight at 12:01' -FrequencyType Daily -FrequencyInterval EveryDay -StartTime 000100 -Force

    #endregion DBA Recycle SQL Error Log
}
#endregion Best Practices
