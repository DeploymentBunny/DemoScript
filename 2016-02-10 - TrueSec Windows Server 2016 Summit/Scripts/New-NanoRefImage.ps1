Function Create-FANanoVHD{
    Param(
        $WimFile = "D:\NanoServer\NanoServer.wim",
        $DiskLayOut,
        $VHDXFile,
        $PackPath
    )
        C:\setup\Scripts\Convert-WIM2VHD.ps1 `
        -SourceFile $WimFile -DestinationFile $VHDXFile -Disklayout BIOS -Index 1 -SizeInMB 5000 -Verbose
        #Add Package to VHD
        Mount-DiskImage -ImagePath $VHDXFile
        $DriveLetter = (Get-Volume | Where-Object -Property FileSystemLabel -EQ -Value OSDisk).DriveLetter
        Add-WindowsPackage -PackagePath "$PackPath\Microsoft-NanoServer-Storage-Package.cab" -Path "$($DriveLetter):\"
        Add-WindowsPackage -PackagePath "$PackPath\en-us\Microsoft-NanoServer-Storage-Package.cab" -Path "$($DriveLetter):\"
        Add-WindowsPackage -PackagePath "$PackPath\Microsoft-NanoServer-Guest-Package.cab" -Path "$($DriveLetter):\"
        Add-WindowsPackage -PackagePath "$PackPath\en-us\Microsoft-NanoServer-Guest-Package.cab" -Path "$($DriveLetter):\"
        Add-WindowsPackage -PackagePath "$PackPath\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path "$($DriveLetter):\"
        Add-WindowsPackage -PackagePath "$PackPath\en-us\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path "$($DriveLetter):\"
        Add-WindowsPackage -PackagePath "$PackPath\Microsoft-NanoServer-Compute-Package.cab" -Path "$($DriveLetter):\"
        Add-WindowsPackage -PackagePath "$PackPath\en-us\Microsoft-NanoServer-Compute-Package.cab" -Path "$($DriveLetter):\"
        Dismount-DiskImage -ImagePath $VHDXFile
}

$NanoWim = "C:\Setup\OS\RWS2016D-001\NanoServer\NanoServer.wim"
$PackPath = "C:\Setup\OS\RWS2016D-001\NanoServer\Packages"

Create-FANanoVHD -WimFile $NanoWim -DiskLayOut BIOS -VHDXFile C:\Setup\OS\RWS2016D-001\NanoServer\NANO_BIOS.vhdx -PackPath $PackPath
Create-FANanoVHD -WimFile $NanoWim -DiskLayOut UEFI -VHDXFile C:\Setup\OS\RWS2016D-001\NanoServer\NANO_UEFI.vhdx -PackPath $PackPath

