cd $PSScriptRoot
function GetTFSSource([string]$DriveSource) 
{
  $TFSSource = $DriveSource
  $Args = $TFSSource -replace "\\", "/"
  $Pieces = $Args.split("/")
  $TFSSource  = "$/" + $Pieces[2] + "/" + $Pieces[3] + "/" + $Pieces[4] + "/" + $Pieces[5]
  $TFSSource 
}

$CurrentUser = [Environment]::UserName
[xml]$ConfigFile = Get-Content DBUpdatebetter.xml
$CoreVersion = $ConfigFile.Settings.CoreVersion
$Pieces = $CoreVersion.split(".")
$MajorVersion = $Pieces[0]
$MinorVersion = $Pieces[1]
$OverrideConfig = $ConfigFile.Settings.ASNCoreRoot + $MajorVersion + "_" + $MinorVersion + "\DBUpdatebetter.xml"
if (-Not(Test-Path $OverrideConfig))
{
  write-host "settings from $($PSScriptRoot)\DBUpdatebetter.xml" -foreground "yellow"
}
else
{
	write-host "settings from $($OverrideConfig)" -foreground "yellow"
	[xml]$ConfigFile = Get-Content $OverrideConfig
}
$CoreVersion = $ConfigFile.Settings.CoreVersion
$Pieces = $CoreVersion.split(".")
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
$HDriveSeparator = $ConfigFile.Settings.HDriveSeparator
$PDriveRoot = $ConfigFile.Settings.PDriveRoot
$LoadUCDataFolder = $PDriveRoot + "CS08_" + $MajorVersion + "_" + $MinorVersion + "\" + $ConfigFile.Settings.LoadUCData.LoadUCDataFolder
$TFSPath = $ConfigFile.Settings.HDriveRoot + "CS08" + $HDriveSeparator + $MajorVersion + $HDriveSeparator + $MinorVersion + "\"
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
$INICorePath = "/ini=" + $ASNCorePath + $ConfigFile.Settings.INICoreName
$TempFileLocation = $ConfigFile.Settings.TempFileLocation
$MessageArgs = GetTFSSource $TFSPath
$MessageArgs = $MessageArgs + $ConfigFile.Settings.GenerateUARFile.MessageArgs
$SettingsRoot
$MajorVersion
$MinorVersion
$TFSIncludePath
$TFSGlobalPath 
$TFSModelPath
$TFSComponentPath
$IncludeArgs
$GlobalArgs
$ModelArgs
$ComponentArgs
$ImportIncludes
$ImportGlobals
$ImportModels
$ImportComponent
$ASNCorePath
$INICorePath
$TempFileLocation
$TFSWorkspace
$MessageArgs
$LoadUCDataFolder