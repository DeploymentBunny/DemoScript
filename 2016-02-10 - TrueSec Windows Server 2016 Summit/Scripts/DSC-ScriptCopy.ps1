Get-DscResource

Configuration CopyScriptSource
{
    Param
    (
        [string[]]$ComputerName = 'localhost',
        [string]$SourceFolder,
        [string]$DestinationFolder
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node $ComputerName
    {
        File DirectoryCopy
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            Recurse = $true # Ensure presence of subdirectories, too
            SourcePath = $SourceFolder
            DestinationPath = $DestinationFolder
        }
    }
}

CopyScriptSource -ComputerName "TCLHOST02","TCLHOST03" -SourceFolder "\\TCLHOST01\Setup" -DestinationFolder "C:\Setup" -Verbose -OutputPath C:\Setup\ScriptSurce
Start-DscConfiguration -Wait -Verbose -Path C:\Setup\ScriptSurce

