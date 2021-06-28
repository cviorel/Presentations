. .\envPrep.ps1

C:\HashiCorp\packer.exe validate json\win2019core.json
C:\HashiCorp\packer.exe build -force -var-file='json\vars.json' 'json\win2019core.json'

C:\HashiCorp\packer.exe validate json\win2019gui.json
C:\HashiCorp\packer.exe build -force -var-file='json\vars.json' 'json\win2019gui.json'

C:\HashiCorp\packer.exe validate json\ubuntu18.json
C:\HashiCorp\packer.exe build -force -var-file='json\vars.json' 'json\ubuntu18.json'
