<#
    Powershell LoadUCData script
#>
function GetElapsedTime([datetime]$starttime) 
{
    $runtime = $(get-date) - $starttime
    $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
    $retStr
}
clear
$script:startTime = Get-Date
write-host "LoadUCData Script Started at $script:startTime" -foreground "green"

[xml]$ConfigFile = Get-Content DBUpdate.xml
$OverrideDirectory = $ConfigFile.Settings.Users.$([Environment]::UserName).SettingsDirectory 
if ($OverrideDirectory -ne "")
{
	$OverrideDirectory = $OverrideDirectory + "DBUpdate.xml"
	write-host "settings from $($OverrideDirectory)" -foreground "yellow"
	[xml]$ConfigFile = Get-Content $OverrideDirectory
}
else
{
	write-host "settings from DBUpdate.xml" -foreground "yellow"
}
$ASNFileDirectory = $ConfigFile.Settings.LoadUCData.ASNFileDirectory
$ASNFileFileName = $ConfigFile.Settings.LoadUCData.ASNFileName
$LoadUCDataTool = $ConfigFile.Settings.LoadUCData.LoadUCDataTool
$LoadUCDataFile = $ConfigFile.Settings.LoadUCData.LoadUCDataFile
$TempFileLocation = $ConfigFile.Settings.LoadUCData.TempFileLocation

$LoadUCDataOld = $TempFileLocation + "LoadUCData.old"
$LoadUCDataASN = $ASNFileDirectory + $ASNFileFileName
$LoadUCDataTempFile = $TempFileLocation + "LoadUCData.sql"

cd $ASNFileDirectory
Convert-Path .
If (Test-Path $LoadUCDataOld)
{
	write-host "$(get-date) Removing old LoadUCData file" -foreground "green"
	Remove-Item $LoadUCDataOld -force
}
If (Test-Path $LoadUCDataFile)
{
	write-host "$(get-date) Renaming LoadUCData.sql to LoadUCData.old" -foreground "green"
	Rename-Item $LoadUCDataFile $LoadUCDataOld
}
$itemtime = Get-Date
write-host "$(get-date) Generating LoadUCData.sql (oracle DB only)" -foreground "green"
$outputTool = & $LoadUCDataTool ora, $LoadUCDataASN, $LoadUCDataTempFile
$outputTool
if ($outputTool -match "error")
{
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "red"
}
else
{
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
  If (Test-Path $LoadUCDataFile)
  {
    write-host "$(get-date) Removing production LoadUCData file" -foreground "green"
    Remove-Item $LoadUCDataFile -force
  }
  write-host "$(get-date) Copying LoadUCData.sql to production" -foreground "green"
  Copy-Item $LoadUCDataTempFile $LoadUCDataFile
}

cd $PSScriptRoot
Convert-Path .
write-host "Script Ended at $(get-date)" -foreground "green"
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed;
