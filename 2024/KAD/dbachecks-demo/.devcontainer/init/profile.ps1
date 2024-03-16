function Get-SaCredential {
    param (
        [string]$SecretName
    )

    $Secret = Get-Secret -Name $SecretName
    $SqlCredential = New-Object System.Management.Automation.PSCredential ($SecretName, $Secret)
    $SqlCredential
}

function Normalize-Path {
    param (
        [string]$Path
    )
    if ( -not [IO.Path]::IsPathRooted($Path) ) {
        $Path = Join-Path -Path (Get-Location).Path -ChildPath $Path
    }
    $Path = Join-Path -Path $Path -ChildPath '.'
    $Path = [IO.Path]::GetFullPath($Path)
    return $Path
}

Set-Alias -Name ll -Value Get-ChildItem

#region Set env
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -Register
Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false -Register
#endregion Set env

# #region Secrets
# # Required modules:
# #    Microsoft.PowerShell.SecretStore
# #    Microsoft.PowerShell.SecretManagement


# if ($null -eq (Get-Secret -Name sa -ErrorAction SilentlyContinue)) {
#     Set-Secret -Name sa -Secret $(Get-Content /run/secrets/sa_password)
# }

# if ($null -eq (Get-Secret -Name sqladmin)) {
#     Set-Secret -Name sqladmin -Secret $(Get-Content /run/secrets/sa_password)
# }


# if (-not $credential) {
#     $credential = Get-SaCredential -SecretName sa
# }

# $PSDefaultParameterValues.Clear()
# if (-not ($PSDefaultParameterValues.'*-Dba*:SqlCredential')) {
#     $PSDefaultParameterValues += @{
#         '*-Dba*:SqlCredential' = $credential
#     }
#     $PSDefaultParameterValues += @{
#         '*-Dbc*:SqlCredential' = $credential
#     }
# }

# $sqlInstances = @(
#     'sql2017',
#     'sql2019',
#     'sql2022'
# )
# #endregion Secrets

oh-my-posh init pwsh --config ~/jandedobbeleer.omp.json | Invoke-Expression
