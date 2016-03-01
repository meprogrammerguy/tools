<#
    Powershell LoadUCData script
#>
$Host.UI.RawUI.WindowTitle = "LoadUCData Script"

function GetElapsedTime([datetime]$starttime) 
{
  $runtime = $(get-date) - $starttime
  $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
  $retStr
}
$script:startTime = Get-Date
write-host "LoadUCData Script Started at $script:startTime" -foreground "green"

cd $PSScriptRoot
$CurrentUser = [Environment]::UserName
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
<#
    Networked drive mappings
#>
write-host "Current user: $CurrentUser" -foreground "yellow"
write-host "Current domain: $([Environment]::UserDomainName)" -foreground "yellow"
write-host "Current machine: $([Environment]::MachineName)" -foreground "yellow"

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
$ASNCorePath = $ConfigFile.Settings.ASNCoreRoot + $MajorVersion + "_" + $MinorVersion + "\"
if (-Not (Test-Path $ASNCorePath))
{
  $WarnSetup = $ASNCorePath + " Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$TempFileLocation = $ASNCorePath + $ConfigFile.Settings.TempFileFolder + "\"
if (-Not (Test-Path $TempFileLocation))
{
  $WarnSetup = $TempFileLocation + " Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}

<#
    This script's config settings
#>
$Tool = $ConfigFile.Settings.LoadUCData.Tool
if (-Not (Test-Path $Tool))
{
  $WarnSetup = $Tool + " Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}

$PDriveRoot = $ConfigFile.Settings.PDriveRoot + $MajorVersion + "X\CS08_"
$LoadUCDataFile = $PDriveRoot + $MajorVersion + "_" + $MinorVersion + "\" + $ConfigFile.Settings.LoadUCData.LoadUCDataFolder
$LoadUCDataOld = $TempFileLocation + "LoadUCData.old"
$LoadUCDataASN = $ASNCorePath + $ConfigFile.Settings.LoadUCData.ASNFileName
$LoadUCDataTempFile = $TempFileLocation + "LoadUCData.sql"

cd $ASNCorePath
Convert-Path .
If (Test-Path $LoadUCDataOld)
{
	write-host "$(get-date) Removing old LoadUCData file" -foreground "green"
	Remove-Item $LoadUCDataOld -force
}
If (Test-Path $LoadUCDataFile)
{
	write-host "$(get-date) Copying LoadUCData.sql to LoadUCData.old" -foreground "green"
  Copy-Item -Path $LoadUCDataFile -Destination $LoadUCDataOld -Force
}
$itemtime = Get-Date
write-host "$(get-date) Generating LoadUCData.sql (oracle DB only)" -foreground "green"
$outputTool = & $Tool ora, $LoadUCDataASN, $LoadUCDataTempFile
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
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed -foreground "yellow"
write-host "Script Ended at $(get-date)" -foreground "green"
Write-Host "Press any key to continue ..." -foreground "magenta"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

