#Install HyperV
$Servers = "TCLHOST01","TCLHOST02","TCLHOST03"
Foreach($Server in $Servers){
    Add-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools -ComputerName $Server
}

$Servers = "TCLHOST02","TCLHOST03"
Restart-Computer -ComputerName "TCLHOST02","TCLHOST03" -Force

$Servers = "TCLHOST02","TCLHOST03"
Foreach($Server in $Servers){
    Do{}until((Test-NetConnection -ComputerName $Server -CommonTCPPort RDP).TcpTestSucceeded) 
}

$Servers = "TCLHOST01","TCLHOST02","TCLHOST03"
Foreach($Server in $Servers){
    Invoke-Command -ComputerName $Server -ScriptBlock {
        Get-NetLbfoTeam | Remove-NetLbfoTeam
    }
}

$Servers = "TCLHOST01","TCLHOST02","TCLHOST03"
foreach($Server  in $Servers){
    robocopy.exe C:\Setup\ \\$Server\c$\Setup /s 
}

