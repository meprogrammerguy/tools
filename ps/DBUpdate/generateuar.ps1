<#
    Powershell GenerateUAR Script
#>
$Host.UI.RawUI.WindowTitle = "GenerateUAR Script"
function GetElapsedTime([datetime]$starttime) 
{
    $runtime = $(get-date) - $starttime
    $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
    $retStr
}
clear
$script:startTime = Get-Date
$CurrentUser = [Environment]::UserName
$CurrentUser
[Environment]::UserDomainName
[Environment]::MachineName

Add-PSSnapin Microsoft.TeamFoundation.PowerShell
write-host "GenerateUAR Script Started at $script:startTime" -foreground "green"

[xml]$ConfigFile = Get-Content DBUpdate.xml

$OverrideDirectory = $ConfigFile.Settings.Users.$($CurrentUser).SettingsDirectory 
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
$UnifaceIDFPath = $ConfigFile.Settings.UnifaceIDFPath
$TFSWorkspace = $ConfigFile.Settings.GenerateUARFile.TFSWorkspace
$MessageOld = $TFSWorkspace + "\messagesgenerated.old"
$MessageNew =  $TFSWorkspace + "\messagesgenerated.uar"
$MessageArgs = $ConfigFile.Settings.GenerateUARFile.MessageArgs
$TFSModelPath = $ConfigFile.Settings.GenerateUARFile.TFSModelPath
$ModelArgs = $ConfigFile.Settings.GenerateUARFile.ModelArgs
$TFSToolPath = $ConfigFile.Settings.GenerateUARFile.TFSToolPath
$ImportModels = $ConfigFile.Settings.GenerateUARFile.ImportModels
$ASNPath = $ConfigFile.Settings.GenerateUARFile.ASNPath
$UARGeneratedFile = $ConfigFile.Settings.GenerateUARFile.UARGeneratedFile
$INIGenerated = $ConfigFile.Settings.GenerateUARFile.INIGenerated
$ResourcesGenerated = $ConfigFile.Settings.GenerateUARFile.ResourcesGenerated
$ZipLocation = $ConfigFile.Settings.GenerateUARFile.ZipLocation
$ZipArgs = $ConfigFile.Settings.GenerateUARFile.ZipArgs
$LogPath = $ConfigFile.Settings.GenerateUARFile.LogPath

$theServer = $ConfigFile.Settings.GenerateUARFile.SQLServer.Server
$theDB = $ConfigFile.Settings.GenerateUARFile.SQLServer.Database
$theUser = $ConfigFile.Settings.GenerateUARFile.SQLServer.User
$thePassword = $ConfigFile.Settings.GenerateUARFile.SQLServer.Password
$theTables =  $ConfigFile.Settings.GenerateUARFile.SQLServer.DropTableList

$Pieces = $theTables.split(",")
if ($Pieces[0] -gt "")
{
  $QueryArray = @()
	foreach ($Piece in $Pieces)
	{
		$Piece = $Piece.ToUpper()
		$QueryArray = $QueryArray + @("Drop table " + $Piece + ";")
	}
}

cd $TFSWorkspace
Convert-Path .

$LockTest = & $TFSToolPath status /user:* /format:detailed $MessageArgs
if ($LockTest -match "no pending")
{
  $itemtime = Get-Date
  write-host "$(get-date) Checking out the messagesgenerated.uar file" -foreground "green"
  & $TFSToolPath get $MessageArgs | Out-null
  & $TFSToolPath checkout $MessageArgs | Out-null
  $LockTest = & $TFSToolPath status /user:* /format:detailed $MessageArgs | Out-null
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
  Exit
}
$LockTest

cd $LogPath
Convert-Path .
write-host "$(get-date) Removing old uniface log files" -foreground "green"
foreach ($file in Get-ChildItem -name)
{
  if ($file -match $CurrentUser)
  {
    Remove-Item $file -force
  } 
}

write-host "$(get-date) Dropping tables" -foreground "green"
foreach ($Query in $QueryArray)
{
  write-host "$(get-date) $($Query)" -foreground "green"
  Invoke-Sqlcmd -ErrorAction silentlyContinue -WarningAction silentlyContinue -ServerInstance $theServer -Database $theDB -U $theUser -P $thePassword -Query $Query
}

cd $TFSModelPath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Models" -foreground "green"
& $TFSToolPath get $ModelArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $ASNPath
Convert-Path .
If (Test-Path $UARGeneratedFile)
{
  $itemtime = Get-Date
  write-host "$(get-date) Removing old UAR file" -foreground "green"
	Remove-Item $UARGeneratedFile -force
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
& $UnifaceIDFPath $INIGenerated /imp $ImportModels | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Analyizing Models" -foreground "green"
& $UnifaceIDFPath $INIGenerated /con | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Generating R, S and Y messages" -foreground "green"
& $UnifaceIDFPath $INIGenerated /tst gen_messages.aps RSY | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Generating UAR file" -foreground "green"
& $ZipLocation a -tzip $UARGeneratedFile $ResourcesGenerated\ | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"
If (Test-Path $MessageOld)
{
  write-host "$(get-date) Removing old UAR backup file" -foreground "green"
	Remove-Item $MessageOld -force
}
write-host "$(get-date) Renaming messagesgenerated.uar to messagesgenerated.old" -foreground "green"
Rename-Item $MessageNew messagesgenerated.old
write-host "$(get-date) Copying new messagesgenerated.uar to TFS checkin directory" -foreground "green"
Copy-Item $UARGeneratedFile $TFSWorkspace
$fileold = Get-Item $MessageOld
$filenew = Get-Item $MessageNew

cd $TFSWorkspace
Convert-Path .
if ($filenew.length -ge $fileold.length)
{
  $itemtime = Get-Date
  write-host "$(get-date) Checking in messagesgenerated.uar" -foreground "green"
  New-TfsChangeset -Item $MessageArgs -Verbose -Comment "Updated from DBUpdate script"
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
}
else
{
  $sizeIssue = "Old size: " + $fileold.length + " New size: " + $filenew.length
  write-host $sizeIssue -foreground "red"
  write-host "$(get-date) File size problem, undoing pending changes to messagesgenerated.uar" -foreground "red"
  & $TFSToolPath undo $MessageArgs | Out-null
}

cd $PSScriptRoot
Convert-Path .
write-host "Script Ended at $(get-date)" -foreground "green"
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed;
