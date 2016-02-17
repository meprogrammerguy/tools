<#
    Powershell RefreshCore script
#>
$Host.UI.RawUI.WindowTitle = "RefreshCore Script (elevated)"
Add-PSSnapin Microsoft.TeamFoundation.PowerShell -erroraction "silentlycontinue"

function GetElapsedTime([datetime]$starttime) 
{
  $runtime = $(get-date) - $starttime
  $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
  $retStr
}

function GetTFSSource([string]$DriveSource) 
{
  $TFSSource = $DriveSource
  $Args = $TFSSource -replace "\\", "/"
  $Pieces = $Args.split("/")
  $TFSSource  = "$/" + $Pieces[2] + "/" + $Pieces[3] + "/" + $Pieces[4] + "/" + $Pieces[5]
  $TFSSource 
}

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
$TempFileLocation = $ConfigFile.Settings.TempFileLocation
if (-Not (Test-Path $TempFileLocation))
{
  $WarnSetup = $TempFileLocation + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$ASNCorePath = $ConfigFile.Settings.ASNCoreRoot + $MajorVersion + "_" + $MinorVersion + "\"
if (-Not (Test-Path $ASNCorePath))
{
  $WarnSetup = $ASNCorePath + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$PDriveRoot = $ConfigFile.Settings.PDriveRoot + $MajorVersion + "X\CS08_"
$INICorePath = "/ini=" + $PDriveRoot + $MajorVersion + "_" + $MinorVersion + "\" + $ConfigFile.Settings.INICoreLocation
$TFSPath = $ConfigFile.Settings.HDriveRoot + $HDriveRoot2 + "\CS08" + $HDriveSeparator + $MajorVersion + $HDriveSeparator + $MinorVersion + "\"

$TFSIncludePath = $TFSPath + $ConfigFile.Settings.TFSIncludeFolder
$TFSGlobalPath = $TFSPath + $ConfigFile.Settings.TFSGlobalFolder
$TFSModelPath = $TFSPath + $ConfigFile.Settings.TFSModelFolder
$TFSComponentPath = $TFSPath + $ConfigFile.Settings.TFSComponentFolder

$IncludeArgs = GetTFSSource $TFSIncludePath
$GlobalArgs = GetTFSSource $TFSGlobalPath
$ModelArgs = GetTFSSource $TFSModelPath
$ComponentArgs = GetTFSSource $TFSComponentPath

$ImportIncludes = "XML:" + $TFSIncludePath + "\*." + $ConfigFile.Settings.TFSIncludeExtension
$ImportGlobals = "XML:" + $TFSGlobalPath + "\*." + $ConfigFile.Settings.TFSGlobalExtension
$ImportModels = "XML:" + $TFSModelPath + "\*." + $ConfigFile.Settings.TFSModelExtension
$ImportComponent = "XML:" + $TFSComponentPath
$ImportAllComponents = $ImportComponent + "\*." + $ConfigFile.Settings.TFSComponentExtension

$ComponentFiles = $TFSComponentPath + "\*." + $ConfigFile.Settings.TFSComponentExtension
<#
    This script's config settings
#>
$LocalResourcesFolder = $ASNCorePath + $ConfigFile.Settings.RefreshCore.LocalResourcesFolder
$ProductionResourcesFolder = $PDriveRoot + $MajorVersion + "_" + $MinorVersion + "\resources"
$RoboLog = $TempFileLocation + "robocopy_$($CurrentUser).log"

"==="
$TempFileLocation = $ConfigFile.Settings.TempFileLocation
if (-Not (Test-Path $TempFileLocation))
{
  $WarnSetup = $TempFileLocation + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$ASNCorePath = $ConfigFile.Settings.ASNCoreRoot + $MajorVersion + "_" + $MinorVersion + "\"
if (-Not (Test-Path $ASNCorePath))
{
  $WarnSetup = $ASNCorePath + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
write-host "TempFileLocation = $($TempFileLocation)"
write-host "ASNCorePath = $($ASNCorePath)"
write-host "PDriveRoot = $($PDriveRoot)"
write-host "INICorePath = $($INICorePath)"
write-host "TFSPath = $($TFSPath)"
write-host "TFSIncludePath = $($TFSIncludePath)"
write-host "TFSGlobalPath = $($TFSGlobalPath)"
write-host "TFSModelPath = $($TFSModelPath)"
write-host "TFSComponentPath = $($TFSComponentPath)"
write-host "IncludeArgs = $($IncludeArgs)"
write-host "GlobalArgs = $($GlobalArgs)"
write-host "ModelArgs = $($ModelArgs)"
write-host "ComponentArgs = $($ComponentArgs)"
write-host "ImportIncludes = $($ImportIncludes)"
write-host "ImportGlobals = $($ImportGlobals)"
write-host "ImportModels = $($ImportModels)"
write-host "ImportComponent = $($ImportComponent)"
write-host "ImportAllComponents = $($ImportAllComponents)"
write-host "ComponentFiles = $($ComponentFiles)"
write-host "LocalResourcesFolder = $($LocalResourcesFolder)"
write-host "ProductionResourcesFolder = $($ProductionResourcesFolder)"
write-host "RoboLog = $($RoboLog)"

"==="




cd $PSScriptRoot
Convert-Path .
Write-Host "Press any key to continue ..." -foreground "magenta"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
