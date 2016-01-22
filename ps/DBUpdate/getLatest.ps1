Add-PSSnapin Microsoft.TeamFoundation.PowerShell
function GetElapsedTime([datetime]$starttime) 
{
    $runtime = $(get-date) - $starttime
    $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
    $retStr
}
$script:startTime = Get-Date
$TFSLocation = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$StateList = $PSScriptRoot + "\TFSStateList.txt"
write-host "Script Started at $script:startTime" -foreground "green"

cd H:\unicomp\CSCE\CS06\CS08.2.26\Components
Convert-Path .
$itemtime = Get-Date
& $TFSLocation get $CSCE\CS06\CS08.2.26\Components /recursive /preview
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $PSScriptRoot
Convert-Path .
write-host "Script Ended at $(get-date)" -foreground "green"
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed;