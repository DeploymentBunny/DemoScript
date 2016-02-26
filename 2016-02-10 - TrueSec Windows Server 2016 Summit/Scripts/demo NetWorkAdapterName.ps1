$cred = Get-Credential
$VM = Get-VM -Name TCLVM01

Invoke-Command -VMName $VM.Name -ScriptBlock {
    $env:COMPUTERNAME
    Get-NetAdapter
} -Credential $cred

Add-VMNetworkAdapter -VMName $vm.Name -SwitchName UplinkSwitch -Name Markus -DeviceNaming On

Invoke-Command -VMName $VM.Name -ScriptBlock {
    $env:COMPUTERNAME
    Get-NetAdapter
} -Credential $cred


Invoke-Command -VMName $VM.Name -ScriptBlock {
    $env:COMPUTERNAME
    Get-NetAdapterAdvancedProperty -Name * | Where-Object -FilterScript {$_.DisplayValue -LIKE "Markus”}
} -Credential $cred

Invoke-Command -VMName $VM.Name -ScriptBlock {
    $env:COMPUTERNAME
    $Nic = Get-NetAdapterAdvancedProperty -Name * | Where-Object -FilterScript {$_.DisplayValue -LIKE "Markus”}
    $Nic.InterfaceAlias
} -Credential $cred
