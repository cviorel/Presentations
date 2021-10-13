# put your post deployment commands here

New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
$env:COMPUTERNAME | Out-File C:\Temp\hostname.txt
$myIp = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -ne "Disconnected" }).IPv4Address.IPAddress
Write-Output ":: Hello from $env:COMPUTERNAME!"
Write-Output ":: My IP address is $myIp"
