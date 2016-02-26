#Build VMs

New-Item -Path C:\Setup\VHDs -ItemType Directory -Force
C:\Setup\Scripts\Convert-WIM2VHD.ps1 -SourceFile C:\Setup\OS\RWS2012R2X64STD\RWS2012R2X64STD.wim -DestinationFile C:\Setup\VHDs\WS2012R2_G2.vhdx -Disklayout UEFI -Index 1 -SizeInMB 100000 -Verbose
C:\Setup\Scripts\Convert-WIM2VHD.ps1 -SourceFile C:\Setup\OS\RWS2016D-001\RWS2016D-001.wim -DestinationFile C:\Setup\VHDs\WS2016_G2.vhdx -Disklayout UEFI -Index 1 -SizeInMB 100000 -Verbose

#Create Shared Folder
New-Item -Path C:\SharedVHD -ItemType Directory
New-SmbShare -FullAccess Everyone -Path c:\SharedVHD -Name SharedVHD

$RefWS2016 = "WS2016_G2.vhdx"
$RefWS2012R2 = "WS2012R2_G2.vhdx"

Function Create-VIAVM2016{
    Param
    (
        $Name,$VHDBase,$IP
    )
    $Server = $Name
    C:\Setup\Scripts\New-VIAVM.ps1 -VMName $Server -VMMem 2GB -VMvCPU 2 -VMLocation C:\VMs -VHDFile "C:\Setup\VHDs\$VHDBase" -DiskMode Diff -VMSwitchName UplinkSwitch -VMGeneration 2 –Verbose
    C:\Setup\Scripts\New-VIAUnattendXML.ps1 -Computername $Server -OSDAdapter0IPAddressList $IP -DomainOrWorkGroup Domain -ProductKey '2KNJJ-33Y9H-2GXGX-KMQWH-G6H67'
    $VHD = Mount-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\$VHDBase" –Passthru
    $DriveLetter = ($VHD | Get-Disk | Get-Partition | Where Type -EQ Basic).DriveLetter
    New-Item "$($DriveLetter):\Windows\Panther" -ItemType Directory –Force
    Copy-Item .\Unattend.xml "$($DriveLetter):\Windows\Panther\Unattend.xml" –Force
    Dismount-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\$VHDBase"
}
Function Create-VIAVM2012R2{
    Param
    (
        $Name,$VHDBase,$IP
    )
    $Server = $Name
    C:\Setup\Scripts\New-VIAVM.ps1 -VMName $Server -VMMem 2GB -VMvCPU 2 -VMLocation C:\VMs -VHDFile "C:\Setup\VHDs\$VHDBase" -DiskMode Diff -VMSwitchName UplinkSwitch -VMGeneration 2 –Verbose
    C:\Setup\Scripts\New-VIAUnattendXML.ps1 -Computername $Server -OSDAdapter0IPAddressList $IP -DomainOrWorkGroup Domain
    $VHD = Mount-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\$VHDBase" –Passthru
    $DriveLetter = ($VHD | Get-Disk | Get-Partition | Where Type -EQ Basic).DriveLetter
    New-Item "$($DriveLetter):\Windows\Panther" -ItemType Directory –Force
    Copy-Item .\Unattend.xml "$($DriveLetter):\Windows\Panther\Unattend.xml" –Force
    Dismount-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\$VHDBase"
}


#Build
# TCLSTOR11		Storage Replication
# TCLSTOR12		Storage Replication
$Servers =  "TCLSTOR11","TCLSTOR12"
foreach($Server in $Servers){
    Create-VIAVM2016 -Name $Server -VHDBase $RefWS2016 -IP "DHCP"
}
foreach($Server in $Servers){
    Set-VMMemory -VMName $Server -DynamicMemoryEnabled $true
}
$Roles = "Storage-Replica","FailOver-Clustering"
foreach($Server in $Servers){
    $OSVHD = Get-VMHardDiskDrive -VM $(Get-VM -Name $Server)
    Add-WindowsFeature -Name $Roles -IncludeAllSubFeature -IncludeManagementTools -Vhd $OSVHD.Path
}
Foreach($Server in $Servers){
    $VM = Get-VM -Name $Server
    1..4|%{New-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\datadisk0$_.vhdx" -SizeBytes 100GB
    Add-VMHardDiskDrive -VM $VM -Path "C:\VMs\$Server\Virtual Hard Disks\datadisk0$_.vhdx"
    }
}
foreach($Server in $Servers){
    Start-VM -Name $Server
}
foreach($Server in $Servers){
    Do{}until((Test-NetConnection -ComputerName $Server -CommonTCPPort RDP).TcpTestSucceeded) 
}

foreach($Server in $Servers){
    Stop-VM -Name $Server
    Start-VM -Name $Server
}


# TCLSTOR21			
# TCLSTOR22			
# TCLSTOR23			
# TCLSTOR20			Storage Replica Cluster 1
$Servers =  "TCLSTOR21","TCLSTOR22","TCLSTOR23"
$Cluster = "TCLSTOR20"
foreach($Server in $Servers){
    Create-VIAVM2016 -Name $Server -VHDBase $RefWS2016 -IP "DHCP"
}
foreach($Server in $Servers){
    Set-VMMemory -VMName $Server -DynamicMemoryEnabled $true
}
$Roles = "Storage-Replica","FailOver-Clustering"
foreach($Server in $Servers){
    $OSVHD = Get-VMHardDiskDrive -VM $(Get-VM -Name $Server)
    Add-WindowsFeature -Name $Roles -IncludeAllSubFeature -IncludeManagementTools -Vhd $OSVHD.Path
}
1..4|%{New-VHD -Path "\\$env:COMPUTERNAME\SharedVHD\$Cluster\datadisk0$_.vhds" -SizeBytes 100GB}
$SharedDisks = Get-ChildItem -Path "\\$env:COMPUTERNAME\SharedVHD\$Cluster" -Filter *.vhds
Foreach($SharedDisk in $SharedDisks){
    Foreach($Server in $Servers){
        $VM = Get-VM -Name $Server
        Add-VMHardDiskDrive -VM $VM -Path $SharedDisk.fullname -SupportPersistentReservations
    }
}

foreach($Server in $Servers){
    Start-VM -Name $Server
}

Start-Sleep 240

foreach($Server in $Servers){
    Do{}until((Test-NetConnection -ComputerName $Server -CommonTCPPort RDP).TcpTestSucceeded) 
}
foreach($Server in $Servers){
    Stop-VM -Name $Server
    Start-VM -Name $Server
}

# TCLSTOR31			
# TCLSTOR32			
# TCLSTOR33			
# TCLSTOR30			Storage Replica Cluster 2
$Servers =  "TCLSTOR31","TCLSTOR32","TCLSTOR33"
$Cluster = "TCLSTOR30"
foreach($Server in $Servers){
    Create-VIAVM2016 -Name $Server -VHDBase $RefWS2016 -IP "DHCP"
}
foreach($Server in $Servers){
    Set-VMMemory -VMName $Server -DynamicMemoryEnabled $true
}
$Roles = "Storage-Replica","FailOver-Clustering"
foreach($Server in $Servers){
    $OSVHD = Get-VMHardDiskDrive -VM $(Get-VM -Name $Server)
    Add-WindowsFeature -Name $Roles -IncludeAllSubFeature -IncludeManagementTools -Vhd $OSVHD.Path
}
1..4|%{New-VHD -Path "\\$env:COMPUTERNAME\SharedVHD\$Cluster\datadisk0$_.vhds" -SizeBytes 100GB}
$SharedDisks = Get-ChildItem -Path "\\$env:COMPUTERNAME\SharedVHD\$Cluster" -Filter *.vhds
Foreach($SharedDisk in $SharedDisks){
    Foreach($Server in $Servers){
        $VM = Get-VM -Name $Server
        Add-VMHardDiskDrive -VM $VM -Path $SharedDisk.fullname -SupportPersistentReservations
    }
}

foreach($Server in $Servers){
    Start-VM -Name $Server
}

Start-Sleep 240

foreach($Server in $Servers){
    Do{}until((Test-NetConnection -ComputerName $Server -CommonTCPPort RDP).TcpTestSucceeded) 
}
foreach($Server in $Servers){
    Stop-VM -Name $Server
    Start-VM -Name $Server
}

#TCLLEGA10			Cluster för 2012 R2
#TCLLEGA11			
#TCLLEGA12			
#TCLLEGA13
$Servers =  "TCLLEGA11","TCLLEGA12","TCLLEGA13"
$Cluster = "TCLLEGA10"
foreach($Server in $Servers){
    Create-VIAVM2012R2 -Name $Server -VHDBase $RefWS2012R2 -IP "DHCP"
}
foreach($Server in $Servers){
    Set-VMMemory -VMName $Server -DynamicMemoryEnabled $true
}

1..4|%{New-VHD -Path "\\$env:COMPUTERNAME\SharedVHD\$Cluster\datadisk0$_.vhds" -SizeBytes 100GB}
$SharedDisks = Get-ChildItem -Path "\\$env:COMPUTERNAME\SharedVHD\$Cluster" -Filter *.vhds
Foreach($SharedDisk in $SharedDisks){
    Foreach($Server in $Servers){
        $VM = Get-VM -Name $Server
        Add-VMHardDiskDrive -VM $VM -Path $SharedDisk.fullname -SupportPersistentReservations
    }
}
foreach($Server in $Servers){
    Start-VM -Name $Server
}
Start-Sleep 240
foreach($Server in $Servers){
    Do{}until((Test-NetConnection -ComputerName $Server -CommonTCPPort WinRM).TcpTestSucceeded) 
}
foreach($Server in $Servers){
    Add-WindowsFeature -Name FS-FileServer,FailOver-Clustering -IncludeAllSubFeature -IncludeManagementTools -ComputerName $Server
}
foreach($Server in $Servers){
    Stop-VM -Name $Server
    Start-VM -Name $Server
}

# TCLSTOR40			Storage Spaces Direct 
# TCLSTOR41			
# TCLSTOR42			
# TCLSTOR43			
# TCLSTOR44			

$Servers =  "TCLSTOR41","TCLSTOR42","TCLSTOR43","TCLSTOR44"
$Cluster = "TCLSTOR40"
foreach($Server in $Servers){
    Create-VIAVM2016 -Name $Server -VHDBase $RefWS2016 -IP "DHCP"
}
foreach($Server in $Servers){
    Set-VMMemory -VMName $Server -DynamicMemoryEnabled $true
}
$Roles = "File-Services","Failover-Clustering","Multipath-IO","FS-FileServer"
foreach($Server in $Servers){
    $OSVHD = Get-VMHardDiskDrive -VM $(Get-VM -Name $Server)
    Add-WindowsFeature -Name $Roles -IncludeAllSubFeature -IncludeManagementTools -Vhd $OSVHD.Path
}
Foreach($Server in $Servers){
    $VM = Get-VM -Name $Server
    1..8|%{New-VHD -Path "C:\VMs\$Server\Virtual Hard Disks\datadisk0$_.vhdx" -SizeBytes 100GB
    Add-VMHardDiskDrive -VM $VM -Path "C:\VMs\$Server\Virtual Hard Disks\datadisk0$_.vhdx"
    }
}
foreach($Server in $Servers){
    Start-VM -Name $Server
}
Start-Sleep 200
foreach($Server in $Servers){
    Do{}until((Test-NetConnection -ComputerName $Server -CommonTCPPort WinRM).TcpTestSucceeded) 
}

foreach($Server in $Servers){
    Stop-VM -Name $Server
    Start-VM -Name $Server
}

#TCLHYPE10			Hyper-V Cluster med GUI 
# TCLHYPE11			
# TCLHYPE12			
# TCLHYPE13			
$Servers =  "TCLHYPE11","TCLHYPE12","TCLHYPE13"
$Cluster = "TCLHYPE10"
foreach($Server in $Servers){
    Create-VIAVM2016 -Name $Server -VHDBase $RefWS2016 -IP "DHCP"
}
$Roles = "Failover-Clustering","Hyper-V"
foreach($Server in $Servers){
    $OSVHD = Get-VMHardDiskDrive -VM $(Get-VM -Name $Server)
    Add-WindowsFeature -Name $Roles -IncludeAllSubFeature -IncludeManagementTools -Vhd $OSVHD.Path
}
foreach($Server in $Servers){
    Get-VM -Name $Server | Set-VMMemory -StartupBytes 4GB
}
Invoke-WebRequest "https://raw.githubusercontent.com/DeploymentBunny/Files/master/Tools/Enable-NestedHyperV/EnableNestedHyperV.ps1" -OutFile ~/EnableNestedHyperV.ps1
Import-Module ~/EnableNestedHyperV.ps1 -Verbose -Global -Force
foreach($Server in $Servers){
    Enable-NestedHyperV -VM $Server
}
foreach($Server in $Servers){
    Start-VM -Name $Server
}
Start-Sleep 200
foreach($Server in $Servers){
    Do{}until((Test-NetConnection -ComputerName $Server -CommonTCPPort RDP).TcpTestSucceeded) 
}
foreach($Server in $Servers){
    Stop-VM -Name $Server
    Start-VM -Name $Server
}


#TCLRDPS11 CB
#TCLRDPS12 RD Session Host för Penna 
#TCLRDPS13 RDS Personal Session Desktops
$Servers =  "TCLRDPS11","TCLRDPS12","TCLRDPS13"
foreach($Server in $Servers){
    Create-VIAVM2016 -Name $Server -VHDBase $RefWS2016 -IP "DHCP"
}
foreach($Server in $Servers){
    Set-VMMemory -VMName $Server -DynamicMemoryEnabled $true
}
foreach($Server in $Servers){
    Start-VM -Name $Server
}

# TCLVM01			Member Server för Defender, Hot Add/Remove Memory/NIC, NIC Teaming
$Servers =  "TCLVM01"
foreach($Server in $Servers){
    Create-VIAVM2016 -Name $Server -VHDBase $RefWS2016 -IP "DHCP"
}
foreach($Server in $Servers){
    Start-VM -Name $Server
}

#TCLNANO10			Nano Server Cluster (Hyper-V)
C:\Setup\Scripts\New-NanoRefImage.ps1
C:\Setup\Scripts\New-NanoVM.ps1

#TCLNATW01			NETNAT WebServer
New-VMSwitch -Name UplinkSwitchNAT2 -SwitchType NAT -NATSubnetAddress '192.168.2.0/24'
New-NetNat -Name UplinkSwitchNAT2 -InternalIPInterfaceAddressPrefix '192.168.2.0/24'
Add-NetNatStaticMapping -NatName UplinkSwitchNAT2 -Protocol TCP -ExternalIPAddress 0.0.0.0 -InternalIPAddress '192.168.2.10' -InternalPort 80 -ExternalPort 80
Get-NetNat
Get-NetNatStaticMapping
Get-NetNatExternalAddress

$Servers =  "TCLNATW01"
foreach($Server in $Servers){
    Create-VIAVM2016 -Name $Server -VHDBase $RefWS2016 -IP "DHCP"
}
foreach($Server in $Servers){
    Start-VM -Name $Server
}



Remove-NetNat -Name GlobalOut

#TCLPROT01			Shielded VM
#TSRVHOST333-WSUS01

#TCLDOCK01			Dockers
$Servers =  "TCLDOCK01"
foreach($Server in $Servers){
    Create-VIAVM2016 -Name $Server -VHDBase $RefWS2016 -IP "DHCP"
}
$Roles = "Containers","Hyper-V"
foreach($Server in $Servers){
    $OSVHD = Get-VMHardDiskDrive -VM $(Get-VM -Name $Server)
    Add-WindowsFeature -Name $Roles -IncludeAllSubFeature -IncludeManagementTools -Vhd $OSVHD.Path
}
foreach($Server in $Servers){
    Get-VM -Name $Server | Set-VMMemory -StartupBytes 4GB
}
Invoke-WebRequest "https://raw.githubusercontent.com/DeploymentBunny/Files/master/Tools/Enable-NestedHyperV/EnableNestedHyperV.ps1" -OutFile ~/EnableNestedHyperV.ps1
Import-Module ~/EnableNestedHyperV.ps1 -Verbose -Global -Force
foreach($Server in $Servers){
    Enable-NestedHyperV -VM $Server
}
foreach($Server in $Servers){
    Start-VM -Name $Server
}
Start-Sleep 200
foreach($Server in $Servers){
    Do{}until((Test-NetConnection -ComputerName $Server -CommonTCPPort WINRM).TcpTestSucceeded) 
}
foreach($Server in $Servers){
    Stop-VM -Name $Server
    Start-VM -Name $Server
}

