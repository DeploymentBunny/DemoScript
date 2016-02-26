#Build Dockers
Invoke-WebRequest -Uri https://aka.ms/tp4/New-ContainerHost -OutFile C:\Setup\Scripts\New-ContainerHost.ps1
C:\Setup\Scripts\New-ContainerHost.ps1 -VmName TCLDOCK01 -WindowsImage ServerDatacenter -HyperV
