<#
.SYNOPSIS
Performs individual tests using the Invoke-DbcCheck cmdlet.

.DESCRIPTION
This script performs individual tests using the Invoke-DbcCheck cmdlet from the dbatools module. It runs multiple checks on SQL instances and displays the results.

.PARAMETER SqlInstance
Specifies the SQL instances on which the tests will be performed.

.PARAMETER SqlCredential
Specifies the credential to use for authenticating with the SQL instances.

.EXAMPLE
Invoke-DbcCheck -SqlInstance $sqlInstances -SqlCredential $credential -Check MaxMemory -Show All -Verbose
Runs the MaxMemory check on the specified SQL instances and displays detailed information.

.EXAMPLE
Invoke-DbcCheck -Check Backup -SqlInstance sql2017
Runs the Backup check on the SQL instance named sql2017.

.EXAMPLE
Invoke-DbcCheck -Check RecoveryModel -SqlInstance sql2019, sql2022
Runs the RecoveryModel check on the SQL instances named sql2019 and sql2022.

.EXAMPLE
Get-DbcCheck -Tag Database
Gets the checks with the specified tag "Database".

.EXAMPLE
Invoke-DbcCheck -Check UnusedIndex -SqlInstance sql2017
Runs the UnusedIndex check on the SQL instance named sql2017.
#>

Invoke-DbcCheck -SqlInstance $sqlInstances -SqlCredential $credential -Check MaxMemory -Show All -Verbose

Invoke-DbcCheck -Check Backup -SqlInstance sql2017

Invoke-DbcCheck -Check RecoveryModel -SqlInstance sql2019, sql2022

Get-DbcCheck -Tag Database

Invoke-DbcCheck -Check UnusedIndex -SqlInstance sql2017
