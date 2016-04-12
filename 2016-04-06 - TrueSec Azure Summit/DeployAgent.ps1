Function Copy-MMAStandAloneSetupFiles{
    Param(
    $Servers,
    $TargetrootFolder,
    $SetupFolder,
    $CurrentFolder
    )
    foreach($Server in $Servers){
        New-Item -Path "\\$server\c$\$TargetrootFolder" -ItemType Directory -Force -Verbose
        Copy-Item $SetupFolder "\\$server\c$\$TargetrootFolder" -Force -Recurse -Verbose
    }
}
Function Install-MMAStandAloneAgent{
    Param(
    $Servers,
    $SetupFile,
    $SetupFolder,
    $CommandArgs,
    $TargetrootFolder
    )
    foreach($Server in $Servers){
        Invoke-Command -ComputerName $Server -ScriptBlock{
            Param($SetupFile,$SetupFolder,$CommandArgs,$TargetrootFolder,$WorkSpaceID,$WorkSpaceKey)
            if(Test-Path "C:\$TargetrootFolder\$SetupFolder\$SetupFile"){
                $Executable = "C:\$TargetrootFolder\$SetupFolder\$SetupFile"
                $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $CommandArgs -NoNewWindow -Wait -Passthru -Verbose
                Write-Verbose "Returncode from $Executable with $CommandArgs is $($ReturnFromEXE.ExitCode)" -Verbose
                }
                else
                {
                Write-Output "Sorry, could not find $Executable"
                }
            } -ArgumentList $SetupFile,($SetupFolder | Split-Path -Leaf),$CommandArgs,$TargetrootFolder
    }
}

#Set Vars
$Servers = "TSDC01"

#Copy the Setup file
$TargetrootFolder = "Install"
$SetupFolder = 'C:\DataCenterAgents\MMASetup'
Copy-MMAStandAloneSetupFiles -Servers $Servers -TargetrootFolder $TargetrootFolder -SetupFolder $SetupFolder
     
#install
$SetupFolder = "MMASetup"
$SetupFile = "MMASetup-AMD64.exe"
$WorkSpaceID = 'asfoasuoasudaoisud'
$WorkSpacePriKey = '3784qjsdla94wqfjw9rwjf9eefjse9fjslejf9jfspoejfspefjsp9eruspefjpso=='
$CommandArgs = "/C:""setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=$WorkSpaceID OPINSIGHTS_WORKSPACE_KEY=$WorkSpacePriKey AcceptEndUserLicenseAgreement=1"""
Install-MMAStandAloneAgent -Servers $Servers -SetupFile $SetupFile -SetupFolder $SetupFolder -CommandArgs $CommandArgs -TargetrootFolder $TargetrootFolder
