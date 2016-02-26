$Nodes = "TCLSTOR12","TCLSTOR11"
$StoragePool = "Pool01"
$vDisk = "vDisk01"
$vDisk2 = "vDisk02"

foreach ($Node in $Nodes) { 
Install-WindowsFeature –Name File-Services –IncludeManagementTools -ComputerName $Node -verbose 
Install-WindowsFeature –Name Storage-Replica,Multipath-IO,FS-FileServer –IncludeManagementTools -ComputerName $Node -verbose -restart
}

<#
# CleanUp 
foreach ($Node in $Nodes) { 
    Invoke-Command -ComputerName $Nodes -ScriptBlock { 
        Get-SRGroup | Remove-SRGroup -Force
        Get-VirtualDisk | Remove-VirtualDisk -Confirm:$false
        Get-StoragePool | where IsPrimordial -EQ $false | Remove-StoragePool -Confirm:$false
        Get-PhysicalDisk -CanPool $True | Reset-PhysicalDisk -Confirm:$false
        Clear-SRMetadata -AllPartitions -Confirm:$false
        Clear-SRMetadata -AllLogs -Force -Confirm:$false
        Clear-SRMetadata -AllConfiguration -Confirm:$false
        Get-Disk | where IsSystem -EQ $false | Clear-Disk -RemoveData -Confirm:$false
    }
}
#>


# Build Pool and Disks
foreach ($Node in $Nodes) { 
    Invoke-Command -ComputerName $Nodes -ScriptBlock { 
        Get-StoragePool -IsPrimordial $true | Get-PhysicalDisk | Where-Object CanPool -eq $True
        New-StoragePool –FriendlyName StoragePool1 –StorageSubsystemFriendlyName “Windows Storage*” –PhysicalDisks (Get-PhysicalDisk –CanPool $True)
        New-VirtualDisk -StoragePoolFriendlyName StoragePool1 -FriendlyName VirtualDisk1 -ResiliencySettingName Mirror -NumberOfDataCopies 2 -Size 20GB -ProvisioningType Fixed
        New-VirtualDisk -StoragePoolFriendlyName StoragePool1 -FriendlyName VirtualDisk2 -ResiliencySettingName Mirror -NumberOfDataCopies 2 -Size 20GB -ProvisioningType Fixed
        New-VirtualDisk -StoragePoolFriendlyName StoragePool1 -FriendlyName VirtualDisk3 -ResiliencySettingName Mirror -NumberOfDataCopies 2 -Size 20GB -ProvisioningType Fixed
        New-VirtualDisk -StoragePoolFriendlyName StoragePool1 -FriendlyName VirtualDisk4 -ResiliencySettingName Mirror -NumberOfDataCopies 2 -Size 20GB -ProvisioningType Fixed
        Get-VirtualDisk –FriendlyName VirtualDisk1 | Get-Disk | Initialize-Disk –Passthru | New-Partition -DriveLetter F –UseMaximumSize | Format-Volume -NewFileSystemLabel Data
        Get-VirtualDisk –FriendlyName VirtualDisk2 | Get-Disk | Initialize-Disk –Passthru | New-Partition -DriveLetter G –UseMaximumSize | Format-Volume -NewFileSystemLabel Log
        Get-VirtualDisk –FriendlyName VirtualDisk3 | Get-Disk | Initialize-Disk –Passthru | New-Partition -DriveLetter H –UseMaximumSize | Format-Volume -NewFileSystemLabel Data
        Get-VirtualDisk –FriendlyName VirtualDisk4 | Get-Disk | Initialize-Disk –Passthru | New-Partition -DriveLetter I –UseMaximumSize | Format-Volume -NewFileSystemLabel Log
        md C:\Temp
    }
}

<#
    You must create two volumes on each enclosure: one for data and one for logs.
    Log and data disks must be initialized as GPT, not MBR.

    The two data volumes must be of identical size.
    The two log volumes should be of identical size.

    All replicated data disks must have the same sector sizes.
    All log disks must have the same sector sizes.

    The log volumes should use flash-based storage, such as SSD.
    The data disks can use HDD, SSD, or a tiered combination and can use either mirrored or parity spaces or RAID 1 or 10, or RAID 5 or RAID 50.
    The data volume should be no larger than 10TB (for a first test, we recommend no more than 1TB, in order to lower initial replication sync times).
    The log volume must be at least 8GB and may need to be larger based on log requirements.
#>

Test-SRTopology -SourceComputerName $Nodes[1] -SourceVolumeNames f: -SourceLogVolumeName g: -DestinationComputerName $Nodes[0] -DestinationVolumeNames f: -DestinationLogVolumeName g: -DurationInMinutes 1 -ResultPath c:\temp 

 
New-SRPartnership -SourceComputerName $Nodes[1] -SourceRGName rg01 -SourceVolumeName f: -SourceLogVolumeName g: -DestinationComputerName $Nodes[0] -DestinationRGName rg02 -DestinationVolumeName f: -DestinationLogVolumeName g: -LogSizeInBytes 8GB -ReplicationMode Asynchronous 

Get-SRGroup
Get-SRPartnership
(Get-SRGroup).replicas


Get-WinEvent -ProviderName Microsoft-Windows-StorageReplica –max 20


Set-SRPartnership -NewSourceComputerName $Nodes[0] -SourceRGName rg02 -DestinationComputerName $Nodes[1] -DestinationRGName rg01 -Force

Get-SRGroup 
Get-SRPartnership
(Get-SRGroup).replicas

Set-SRPartnership -NewSourceComputerName $Nodes[1] -SourceRGName rg01 -DestinationComputerName $Nodes[0] -DestinationRGName rg02 -Force


