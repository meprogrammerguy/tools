<#
    Powershell DBUpdate
#>
clear
$UnifaceIDFLocation = "T:\UNIFACE\U9605\X505\common\BIN\idf.exe"
$CSMessageLocation = "d:\messages"
$CDMessageOld = $CSMessageLocation + "\messagesgenerated.old"
$CDMessageNew =  $CSMessageLocation + "\messagesgenerated.uar"
$CSMessageArgs = "$/CSCE/CS06/CS08.2.27/USYS/messagesgenerated.uar" 
$CSModelLocation = "H:\unicomp\CSCE\CS06\CS08.2.27\Models"
$CSModelArgs = "$/CSCE/CS06/CS08.2.27/USYS/Models"
$TFSLocation = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$ImportModels = "XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Models\*.xml"
$AsnGenerated = "D:\DBUpdate\MessagesGenerated_v2\"
$URRGenerated = "D:\DBUpdate\MessagesGenerated_v2\messagesgenerated.uar"
$INIGenerated = "/ini=D:\DBUpdate\MessagesGenerated_v2\idf96.ini"
$ResourcesGenerated = "D:\DBUpdate\MessagesGenerated_v2\resources\msg"
$ZipLocation = "D:\DBUpdate\MessagesGenerated_v2\7za.exe"
$ZipArgs = "a -tzip "
$GeneratedLogs = "D:\DBUpdate\MessagesGenerated_v2\Logs\"
$CurrentUser = [Environment]::UserName
function GetElapsedTime([datetime]$starttime) 
{
    $runtime = $(get-date) - $starttime
    $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
    $retStr
}

$script:startTime = Get-Date
[Environment]::UserName
[Environment]::UserDomainName
[Environment]::MachineName
Add-PSSnapin Microsoft.TeamFoundation.PowerShell
write-host "Script Started at $script:startTime" -foreground "green"

cd $CSMessageLocation
Convert-Path .
$LockTest = & $TFSLocation status /user:* /format:detailed $CSMessageArgs
if ($LockTest -match "no pending")
{
  $itemtime = Get-Date
  write-host "$(get-date) Checking out the messagesgenerated.uar file" -foreground "green"
  & $TFSLocation get $CSMessageArgs | Out-null
<#
  & $TFSLocation checkout $CSMessageArgs | Out-null
#>
  $LockTest = & $TFSLocation status /user:* /format:detailed $CSMessageArgs | Out-null
}
else
{
  $itemtime = Get-Date
  write-host "$(get-date) Someone is currently generating messages - exiting now" -foreground "red"
  $LockTest
  cd $PSScriptRoot
  Convert-Path .
  write-host "Script Ended at $(get-date)" -foreground "red"
  $elapsed = GetElapsedTime $script:startTime
  write-host "Total Elapsed Time: " $elapsed;
<#
  Exit
#>
}
$LockTest

cd $GeneratedLogs
Convert-Path .
write-host "$(get-date) Removing old uniface log files" -foreground "green"
foreach ($file in Get-ChildItem -name)
{
  if ($file -match $CurrentUser)
  {
    Remove-Item $file -force
  } 
}

cd $CSModelLocation
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Models" -foreground "green"
& $TFSLocation get $CSModelArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $ASNGenerated
Convert-Path .
If (Test-Path $URRGenerated)
{
  $itemtime = Get-Date
  write-host "$(get-date) Removing old UAR file" -foreground "green"
	Remove-Item $URRGenerated -force
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
}

If (Test-Path $ResourcesGenerated)
{
  $itemtime = Get-Date
  write-host "$(get-date) Removing old msg files" -foreground "green"
  rm -r $ResourcesGenerated
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
}

$itemtime = Get-Date
write-host "$(get-date) Importing Models" -foreground "green"
& $UnifaceIDFLocation $INIGenerated /imp $ImportModels | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Analyizing Models" -foreground "green"
& $UnifaceIDFLocation $INIGenerated /con | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Generating R, S and Y messages" -foreground "green"
& $UnifaceIDFLocation $INIGenerated /tst gen_messages.aps RSY | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Generating UAR file" -foreground "green"
& $ZipLocation a -tzip $URRGenerated $ResourcesGenerated\ | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"
If (Test-Path $CDMessageOld)
{
  write-host "$(get-date) Removing old UAR backup file" -foreground "green"
	Remove-Item $CDMessageOld -force
}
write-host "$(get-date) Renaming messagesgenerated.uar to messagesgenerated.old" -foreground "green"
Rename-Item $CDMessageNew messagesgenerated.old
write-host "$(get-date) Copying new messagesgenerated.uar to TFS checkin directory" -foreground "green"
Copy-Item $URRGenerated $CSMessageLocation
$fileold = Get-Item $CDMessageOld
$filenew = Get-Item $CDMessageNew

if ($filenew.length -gt $fileold.length)
{
  cd $CSMessageLocation
  Convert-Path .
  $itemtime = Get-Date
  write-host "$(get-date) Checking in messagesgenerated.uar" -foreground "green"
  New-TfsChangeset -Item $CSMessageArgs -Verbose -Comment "Updated from DBUpdate script" -Override false
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
}
else
{
  write-host "$(get-date) File size problem, undoing pending changes to messagesgenerated.uar" -foreground "red"
  & $TFSLocation undo $CSMessageArgs | Out-null
}

cd $PSScriptRoot
Convert-Path .
write-host "Script Ended at $(get-date)" -foreground "green"
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed;
