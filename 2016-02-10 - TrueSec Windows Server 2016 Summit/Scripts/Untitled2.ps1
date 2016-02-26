$Servers = 'LC-SRV-002','LC-SRV-003','LC-SRV-004','LC-SRV-005'
foreach($Server in $Servers)
{
    robocopy.exe C:\Setup\Scripts \\$SERVER\c$\Setup\Scripts /E /S
}

$Servers = 'LC-SRV-002','LC-SRV-003','LC-SRV-004','LC-SRV-005'
foreach($Server in $Servers)
{
    robocopy.exe C:\Setup\doc \\$SERVER\c$\Setup\doc /E /S
}