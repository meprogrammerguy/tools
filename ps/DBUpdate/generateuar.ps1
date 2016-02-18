<#
    Powershell GenerateUAR Script
#>
$Host.UI.RawUI.WindowTitle = "GenerateUAR Script (elevated)"
Add-PSSnapin Microsoft.TeamFoundation.PowerShell -erroraction "silentlycontinue"
Import-Module SqlPs -DisableNameChecking

function GetTFSSource([string]$DriveSource) 
{
  $TFSSource = $DriveSource
  $Args = $TFSSource -replace "\\", "/"
  $Pieces = $Args.split("/")
  $TFSSource  = "$/" + $Pieces[2] + "/" + $Pieces[3] + "/" + $Pieces[4] + "/" + $Pieces[5]
  $TFSSource 
}

function GetElapsedTime([datetime]$starttime) 
{
  $runtime = $(get-date) - $starttime
  $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
  $retStr
}

$script:startTime = Get-Date
$CurrentUser = [Environment]::UserName
$CurrentUser
[Environment]::UserDomainName
[Environment]::MachineName

write-host "GenerateUAR Script Started at $script:startTime" -foreground "green"

cd $PSScriptRoot
[xml]$ConfigFile = Get-Content DBUpdate.xml
$CoreVersion = $ConfigFile.Settings.CoreVersion
$Pieces = $CoreVersion.split(".")
if ($Pieces[1].Length -eq "")
{
  $Pieces = $CoreVersion.split("_")
}
$MajorVersion = $Pieces[0]
$MinorVersion = $Pieces[1]
$OverrideConfig = $ConfigFile.Settings.ASNCoreRoot + $MajorVersion + "_" + $MinorVersion + "\DBUpdate.xml"
if (-Not(Test-Path $OverrideConfig))
{
  write-host "settings from $($PSScriptRoot)\DBUpdate.xml" -foreground "yellow"
}
else
{
	write-host "settings from $($OverrideConfig)" -foreground "yellow"
	[xml]$ConfigFile = Get-Content $OverrideConfig
}
$CoreVersion = $ConfigFile.Settings.CoreVersion
$Pieces = $CoreVersion.split(".")
if ($Pieces[1].Length -eq "")
{
  $Pieces = $CoreVersion.split("_")
}
$MajorVersion = $Pieces[0]
$MinorVersion = $Pieces[1]

write-host "Core version: $($MajorVersion).$($MinorVersion)" -foreground "magenta"

<#
    Global config settings
#>
$UnifaceIDFPath = $ConfigFile.Settings.UnifaceIDFPath
if (-Not (Test-Path $UnifaceIDFPath))
{
  $WarnSetup = $UnifaceIDFPath + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$TFSToolPath = $ConfigFile.Settings.TFSToolPath
if (-Not (Test-Path $TFSToolPath))
{
  $WarnSetup = $TFSToolPath + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$HDriveSeparator = "."
$HDriveRoot2 = "CS06"
if ($MajorVersion -eq "3")
{
  $HDriveSeparator = "_"
  $HDriveRoot2 = "CSPV6"
}
$TFSPath = $ConfigFile.Settings.HDriveRoot + $HDriveRoot2 + "\CS08" + $HDriveSeparator + $MajorVersion + $HDriveSeparator + $MinorVersion + "\"
$TFSModelPath = $TFSPath + $ConfigFile.Settings.TFSModelFolder
$ModelArgs = GetTFSSource $TFSModelPath
$ImportModels = "XML:" + $TFSModelPath + "\*." + $ConfigFile.Settings.TFSModelExtension
$TempFileLocation = $ConfigFile.Settings.TempFileLocation
if (-Not (Test-Path $TempFileLocation))
{
  $WarnSetup = $TempFileLocation + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}

<#
    This script's config settings
#>
$TFSWorkspace = $ConfigFile.Settings.GenerateUARFile.TFSWorkspaceRoot + $MajorVersion + "_" + $MinorVersion + "\"
if (-Not (Test-Path $TFSWorkspace))
{
  $WarnSetup = $TFSWorkspace + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$MessageOld = $TempFileLocation + "\messagesgenerated.old"
$MessageNew =  $TempFileLocation + "\messagesgenerated.uar"
$MessageArgs = GetTFSSource $TFSPath
$MessageArgs = $MessageArgs + $ConfigFile.Settings.GenerateUARFile.MessageArgs
$ASNMessagePath = $ConfigFile.Settings.GenerateUARFile.ASNMessagePath
$INIMessageLocation = "/ini=" + $ConfigFile.Settings.PDriveRoot + $MajorVersion + "X\" + $ConfigFile.Settings.GenerateUARFile.INIMessageLocation
$ResourcesGenerated = $ConfigFile.Settings.GenerateUARFile.ResourcesGenerated
$ZipLocation = $ConfigFile.Settings.GenerateUARFile.ZipLocation
if (-Not (Test-Path $ZipLocation))
{
  $WarnSetup = $ZipLocation + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
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
  & $TFSToolPath get /force $MessageArgs | Out-null
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
& $TFSToolPath get /force $ModelArgs | Out-null
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
& $UnifaceIDFPath $INIMessageLocation /imp $ImportModels | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Analyizing Models" -foreground "green"
& $UnifaceIDFPath $INIMessageLocation /con | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Generating R, S and Y messages" -foreground "green"
& $UnifaceIDFPath $INIMessageLocation /tst gen_messages.aps RSY | Out-null
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

