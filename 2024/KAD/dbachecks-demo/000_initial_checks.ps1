# This test case checks if the Docker process is running
# Run it outside of the container

# Invoke-Pester -Script .\000_initial_checks.ps1

Describe "Docker Process" {
    It "Should be running" {
        $dockerProcess = Get-Process -Name "docker" -ErrorAction SilentlyContinue
        $dockerProcess | Should -Not -Be $null
    }
}

Describe "Testing for Demo" {
    Context "PowerShell" {
        $modules = 'dbachecks', 'dbatools', 'Pester'
        $modules.ForEach{
            It "Module $Psitem should be available" {
                Get-Module $Psitem -ListAvailable | Should -Not -BeNullOrEmpty
            }
        }
    }
}
