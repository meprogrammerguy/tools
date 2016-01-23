<#
    Powershell Config Testing script
#>
[xml]$ConfigFile = Get-Content "D:\DBUpdate\settings\DBUpdate.xml"
$ASNFileDirectory = $ConfigFile.Settings.LoadUCData.ASNFileDirectory
write-host $ASNFileDirectory -foreground "green"
$ASNFileFileName = $ConfigFile.Settings.LoadUCData.ASNFileName
write-host $ASNFileFileName -foreground "green"
$LoadUCDataTool = $ConfigFile.Settings.LoadUCData.LoadUCDataTool
write-host $LoadUCDataTool -foreground "green"
$LoadUCDataFile = $ConfigFile.Settings.LoadUCData.LoadUCDataFile
write-host $LoadUCDataFile -foreground "green"
$TempFileLocation = $ConfigFile.Settings.LoadUCData.TempFileLocation
write-host $TempFileLocation -foreground "green"





