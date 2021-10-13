
. .\Get-Terraform.ps1

Get-Terraform -LocalPath C:\HashiCorp

$logFile = "$env:TEMP\terraform.txt"
if (Test-Path -Path $logFile -ErrorAction SilentlyContinue) {
    Remove-Item -Path $logFile -Force -ErrorAction SilentlyContinue
}

# Terraform log settings
$env:TF_LOG = "TRACE" # Valid options are: TRACE, DEBUG, INFO, WARN, ERROR
$env:TF_LOG_PATH = $logFile
