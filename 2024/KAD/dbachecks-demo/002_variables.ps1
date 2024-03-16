<#
.SYNOPSIS
This script sets default parameter values for SQL Server commands and defines an array of SQL instances.

.DESCRIPTION
The script checks if the default parameter values for SQL credentials are already set. If not, it adds the specified SQL credential to the default parameter values for commands that match the patterns '*-Dba*:SqlCredential' and '*-Dbc*:SqlCredential'.

The script also defines an array of SQL instances that includes 'sql2017', 'sql2019', and 'sql2022'.

.PARAMETER credential
The SQL credential to be used for authentication.

.NOTES
Author: Viorel Ciucu
Version: 1.0

.EXAMPLE
.\001_variables.ps1 -credential $myCredential
#>

if (-not ($PSDefaultParameterValues.'*-Dba*:SqlCredential')) {
    $PSDefaultParameterValues += @{
        '*-Dba*:SqlCredential' = $credential
    }
    $PSDefaultParameterValues += @{
        '*-Dbc*:SqlCredential' = $credential
    }
}

$sqlInstances = @(
    'sql2017',
    'sql2019',
    'sql2022'
)
