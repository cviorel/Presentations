<#
.SYNOPSIS
Sets the credentials for the sa and sqladmin accounts.

.DESCRIPTION
This script checks if the secrets for the sa and sqladmin accounts are already set. If not, it sets the secrets using the values from the specified secret files. Then, it retrieves the credentials for the sa account and assigns them to the $credential variable.

.PARAMETER sa_password
The path to the secret file containing the password for the sa account.

.EXAMPLE
./002_set_credentials.ps1 -sa_password "/run/secrets/sa_password"
#>

if ($null -eq (Get-Secret -Name sa -ErrorAction SilentlyContinue)) {
    Set-Secret -Name sa -Secret $(Get-Content /run/secrets/sa_password)
}

if ($null -eq (Get-Secret -Name sqladmin -ErrorAction SilentlyContinue)) {
    Set-Secret -Name sqladmin -Secret $(Get-Content /run/secrets/sa_password)
}

if (-not $credential) {
    $credential = Get-SaCredential -SecretName sa
}
