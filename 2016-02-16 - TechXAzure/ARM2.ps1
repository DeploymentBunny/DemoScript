# Login to Azure PowerShell
Login-AzureRmAccount

# Create the self signed cert
$currentDate = Get-Date
$endDate = $currentDate.AddYears(1)
$notAfter = $endDate.AddYears(1)
$pwd = "P@ssW0rd1"
$thumb = (New-SelfSignedCertificate -CertStoreLocation cert:\localmachine\my -DnsName com.foo.bar -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter).Thumbprint
$pwd = ConvertTo-SecureString -String $pwd -Force -AsPlainText
Export-PfxCertificate -cert "cert:\localmachine\my\$thumb" -FilePath c:\certificates\examplecert.pfx -Password $pwd

# Load the certificate
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("C:\certificates\examplecert.pfx", $pwd)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
$keyId = [guid]::NewGuid()
Import-Module AzureRM.Resources
$keyCredential = New-Object  Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADKeyCredential
$keyCredential.StartDate = $currentDate
$keyCredential.EndDate= $endDate
$keyCredential.KeyId = $keyId
$keyCredential.Type = "AsymmetricX509Cert"
$keyCredential.Usage = "Verify"
$keyCredential.Value = $keyValue

# Create the Azure Active Directory Application
$azureAdApplication = New-AzureRmADApplication -DisplayName "<Your Application Display Name>" -HomePage "<https://YourApplicationHomePage>" -IdentifierUris "<https://YouApplicationUri>" -KeyCredentials $keyCredential  

# Create the Service Principal and connect it to the Application
New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId

# Give the Service Principal Reader access to the current subscription
New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $azureAdApplication.ApplicationId

# Now you can login to Azure PowerShell with your Service Principal and Certificate
Login-AzureRmAccount -TenantId (Get-AzureRmContext).Tenant.TenantId -ServicePrincipal -Certificate Thumbprint $thumb -ApplicationId $azureAdApplication.ApplicationId 


