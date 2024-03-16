# DBACHECKS

## Purpose

The current configuration of servers hosting SQL Server instances needs to be monitored against configuration drift and to validate that best practices are applied.

## Method

dbachecks is a PowerShell module created by and for SQL Server pros who need to validate their environments.
Basically, we all share similar checklists and mostly just the server names and RPO/RTO/etc. change.
This open-source module allows us to crowdsource our checklists using Pester tests. Such checks include:

- Backups are being performed
- Identity columns are not about to max out
- Servers have access to backup paths
- Database integrity checks are being performed and corruption does not exist
- Disk space is not about to run out
- All enabled jobs have succeeded

Custom checks can be written to cover other aspects of database and server configuration.

## Prerequisites

In order to be able to connect to SQL servers that are part of a Failover Cluster, the host where the monitoring solution resides must meet the following prerequisites:

```powershell
$servicesToInstall = @(
    'RSAT-AD-PowerShell',
    'Failover-Clustering'
)

$servicesToInstall | ForEach-Object {
    $isInstalled = Get-WindowsFeature -Name $_
    if (!($isInstalled)) {
        ":: Installing $_"
        Install-WindowsFeature -Name $_ -IncludeManagementTools -IncludeAllSubFeature
    }
}
```

## Tools

The tools used for the solution consist of the following PowerShell modules:

- dbachecks
- dbatools
- Pester
- PSFramework

These tools are free to use under the MIT license.

```powershell
$modules = @(
    'dbatools',
    'dbachecks',
    'Pester',
    'PSFramework'
)

$modules | ForEach-Object {
    $isInstalled = Get-Module $_ -ListAvailable | Sort-Object Version -Descending | Select-Object -Last 1
    if (!($isInstalled)) {
        Write-Output ":: Installing module $_"
        Install-Module -Name $_
    }
}
```

## Configuration

The configuration can be very flexible and can be done via config files or via parameters in a PowerShell script:

```powershell
# Computer Names
$sqlNodes = @(
    'SERVER01',
    'SERVER02',
    'SERVER03'
)

# SQL Instances (you can use custom TCP ports)
$sqlInstances = @(
    'SERVER01',
    'SERVER02',
    'SERVER03'
)

$saUser = 'sa'
$dbaDatabase = 'DBA'

$dbaOperatorEmail = 'operator@email.local'
$dbaOperatorName = 'TheDBATeam'
$mailProfile = 'DBA'

$clusterName = 'WFCluster'
$domainName = 'domain.local'

$myChecks = "$HOME\Documents\dbachecks"
$myCustomChecks = "$myChecks\CustomChecks"
$myChecksReport = "$myChecks\Report"
```

## Default parameters/policies

dbacheck – default parameters can be set via the global configuration:

```powershell
# Resets configuration entries to their default values
Reset-DbcConfig

# The computername we will be testing
Set-DbcConfig -Name app.computername -Value $sqlNodes

# The Instances we want to test
Set-DbcConfig -Name app.sqlinstance -Value $sqlInstances

if (Get-ChildItem -Path $myCustomChecks -Filter '\*.ps1') {
    Set-DbcConfig -Name app.checkrepos -Value $myCustomChecks -Append
}

# Report files location
Set-DbcConfig -Name app.maildirectory -Value $myChecksReport
#Set-DbcConfig -Name app.localapp -Value $myChecksReport

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

# The number of days prior to check for error log issues - default 2
Set-DbcConfig -Name agent.failedjob.since -Value 3

# The cluster for the HADR tests
Set-DbcConfig -Name app.cluster -Value $clusterName

# The database owner we expect
Set-DbcConfig -Name policy.validdbowner.name -Value $saUser

# the database owner we do NOT expect
Set-DbcConfig -Name policy.invaliddbowner.name -Value $saUser

# Should backups be compressed by default?
Set-DbcConfig -Name policy.backup.defaultbackupcompression -Value $true

# Do we allow DAC connections?
Set-DbcConfig -Name policy.dacallowed -Value $true

# What recovery model should we have?
Set-DbcConfig -Name policy.recoverymodel.type -value FULL

# What should our database growth type be?
Set-DbcConfig -Name policy.database.filegrowthtype -Value kb

# What authentication scheme are we expecting?
Set-DbcConfig -Name policy.connection.authscheme -Value 'Kerberos'

# Which Agent Operator should be defined?
Set-DbcConfig -Name agent.dbaoperatorname -Value $dbaOperatorName

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
Set-DbcConfig -Name policy.recoverymodel.excludedb -Value 'master', 'msdb', 'tempdb'

# What is my SQL Credential
Set-DbcConfig -Name app.sqlcredential -Value $null

# Should I skip the check for temp files on c?
Set-DbcConfig -Name skip.tempdbfilesonc -Value $true

# Should I skip the check for temp files count?
Set-DbcConfig -Name skip.tempdbfilecount -Value $true

# Which Checks should be excluded?
Set-DbcConfig -Name command.invokedbccheck.excludecheck -Value LogShipping, ExtendedEvent, PseudoSimple

# How many months before a build is unsupported do I want to fail the test?
Set-DbcConfig -Name policy.build.warningwindow -Value 6

# Adhoc Distributed Queries
Set-DbcConfig -Name policy.security.adhocdistributedqueriesenabled -Value $true
```

The full list of configuration options can be viewed using the following commands:

```powershell
# Take a peak at the config
Get-Dbcconfig | Out-GridView

# Search for a specific config
Get-DbcConfig *mail*
```

Once a custom configuration has been set, it can be exported/imported as needed:

```powershell
Export-DbcConfig -Path $myChecks\PROD.json
Import-DbcConfig -Path $myChecks\PROD.json
```

It is recommended that an export is kept with the result files, for documentation and history tracking.

## Usage

The invocation of the tool consists in running a PowerShell script or individual commands.
The following example illustrates how the results can be saved into individual files, one per each tested SQL instance:

```powershell
$tagsFile = "$myChecks\tags.txt"
if (!(Test-Path -Path $tagsFile)) {
    New-Item -Path $tagsFile -ItemType File | Out-Null
    $tagsFileContent | Set-Content -Path $tagsFile
}

$tags = @(Get-Content -Path $tagsFile | Select-String '^[^#]')

foreach ($sqlInstance in $sqlInstances) {
    $fileName = "${sqlInstance}" + '.xml'
    $fileName = $fileName.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $fileName = "${outputDirectory}\${fileName}"
    Invoke-DbcCheck -SqlInstance $sqlInstance -Tags $tags -Show Summary -OutputFile $fileName -OutputFormat NunitXML
}

$modulePath = (Get-Module -Name dbachecks).ModuleBase
$reportunit = "$modulePath\bin\ReportUnit.exe"
& $reportunit $outputDirectory
```

Results can be sent via email. A common configuration looks like this:

```powershell
$htmlbody = Get-Content -Path $outputpath -ErrorAction SilentlyContinue | Out-String

$from = "nobody@dbachecks.local"
$to = "dbateam@yourdomain.com"
$smtpServer = smtp.ad.local
Send-MailMessage -To $to -From $from -SMTP $smtpServer -BodyAsHtml $htmlbody
```

The results can also be saved in a database:

```powershell
$sqlInstance = "sql2017"
Invoke-DbcCheck -SqlInstance $sqlInstance -Check AutoClose -Passthru | `
    Convert-DbcResult -Label DBACheck | `
    Write-DbcTable -SqlInstance $sqlInstance -Database DBA -Table dbachecks
```

## Resources

- https://dbachecks.readthedocs.io/
- https://dbatools.io/commands/
- https://pester.dev/
- https://github.com/pester/Pester
