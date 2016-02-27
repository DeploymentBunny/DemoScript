1..12 | % {New-VHD -Path E:\demo\disk$_.VHDX -Dynamic –SizeBytes 400GB}
13..48 | % {New-VHD -Path E:\demo\disk$_.VHDX -Dynamic –SizeBytes 2TB}

$VHDs = Get-ChildItem E:\Demo
foreach ($VHD in $VHDs)
{
    Mount-VHD -Path $VHD.FullName
}

Get-PhysicalDisk -CanPool $true
Get-StorageSubSystem -FriendlyName *Spaces*

$StorageSubSystem = Get-StorageSubSystem -FriendlyName *Spaces*
$PhysicalDisk = Get-PhysicalDisk -CanPool $true
$PoolName = "stpool01"

New-StoragePool -FriendlyName $PoolName -StorageSubSystemFriendlyName $StorageSubSystem.FriendlyName -PhysicalDisks $PhysicalDisk

Get-StoragePool -FriendlyName $PoolName | Get-PhysicalDisk | Where-Object -Property Size -EQ -Value 428691423232 | Set-PhysicalDisk -MediaType SSD #For Demo Only 
Get-StoragePool -FriendlyName $PoolName | Get-PhysicalDisk | Where-Object -Property Size -NE -Value 428691423232 | Set-PhysicalDisk -MediaType HDD #For Demo Only 

Get-StoragePool -FriendlyName $PoolName | Get-PhysicalDisk | Where-Object -Property MediaType -EQ -Value SSD
Get-StoragePool -FriendlyName $PoolName | Get-PhysicalDisk | Where-Object -Property MediaType -EQ -Value HDD

$SSDTierName = "SSDTier"
$HDDTierName = "HDDTier"

$SSDTier = Get-StoragePool -FriendlyName $PoolName | New-StorageTier -MediaType SSD -FriendlyName $SSDTierName
$HDDTier = Get-StoragePool -FriendlyName $PoolName | New-StorageTier -MediaType HDD -FriendlyName $HDDTierName

Set-StoragePool -FriendlyName $PoolName -RetireMissingPhysicalDisks Always -RepairPolicy Parallel
#Preserve 1 HDD plus 8 GB and 1 SSD plus 8 GB per enclosure for the automatic repair proccess to work correctly
#Use at least one fewer columns then maximum!

Get-StoragePool -FriendlyName $PoolName | Select-Object RetireMissingPhysicalDisks,RepairPolicy

# 2 Tier 2 way Mirror with 6 columns$vDisk01Name = "vDisk01"
$vDisk01 = New-VirtualDisk  `
-FriendlyName $vDisk01Name  `
-ResiliencySettingName Mirror  `
-NumberOfDataCopies 2  `
-NumberOfColumns 5  `
-StoragePoolFriendlyName $PoolName  `
-StorageTiers $SSDTier, $HDDTier  `
-StorageTierSizes 8gb, 32gb

Get-VirtualDisk -FriendlyName $vDisk01Name | Format-List FriendlyName,OperationalStatus,HealthStatus,ProvisioningType,ParityLayout,WriteCacheSize,AllocatedSize,Interleave,IsEnclosureAware,NumberOfAvailableCopies,NumberOfColumns,PhysicalDiskRedundancy,Size

# 2 Tier 3 way Mirror with 4 columns$vDisk02Name = "vDisk02"
$vDisk02 = New-VirtualDisk  `
-FriendlyName $vDisk02Name  `
-ResiliencySettingName Mirror  `
-NumberOfDataCopies 3  `
-NumberOfColumns 3  `
-StoragePoolFriendlyName $PoolName  `
-StorageTiers $SSDTier, $HDDTier  `
-StorageTierSizes 8gb, 32gb

Get-VirtualDisk -FriendlyName $vDisk02Name | Format-List FriendlyName,OperationalStatus,HealthStatus,ProvisioningType,ParityLayout,WriteCacheSize,AllocatedSize,Interleave,IsEnclosureAware,NumberOfAvailableCopies,NumberOfColumns,PhysicalDiskRedundancy,Size

# Parity with 17 col$vDisk03Name = "vDisk03"
$vDisk03 = New-VirtualDisk  `
-FriendlyName $vDisk03Name  `
-ResiliencySettingName Parity  `
-StoragePoolFriendlyName $PoolName  `
-Size 100GB  `
-PhysicalDiskRedundancy 2

Get-VirtualDisk -FriendlyName $vDisk03Name | Format-List FriendlyName,OperationalStatus,HealthStatus,ProvisioningType,ParityLayout,WriteCacheSize,AllocatedSize,Interleave,IsEnclosureAware,NumberOfAvailableCopies,NumberOfColumns,PhysicalDiskRedundancy,Size

