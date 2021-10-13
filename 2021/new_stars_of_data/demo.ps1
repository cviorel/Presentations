breaK

Set-Location -Path "C:\Users\Viorel\Documents\GitHub\Presentations\2021\new_stars_of_data"

#region Packer
code .\01_Packer_vSphere_Lab\json\win2019core.json
code .\01_Packer_vSphere_Lab\scripts\win-common\SysPrepWin.ps1
#endregion Packer


#region Terraform
code .\02_Terraform_vSphere_Lab\main.tf
code .\02_Terraform_vSphere_Lab\outputs.tf
code .\02_Terraform_vSphere_Lab\terraform.tfvars
#endregion Terraform


#region DeployLab
code .\03_DeployLab\00_set-variables.ps1
code .\03_DeployLab\06_install-sql.ps1
#endregion DeployLab
