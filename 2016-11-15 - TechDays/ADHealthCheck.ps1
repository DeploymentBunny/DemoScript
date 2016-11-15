$getForest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()
$DCServers = $getForest.domains | ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name} 

foreach ($DCServer in $DCServers){
    Write-Host "Checking netaccess to $DCServer" -ForegroundColor Green
    Test-Connection -ComputerName $DCServer

    Write-Host "Checking Services that should be running on $DCServer" -ForegroundColor Green
    Invoke-Command -ComputerName $DCServer -ScriptBlock {
        $Services = Get-Service
        Foreach($Service in $Services | Where-Object -Property StartType -EQ Automatic){
            $Service | Where-Object -Property Status -NE -Value Running
            }
    }

    Write-Host "Running DCDiag on $DCServer" -ForegroundColor Green
    Invoke-Command -ComputerName $DCServer -ScriptBlock {
        dcdiag.exe /test:netlogons /Q
        dcdiag.exe /test:Services /Q
        dcdiag.exe /test:Advertising /Q
        dcdiag.exe /test:FSMOCheck /Q
    }

    Write-Host "Checking access to SYSVOL on $DCServer" -ForegroundColor Green
    Test-Path -Path \\$DCServer\sysvol


    Write-Host "Running BPA on $DCServer" -ForegroundColor Green
    Invoke-Command -ComputerName $DCServer -ScriptBlock {
        $BPA = "Microsoft/Windows/DirectoryServices"
        Invoke-BpaModel -BestPracticesModelId $BPA
        Get-BpaResult -ModelID $BPA -Filter Noncompliant | Select-Object ResultNumber,Severity,Category,Title,Problem,Impact,Resolution
    }
}
