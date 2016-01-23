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
write-host "Script Started at $script:startTime" -foreground "green"

$AsnLocation = "D:\DBUpdate\Devo_v2\"
$LoadUCDataLocation = $AsnLocation  + "loaducdata.exe"
$LoadUCDataFile = "P:\CS08_2X\CS08_2_27\UTILS\LoadUCData.sql"
$LoadUCDataTempFile = $AsnLocation  + "LoadUCData.sql"
$LoadUCDataOld = $AsnLocation  + "LoadUCData.old"
$LoadUCDataASN = $AsnLocation + "idf.asn"
$LoadUCDataArgs = $LoadUCDataASN + "," + $LoadUCDataFile

cd $AsnLocation
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
$outputTool = & $LoadUCDataLocation ora, $LoadUCDataASN, $LoadUCDataTempFile
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
