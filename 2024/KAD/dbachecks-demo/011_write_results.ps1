<#
.SYNOPSIS
    Runs tests and writes the results to a database table.

.DESCRIPTION
    This section of the script runs tests using the Invoke-DbcCheck cmdlet and writes the results to a database table. The tests are performed on the SQL instance specified by the $sqlInstance variable. The results are converted into a format suitable for writing to the table using the Convert-DbcResult cmdlet. The table used for storing the results is specified by the -Table parameter of the Write-DbcTable cmdlet.

.PARAMETER sqlInstance
    Specifies the SQL instance on which the tests will be performed and the results will be written.

.INPUTS
    None.

.OUTPUTS
    None.

.EXAMPLE
    # Run tests and write results to the "dbachecks" table in the "DBA" database on the "ReportingSQLInstance" SQL instance
    $sqlInstance = "ReportingSQLInstance"
    Invoke-DbcCheck -SqlInstance $sqlInstance -Check AutoClose -PassThru | `
        Convert-DbcResult -Label DBACheck | `
        Write-DbcTable -SqlInstance $sqlInstance -Database DBA -Table dbachecks

#>

$sqlInstance = "ReportingSQLInstance"
Invoke-DbcCheck -SqlInstance $sqlInstance -Check AutoClose -PassThru | `
    Convert-DbcResult -Label DBACheck | `
    Write-DbcTable -SqlInstance $sqlInstance -Database DBA -Table dbachecks
