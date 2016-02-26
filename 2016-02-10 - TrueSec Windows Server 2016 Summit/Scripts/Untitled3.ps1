$Cred = Get-Credential
Invoke-Command -VMName (Get-VM -Name DC01).Name -ScriptBlock {
$IFAlias = (Get-NetAdapter).InterfaceAlias
New-NetIPAddress -IPAddress 192.168.1.200 -InterfaceAlias $IFAlias -DefaultGateway 192.168.1.1 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias $IFAlias -ServerAddresses 8.8.8.8
Test-NetConnection
} -Credential $Cred


Invoke-Command -VMName (Get-VM -Name DC01).Name -ScriptBlock {
whoami /priv
} -Credential $Cred


Invoke-Command -VMName (Get-VM -Name DC01).Name -ScriptBlock {
Test-NetConnection
} -Credential $Cred

