<#
    Powershell GenerateUAR Script
#>
$Host.UI.RawUI.WindowTitle = "GenerateUAR Script (elevated)"
cd $PSScriptRoot
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

<#
    Global config settings
#>
$UnifaceIDFPath = $ConfigFile.Settings.UnifaceIDFPath
$TFSToolPath = $ConfigFile.Settings.TFSToolPath
$TFSModelPath = $ConfigFile.Settings.TFSModelPath
$ModelArgs = $ConfigFile.Settings.ModelArgs
$ImportModels = $ConfigFile.Settings.ImportModels
$TempFileLocation = $ConfigFile.Settings.TempFileLocation

<#
    This script's config settings
#>
$TFSWorkspace = $ConfigFile.Settings.GenerateUARFile.TFSWorkspace
$MessageOld = $TempFileLocation + "\messagesgenerated.old"
$MessageNew =  $TempFileLocation + "\messagesgenerated.uar"
$MessageArgs = $ConfigFile.Settings.GenerateUARFile.MessageArgs
$ASNMessagePath = $ConfigFile.Settings.GenerateUARFile.ASNMessagePath
$INIGenerated = $ConfigFile.Settings.GenerateUARFile.INIGenerated
$ResourcesGenerated = $ConfigFile.Settings.GenerateUARFile.ResourcesGenerated
$ZipLocation = $ConfigFile.Settings.GenerateUARFile.ZipLocation
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
$WarningPreference = 'SilentlyContinue'
foreach ($Query in $QueryArray)
{
  write-host "$(get-date) $($Query)" -foreground "green"
  Invoke-Sqlcmd -ErrorAction silentlyContinue -WarningAction silentlyContinue -ServerInstance $theServer -Database $theDB -U $theUser -P $thePassword -Query $Query
}
$WarningPreference = 'Continue'

cd $TFSModelPath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Models" -foreground "green"
& $TFSToolPath get $ModelArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $ASNMessagePath
Convert-Path .
If (Test-Path $MessageOld)
{
  $itemtime = Get-Date
  write-host "$(get-date) Removing old backup UAR file" -foreground "green"
	Remove-Item $MessageOld -force
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
}
write-host "$(get-date) Copying messagesgenerated.uar to messagesgenerated.old" -foreground "green"
Copy-Item $TFSWorkspace\messagesgenerated.uar $MessageOld

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
& $ZipLocation a -tzip $MessageNew $ResourcesGenerated\ | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

write-host "$(get-date) Copying new messagesgenerated.uar to TFS checkin directory" -foreground "green"
Copy-Item $MessageNew $TFSWorkspace -force
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
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed -foreground "yellow"
write-host "Script Ended at $(get-date)" -foreground "green"
Write-Host "Press any key to continue ..." -foreground "magenta"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

