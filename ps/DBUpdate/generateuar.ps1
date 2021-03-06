<#
    Powershell GenerateUAR Script
#>
$Host.UI.RawUI.WindowTitle = "GenerateUAR Script (elevated)"
<#
    Adds the script snap ins and the SQL cmdlet module
#> 
Add-PSSnapin Microsoft.TeamFoundation.PowerShell -erroraction "silentlycontinue"
Import-Module SqlPs -DisableNameChecking
<#
    this function parses the directory filespec and makes it meaningful for the TFS tools arguments
#>
function GetTFSSource([string]$DriveSource) 
{
  $TFSSource = $DriveSource
  $Args = $TFSSource -replace "\\", "/"
  $Pieces = $Args.split("/")
  $TFSSource  = "$/" + $Pieces[2] + "/" + $Pieces[3] + "/" + $Pieces[4] + "/" + $Pieces[5]
  $TFSSource 
}
<#
    the elapsed time calculation function
#>
function GetElapsedTime([datetime]$starttime) 
{
  $runtime = $(get-date) - $starttime
  $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
  $retStr
}

$script:startTime = Get-Date
$CurrentUser = [Environment]::UserName
write-host "Current user: $CurrentUser" -foreground "yellow"
write-host "Current domain: $([Environment]::UserDomainName)" -foreground "yellow"
write-host "Current machine: $([Environment]::MachineName)" -foreground "yellow"

write-host "GenerateUAR Script Started at $script:startTime" -foreground "green"

<#
    Opens the settings file, looks into the ASNCore root folder for a settings file
    If it finds a settings file there then that file is used.
#>
cd $PSScriptRoot
[xml]$ConfigFile = Get-Content DBUpdate.xml
$CoreVersion = $ConfigFile.Settings.CoreVersion
$Pieces = $CoreVersion.split(".")
$MajorVersion = $Pieces[0]
$MinorVersion = $Pieces[1]
$ReleaseVersion = $Pieces[2]
$PDriveRoot = $ConfigFile.Settings.PDriveRoot + $MajorVersion + "\" + $MinorVersion + "." + $ReleaseVersion
$OverrideConfig = $PDriveRoot + "\" + $ConfigFile.Settings.ASNCoreFolder + "\" + $MinorVersion + "." + $ReleaseVersion + "\DBUpdate.xml"
if (-Not(Test-Path $OverrideConfig))
{
  write-host "settings from $($PSScriptRoot)\DBUpdate.xml" -foreground "yellow"
}
else
{
	write-host "settings from $($OverrideConfig)" -foreground "yellow"
	[xml]$ConfigFile = Get-Content $OverrideConfig
}

<#
    Networked drive mappings
    Here is where the H:\, P:\ and T:\ drives are tested and set from the script (if they are not yet set up)
#>
if (-Not (Test-Path h:))
{
  $UserHDrive = $ConfigFile.Settings.Network.User.$($CurrentUser).HDrive
  if ($UserHDrive -gt "")
  {
    & net use h: $UserHDrive /persist:yes
  }
  if (-Not (Test-Path h:))
  {
    $WarnSetup = "network H:\ Does not exist, You need to set this up first (New version?)"
    write-host $WarnSetup -foreground "red"
    Exit
  }
}

if (-Not (Test-Path p:))
{
  $UserPDrive = $ConfigFile.Settings.Network.PDrive
  if ($UserPDrive -gt "")
  {
    & net use p: $UserPDrive /persist:yes
  }
  if (-Not (Test-Path p:))
  {
    $WarnSetup = "network P:\ Does not exist, You need to set this up first (New version?)"
    write-host $WarnSetup -foreground "red"
    Exit
  }
}

if (-Not (Test-Path t:))
{
  $UserTDrive = $ConfigFile.Settings.Network.TDrive
  if ($UserTDrive -gt "")
  {
    & net use t: $UserTDrive /persist:yes
  }
  if (-Not (Test-Path t:))
  {
    $WarnSetup = "network T:\ Does not exist, You need to set this up first (New version?)"
    write-host $WarnSetup -foreground "red"
    Exit
  }
}
$CoreVersion = $ConfigFile.Settings.CoreVersion
$Pieces = $CoreVersion.split(".")
$MajorVersion = $Pieces[0]
$MinorVersion = $Pieces[1]
$ReleaseVersion = $Pieces[2]

write-host "Core version: $($MajorVersion) $($MinorVersion).$($ReleaseVersion)" -foreground "magenta"

<#
    Global config settings
    if the tools or the directories are not found the script will warn and stop
#>
$UnifaceIDFPath = $ConfigFile.Settings.UnifaceIDFPath
if (-Not (Test-Path $UnifaceIDFPath))
{
  $WarnSetup = $UnifaceIDFPath + " Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$TFSToolPath = $ConfigFile.Settings.TFSToolPath
if (-Not (Test-Path $TFSToolPath))
{
  $WarnSetup = $TFSToolPath + " Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
<#
    This code is because v3 and v2 have different directory naming conventions for the H:\ drive
#>
$HDriveRoot2 = $MajorVersion

$TFSPath = $ConfigFile.Settings.HDriveRoot + $HDriveRoot2 + "\" + $MinorVersion + "." + $ReleaseVersion + "\"
$TFSModelPath = $TFSPath + $ConfigFile.Settings.TFSModelFolder
$ModelArgs = GetTFSSource $TFSModelPath
$ImportModels = "XML:" + $TFSModelPath + "\*." + $ConfigFile.Settings.TFSModelExtension

$TranslatePath = $ConfigFile.Settings.GenerateUARFile.TranslateModels
$TranslateArgs = GetTFSSource $TranslatePath
$TranslateModels = "XML:" + $TranslatePath + "*." + $ConfigFile.Settings.TFSModelExtension

<#
    This script's config settings
#>
$ASNMessagePath = $PDriveRoot + "\" + $ConfigFile.Settings.GenerateUARFile.ASNMessageFolder
$TFSWorkspace = $TFSPath + $ConfigFile.Settings.GenerateUARFile.WorkspaceFolder
if (-Not (Test-Path $TFSWorkspace))
{
  $WarnSetup = $TFSWorkspace + " Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$TempFileLocation = $ASNMessagePath + "\"+ $ConfigFile.Settings.TempFileFolder + "\"
if (-Not (Test-Path $TempFileLocation))
{
  $WarnSetup = $TempFileLocation + " Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$MessageOld = $TempFileLocation + "\messagesgenerated.old"
$MessageNew =  $TempFileLocation + "\messagesgenerated.uar"
$MessageArgs = GetTFSSource $TFSPath
$MessageArgs = $MessageArgs + $ConfigFile.Settings.GenerateUARFile.MessageArgs
$INIMessageLocation = "/ini=" + $ConfigFile.Settings.PDriveRoot + $MajorVersion + "\" + $ConfigFile.Settings.GenerateUARFile.INIMessageLocation
$ResourcesGenerated = $ASNMessagePath + "\" + $MinorVersion + "." + $ReleaseVersion + "\" + $ConfigFile.Settings.GenerateUARFile.ResourcesGeneratedFolder
$ResourcesCore = $PDriveRoot + "\" + $ConfigFile.Settings.GenerateUARFile.ResourcesGeneratedFolder
$ZipLocation = $PDriveRoot + "\" + $ConfigFile.Settings.ToolFolder + "\" + $ConfigFile.Settings.GenerateUARFile.ZipName
if (-Not (Test-Path $ZipLocation))
{
  $WarnSetup = $ZipLocation + " Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$LogPath = $ASNMessagePath + "\" + $ConfigFile.Settings.GenerateUARFile.LogFolder + "\"
<#
    SQLserver settings used by the Invoke-Sqlcmd cmdlet
#>
$theServer = $ConfigFile.Settings.GenerateUARFile.SQLServer.Server
$theDB = $ConfigFile.Settings.GenerateUARFile.SQLServer.Database2x
if ($MajorVersion -eq "CSV3")
{
  $theDB = $ConfigFile.Settings.GenerateUARFile.SQLServer.Database3x
}
$theUser = $ConfigFile.Settings.GenerateUARFile.SQLServer.User
$thePassword = $ConfigFile.Settings.GenerateUARFile.SQLServer.Password
$theTables =  $ConfigFile.Settings.GenerateUARFile.SQLServer.DeleteTableList
$LockTable = $ConfigFile.Settings.GenerateUARFile.SQLServer.LockTable
$LockKey = $ConfigFile.Settings.GenerateUARFile.SQLServer.LockKey
$LockKeyValue = $ConfigFile.Settings.GenerateUARFile.SQLServer.LockKeyValue
$LockWho = $ConfigFile.Settings.GenerateUARFile.SQLServer.LockWho
$LockQuery = "select " + $LockWho + " from " + $LockTable + " where " + $LockKey + " = '" + $LockKeyValue + "'"
$LockDelete = "delete from " + $LockTable + " where "+ $LockKey + " = '" + $LockKeyValue + "'"

$Pieces = $theTables.split(",")
if ($Pieces[0] -gt "")
{
  $QueryArray = @()
	foreach ($Piece in $Pieces)
	{
		$Piece = $Piece.ToUpper()
		$QueryArray = $QueryArray + @("Delete from " + $Piece + ";")
	}
}

<#
    Checks The Lock file And Bail if someone else is Generating messages (in any release)
#>
write-host "$(get-date) Checking the Lock File" -foreground "green"
$WarningPreference = 'SilentlyContinue'
write-host "$(get-date) $($LockQuery)" -foreground "green"
$LockTest = Invoke-Sqlcmd -ErrorAction silentlyContinue -WarningAction silentlyContinue -ServerInstance $theServer -Database $theDB -U $theUser -P $thePassword -Query $LockQuery
$WarningPreference = 'Continue'
if ($LockTest.length -gt 1)
{
  $itemtime = Get-Date
  write-host "$(get-date) Someone is currently generating messages - exiting now" -foreground "red"
  write-host ($LockTest | Format-Table | Out-String)
  cd $PSScriptRoot
  Convert-Path .
  write-host "Script Ended at $(get-date)" -foreground "red"
  $elapsed = GetElapsedTime $script:startTime
  write-host "Total Elapsed Time: " $elapsed;
  Exit
}

<#
    This section tries to check out the messagesgenerated file. If it is already locked the script shows
    who, and stops. If it can lock the file it begins running 
#>
cd $TFSWorkspace
Convert-Path .
$LockTest = & $TFSToolPath status /user:* /format:detailed $MessageArgs
if ($LockTest -match "no pending")
{
  $itemtime = Get-Date
  write-host "$(get-date) Checking out the messagesgenerated.uar file" -foreground "green"
  & $TFSToolPath get /force $MessageArgs | Out-null
  & $TFSToolPath checkout $MessageArgs | Out-null
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
$LockTest = & $TFSToolPath status /user:* /format:detailed $MessageArgs
$LockTest
<#
    Inserts The user currently running into the Lock file and continue
#>
write-host "$(get-date) Inserting user into the Lock File" -foreground "green"
$WarningPreference = 'SilentlyContinue'
$LockQuery = "insert into " + $LockTable + " values ('" + $LockKeyValue + "','" + $LockTest + "')"
Invoke-Sqlcmd -ErrorAction silentlyContinue -WarningAction silentlyContinue -ServerInstance $theServer -Database $theDB -U $theUser -P $thePassword -Query $LockQuery
$WarningPreference = 'Continue'

<#
    cleans up old log files (based on your user name)
#>
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
<#
    Delete from tables from <DeleteTableList> found in XML settings file
    These columns are deleted so old stuff is not there (uniface "never" deletes)
#>
write-host "$(get-date) Deleting from tables" -foreground "green"
$WarningPreference = 'SilentlyContinue'
foreach ($Query in $QueryArray)
{
  write-host "$(get-date) $($Query)" -foreground "green"
  Invoke-Sqlcmd -ErrorAction silentlyContinue -WarningAction silentlyContinue -ServerInstance $theServer -Database $theDB -U $theUser -P $thePassword -Query $Query
}
$WarningPreference = 'Continue'
<#
    gets latest models from TFS does a /force to always get the latest
#>
cd $TFSModelPath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Models" -foreground "green"
& $TFSToolPath get /force $ModelArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

<#
    gets latest translation models from TFS does a /force to always get the latest
#>
cd $TranslatePath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Translation Models" -foreground "green"
& $TFSToolPath get /force $TranslateArgs | Out-null
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
<#
    removes the resources folder
#>
If (Test-Path $ResourcesGenerated)
{
  $itemtime = Get-Date
  write-host "$(get-date) Removing old msg files" -foreground "green"
  rm -r $ResourcesGenerated
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
}
<#
    Import, analyze of the models and regenerating the messages
#>
$itemtime = Get-Date
write-host "$(get-date) Importing Models" -foreground "green"
& $UnifaceIDFPath $INIMessageLocation /imp $ImportModels | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Importing Translation Models" -foreground "green"
& $UnifaceIDFPath $INIMessageLocation /imp $TranslateModels | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Analyzing Models" -foreground "green"
& $UnifaceIDFPath $INIMessageLocation /con /war | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

$itemtime = Get-Date
write-host "$(get-date) Generating R, S and Y messages" -foreground "green"
& $UnifaceIDFPath $INIMessageLocation /tst gen_messages.aps RSY | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

<#
    kicking off the LoadUCData script
#>
cd $PSScriptRoot
Convert-Path .
cmd /c start powershell -Command {.\LoadUCData.ps1}

<#
    zipping up the resources\msg folder into messagesgenerated.uar
#>
$itemtime = Get-Date
write-host "$(get-date) Generating UAR (zip) file" -foreground "green"
& $ZipLocation a -aoa -tzip $MessageNew $ResourcesGenerated\ | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

write-host "$(get-date) Copying new messagesgenerated.uar to TFS checkin directory" -foreground "green"
Copy-Item $MessageNew $TFSWorkspace -force
$fileold = Get-Item $MessageOld
$filenew = Get-Item $MessageNew

<#
    this is where the messagesgenerated file is checked into TFS. 
    If the new file is smaller than the old file the file will not be checked in (you can do this by hand if you are sure everything is ok, first)
#>
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
<#
    Deletes The user currently running from the Lock file
#>
write-host "$(get-date) Deleting user From the Lock File" -foreground "green"
$WarningPreference = 'SilentlyContinue'
Invoke-Sqlcmd -ErrorAction silentlyContinue -WarningAction silentlyContinue -ServerInstance $theServer -Database $theDB -U $theUser -P $thePassword -Query $LockDelete
$WarningPreference = 'Continue'
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed -foreground "yellow"
write-host "Script Ended at $(get-date)" -foreground "green"
Write-Host "Press any key to continue ..." -foreground "magenta"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

