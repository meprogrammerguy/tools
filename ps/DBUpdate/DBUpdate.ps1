<#
    Powershell DBUpdate script (Launches everything)
#>
$Host.UI.RawUI.WindowTitle = "DBUpdate Script - Launch everything"

cd $PSScriptRoot
cmd /c start powershell -Command {.\RefreshCore.ps1}
cmd /c start powershell -Command {.\GenerateUAR.ps1}

