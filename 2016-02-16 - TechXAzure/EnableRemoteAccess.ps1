#Enable Remote Access
New-NetFirewallRule -DisplayName "RemoteConfigRule" -Name "RemoteConfigRule" -Group "@FirewallAPI.dll,-30267" -Enabled True -Profile Any -Direction Inbound -Action Allow
Enable-PSRemoting -Force
Restart-Service -Name WinRM -Force
#Add-Computer -ComputerName $env:COMPUTERNAME -DomainName "cloud.truesec.com" -OUPath "OU=Demo,OU=Server,OU=Cloud,DC=cloud,DC=truesec,DC=com" -Restart