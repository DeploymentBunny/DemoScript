$CLU1Nodes = "TCLSTOR23","TCLSTOR22","TCLSTOR21"
$CLU2Nodes = "TCLSTOR33","TCLSTOR32","TCLSTOR31"
$CLU1 = "TCLSTOR20"
$CLU2 = "TCLSTOR30"
$CLUNodes = $CLU2Nodes + $CLU1Nodes 
$CLU = $CLU2 + $CLU1

$CLU1FQDN = $CLU1+"."+$env:USERDNSDOMAIN
$CLU2FQDN = $CLU2+"."+$env:USERDNSDOMAIN


foreach ($Node in $CLUNodes) { 
Install-WindowsFeature –Name File-Services, Failover-Clustering –IncludeManagementTools -ComputerName $Node -verbose 
Install-WindowsFeature –Name Storage-Replica,Failover-Clustering,Multipath-IO,FS-FileServer –IncludeManagementTools -ComputerName $Node -verbose 
}

sleep -Seconds 30

foreach ($Node in $CLUNodes) { 
#Enable-MSDSMAutomaticClaim -BusType SAS -Confirm:$False
}
Restart-Computer -ComputerName $CLUNodes -Force -Wait
Restart-Computer



Test-Cluster –Node $CLU2Nodes –Include Inventory,Network,”System Configuration” -verbose
Test-Cluster –Node $CLU1Nodes –Include Inventory,Network,”System Configuration” -verbose

New-Cluster –Name $CLU2 –Node $CLU2Nodes –NoStorage -verbose
New-Cluster –Name $CLU1 –Node $CLU1Nodes –NoStorage -verbose 

# Enable Storage Spaces Direct 
#Disable-ClusterStorageSpacesDirect -Verbose -Cluster $CLU1 -Force
#Disable-ClusterStorageSpacesDirect -Verbose -Cluster $CLU2 -Force


# Create a Stroage Pool 
Invoke-Command -ComputerName $CLU1Nodes[2],$CLU2Nodes[2] -scriptblock { 

Get-Disk | Where-Object IsSystem –eq $False | Where-Object PartitionStyle –Eq "RAW" | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem ReFS
Get-Disk | Where-Object IsSystem –eq $False | Add-ClusterDisk -Verbose 
MD c:\temp
Add-ClusterSharedVolume -Name "Cluster Disk 1"
}


#Test-SRTopology -SourceComputerName $CLU1Nodes[2] -SourceVolumeNames e: -SourceLogVolumeName g: -DestinationComputerName $CLU2Nodes[2] -DestinationVolumeNames f: -DestinationLogVolumeName g: -DurationInMinutes 1 -ResultPath c:\temp

Grant-SRAccess -ComputerName $CLU1Nodes[2] -Cluster $CLU2 -Verbose
Grant-SRAccess -ComputerName $CLU2Nodes[2] -Cluster $CLU1 -Verbose

New-SRPartnership -SourceComputerName $CLU1 -SourceRGName rg01 -SourceVolumeName c:\ClusterStorage\Volume1 -SourceLogVolumeName G: -DestinationComputerName $CLU2 -DestinationRGName rg02 -DestinationVolumeName c:\ClusterStorage\Volume1 -DestinationLogVolumeName G: -ReplicationMode Synchronous 


Get-SRGroup 
Get-SRPartnership
(Get-SRGroup).replicas

Get-WinEvent -ProviderName Microsoft-Windows-StorageReplica –max 20


Get-SRPartnership | Remove-SRPartnership -Force
Get-SRGroup | Remove-SRGroup -Force



Get-Cluster -Name $CLU2 | Remove-Cluster -CleanupAD -Force
Get-Cluster -Name $CLU1 | Remove-Cluster -CleanupAD -Force


# Clean Up 
foreach ($Node in $CLUNodes) { 
    Invoke-Command -ComputerName $Node -ScriptBlock { 
        get-SRPartnership | Remove-SRPartnership -Force
        Get-SRGroup | Remove-SRGroup -Force
        Get-VirtualDisk | Remove-VirtualDisk -Confirm:$false
        Get-StoragePool | where IsPrimordial -EQ $false | Remove-StoragePool -Confirm:$false
        Get-PhysicalDisk -CanPool $True | Reset-PhysicalDisk -Confirm:$false
        Clear-SRMetadata -AllPartitions -Force -AllConfiguration -AllLogs -Verbose
    }
}

foreach ($Node in ($CLU1Nodes[2],$CLU2Nodes[2])) { 
    Invoke-Command -ComputerName $Node -ScriptBlock { 
        get-disk | where IsSystem -eq $false | Set-Disk -IsOffline $False 
        get-disk | where IsSystem -eq $false | Set-Disk -IsReadonly $False
        get-disk | where IsSystem -eq $false | Clear-Disk -Confirm:$false -RemoveData 
    }
}
