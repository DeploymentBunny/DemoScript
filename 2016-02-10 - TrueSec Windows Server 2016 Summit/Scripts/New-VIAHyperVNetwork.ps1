# Setting Variables
$TeamName = "Team1"
$SwitchName = "UpLinkSwitch" 

# Create Team
$AllNics = Get-NetAdapter | where Status -EQ Up
New-NetLbfoTeam $TeamName -TeamMembers $AllNics.name -TeamNicName $TeamName -Confirm:$false -Verbose

# Create Switch
New-VMSwitch -Name $SwitchName –NetAdapterName $TeamName –MinimumBandwidthMode Weight –AllowManagementOS $false -Verbose

# Create and Configure VMNic for Managment
$NicToConfigName = "Management"
Add-VMNetworkAdapter –ManagementOS –Name $NicToConfigName –SwitchName $SwitchName -Verbose
Set-VMNetworkAdapter –ManagementOS –Name $NicToConfigName –MinimumBandwidthWeight 5 -Verbose
