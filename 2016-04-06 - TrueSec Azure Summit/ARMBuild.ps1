#Connect to Azure
Login-AzureRmAccount

# Set values for existing resource group and storage account names
$SubscriptionName = "AZ Demo"
$ResourceGroupName = "AZ Prod"
$StorageAccountName = "azprodstor01"
$LocationName = "West Europe"
$vnetName = "AZNetwork"
$VMname = "AZSRV24"
$LocalAdminPassword = "P@ssw0rd"
$LocalAdminName = "azadm"
$localCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $LocalAdminName, (ConvertTo-SecureString $LocalAdminPassword -AsPlainText -Force)

#Get and set the correct sub
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Set-AzureRmContext
$Subscription

#Get and set default storage
$AzureRmStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$AzureRmCurrentStorageAccount = Set-AzureRmCurrentStorageAccount -ResourceGroupName $AzureRmStorageAccount.ResourceGroupName -Name $AzureRmStorageAccount.StorageAccountName
$Subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Set-AzureRmContext
$Subscription

#Check that we are connected to the correct Resource Group
Get-AzureRmResourceGroup -Name $ResourceGroupName

#Set the existing vnet and subnet index
$subnetIndex=0
$vnet=Get-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $ResourceGroupName

#Create the NIC
$nicName = $VMname + "Nic01"
$pip=New-AzureRMPublicIpAddress -Name $nicName -ResourceGroupName $ResourceGroupName -Location $LocationName -AllocationMethod Dynamic -Verbose
$nic=New-AzureRMNetworkInterface -Name $nicName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id  -Verbose

#Set name and size,
$vmSize = 'Standard_D2'
$vm = New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize

# Add data disk
$diskSize = 300
$diskLabel = "Datadisk01"
$diskName = "$VMname-DISK02"
$storageAcc = Get-AzureRMStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$vhdURI = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
Add-AzureRMVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdUri $vhdURI -CreateOption empty -Verbose

#Specify image name, local administrator account, and then add the NIC
$pubName = "MicrosoftWindowsServer"
$offerName = "WindowsServer"
$skuName = "2012-R2-Datacenter"
$vm = Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $localCred -ProvisionVMAgent
$vm = Set-AzureRMVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
$vm = Add-AzureRMVMNetworkInterface -VM $vm -Id $nic.Id

# Specify the OS disk name and create the VM
$diskName = "OSDisk"
$storageAcc = Get-AzureRMStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
$vm = Set-AzureRMVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRMVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $vm -Verbose

#Get the VMdunction 
Get-WindowsAzureGet Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmname

#What extension do we already have?
(Get-AzureRmVM -Name $VMname -ResourceGroupName $ResourceGroupName).Extensions.name

#Get the Extension
Get-AzureVMAvailableExtension | FT Label,ExtensionName,Publisher

#Hmm
$Ext4 = Get-AzureVMAvailableExtension -ExtensionName "VMAccessAgent"
Set-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMname -ExtensionType $Ext4.ExtensionName -Name $Ext4.ExtensionName -Publisher $Ext4.Publisher -TypeHandlerVersion $Ext4.Version -Location $LocationName
Get-AzureRmVMExtension -Name $Ext4.ExtensionName -ResourceGroupName $ResourceGroupName -VMName $VMname -Status

#Join to domain
$Ext3 = Get-AzureVMAvailableExtension -ExtensionName "JsonADDomainExtension"
$String1 = '{
    "Name": "demo.domain.local",
    "User": "demo.domain.local\\AZ_Join",
    "Restart": "true",
    "Options": "3"
    }'
$String2 = '{ "Password": "P@ssw0rd" }'
Set-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMname -ExtensionType "JsonADDomainExtension" -Name "joindomain" -Publisher "Microsoft.Compute" -TypeHandlerVersion "1.0" -SettingString $String1 -ProtectedSettingString $String2 -Location $LocationName
Get-AzureRmVMExtension -Name "joindomain" -ResourceGroupName $ResourceGroupName -VMName $VMname -Status

#Check if success
do{}until((Get-AzureRmVMExtension -Name "joindomain" -ResourceGroupName $ResourceGroupName -VMName $VMname -Status).Statuses.message -eq "Join completed for Domain 'demo.domain.local'")

#Add Anitmalware
$Ext1 = Get-AzureVMAvailableExtension -ExtensionName "IaaSAntimalware"
$String1 = '{"AntimalwareEnabled":true}'
Set-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMname -Name $Ext1.ExtensionName -Publisher $Ext1.Publisher -ExtensionType $Ext1.ExtensionName -SettingString $String1 -TypeHandlerVersion $Ext1.Version -Location $LocationName
Get-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMname -Name $Ext1.ExtensionName -Status

#Check if success
do{}until((Get-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMname -Name $Ext1.ExtensionName -Status).Statuses.message -eq "Microsoft Antimalware enabled with custom settings")

#Add OMS
$Ext2 = Get-AzureVMAvailableExtension -ExtensionName "MicrosoftMonitoringAgent"
$string1 = ‘{ "workspaceId": "arrtertertertergerger" }’
$string2 =  ‘{ "workspaceKey": "aspdofspdfupfupfufjsödjfsödfjsödjfsödfjsöldfjsöldjf==" }’
Set-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -Name $Ext2.ExtensionName -ExtensionType $Ext2.ExtensionName -Publisher $Ext2.Publisher -Version $Ext2.Version -VM $VMname -Verbose -SettingString $String1 -ProtectedSettingString $String2 -Location $LocationName
Get-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMname -Name $Ext2.ExtensionName -Status
