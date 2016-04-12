#Connect to Azure
#$SubscriptionName = "TrueSec Demo Azure"
$SubscriptionName = "Windows Azure MSDN - Visual Studio Premium"
$StorageAccountName = "deploymentbunny"

#Cleanup existing Azure Account
Remove-AzureAccount -Name (Get-AzureAccount).Id -Force
Add-AzureAccount
(Get-AzureAccount).Id

#Get and set the correct sub
Get-AzureSubscription -SubscriptionName $SubscriptionName | Select-AzureSubscription 
$Subscription =  Get-AzureSubscription | Where-Object -Property IsDefault -EQ -Value True
$Subscription

#Get and set default storage
Set-AzureSubscription -SubscriptionName $SubscriptionName -CurrentStorageAccountName $StorageAccountName
$Subscription =  Get-AzureSubscription | Where-Object -Property IsDefault -EQ -Value True
$Subscription

#Get the network we have
$AzureVNetSite = Get-AzureVNetSite
$AzureVNetSite

#Get Location
$AzureLocation = Get-AzureLocation | Where-Object -Property Name -EQ -Value $($AzureVNetSite.Location)

#Get VM role sizes at my location and facts for each of them
$AzureLocationVirtualMachineRoleSize = Foreach($VirtualMachineRoleSize in ($AzureLocation.VirtualMachineRoleSizes | Select-Object -First 5)){
    Get-AzureRoleSize -InstanceSize $VirtualMachineRoleSize
    }
$AzureLocationVirtualMachineRoleSize
$AzureLocation.StorageAccountTypes

#Get Image Names
$AzureVMimages = Get-AzureVMimage | Where-Object -Property Label -Like -Value "Windows Server*" | Select-Object OS,Label -Unique
$AzureVMimages

#Set Names
$WS2012R2ImageName = "Windows Server 2012 R2 Datacenter, January 2016"
$WS2016TP4ImageName = "Windows Server 2016 Technical Preview 4"

#Set Image
$WS2012R2Image = Get-AzureVMImage | Where-Object -Property Label -EQ -Value $WS2012R2ImageName
$WS2016TP4Image = Get-AzureVMImage | Where-Object -Property Label -EQ -Value $WS2016TP4ImageName

#NewVM
Function New-StandAloneVMInAzure{
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

    #Create Config
    $AzureVMConfig = New-AzureVMConfig -Name $VMName -InstanceSize $InstanceSize -ImageName (Get-AzureVMImage | Where-Object -Property Label -EQ -Value $ImageName).ImageName
    $AzureProvisioningConfig = Add-AzureProvisioningConfig -WindowsDomain -AdminUsername $AdminUsername  -Password $LocalPassword -VM $AzureVMConfig -TimeZone "W. Europe Standard Time" -JoinDomain $JoinDomain -Domain $JoinDomain -DomainUserName $JoinAccount -DomainPassword $JoinPassword -MachineObjectOU $MachineObjectOU -EnableWinRMHttp
    $AzureProvisioningConfig | Set-AzureSubnet -SubnetNames $SubnetName
    
    #Create Service
    New-AzureService -ServiceName $VMName -Location "West Europe"

    #Create VM
    $AzureProvisioningConfig | New-AzureVM -ServiceName $VMName -VNetName (Get-AzureVNetSite -VNetName $vNetName).name
}

#Set Param
$VMName = "GUNK52"
$JoinPassword = "Password33"
$JoinAccount = "AzureJoin"
$JoinDomain = "network.local"
$AdminUsername = "azadm"
$LocalPassword = "NotForUse!"
$MachineObjectOU = "OU=InfraStructure Computers,OU=Computers,OU=NETWORK,DC=network,DC=local"
$ImageName = "Windows Server 2012 R2 Datacenter, January 2016"
$InstanceSize = 'Standard_D2'
$vNetname = "SkyNet"
$SubnetName = "Subnet-1"

#Build VM
New-StandAloneVMInAzure -VMName $VMName -JoinPassword $JoinPassword -JoinAccount $JoinAccount -JoinDomain $JoinDomain -AdminUsername $AdminUsername -LocalPassword $LocalPassword -MachineObjectOU $MachineObjectOU -ImageName $ImageName -InstanceSize $InstanceSize -SubnetName $SubnetName -vNetName $vNetname

#Wait until done
do{}until((Get-AzureVM -Name $VMName -ServiceName $VMName).InstanceStatus -eq 'ReadyRole')

#Get the Extension
Get-AzureVMAvailableExtension | FT Label,ExtensionName
$Ext1 = Get-AzureVMAvailableExtension -ExtensionName "IaaSAntimalware"
$Ext2 = Get-AzureVMAvailableExtension -ExtensionName "MicrosoftMonitoringAgent"

#Check if Agent is ready to work
$AzureVM = Get-AzureVM -ServiceName $VMName -Name $VMName
$AzureVM | Update-AzureVM -verbose
if(($AzureVM.GuestAgentStatus).Status -eq "Ready"){Write-Host "Agent is ready in $VMName"}

#Add Antimalware
Set-AzureVMExtension -ExtensionName $Ext1.ExtensionName -Publisher $Ext1.Publisher -Version $Ext1.Version -VM $AzureVM -ForceUpdate -Verbose

#Add OMS
$string1 = ‘{ "workspaceId": "e55e18fb-e4c9-4008-ad73-ab1154449cf6" }’
$string2 =  ‘{ "workspaceKey": "LV7gBAOmqJphM/+oKWGf2EALulrbFxvdjDVy+iXBoDG4p5rfgBc9cqvDGtJNSFn+kcz/PdQ1DNv3xOhjPUdxrA==" }’
Set-AzureVMExtension -ExtensionName $Ext2.ExtensionName -Publisher $Ext2.Publisher -Version $Ext2.Version -VM $AzureVM -ForceUpdate -Verbose -PublicConfiguration $string1 -PrivateConfiguration $string2
$AzureVM | Update-AzureVM 

#Get status
Get-AzureVMExtension -VM $AzureVM
