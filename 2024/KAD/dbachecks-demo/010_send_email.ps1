<#
.SYNOPSIS
Sends an email with the results of a script execution.

.DESCRIPTION
This script sends an email with the contents of a specified file as the HTML body. The email is sent from a specified sender to a specified recipient using an SMTP server.

.PARAMETER outputpath
The path to the file containing the HTML content to be sent as the email body.

.PARAMETER from
The email address of the sender.

.PARAMETER to
The email address of the recipient.

.PARAMETER smtpServer
The SMTP server to be used for sending the email.

.EXAMPLE
Send-EmailWithResults -outputpath "C:\output.html" -from "nobody@dbachecks.local" -to "dbateam@yourdomain.com" -smtpServer "smtp.ad.local"
#>

$htmlbody = Get-Content -Path $outputpath -ErrorAction SilentlyContinue | Out-String

$from = "nobody@dbachecks.local"
$to = "dbateam@yourdomain.com"
$smtpServer = "smtp.ad.local"
Send-MailMessage -To $to -From $from -SMTP $smtpServer -BodyAsHtml $htmlbody
