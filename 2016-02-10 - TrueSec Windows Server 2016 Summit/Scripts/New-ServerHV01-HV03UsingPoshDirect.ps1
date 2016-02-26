$CMPs = "HV01","HV02","HV03"
$VHDBase = "WS2016_UEFI.vhdx"
$MountFolder = "C:\MountVHD"
$AdminPassword
$DomainName
$DomainAdminPassword
$localCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "Administrator", (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
$domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force)

Foreach($CMP in $CMPs){
    C:\Setup\Scripts\New-VIAVM.ps1 -VMName $CMP -VMMem 4GB -VMvCPU 2 -VMLocation C:\VMs -VHDFile "C:\Setup\VHD\$VHDBase" -DiskMode Diff -VMSwitchName UplinkSwitchNAT -VMGeneration 2
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

$CMPs = "HV01","HV02","HV03"
Foreach($CMP in $CMPs){
    $VM = Get-VM -Name $CMP
    Set-VMMemory -VM $VM -DynamicMemoryEnabled $false
    Set-VM -VM $VM -AutomaticStopAction ShutDown
    Set-VM -VM $VM -AutomaticStartAction Start
    Enable-VMIntegrationService -VM $VM -Name "Guest Service Interface"
}

Invoke-WebRequest "https://raw.githubusercontent.com/DeploymentBunny/Files/master/Tools/Enable-NestedHyperV/EnableNestedHyperV.ps1" -OutFile ~/EnableNestedHyperV.ps1
Import-Module ~/EnableNestedHyperV.ps1

$CMPs = "HV01","HV02","HV03"
Foreach($CMP in $CMPs){
    Enable-NestedHyperV -VM $CMP
    Start-VM -Name $CMP    
}


$CMPs = "HV01","HV02","HV03"
Foreach($CMP in $CMPs){
    Invoke-Command -VMName $CMP -ScriptBlock{
        Add-WindowsFeature -Name "Hyper-V","Failover-Clustering" -IncludeAllSubFeature -IncludeManagementTools
        } -Credential $domainCred
}


$CMPs = "HV01","HV02","HV03"
Foreach($CMP in $CMPs){
    Invoke-Command -VMName $CMP -ScriptBlock{
        net stop w32time
        w32tm /unregister
        w32tm /register
        net start w32time
        } -Credential $domainCred
}


$CMPs = "HV01","HV02","HV03"
Foreach($CMP in $CMPs){
    Stop-VM -Name $CMP -Passthru | Start-VM 
}
