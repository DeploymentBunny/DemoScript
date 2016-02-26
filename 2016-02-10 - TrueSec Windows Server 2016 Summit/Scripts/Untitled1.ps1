C:\Setup\Scripts\Import-VIAMDTOS.ps1 -Path "C:\MDTBuildlab" -ISO 'C:\Setup\ISO\Windows Server 2016.iso' -MDTDestinationPath "Operating Systems\Windows Server 2016" -MDTDestinationFolderName WS2016
C:\Setup\Scripts\CreateNew-VM.ps1 -VMName REFWS2016-001 -VMMem 2GB -VMvCPU 2 -VMLocation C:\VMs -DiskMode Empty -EmptyDiskSize 100GB -VMSwitchName UplinkSwitch -VMGeneration 1 -ISO 'C:\MDTBuildLAB\Boot\MDT Build Lab x86.iso' -Verbose


C:\Setup\Scripts\Convert-VIAWIM2VHD.ps1 -SourceFile C:\MDTBuildLab\Captures\REFWS2016-001.wim -DestinationFile C:\Setup\VHD\WS2016_UEFI.vhdx -Disklayout UEFI -Index 1 -SizeInMB 100000 –Verbose



C:\Setup\Scripts\New-VIAVM.ps1 -VMName DC01 -VMMem 2GB -VMvCPU 2 -VMLocation C:\VMs -DiskMode Empty -EmptyDiskSize 100GB -VMSwitchName UplinkSwitchNAT -VMGeneration 2 -ISO 'C:\MDTOfflineMedia\Windows Server 2016.iso' -Verbose
C:\Setup\Scripts\New-VIAMDTProductionDS.ps1 -Path "C:\MDTProduction" -Description "MDT Production"
C:\setup\Scripts\Set-VIAMDTProductionDS.ps1 -Path "C:\MDTProduction"


C:\Setup\Scripts\Import-VIAMDTCOS.ps1 -Path "C:\MDTProduction" -WIM "C:\Setup\WIM\REFWS2016-001.wim" -SetupFiles "C:\MDTBuildlab\Operating Systems\WS2016" -MDTDestinationPath "Operating Systems\Windows Server 2016" -MDTDestinationFolderName "CWS2016"


