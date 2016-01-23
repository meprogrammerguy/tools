<#
    Powershell Config Testing script
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

$AsnLocation
$LoadUCDataLocation
$LoadUCDataFile
$LoadUCDataTempFile
$LoadUCDataOld
$LoadUCDataASN
$LoadUCDataArgs

cd $PSScriptRoot
Convert-Path .
write-host "Script Ended at $(get-date)" -foreground "green"
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed;
