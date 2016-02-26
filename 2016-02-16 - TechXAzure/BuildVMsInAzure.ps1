#Connect to Azure
$SubscriptionName = "TrueSec Demo Azure"
Add-AzureAccount -Verbose
Get-AzureSubscription -SubscriptionName $SubscriptionName | Select-AzureSubscription
$CurrentStorageAccountName = "clstore01"
$StorageAccount = Get-AzureStorageAccount | Where-Object -Property Label -EQ -Value clstore01
Set-AzureSubscription -SubscriptionName $SubscriptionName -CurrentStorageAccountName $CurrentStorageAccountName

#Get-AffGroup 
$AzureAffinityGroup = Get-AzureAffinityGroup -Name "TrueSecCloudHybrid"
$AzureAffinityGroup

#New ServiceName
$ServiceName = "aztexdemo01"
New-AzureService -ServiceName $ServiceName -AffinityGroup $AzureAffinityGroup.Name
$AzureService = Get-AzureService -ServiceName $ServiceName
$AzureService

#Get Image Names
$AzureVMimages = Get-AzureVMimage
$AzureVMimages | Where-Object -Property OS -EQ -Value Windows | Select-Object Label

#Set Names
$WS2012R2ImageName = "Windows Server 2012 R2 Datacenter, January 2016"
$WS2016TP4ImageName = "Windows Server 2016 Technical Preview 4"
$WS2016TP4NImageName = "Windows Server 2016 Core with Containers Tech Preview 4"

#Set Image
$WS2012R2Image = Get-AzureVMImage | Where-Object -Property Label -EQ -Value "Windows Server 2012 R2 Datacenter, January 2016"
$WS2016TP4Image = Get-AzureVMImage | Where-Object -Property Label -EQ -Value "Windows Server 2016 Technical Preview 4"
$WS2016TP4NImage = Get-AzureVMImage | Where-Object -Property Label -EQ -Value "Windows Server 2016 Core with Containers Tech Preview 4"


#NewVM
Function New-VMInAzure{
    Param(
    $VMName,
    $JoinPassword,
    $JoinAccount,
    $JoinDomain,
    $AdminUsername,
    $LocalPassword,
    $MachineObjectOU,
    $ImageName,
    $InstanceSize,
    $SubnetName,
    $vNetName
    )

    $AzureVMConfig = New-AzureVMConfig -Name $VMName -InstanceSize $InstanceSize -ImageName (Get-AzureVMImage | Where-Object -Property Label -EQ -Value $ImageName).ImageName
    $AzureProvisioningConfig = Add-AzureProvisioningConfig -WindowsDomain -AdminUsername $AdminUsername  -Password $LocalPassword -VM $AzureVMConfig -TimeZone "W. Europe Standard Time" -JoinDomain $JoinDomain -Domain $JoinDomain -DomainUserName $JoinAccount -DomainPassword $JoinPassword -MachineObjectOU $MachineObjectOU -EnableWinRMHttp
    $AzureProvisioningConfig | Set-AzureSubnet -SubnetNames $SubnetName
    $AzureProvisioningConfig | New-AzureVM -ServiceName $ServiceName -VNetName (Get-AzureVNetSite -VNetName $vNetName)

    $Ext1 = Get-AzureVMAvailableExtension -ExtensionName IaaSAntimalware
    $Ext2 = Get-AzureVMAvailableExtension -ExtensionName CustomScriptExtension
    Set-AzureVMExtension -ExtensionName $ext1.ExtensionName -Publisher $ext1.Publisher -Version $Ext1.Version -VM (Get-AzureVM -ServiceName $ServiceName -Name $VMName) -ForceUpdate | Update-AzureVM -verbose
    #Set-AzureVMExtension -ExtensionName $ext2.ExtensionName -Publisher $ext2.Publisher -Version $Ext2.Version -VM (Get-AzureVM -ServiceName $ServiceName -Name $VMName) -ForceUpdate
    #Set-AzureVMCustomScriptExtension
}

$VMName = "TCLTEST04"
$JoinPassword = "Microsoft Azure!"
$JoinAccount = "TechXJoin"
$JoinDomain = "cloud.truesec.com"
$AdminUsername = "azadm"
$LocalPassword = "NotForUse!"
$MachineObjectOU = "OU=Demo,OU=Server,OU=Cloud,DC=cloud,DC=truesec,DC=com"
$ImageName = "Windows Server 2012 R2 Datacenter, January 2016"
$InstanceSize = 'Small'
$vNetname = "CloudNetwork01"
$SubnetName = "CloudSubNet01"
New-VMInAzure -VMName $VMName -JoinPassword $JoinPassword -JoinAccount $JoinAccount -JoinDomain $JoinDomain -AdminUsername $AdminUsername -LocalPassword $LocalPassword -MachineObjectOU $MachineObjectOU -ImageName $ImageName -InstanceSize $InstanceSize -SubnetName $SubnetName -vNetName $vNetname

$VMNames = "TCLDEMO10","TCLDEMO11","TCLDEMO12","TCLDEMO13","TCLDEMO14","TCLDEMO15","TCLDEMO16","TCLDEMO17","TCLDEMO18","TCLDEMO19"
foreach($VMName in $VMNames){
    New-VMInAzure -VMName $VMName -JoinPassword $JoinPassword -JoinAccount $JoinAccount -JoinDomain $JoinDomain -AdminUsername $AdminUsername -LocalPassword $LocalPassword -MachineObjectOU $MachineObjectOU -ImageName $ImageName -InstanceSize $InstanceSize -SubnetName $SubnetName -vNetName $vNetname
}




Get-AzureVM -ServiceName $ServiceName -Name $VMName | Update-AzureVM -verbose -Debug
Get-AzureVMExtension -VM (Get-AzureVM -ServiceName $ServiceName -Name $VMName)






#Check if VM is up
do{Write-Host "Checking for a sign of life";Start-Sleep -Seconds 1}while((Get-AzureVM -ServiceName $ServiceName -Name $VMName).Status -ne 'ReadyRole')
(Test-NetConnection -ComputerName (Get-AzureVM -ServiceName $ServiceName -Name $VMName).IpAddress -CommonTCPPort RDP).TcpTestSucceeded
(Test-NetConnection -ComputerName (Get-AzureVM -ServiceName $ServiceName -Name $VMName).IpAddress -CommonTCPPort WINRM).TcpTestSucceeded


(Get-AzureVNetSite -VNetName CloudNetwork01).name
(Get-AzureVNetSite -VNetName CloudNetwork01).subnets |Where-Object -Property Name -EQ -Value "CloudSubNet01"



New-AzureVM -ServiceName $AzureService.ServiceName -AffinityGroup $AzureAffinityGroup.Name  -Location $AzureAffinityGroup.Location



#New-VM

Get-AzureVM -ServiceName $VMName | Stop-AzureVM -StayProvisioned
Get-AzureVM -ServiceName $VMName | Start-AzureVM

$AZVM = Get-AzureVM -ServiceName $ServiceName -Name $VMName
Get-AzureVMExtension -VM $AZVM

$AZVM = Get-AzureVM -ServiceName $ServiceName -Name TCLTEST02
Get-AzureVMExtension -VM $AZVM




Get-AzureVMAvailableExtension -ExtensionName IaaSAntimalware
Get-AzureVMAvailableExtension -ExtensionName CustomScriptExtension


Enable-PSRemoting -Force