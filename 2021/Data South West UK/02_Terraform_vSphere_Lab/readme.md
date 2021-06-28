# Deployment

The code in the **_02_Terraform_vSphere_Lab_** folder will deploy (see **_variables.tf_**):

- **_4_** Ubuntu 18.04 VMs:
  - Ubuntu01
  - Ubuntu02
  - Ubuntu03
  - Ubuntu04
- **_1_** Windows 2019 with GUI VM:
  - WinGui01
- **_3_** Windows 2019 Core VMs:
  - WinCore01
  - WinCore02
  - WinCore03

# Path

Use this to add the Terraform execurable to your path:

```powershell
$path = "C:\HashiCorp"
$env:Path = $env:Path + ";" + $path
$userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
[System.Environment]::SetEnvironmentVariable("PATH", $userenv + ";" + $path, "User")
```

# Logging

```powershell
# Terraform log settings
$env:TF_LOG="TRACE"
$env:TF_LOG_PATH="C:\HashiCorp\terraform.txt"
```
