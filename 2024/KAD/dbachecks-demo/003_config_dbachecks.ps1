<#
.SYNOPSIS
This script sets up the configuration for the dbachecks module.

.DESCRIPTION
The script defines various variables and sets up advanced configurations for the dbachecks module. It creates custom folders, sets configuration values, and exports the configuration to a JSON file.

.PARAMETER saUser
The username for the SQL Server system administrator.

.PARAMETER dbaDatabase
The name of the database used by the dbachecks module.

.PARAMETER allowedTraceFlags
An array of trace flags that are allowed.

.PARAMETER requiredXevents
An array of XE sessions that are required.

.PARAMETER validXevents
An array of XE sessions that are valid.

.PARAMETER dbaOperatorEmail
The email address of the DBA operator.

.PARAMETER dbaOperatorName
The name of the DBA operator.

.PARAMETER mailProfile
The mail profile used by the DBA team.

.PARAMETER myChecks
The path to the dbachecks folder.

.PARAMETER myCustomChecks
The path to the custom checks folder.

.PARAMETER myChecksReport
The path to the report folder.

.EXAMPLE
.\01_config_dbachecks.ps1
This script sets up the configuration for the dbachecks module.

.NOTES
Author: Viorel Ciucu
#>

#region Variables
$saUser = 'sa'
$dbaDatabase = 'DBA'
$allowedTraceFlags = @(2301, 2371, 3226, 3459)
$requiredXevents = @('system_health', 'TimeOuts')
$validXevents = @('system_health', 'TimeOuts')

$dbaOperatorEmail = 'TheOperator@lan.local'
$dbaOperatorName = 'TheOperator'
$mailProfile = 'The DBA Team'

$myChecks = Normalize-Path -Path "dbachecks"
$myCustomChecks = Normalize-Path -Path "$myChecks\CustomChecks"
$myChecksReport = Normalize-Path -Path "$myChecks\Report"
#endregion Variables

#region Custom Folders
if (!(Test-Path -Path $myChecks)) {
    New-Item -Path $myChecks -ItemType Directory | Out-Null
}
if (!(Test-Path -Path $myCustomChecks)) {
    New-Item -Path $myCustomChecks -ItemType Directory | Out-Null
}
if (!(Test-Path -Path $myChecksReport)) {
    New-Item -Path $myChecksReport -ItemType Directory | Out-Null
}
#endregion Custom Folders

#region Advanced Config

# Resets configuration entries to their default values
$null = Reset-DbcConfig

# How many Configurations
# (Get-DbcConfig).Count

Set-DbcConfig -Name app.sqlcredential -Value $credential

# The computername we will be testing
Set-DbcConfig -Name app.computername -Value $sqlInstances

# The Instances we want to test
Set-DbcConfig -Name app.sqlinstance -Value $sqlInstances

# fix for linux paths
Set-DbcConfig -Name app.checkrepos -Value $(Normalize-Path -Path (Get-DbcConfig -Name app.checkrepos).Value)

# Report files location
Set-DbcConfig -Name app.maildirectory -Value $myChecksReport
Set-DbcConfig -Name app.localapp -Value $myChecks

Set-DbcConfig -Name agent.failsafeoperator -Value $dbaOperatorEmail

# Percent disk free
Set-DbcConfig -Name policy.diskspace.percentfree -Value 10

# The maximum percentage variance that the last run of a job is allowed over the average for that job
Set-DbcConfig -Name agent.lastjobruntime.percentage -Value 20

# The maximum percentage variance that a currently running job is allowed over the average for that job
Set-DbcConfig -Name agent.longrunningjob.percentage -Value 20

# Maximum job history log size (in rows). The value -1 means disabled
Set-DbcConfig -Name agent.history.maximumhistoryrows -Value 10000

# The maximum number of days to check for failed jobs
Set-DbcConfig -Name agent.failedjob.since -Value 8

Set-DbcConfig -Name skip.connection.remoting -Value $true
Set-DbcConfig -Name skip.connection.ping -Value $true
Set-DbcConfig -Name skip.connection.auth -Value $true

Set-DbcConfig -Name agent.alert.severity -Value $(17..25)

# The number of days prior to check for error log issues - default 2
Set-DbcConfig -Name agent.failedjob.since -Value 3

# The cluster for the HADR tests
# Set-DbcConfig -Name app.cluster -Value $clusterName

# The database owner we expect
Set-DbcConfig -Name policy.validdbowner.name -Value $saUser

# the database owner we do NOT expect
Set-DbcConfig -Name policy.invaliddbowner.name -Value $saUser

# Should backups be compressed by default?
Set-DbcConfig -Name policy.backup.defaultbackupcompression -Value $true

# Do we allow DAC connections?
Set-DbcConfig -Name policy.dacallowed -Value $true

# What recovery model should we have?
Set-DbcConfig -Name policy.recoverymodel.type -Value FULL

# What should our database growth type be?
Set-DbcConfig -Name policy.database.filegrowthtype -Value 'kb'

# What authentication scheme are we expecting?
Set-DbcConfig -Name policy.connection.authscheme -Value 'SQL'

# Which Agent Operator should be defined?
Set-DbcConfig -Name agent.dbaoperatorname -Value $dbaOperatorName

# Windows only
Set-DbcConfig -Name skip.security.agentserviceadmin -Value $true
Set-DbcConfig -Name skip.security.builtinadmin -Value $true

# Which Agent Operator email should be defined?
Set-DbcConfig -Name agent.dbaoperatoremail -Value $dbaOperatorEmail

# Mail Profile
Set-DbcConfig -Name agent.databasemailprofile -Value $mailProfile

# Where is the whoisactive stored procedure?
Set-DbcConfig -Name policy.whoisactive.database -Value $dbaDatabase

# What is the maximum time since I took a Full backup?
Set-DbcConfig -Name policy.backup.fullmaxdays -Value 7

# What is the maximum time since I took a DIFF backup (in hours) ?
Set-DbcConfig -Name policy.backup.diffmaxhours -Value 26

# What is the maximum time since I took a log backup (in minutes)?
Set-DbcConfig -Name policy.backup.logmaxminutes -Value 30

# What is my domain name?
Set-DbcConfig -Name domain.name -Value $domainName

# Where is my Ola database?
Set-DbcConfig -Name policy.ola.database -Value $dbaDatabase

# Which database should not be checked for recovery model
Set-DbcConfig -Name policy.recoverymodel.excludedb -Value 'master', 'msdb', 'tempdb', 'MSDBData'

# What is my SQL Credential
Set-DbcConfig -Name app.sqlcredential -Value $null

# Should I skip the check for temp files on c?
Set-DbcConfig -Name skip.tempdbfilesonc -Value $true

# Should I skip the check for temp files count?
Set-DbcConfig -Name skip.tempdbfilecount -Value $true

# Don't run test for Temp Database Files Max Size
Set-DbcConfig -Name skip.tempdbfilesizemax -Value $true

# Which Checks should be excluded?
Set-DbcConfig -Name command.invokedbccheck.excludecheck -Value LogShipping, ExtendedEvent, PseudoSimple

# How many months before a build is unsupported do I want to fail the test?
Set-DbcConfig -Name policy.build.warningwindow -Value 6

# Adhoc Distributed Queries
Set-DbcConfig -Name policy.security.adhocdistributedqueriesenabled -Value $false

# Custom Trace Flags
Set-DbcConfig -Name policy.traceflags.expected -Value $allowedTraceFlags

# List of XE Sessions that should be running
Set-DbcConfig -Name policy.xevent.requiredrunningsession -Value $requiredXevents

# List of XE Sessions that can be be running
Set-DbcConfig -Name policy.xevent.validrunningsession -Value $validXevents

# Valid MaxDOP value - for each DB
Set-DbcConfig -Name policy.instancemaxdop.userecommended -Value $true
# Set-DbcConfig -Name policy.database.maxdop -Value 1
# Set-DbcConfig -Name policy.database.maxdopexcludedb -Value $dbaDatabase

# Valid MaxDOP value - instance
Set-DbcConfig -Name policy.instancemaxdop.maxdop -Value 1

# Query store
Set-DbcConfig -Name database.querystoreenabled.excludedb -Value 'master', 'msdb', 'tempdb', 'MSDBData'
Set-DbcConfig -Name database.querystoredisabled.excludedb -Value 'master', 'msdb', 'tempdb', 'MSDBData'

Set-DbcConfig -Name policy.database.filegrowthexcludedb -Value 'master', 'msdb', 'tempdb', 'MSDBData'

Set-DbcConfig -Name policy.security.databasemailenabled -Value $true

# This is non default setting
Set-DbcConfig -Name policy.database.autoupdatestatisticsasynchronously -Value $false

# Skips the scan for if the public role has access to SQL Agent proxies
Set-DbcConfig -Name skip.security.sqlagentproxiesnopublicrole -Value $false

Set-DbcConfig -Name skip.security.engineserviceadmin -Value $false

Set-DbcConfig -Name skip.security.sadisabled -Value $false

Set-DbcConfig -Name skip.security.builtinadmin -Value $false

Set-DbcConfig -Name skip.tempdb1118 -Value $true

# Take a peek at the config
# Get-DbcConfig | Out-ConsoleGridView

# Get-DbcTagCollection

# Search for a specific config
#Get-DbcConfig *tempdb*

Export-DbcConfig -Path $(Normalize-Path -Path "$myChecks\checks.json") -Force | Out-Null

# Config can be saved and loaded from a file for easy sharing
# $environment = 'PROD'
# Export-DbcConfig -Path $(Normalize-Path -Path "$myChecks\$environment.json") -Force | Out-Null
# $null = Import-DbcConfig -Path $(Normalize-Path -Path "$myChecks\$environment.json")
#endregion  Advanced Config
