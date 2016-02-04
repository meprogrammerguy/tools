<#
    Powershell DBUpdate script (Launches everything)
#>
$Host.UI.RawUI.WindowTitle = "DBUpdate Script - Launch everything"
<<<<<<< HEAD

cd $PSScriptRoot
=======
>>>>>>> 183db694bb4d5daf2524183bb07bd590297ea5e1
cmd /c start powershell -Command {.\RefreshCore.ps1}
cmd /c start powershell -Command {.\GenerateUAR.ps1}

