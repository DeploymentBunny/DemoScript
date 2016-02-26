$Server = "DC02"
$VHDBase = "WS2016_UEFI.vhdx"
C:\Setup\Scripts\New-VIAVM.ps1 -VMName $Server -VMMem 1GB -VMvCPU 2 -VMLocation C:\VMs -VHDFile "C:\setup\VHD\$VHDBase" -DiskMode Diff -VMSwitchName UplinkSwitchNAT -VMGeneration 2 -Verbose
C:\Setup\Scripts\New-VIAUnattendXML.ps1 -Computername $Server -OSDAdapter0IPAddressList 192.168.1.201 -DomainOrWorkGroup Domain
$VHD = Mount-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\$VHDBase" -Passthru
$DriveLetter = ($VHD | Get-Disk | Get-Partition | Where Type -EQ Basic).DriveLetter
New-Item "$($DriveLetter):\Windows\Panther" -ItemType Directory -Force
Copy-Item .\Unattend.xml "$($DriveLetter):\Windows\Panther\Unattend.xml" -Force
Dismount-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\$VHDBase"
Get-VM -Name $Server | Set-VMMemory -DynamicMemoryEnabled $true
Add-WindowsFeature -Name "AD-Domain-Services","DHCP","DNS" -IncludeAllSubFeature -IncludeManagementTools -Vhd "C:\VMs\DC02\Virtual Hard Disks\$VHDBase"



