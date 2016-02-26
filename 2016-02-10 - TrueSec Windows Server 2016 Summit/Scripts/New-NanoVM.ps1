#Set Var
$DC = "CLADDS01"
$Global:BlobFolder = "C:\Blobs"
$Blob = "C:\blobs\obj.blob"
$UATemplateSource = "C:\Setup\Settings\uatemplate.xml"
$localCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "Administrator", (ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force)
$domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "CLOUD\admminy", (ConvertTo-SecureString $PW -AsPlainText -Force)
$VHDXFile = "C:\Setup\OS\RWS2016D-001\NanoServer\NANO_BIOS.vhdx"
$VMName = "TCLNANO03"

#Create Blob Folder
New-Item -Path C:\Blobs -ItemType Directory -Force

#Configure Remote Access via CredSSp
Set-Item WSMan:\localhost\Client\TrustedHosts $DC -Force

#Create VM
C:\setup\Scripts\New-VIAVM.ps1 -VMName $VMName -VMMem 1024mb -VMvCPU 2 -VMLocation "C:\VMs" -VHDFile $VHDXFile -DiskMode Diff -VMSwitchName UplinkSwitch -VMGeneration 1
$MountedVHD = Mount-DiskImage -ImagePath (Get-VHD -VMId (Get-VM -Name $VMName).Id).Path -PassThru | Get-DiskImage | Get-Disk | Get-Partition | Where-Object -Property type -EQ -Value IFS
$MountedVHD.DriveLetter

#Create Folders in VHD
New-Item -Path "$($MountedVHD.DriveLetter):\Windows\Setup" -ItemType Directory -Force
New-Item -Path "$($MountedVHD.DriveLetter):\Windows\Setup\Scripts" -ItemType Directory -Force
New-Item -Path "$($MountedVHD.DriveLetter):\Windows\Panther" -ItemType Directory -Force
New-Item -Path "$($MountedVHD.DriveLetter):\Temp" -ItemType Directory -Force

#Create The Blob
Invoke-Command -ComputerName $DC -Credential $DomainCred -ScriptBlock{
    Param($VMname)
    $Blob = "C:\Blobs\obj.blob"
    $BlobFolder = "C:\Blobs"
    #Skapa blobsmapp om den inte finns
    if(!(Test-Path $BlobFolder)){New-Item -Path $BlobFolder -ItemType Directory -Force}
    #Radera blobfil från tidigare körning om den finns
    if(Test-Path -Path $Blob){Remove-Item -Path $Blob}
    C:\Windows\System32\djoin.exe /provision /domain cloud.truesec.com /machine $VMname /savefile C:\blobs\obj.blob
    } -ArgumentList $VMName
$BlobData = Invoke-Command -ComputerName $DC -Credential $DomainCred -ScriptBlock{
    $Blob = "C:\blobs\obj.blob"
    $(Get-Content $Blob)
    }

#Get the blob and store on VHD
$BlobData | Out-File -FilePath $Blob -Force
Copy-Item -Path $Blob -Destination "$($MountedVHD.DriveLetter):\Temp" -Force -Verbose

#Get UATemplate, Update and store on VHD
$UAXMLTemplateFile = "$($MountedVHD.DriveLetter):\Windows\Panther\uatemplate.xml"
(Get-Content $UATemplateSource) -replace ('OSDComputerName',"$VMName") | Out-File "$($MountedVHD.DriveLetter):\Windows\Panther\UnAttend.xml" -Encoding ascii -Force

#Dismount VHD
Dismount-VHD -Path (Get-VHD -VMId (Get-VM -Name $VMName).Id).Path

Start-VM -Name $VMName

function waitForPSDirect([string]$VMName, $cred)
 {
 Write-Output "[$($VMName)]:: Waiting for PowerShell Direct (using $($cred.username))"
 while ((Invoke-Command -VMName $VMName -Credential $cred -ScriptBlock { "Test" } -ea SilentlyContinue) -ne "Test") { Sleep -Seconds 1 }
 }

waitForPSDirect -VMName $VMName -cred $localCred

Invoke-Command -VMName $VMName -ScriptBlock{
    $env:COMPUTERNAME
} -Credential $localCred


Invoke-Command -VMName $VMName -Credential $localCred -ScriptBlock{ 
    djoin /requestodj /loadfile c:\temp\obj.blob /windowspath c:\windows /localos 
}

Stop-VM -Name $VMName
Start-VM -Name $VMName
