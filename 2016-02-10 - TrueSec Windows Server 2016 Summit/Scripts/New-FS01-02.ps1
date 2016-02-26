#Set Variables
$CMPs = "FS01","FS02"
$VHDBase = "WS2016_UEFI.vhdx"
$MountFolder = "C:\MountVHD"

#Build VMs
Foreach($CMP in $CMPs){
    C:\Setup\Scripts\New-VIAVM.ps1 -VMName $CMP -VMMem 2GB -VMvCPU 2 -VMLocation C:\VMs -VHDFile "C:\Setup\VHD\$VHDBase" -DiskMode Diff -VMSwitchName UplinkSwitchNAT -VMGeneration 2
    C:\Setup\Scripts\New-VIAUnattendXML.ps1 -Computername $CMP -OSDAdapter0IPAddressList DHCP -DomainOrWorkGroup Domain -ProductKey '2KNJJ-33Y9H-2GXGX-KMQWH-G6H67'
    $VHD = Mount-VHD -Path "C:\VMs\$CMP\Virtual Hard Disks\$VHDBase" -Passthru -NoDriveLetter
    $MountVHD = New-Item -Path $MountFolder -ItemType Directory -Force
    Add-PartitionAccessPath -DiskNumber $VHD.DiskNumber -PartitionNumber 4 -AccessPath $($MountVHD.FullName)
    New-Item "C:\MountVHD\Windows\Panther" -ItemType Directory -Force
    Copy-Item .\Unattend.xml "C:\MountVHD\Windows\Panther\Unattend.xml" -Force
    Remove-PartitionAccessPath -DiskNumber $VHD.DiskNumber -PartitionNumber 4 -AccessPath $($MountVHD.FullName)
    Dismount-VHD -Path "C:\VMs\$CMP\Virtual Hard Disks\$VHDBase"
    Remove-Item -Path $($MountVHD.FullName) -Force
}

#Add Windows Features (offline)
$CMPs = "FS01","FS02"
Foreach($CMP in $CMPs){
    $VHD = (Get-VM -Name $CMP | Get-VMHardDiskDrive).Path
    Add-WindowsFeature -Name "Storage-Replica","File-Services" -IncludeAllSubFeature -IncludeManagementTools -Vhd $VHD
}

