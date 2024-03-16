<#
.SYNOPSIS
This script is used to run tests on SQL instances using dbachecks module.

.DESCRIPTION
The script performs the following tasks:
1. Removes all files in the specified output directory.
2. Checks if the tags file exists, and creates it if it doesn't.
3. Reads the tags from the tags file.
4. Retrieves the SQL credential if not provided.
5. Runs tests for each SQL instance using the specified tags.
6. Generates an XML output file for each SQL instance.

.PARAMETER outputDirectory
The directory where the output files will be stored.

.PARAMETER credential
The SQL credential to use for authentication.

.PARAMETER sqlInstances
The list of SQL instances to run tests on.

.PARAMETER tagsFile
The path to the file containing the tags to be tested.

.EXAMPLE
.\004_run_tests.ps1 -outputDirectory "C:\Output" -credential $credential -sqlInstances "sql2017", "sql2019" -tagsFile "C:\Tags\tags.txt"
Runs tests on the specified SQL instances using the tags defined in the tags file. The output files will be stored in the specified output directory.

.NOTES
- This script requires the dbachecks module to be installed.
- The tags file should be in the following format:
    #
    # Use Get-DbcTagCollection to see the available ones
    #
    # Comment out with # the entries that you don't want to be tested
    #
    #----------------------------------------------------------------
    Tag1
    Tag2
    Tag3
    ...
#>

#region Run Tests
$outputDirectory = (Get-DbcConfigValue -Name app.maildirectory)
Remove-Item -Path "$($outputDirectory)\*" -Recurse -Force

$tagsFileContent = @'
#
# Use Get-DbcTagCollection to see the available ones
#
# Comment out with # the entries that you don't want to be tested
#
#----------------------------------------------------------------
'@

$tagsFile = Normalize-Path -Path "$myChecks\tags.txt"
if (!(Test-Path -Path $tagsFile)) {
    New-Item -Path $tagsFile -ItemType File | Out-Null
    $tagsFileContent | Set-Content -Path $tagsFile
}

$tags = @(Get-Content -Path $tagsFile | Select-String '^[^#]')

if (-not $credential) {
    $credential = Get-SaCredential -SecretName sa
}

if ($tags) {
    foreach ($sqlInstance in $sqlInstances) {
        Write-Output ":: Running tests for $sqlInstance"
        $fileName = "${sqlInstance}.xml"
        $fileName = $fileName.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $fileName = Normalize-Path -Path "${outputDirectory}\${fileName}"
        Invoke-DbcCheck -SqlInstance $sqlInstance -SqlCredential $credential -Tags $tags -Show Summary -OutputFile $fileName -OutputFormat NunitXML
    }
} `
    else {
    Write-Warning ":: No tags found in $tagsFile"
}

#endregion Run Tests
