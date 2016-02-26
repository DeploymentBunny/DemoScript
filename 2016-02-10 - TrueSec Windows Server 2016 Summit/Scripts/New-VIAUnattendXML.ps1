<#
 ##################################################################################
 #  Script name: Create-UnattendXML.ps1
 #  Created:		2013-09-02
 #  version:		v1.0
 #  Author:      Mikael Nystrom
 #  Homepage:    http://deploymentbunny.com/
 ##################################################################################
 
 ##################################################################################
 #  Disclaimer:
 #  -----------
 #  This script is provided "AS IS" with no warranties, confers no rights and 
 #  is not supported by the authors or DeploymentBunny.
 ##################################################################################
#>
Param(
    [parameter(mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $Computername,
    
    [parameter(mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $OSDAdapter0IPAddressList,
    
    [parameter(mandatory=$false)]
    [ValidateSet("Domain","Workgroup")]
    $DomainOrWorkGroup,

    [parameter(mandatory=$false)]
    $ProductKey = 'NONE'
)

#Setting Machine
$AdminPassword = "P@ssw0rd"
$OrgName = "ViaMonstra"
$Fullname = "ViaMonstra"
$TimeZoneName = "W. Europe Standard Time"
$InputLocale = "en-US"
$SystemLocale = "en-US"
$UILanguage = "en-US"
$UserLocale = "en-US"
$OSDAdapter0Gateways = "172.16.200.1"
$OSDAdapter0DNS1 = "172.16.200.21"
$OSDAdapter0DNS2 = "172.16.200.22"
$OSDAdapter0SubnetMaskPrefix = "22"
$VMName = $Computername

#Setting Domain
$DNSDomain
$DomainNetBios
$DomainAdmin
$DomainAdminPassword
$DomainAdminDomain
$MachienObjectOU

#Workgroup Settings
$JoinWorkgroup = "WORKGROUP"

if(Test-Path "Unattend.xml"){del .\Unattend.xml}
Write-Host "IP is $OSDAdapter0IPAddressList"
    $unattendFile = New-Item "Unattend.xml" -type File
    set-Content $unattendFile '<?xml version="1.0" encoding="utf-8"?>'
    add-Content $unattendFile '<unattend xmlns="urn:schemas-microsoft-com:unattend">'
    add-Content $unattendFile '    <settings pass="specialize">'
    Switch ($DomainOrWorkGroup){
DOMAIN{
Write-Host "Configure for domain mode"
    add-Content $unattendFile '        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">'
    add-Content $unattendFile '            <Identification>'
    add-Content $unattendFile '                <Credentials>'
    add-Content $unattendFile "                    <Username>$DomainAdmin</Username>"
    add-Content $unattendFile "                    <Domain>$DomainAdminDomain</Domain>"
    add-Content $unattendFile "                    <Password>$DomainAdminPassword</Password>"
    add-Content $unattendFile '                </Credentials>'
    add-Content $unattendFile "                <JoinDomain>$DNSDomain</JoinDomain>"
    add-Content $unattendFile "                <MachineObjectOU>$MachienObjectOU</MachineObjectOU>"
    add-Content $unattendFile '            </Identification>'
    add-Content $unattendFile '        </component>'
}
WORKGROUP{
Write-Host "Configure unattend.xml for workgroup mode"
    add-Content $unattendFile '        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">'
    add-Content $unattendFile '            <Identification>'
    add-Content $unattendFile "                <JoinWorkgroup>$JoinWorkgroup</JoinWorkgroup>"
    add-Content $unattendFile '            </Identification>'
    add-Content $unattendFile '        </component>'
}
default{
Write-Host "Epic Fail, exit..."
Exit
}
}
    add-Content $unattendFile '        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">'
    add-Content $unattendFile "            <ComputerName>$VMName</ComputerName>"
if ($ProductKey -eq 'NONE')
{
Write-Host "No Productkey"
}else{
Write-Host "Adding Productkey $ProductKey"
    add-Content $unattendFile "            <ProductKey>$ProductKey</ProductKey>"
}
    add-Content $unattendFile "            <RegisteredOrganization>$OrgName</RegisteredOrganization>"
    add-Content $unattendFile "            <RegisteredOwner>$Fullname</RegisteredOwner>"
    add-Content $unattendFile '            <DoNotCleanTaskBar>true</DoNotCleanTaskBar>'
    add-Content $unattendFile "            <TimeZone>$TimeZoneName</TimeZone>"
    add-Content $unattendFile '        </component>'
    add-Content $unattendFile '        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
    add-Content $unattendFile "            <InputLocale>$InputLocale</InputLocale>"
    add-Content $unattendFile "            <SystemLocale>$SystemLocale</SystemLocale>"
    add-Content $unattendFile "            <UILanguage>$UILanguage</UILanguage>"
    add-Content $unattendFile "            <UserLocale>$UserLocale</UserLocale>"
    add-Content $unattendFile '        </component>'
if ($OSDAdapter0IPAddressList -contains "DHCP"){
Write-Host "IP is $OSDAdapter0IPAddressList so we prep for DHCP"
}else{
Write-Host "IP is $OSDAdapter0IPAddressList so we prep for Static IP"
    add-Content $unattendFile '        <component name="Microsoft-Windows-DNS-Client" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
    add-Content $unattendFile '            <Interfaces>'
    add-Content $unattendFile '                <Interface wcm:action="add">'
    add-Content $unattendFile '                    <DNSServerSearchOrder>'
    add-Content $unattendFile "                        <IpAddress wcm:action=`"add`" wcm:keyValue=`"1`">$OSDAdapter0DNS1</IpAddress>"
    add-Content $unattendFile "                        <IpAddress wcm:action=`"add`" wcm:keyValue=`"2`">$OSDAdapter0DNS2</IpAddress>"
    add-Content $unattendFile '                    </DNSServerSearchOrder>'
    add-Content $unattendFile '                    <Identifier>Ethernet</Identifier>'
    add-Content $unattendFile '                </Interface>'
    add-Content $unattendFile '            </Interfaces>'
    add-Content $unattendFile '        </component>'
    add-Content $unattendFile '        <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
    add-Content $unattendFile '            <Interfaces>'
    add-Content $unattendFile '                <Interface wcm:action="add">'
    add-Content $unattendFile '                    <Ipv4Settings>'
    add-Content $unattendFile '                        <DhcpEnabled>false</DhcpEnabled>'
    add-Content $unattendFile '                    </Ipv4Settings>'
    add-Content $unattendFile '                    <Identifier>Ethernet</Identifier>'
    add-Content $unattendFile '                    <UnicastIpAddresses>'
    add-Content $unattendFile "                       <IpAddress wcm:action=`"add`" wcm:keyValue=`"1`">$OSDAdapter0IPAddressList/$OSDAdapter0SubnetMaskPrefix</IpAddress>"
    add-Content $unattendFile '                    </UnicastIpAddresses>'
    add-Content $unattendFile '                    <Routes>'
    add-Content $unattendFile '                        <Route wcm:action="add">'
    add-Content $unattendFile '                            <Identifier>0</Identifier>'
    add-Content $unattendFile "                            <NextHopAddress>$OSDAdapter0Gateways</NextHopAddress>"
    add-Content $unattendFile "                            <Prefix>0.0.0.0/0</Prefix>"
    add-Content $unattendFile '                        </Route>'
    add-Content $unattendFile '                    </Routes>'
    add-Content $unattendFile '                </Interface>'
    add-Content $unattendFile '            </Interfaces>'
    add-Content $unattendFile '        </component>'
}
    add-Content $unattendFile '    </settings>'
    add-Content $unattendFile '    <settings pass="oobeSystem">'
    add-Content $unattendFile '        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">'
    add-Content $unattendFile '            <UserAccounts>'
    add-Content $unattendFile '                <AdministratorPassword>'
    add-Content $unattendFile "                    <Value>$AdminPassword</Value>"
    add-Content $unattendFile '                    <PlainText>True</PlainText>'
    add-Content $unattendFile '                </AdministratorPassword>'
    add-Content $unattendFile '            </UserAccounts>'
    add-Content $unattendFile '            <OOBE>'
    add-Content $unattendFile '                <HideEULAPage>true</HideEULAPage>'
    add-Content $unattendFile '                <NetworkLocation>Work</NetworkLocation>'
    add-Content $unattendFile '                <ProtectYourPC>1</ProtectYourPC>'
    add-Content $unattendFile '            </OOBE>'
    add-Content $unattendFile "            <RegisteredOrganization>$Orgname</RegisteredOrganization>"
    add-Content $unattendFile "            <RegisteredOwner>$FullName</RegisteredOwner>"
    add-Content $unattendFile "            <TimeZone>$TimeZoneName</TimeZone>"
    add-Content $unattendFile '        </component>'
    add-Content $unattendFile '        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
    add-Content $unattendFile "            <InputLocale>$InputLocale</InputLocale>"
    add-Content $unattendFile "            <SystemLocale>$SystemLocale</SystemLocale>"
    add-Content $unattendFile "            <UILanguage>$UILanguage</UILanguage>"
    add-Content $unattendFile "            <UserLocale>$UserLocale</UserLocale>"
    add-Content $unattendFile '        </component>'
    add-Content $unattendFile '    </settings>'
    add-Content $unattendFile '</unattend>'
$unattendFile
