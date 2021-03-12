#region VMs
$domainControllers = @{
    'tf-wincore01' = "192.168.1.81"
}

$sqlNodes = @{
    'tf-wincore02' = "192.168.1.82"
    'tf-wincore03' = "192.168.1.83"
}

$managementNodes = @{
    'tf-wingui01' = "192.168.1.84"
}
#endregion VMs

#region AD
$globalSubnet = '192.168.1.0/24'

# NTP Variables
$ntpserver1 = '0.be.pool.ntp.org'
$ntpserver2 = '1.be.pool.ntp.org'

$subnetLocation = 'Brussels,Belgium'

$domainName = 'lab.local'
$domainNameShort = (($domainName.Split('.'))[0]).ToUpper()
$SafeModeAdminPassword = 'SecretPa$$word'
$LocalAdminPassword = 'SecretPa$$word'
#endregion AD

#region WFC
$cluster_name = 'dbcluster'
$ClusterCNO = 'SQLClu'
$ClusterIP = '192.168.1.99'
#endregion WFC

#region SQL
$SQLInstanceName = 'SQL1'
$SQLInstancePort = 10001
$dacSQLInstancePort = '2000' + $SQLInstanceName.Substring($($SQLInstanceName.Length) - 1, 1)
$db_folder_data = 'SQLData'
$db_folder_log = 'SQLLog'
$db_folder_backup = 'SQLBackup'
$db_name = 'TestDB'
$sa_password = 'SecretPa$$word'
$EngineAccountName = "svc_${SQLInstanceName}_de"
$AgentAccountName = "svc_${SQLInstanceName}_ag"
$sqlCollation = 'SQL_Latin1_General_CP1_CI_AS'
$SQLSYSADMINACCOUNTS = @("$domainNameShort\Administrator")
$setupPath = "\\192.168.1.94\share"
#endregion SQL

#region Availability Group
$name_ag = 'cluster-ag'
$name_ag_listener = 'ag-listener'
$ag_listener_ip = '192.168.1.199'
#endregion Availability Group
