$CMPs = "ST01","ST02","ST03","ST04"
Foreach($CMP in $CMPs){
    C:\Scripts\New-VirtualMachine.ps1 -VMName $CMP -VMMem 4GB -VMvCPU 2 -VMLocation C:\VMs -VHDFile C:\REF\RWS2016_UEFI.vhdx -DiskMode Diff -VMSwitchName UplinkSwitch -VlanID 2021 -VMGeneration 2
    C:\Scripts\New-UnattendXML.ps1 -Computername $CMP -OSDAdapter0IPAddressList DHCP -DomainOrWorkGroup Domain
    $VHD = Mount-VHD -Path "C:\VMs\$CMP\Virtual Hard Disks\RWS2016_UEFI.vhdx" -Passthru -NoDriveLetter
    New-Item -Path C:\MountVHD -ItemType Directory -Force
    Add-PartitionAccessPath -DiskNumber $VHD.DiskNumber -PartitionNumber 4 -AccessPath C:\MountVHD
    New-Item "C:\MountVHD\Windows\Panther" -ItemType Directory -Force
    Copy-Item .\Unattend.xml "C:\MountVHD\Windows\Panther\Unattend.xml" -Force
    Remove-PartitionAccessPath -DiskNumber $VHD.DiskNumber -PartitionNumber 4 -AccessPath C:\MountVHD
    Dismount-VHD -Path "C:\VMs\$CMP\Virtual Hard Disks\RWS2016_UEFI.vhdx"
    Remove-Item -Path C:\MountVHD -Force
}

$CMPs = "ST01","ST02","ST03","ST04"
Foreach($CMP in $CMPs){
    $VM = Get-VM -Name $CMP
    Set-VMMemory -VM $VM -DynamicMemoryEnabled $true
    Set-VM -VM $VM -AutomaticStopAction ShutDown
    Set-VM -VM $VM -AutomaticStartAction Start
    Enable-VMIntegrationService -VM $VM -Name "Guest Service Interface"
}

$CMPs = "ST01","ST02","ST03","ST04"
Foreach($CMP in $CMPs){
    $VM = Get-VM -Name $CMP
    1..8|%{New-VHD -Path "C:\VMs\$CMP\Virtual Hard Disks\datadisk0$_.vhdx" -SizeBytes 100GB
    Add-VMHardDiskDrive -VM $VM -Path "C:\VMs\$CMP\Virtual Hard Disks\datadisk0$_.vhdx"
    }
}

$CMPs = "ST01","ST02","ST03","ST04"
Foreach($CMP in $CMPs){
    Start-VM -Name $CMP    
}

$AdminPassword
$DomainName
$DomainAdminPassword

$localCred = new-object -typename System.Management.Automation.PSCredential `
             -argumentlist "Administrator", (ConvertTo-SecureString $adminPassword -AsPlainText -Force)

$domainCred = new-object -typename System.Management.Automation.PSCredential `
              -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force)

$CMPs = "ST01","ST02","ST03","ST04"
Foreach($CMP in $CMPs){
    Invoke-Command -VMName $CMP -ScriptBlock{
        Add-WindowsFeature -Name "FS-FileServer","Failover-Clustering" -IncludeAllSubFeature -IncludeManagementTools
        } -Credential $domainCred
}


$CMPs = "ST01","ST02","ST03","ST04"
Foreach($CMP in $CMPs){
    Invoke-Command -VMName $CMP -ScriptBlock{
        net stop w32time
        w32tm /unregister
        w32tm /register
        net start w32time
        } -Credential $domainCred
}


$CMPs = "ST01","ST02","ST03","ST04"
Foreach($CMP in $CMPs){
    Stop-VM -Name $CMP
    Start-VM -Name $CMP
}


