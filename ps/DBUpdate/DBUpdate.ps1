<#
    Powershell DBUpdate script (Launches everything)
#>
$Host.UI.RawUI.WindowTitle = "DBUpdate Script - Launch everything"

cmd /c start powershell -Command {.\RefreshCore.ps1}

<#
cmd /c start powershell -Command {.\GenerateUAR.ps1}
#>
