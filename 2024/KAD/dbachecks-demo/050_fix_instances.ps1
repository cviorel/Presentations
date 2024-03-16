<#
.SYNOPSIS
This script performs various configuration tasks on SQL instances and databases.

.DESCRIPTION
The script sets custom, best practice options on the SQL instance, creates logins and server roles, configures database settings, sets up database mail, installs maintenance solutions, schedules backup and maintenance jobs, creates operators and alerts, and performs other configuration tasks.

.PARAMETER SqlInstance
Specifies the SQL instances on which the configuration tasks will be performed.

.PARAMETER SqlCredential
Specifies the credential to use for authenticating with the SQL instances.

.EXAMPLE
.\050_fix_instances.ps1 -SqlInstance 'SQLServer1', 'SQLServer2' -SqlCredential $credential
Performs the configuration tasks on the SQL instances 'SQLServer1' and 'SQLServer2' using the specified credential.

.NOTES
- This script requires the dbatools module to be installed.
- The script should be run with administrative privileges.
- Review and modify the script according to your specific requirements before running it.
#>

$Params = @{
    SqlInstance   = $sqlInstances
    SqlCredential = $credential
}

New-DbaLogin @Params -Login 'sqladmin' -SecurePassword $((Get-SaCredential -SecretName sqladmin).Password) -Force
Add-DbaServerRoleMember @Params -ServerRole sysadmin -Login sqladmin -Confirm:$false

# Sets custom, best practice options on the SQL instance running on $server
Set-DbaSpConfigure @Params -ConfigName CostThresholdForParallelism -Value 50
Set-DbaSpConfigure @Params -ConfigName DefaultBackupCompression -Value 1
Set-DbaSpConfigure @Params -ConfigName OptimizeAdhocWorkloads -Value 1
Set-DbaSpConfigure @Params -ConfigName RemoteDacConnectionsEnabled -Value 1
Set-DbaSpConfigure @Params -ConfigName ShowAdvancedOptions -Value 1
# Set-DbaErrorLogConfig @Params -LogCount 25 -LogSize 102400 # 100 MB
Set-DbaMaxDop @Params

Set-DbaDbRecoveryModel @Params -Database model -RecoveryModel Simple -Confirm:$false
Invoke-DbaQuery @Params -Query 'REVOKE CONNECT TO GUEST' -Database model

New-DbaDatabase @Params -Database DBA -RecoveryModel Simple -Owner 'sqladmin'
Invoke-DbaQuery @Params -Query 'REVOKE CONNECT TO GUEST' -Database DBA

Set-DbaSpConfigure @Params -Name "Database Mail XPs" -Value $true

Remove-DbaDbMailAccount @Params -Account 'The DBA Team' -Confirm:$false
New-DbaDbMailAccount @Params -Account 'The DBA Team' -Description 'The DBA Team' -MailServer 'smtp.lan.local' -EmailAddress "DBATeam@lan.local" -Force
Remove-DbaDbMailProfile @Params -Confirm:$false
New-DbaDbMailProfile @Params -Profile 'The DBA Team'

# Suppress all successful backups in SQL server error log
#Enable-DbaTraceFlag @Params -TraceFlag 3226
#Set-DbaStartupParameter @Params -TraceFlag 3226 -Confirm:$false -Force -Verbose

Enable-DbaTraceFlag @Params -TraceFlag 2301

Install-DbaMaintenanceSolution @Params -Database DBA -Solution All -ReplaceExisting -CleanupTime 48 -InstallJobs #-LocalFile "$env:HOME\ola-sql-server-maintenance-solution.zip"

New-DbaAgentSchedule @Params -Job 'DatabaseBackup - SYSTEM_DATABASES - FULL' -Schedule Daily -FrequencyType Daily -FrequencyInterval Everyday -StartTime 010000 -Force
#New-DbaAgentSchedule @Params -Job 'DatabaseBackup - USER_DATABASES - DIFF' -Schedule Weekdays -FrequencyType Weekly -FrequencyInterval Weekdays -StartTime 020000 -Force
New-DbaAgentSchedule @Params -Job 'DatabaseBackup - USER_DATABASES - FULL' -Schedule Sunday -FrequencyType Daily -FrequencyInterval Everyday -StartTime 020000 -Force
New-DbaAgentSchedule @Params -Job 'DatabaseBackup - USER_DATABASES - LOG' -Schedule 'Every_15_Minutes' -FrequencyType Daily -FrequencyInterval EveryDay -FrequencySubdayType Minutes -FrequencySubdayInterval 15 -StartTime 000000 -Force

New-DbaAgentSchedule @Params -Job 'DatabaseIntegrityCheck - SYSTEM_DATABASES' -Schedule Saturday -FrequencyType Weekly -FrequencyInterval Saturday -StartTime 210000 -Force
New-DbaAgentSchedule @Params -Job 'DatabaseIntegrityCheck - USER_DATABASES' -Schedule Saturday -FrequencyType Weekly -FrequencyInterval Saturday -StartTime 220000 -Force
New-DbaAgentSchedule @Params -Job 'IndexOptimize - USER_DATABASES' -Schedule Saturday -FrequencyType Weekly -FrequencyInterval Saturday -StartTime 230000 -Force

New-DbaAgentSchedule @Params -Job 'CommandLog Cleanup' -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
New-DbaAgentSchedule @Params -Job 'Output File Cleanup' -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
New-DbaAgentSchedule @Params -Job 'sp_delete_backuphistory' -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force
New-DbaAgentSchedule @Params -Job 'sp_purge_jobhistory' -Schedule Monthly -FrequencyType Monthly -FrequencyInterval 1 -StartTime 060000 -Force

Install-DbaWhoIsActive @Params -Database DBA #-LocalFile "$env:HOME\Downloads\spwhoisactive.zip"
# Set-DbaTempDbConfig @Params -DataFileSize 500 -DataFileGrowth 100 -LogFileSize 200 -LogFileGrowth 100

#region DBA Reports Category
New-DbaAgentJobCategory @Params -Category 'DBA Reports' -CategoryType LocalJob -Force
#endregion DBA Reports Category

#region Operator
$Operator = @{
    SqlInstance       = $Params.SqlInstance
    SqlCredential     = $Params.SqlCredential
    Operator          = 'TheOperator'
    EmailAddress      = 'TheOperator@lan.local'
    NetSendAddress    = "sqladmin"
    PagerAddress      = 'TheOperator@lan.local'
    PagerDay          = 'Everyday'
    SaturdayStartTime = '070000'
    SaturdayEndTime   = '180000'
    SundayStartTime   = '080000'
    SundayEndTime     = '170000'
    WeekdayStartTime  = '060000'
    WeekdayEndTime    = '190000'
}
New-DbaAgentOperator @Operator -Force
#endregion Operator

#region Alerts
# Creates alerts for severity 17-25 and messages 823-825
Install-DbaAgentAdminAlert @Params
#endregion Alerts

#region DBA Recycle SQL Error Log
$recycleJobName = 'DBA Recycle SQL Error Log'

$recycleJobNameExists = Get-DbaAgentJob @Params -Job $recycleJobName
if ($recycleJobNameExists) {
    $recycleJobNameExists | Remove-DbaAgentJob -Confirm:$false
}

New-DbaAgentJob @Params -Job $recycleJobName -Description 'Recycle SQL Error Log' -OwnerLogin sqladmin -Category 'DBA Reports'
New-DbaAgentJobStep @Params -Job $recycleJobName -StepName 'Recycle SQL Error Log' -Subsystem TransactSql -Database master -Command 'EXEC sp_cycle_errorlog'
New-DbaAgentSchedule @Params -Job $recycleJobName -Schedule 'Every midnight at 12:01' -FrequencyType Daily -FrequencyInterval EveryDay -StartTime 000100 -Force
#endregion DBA Recycle SQL Error Log

$sqlInstances | ForEach-Object -ThrottleLimit $([Environment]::ProcessorCount) -Parallel {
    Backup-DbaDatabase -SqlInstance $_ -SqlCredential $using:credential -BackupDirectory "/shared/$_" -Type Full
    Backup-DbaDatabase -SqlInstance $_ -SqlCredential $using:credential -BackupDirectory "/shared/$_" -Type Log
}

$userDBs = Get-DbaDatabase @Params -ExcludeSystem
Set-DbaDbFileGrowth @Params -GrowthType MB -Growth 100 -Database $userDBs, model -Confirm:$false

Set-DbaDbRecoveryModel @Params -Database $userDBs.name -RecoveryModel Full -Confirm:$false
Set-DbaDbRecoveryModel @Params -Database model -RecoveryModel Full -Confirm:$false

Set-DbaDbQueryStoreOption @Params -State ReadWrite -Database $userDBs.name
