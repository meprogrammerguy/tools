cd $PSScriptRoot
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
$TFSWorkspace = $ConfigFile.Settings.GenerateUARFile.TFSWorkspaceRoot + $MajorVersion + "_" + $MinorVersion + "\"
if (-Not (Test-Path $TFSWorkspace))
{
  $WarnSetup = $TFSWorkspace  + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$ASNCorePath = $ConfigFile.Settings.ASNCoreRoot + $MajorVersion + "_" + $MinorVersion + "\"
if (-Not (Test-Path $ASNCorePath))
{
  $WarnSetup = $ASNCorePath   + "Does not exist, You need to set this up first (New version?)"
  write-host $WarnSetup -foreground "red"
  Exit
}
$ASNMessagePath = $ConfigFile.Settings.GenerateUARFile.ASNMessagePath
if (-Not (Test-Path $ASNMessagePath))
{
  $WarnSetup = $ASNMessagePath   + "Does not exist, You need to set this up first (New version?)"
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
$PDriveRoot = $ConfigFile.Settings.PDriveRoot + $MajorVersion + "X\CS08_"
$LoadUCDataFolder = $PDriveRoot + $MajorVersion + "_" + $MinorVersion + "\" + $ConfigFile.Settings.LoadUCData.LoadUCDataFolder
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
$ImportComponent = "XML:" + $TFSComponentPath + "\*." + $ConfigFile.Settings.TFSComponentExtension
$INICorePath = "/ini=" + $PDriveRoot + $MajorVersion + "_" + $MinorVersion + "\" + $ConfigFile.Settings.INICoreLocation
$TempFileLocation = $ConfigFile.Settings.TempFileLocation
$MessageArgs = GetTFSSource $TFSPath
$MessageArgs = $MessageArgs + $ConfigFile.Settings.GenerateUARFile.MessageArgs
$INIMessageLocation = "/ini=" + $ConfigFile.Settings.PDriveRoot + $MajorVersion + "X\" + $ConfigFile.Settings.GenerateUARFile.INIMessageLocation
$UnifaceIDFPath = $ConfigFile.Settings.UnifaceIDFPath
$ASNCorePathAll = "/asn=" + $ASNCorePath + "idfall"
"==="
$ASNCorePathAll
$ASNCorePath 
$UnifaceIDFPath
$INICorePath
$ImportIncludes
"==="
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Importing Include Procs" -foreground "green"
& $UnifaceIDFPath $ASNCorePathAll $INICorePath /imp $ImportIncludes | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"