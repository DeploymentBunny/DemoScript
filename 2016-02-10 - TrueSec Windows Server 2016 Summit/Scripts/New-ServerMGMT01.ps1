$Server = "MGMT01"
$VHDBase = "WS2016_UEFI.vhdx"
C:\Setup\Scripts\New-VIAVM.ps1 -VMName $Server -VMMem 2GB -VMvCPU 2 -VMLocation C:\VMs -VHDFile "C:\setup\VHD\$VHDBase" -DiskMode Diff -VMSwitchName UplinkSwitchNAT -VMGeneration 2 –Verbose
C:\Setup\Scripts\New-VIAUnattendXML.ps1 -Computername $Server -OSDAdapter0IPAddressList DHCP -DomainOrWorkGroup Domain -ProductKey '2KNJJ-33Y9H-2GXGX-KMQWH-G6H67'
$VHD = Mount-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\$VHDBase" –Passthru
$DriveLetter = ($VHD | Get-Disk | Get-Partition | Where Type -EQ Basic).DriveLetter
New-Item "$($DriveLetter):\Windows\Panther" -ItemType Directory –Force
Copy-Item .\Unattend.xml "$($DriveLetter):\Windows\Panther\Unattend.xml" –Force
Dismount-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\$VHDBase"
Get-VM -Name $Server | Set-VMMemory -DynamicMemoryEnabled $true
Get-VM -Name $Server | Start-VM
