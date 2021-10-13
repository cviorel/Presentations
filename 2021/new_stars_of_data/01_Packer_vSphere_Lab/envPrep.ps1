
. .\Get-Packer.ps1
Get-Packer -LocalPath C:\HashiCorp

$logFile = "$env:TEMP\packer.txt"
if (Test-Path -Path $logFile -ErrorAction SilentlyContinue) {
    Remove-Item -Path $logFile -Force -ErrorAction SilentlyContinue
}

# Packer log settings
$env:PACKER_LOG = 1
$env:PACKER_LOG_PATH = $logFile


$json = Get-Content .\json\vars.json | ConvertFrom-Json

foreach ($x in $json) {
    $env:vsphere_server = $x.vsphere_server
    $env:vsphere_user = $x.vsphere_user
    $env:vsphere_password = $x.vsphere_password
    $env:vsphere_folder = $x.vsphere_folder
    $env:vsphere_compute_cluster = $x.vsphere_compute_cluster
    $env:vsphere_dc_name = $x.vsphere_dc_name
    $env:vsphere_resource_pool = $x.vsphere_resource_pool
    $env:vsphere_host = $x.vsphere_host
    $env:vsphere_portgroup_name = $x.vsphere_portgroup_name
    $env:vsphere_datastore = $x.vsphere_datastore
    $env:windows_admin_password = $x.windows_admin_password
    $env:linux_admin_password = $x.linux_admin_password
}
