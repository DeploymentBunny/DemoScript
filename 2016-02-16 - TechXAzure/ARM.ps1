# To login to Azure Resource Manager
Login-AzureRmAccount

# You can also use a specific Tenant if you would like a faster login experience
# Login-AzureRmAccount -TenantId 7aac71ca-9bf3-49bc-bb57-7d718ed0d37c

# To view all subscriptions for your account
Get-AzureRmSubscription | where SubscriptionName -NotLike "Pay-As*"

# To select a default subscription for your current session
Get-AzureRmSubscription –SubscriptionName “Windows Azure Microsoft Partner Network” | Select-AzureRmSubscription 



# View your current Azure PowerShell session context
# This session state is only applicable to the current session and will not affect other sessions
Get-AzureRmContext 

# List current Storage Account Names 
Get-AzureRmStorageAccount | select ResourceGroupName, StorageAccountName


# List RM Resource Providers 
Get-AzureRmResourceProvider -ListAvailable
Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Storage 
$Storage = Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Storage
$Storage[0].Locations

# Create a Storage Account 
New-AzureRmResourceGroup -Name "TechX4" -Location "West Europe"
New-AzureRmStorageAccount -ResourceGroupName "TechX4" -AccountName "mystorageaccount233" -Location "West Europe" -Type "Standard_GRS"
Get-AzureRmStorageAccount -ResourceGroupName "TechX4" 

# To select the default storage context for your current session
Set-AzureRmCurrentStorageAccount -ResourceGroupName "TechX4" -StorageAccountName "mystorageaccount233" 


# View your current Azure PowerShell session context
# Note: the CurrentStoargeAccount is now set in your session context
Get-AzureRmContext

# To import the Azure.Storage data plane module (blob, queue, table)
Import-Module Azure.Storage

# To list all of the blobs in all of your containers in all of your accounts
Get-AzureRmStorageAccount | Get-AzureStorageContainer | Get-AzureStorageBlob

# Resource Providers 
Get-AzureRmResourceProvider -ListAvailable

# 
Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Sql
((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Web).ResourceTypes | Where-Object ResourceTypeName -eq sites).Locations | Sort-Object
 
((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Sql).ResourceTypes | Where-Object ResourceTypeName -eq servers).Locations | Sort-Object

New-AzureRmResourceGroup -Name "TechX1" -Location "West Europe"
((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Web).ResourceTypes | Where-Object ResourceTypeName -eq sites).ApiVersions

((Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Sql).ResourceTypes | Where-Object ResourceTypeName -eq servers/databases).ApiVersions

# Deploy Template
New-AzureRmResourceGroupDeployment -ResourceGroupName TechX1 -TemplateFile c:\Azure\Templates\azuredeploy.json

New-AzureRmResourceGroupDeployment -ResourceGroupName TechX1 -TemplateFile c:\Azure\Templates\azuredeploy.json -hostingPlanName freeplanwest -serverName techxmarkus2 -databaseName techxmarkus2 -administratorLogin techxmarkus2 


Find-AzureRmResourceGroup | where id -Like *TechX* | Remove-AzureRmResourceGroup -force 


Get-AzureRmSubscription –SubscriptionName “Windows Azure Microsoft Partner Network” | Select-AzureRmSubscription 

Get-AzureRMAuthorizationChangeLog -Verbose

Get-AzureRmLog 


Get-AzureRmResourceGroup | where ResourceGroupName -like *TechX* | Remove-AzureRmResourceGroup -Force 

Get-AzureRmResourceGroup | where ResourceGroupName -like TexhDemo* | Remove-AzureRmResourceGroup -Force 
Get-AzureRmResourceGroup | where ResourceGroupName -like AzureResourceGrou* | Remove-AzureRmResourceGroup -Force 


