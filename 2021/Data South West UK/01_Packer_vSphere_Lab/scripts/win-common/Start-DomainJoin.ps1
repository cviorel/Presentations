<#

.FUNCTIONALITY
1 - This script used with the packer.io
2 - It's called from line 14 of the related autounattend.xml
3 - When first run, it copies itself over from the mounted a:\ drive and creates a shortcut on the desktop of the current user
4 - When called a second time, it prompts to join AD, and removes the shortcut (.LNK) created in step 3

.SYNOPSIS
Change log

July 25, 2020
 -Initial version

July 26, 2020
 -Various edits to cover script copy/LNK creation before code that actually prompts for domain join

Aug 6, 2020
 -Updated to pull domain name from $Cred

Aug 7, 2020
 -Added IF statement to cover $Cred entered in user@domain format or domain\username

Aug 15, 2020
 -Added exit statement when not started as elevated

Sept 23, 2020
-Janky code to create .lnk with "run as admin"

.DESCRIPTION
Author oreynolds@gmail.com

.EXAMPLE
./Start-DomainJoin.ps1

.NOTES

.Link
https://github.com/getvpro/Build-Packer

#>

Add-Type -AssemblyName System.Windows.Forms

$OS = (Get-WMIObject -class win32_operatingsystem).Caption

$text = "The $OS build has now completed.`
`
Do you want to join the computer to the domain ?"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Powershell was not started as an elevated session, script will now exit!"
    Exit
}

if (-not(Test-Path C:\Scripts)) {
    New-Item -ItemType Directory "C:\Scripts"
}

if (-not(Test-Path "C:\Scripts\Start-DomainJoin.ps1" -ErrorAction SilentlyContinue)) {

    Copy-Item a:\Start-DomainJoin.ps1 C:\Scripts -Force -ErrorAction SilentlyContinue

    ### Shortcut creation

    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\Join Active Directory.lnk")
    $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Start-DomainJoin.ps1"'
    $Shortcut.IconLocation = ",0"
    $Shortcut.WindowStyle = 1 #Minimized
    $Shortcut.WorkingDirectory = "C:\Scripts"
    $Shortcut.Description = "Join Active Directory"
    $Shortcut.Save()

    $bytes = [System.IO.File]::ReadAllBytes("$Home\Desktop\Join Active Directory.lnk")
    $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
    [System.IO.File]::WriteAllBytes("$Home\Desktop\Join Active Directory.lnk", $bytes)

    Write-Host "`r`n"
    Write-Host "$Home\Desktop\Start-DomainJoin.ps1 created" -ForegroundColor Cyan
    Write-Host "`r`n"
    Write-Host "The script will now exit, the Start-DomainJoin.ps1 script can be called when the build has completed" -ForegroundColor Cyan
    Start-Sleep -Seconds 3
    Exit
}

if (Test-Path C:\Scripts\Start-DomainJoin.ps1) {

    $UserResponse = [System.Windows.Forms.MessageBox]::Show($Text, "Domain Join" , 4, 32)

    if ($UserResponse -eq "Yes") {
        Write-Host "You will prompted for valid domain credentials to join the computer to the domain" -ForegroundColor Cyan
        $Cred = Get-Credential

        if ($cred.username -like "*@*") {
            $DomainToJoin = $Cred.UserName.Split("@")[1]
        }
        else {
            $DomainToJoin = $Cred.UserName.Split("\")[0]
        }

        Add-Computer -Credential $Cred -DomainName $DomainToJoin
        Remove-Item "$Home\Desktop\Join Active Directory.lnk" -Force
    }

}
