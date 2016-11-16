<#
.Synopsis
    Script from TechDays Sweden 2016
.DESCRIPTION
    Script from TechDays Sweden 2016
.NOTES
    Configure ILO networking settings and verify DNS Addresses 

    Author - Markus Lassfolk
    Twitter: @lassfolk
    Blog   : http://www.isolation.se

    Co-Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

    Disclaimer:
    This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the authors or Deployment Artist.
.LINK
    http://www.deploymentbunny.com
#>

# New ILO Config
$RIBCLScriptFile = "$env:TEMP\ILOConfig.xml"

Function Invoke-VIAExe
{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Executable,

        [parameter(mandatory=$true,position=1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Arguments,

        [parameter(mandatory=$false,position=2)]
        [ValidateNotNullOrEmpty()]
        [int]
        $SuccessfulReturnCode = 0
    )

    Write-Verbose "Running $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
    $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru

    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
}

# Creat ILO XML File 
$RIBCLTemplate = @'
<RIBCL VERSION="2.1">
<LOGIN USER_LOGIN="Administrator" PASSWORD="password">
  <RIB_INFO MODE="write">
  <MOD_NETWORK_SETTINGS>
    <SPEED_AUTOSELECT VALUE = "Y"/>
    <DHCP_GATEWAY VALUE = "Y"/>
    <DHCP_DNS_SERVER VALUE = "Y"/>
    <DHCP_STATIC_ROUTE VALUE = "N"/>
    <DHCP_WINS_SERVER VALUE = "N"/>
    <DHCP_DOMAIN_NAME VALUE="N"/>
    <REG_WINS_SERVER VALUE = "N"/>
    <DNS_NAME VALUE = "OOBHostName"/>
    <DOMAIN_NAME VALUE = "OOBDomainName"/>
    <DHCP_SNTP_SETTINGS VALUE="Y"/>
    <REG_DDNS_SERVER VALUE="Y"/>
    <PING_GATEWAY VALUE="N"/>
    <TIMEZONE VALUE="Europe/Stockholm"/>
  </MOD_NETWORK_SETTINGS>
  </RIB_INFO>
</LOGIN>
</RIBCL>
'@

$OOBHostName = $env:COMPUTERNAME
$OOBDomainName = "ILO"

$RIBCLSettings = $RIBCLTemplate `
-replace ("OOBHostName","$OOBHostName") `
-replace ("OOBDomainName","$OOBDomainName")

$RIBCLSettings | Out-File $RIBCLScriptFile -Force ascii

# Save ILO Network configuration 
$Executable = '"C:\Program Files\HP\hponcfg\hponcfg.exe"' 
Invoke-VIAExe -Executable $Executable -Arguments "/f $RIBCLScriptFile" -Verbose
