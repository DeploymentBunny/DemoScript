$CMPs = "ST01","ST02","ST03","ST04"
$VHDBase = "WS2016_UEFI.vhdx"
$MountFolder = "C:\MountVHD"

Foreach($CMP in $CMPs){
    C:\Setup\Scripts\New-VIAVM.ps1 -VMName $CMP -VMMem 4GB -VMvCPU 2 -VMLocation C:\VMs -VHDFile C:\setup\VHD\$VHDBase -DiskMode Diff -VMSwitchName UplinkSwitchNAT -VMGeneration 2
    C:\Setup\Scripts\New-VIAUnattendXML.ps1 -Computername $CMP -OSDAdapter0IPAddressList DHCP -DomainOrWorkGroup Domain -ProductKey '2KNJJ-33Y9H-2GXGX-KMQWH-G6H67'
    $VHD = Mount-VHD -Path "C:\VMs\$CMP\Virtual Hard Disks\$VHDBase" -Passthru -NoDriveLetter
    $MountVHD = New-Item -Path $MountFolder -ItemType Directory -Force
    Add-PartitionAccessPath -DiskNumber $VHD.DiskNumber -PartitionNumber 4 -AccessPath $($MountVHD.FullName)
    New-Item "$($MountVHD.FullName)\Windows\Panther" -ItemType Directory -Force
    Copy-Item .\Unattend.xml "C:\MountVHD\Windows\Panther\Unattend.xml" -Force
    Remove-PartitionAccessPath -DiskNumber $VHD.DiskNumber -PartitionNumber 4 -AccessPath $($MountVHD.FullName)
    Dismount-VHD -Path "C:\VMs\$CMP\Virtual Hard Disks\$VHDBase"
    Remove-Item -Path $($MountVHD.FullName) -Force
}

Foreach($CMP in $CMPs){
    $VM = Get-VM -Name $CMP
    1..8|%{
        New-VHD -Path "C:\VMs\$CMP\Virtual Hard Disks\datadisk0$_.vhdx" -SizeBytes 100GB
        Add-VMHardDiskDrive -VM $VM -Path "C:\VMs\$CMP\Virtual Hard Disks\datadisk0$_.vhdx"
    }
}

Get-VM -Name ST* | Start-VM
