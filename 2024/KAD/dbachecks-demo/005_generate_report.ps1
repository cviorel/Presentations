<#
.SYNOPSIS
This script generates a report using dbachecks module and opens the report in the default browser.

.DESCRIPTION
The script performs the following steps:
1. Removes any existing HTML report files in the dbachecks\Report folder.
2. Imports the dbachecks module.
3. Retrieves the module path.
4. Sets the path to the ReportUnit.exe tool.
5. Executes the ReportUnit.exe tool to generate the report.
6. Opens the generated report in the default browser.

.PARAMETER None
This script does not accept any parameters.

.EXAMPLE
.\005_generate_report.ps1
Runs the script to generate and open the dbachecks report.

.NOTES
- This script requires the dbachecks module to be installed.
- The generated report will be saved in the dbachecks\Report folder.
- The default browser will be used to open the generated report.
#>

if ($IsLinux) {
    Write-Output "This script is not supported on Linux."
    return
}
else {
    Remove-Item .\dbachecks\Report\*.html -Force -ErrorAction SilentlyContinue

    Import-Module -Name dbachecks -Force
    $modulePath = (Get-Module -Name dbachecks).ModuleBase
    $reportunit = "$modulePath\bin\ReportUnit.exe"
    & $reportunit .\dbachecks\Report\
    Invoke-Item .\dbachecks\Report\Index.html
}
