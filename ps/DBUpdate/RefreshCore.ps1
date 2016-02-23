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
$HDriveSeparator = "."
$HDriveRoot2 = "CS06"
if ($MajorVersion -eq "3")
{
  $HDriveSeparator = "_"
  $HDriveRoot2 = "CSPV6"
}
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
$RoboLog = $TempFileLocation + "robocopy_$($CurrentUser)_$($MajorVersion)_$($MinorVersion).log"
if ($LocalResourcesFolder.Length -eq "")
{
  write-host "Directly building to production resources folder (slower)" -foreground "yellow"
}
else
{
  write-host "Creating a local resources first, and robocopying to production (faster)" -foreground "green"
}
$LogPath = $ASNCorePath + $ConfigFile.Settings.RefreshCore.LogFolder + "\"
$ModelPrompt = $ConfigFile.Settings.RefreshCore.ModelPrompt

<#
    This script's model table(s) input
#>
write-host "Current user: $CurrentUser" -foreground "yellow"
write-host "Current domain: $([Environment]::UserDomainName)" -foreground "yellow"
write-host "Current machine: $([Environment]::MachineName)" -foreground "yellow"
$Tables = Read-Host -Prompt $ModelPrompt

$script:startTime = Get-Date
write-host "Script Started at $script:startTime" -foreground "green"

$PatternStart = '<DAT name=\"ULABEL\">'
$PatternEnd = "</DAT>"
$Pieces = $Tables.split(",")
if ($Pieces[0] -gt "")
{
  $Patterns = @()
	foreach ($Piece in $Pieces)
	{
		$Piece = $Piece.ToUpper()
		$Patterns = $Patterns + @($PatternStart + $Piece + $PatternEnd)
	}
}

cd $LogPath
Convert-Path .
write-host "$(get-date) Removing old log files" -foreground "green"
foreach ($file in Get-ChildItem -name)
{
  if ($file -match $CurrentUser)
  {
    Remove-Item $file -force
  } 
}

If (Test-Path $LocalResourcesFolder)
{
  write-host "$(get-date) Removing local resources folder" -foreground "green"
	Remove-Item  -Recurse -Force $LocalResourcesFolder
}

cd $TFSComponentPath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Components" -foreground "green"
& $TFSToolPath get /force $ComponentArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $TFSModelPath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Models" -foreground "green"
& $TFSToolPath get /force $ModelArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $TFSIncludePath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Include Procs" -foreground "green"
& $TFSToolPath get /force $IncludeArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $ASNCorePath 
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Importing Models" -foreground "green"
& $UnifaceIDFPath $INICorePath /imp $ImportModels | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"
$itemtime = Get-Date
write-host "$(get-date) Analyizing Models" -foreground "green"
& $UnifaceIDFPath $INICorePath /con | Out-null
$elapsed = GetElapsedTime $itemtime 
write-host "Elapsed Time: " $elapsed -foreground "green"
$itemtime = Get-Date
write-host "$(get-date) Generating R, S and Y messages" -foreground "green"
& $UnifaceIDFPath $INICorePath /tst gen_messages.aps RSY | Out-null
$elapsed = GetElapsedTime $itemtime 
write-host "Elapsed Time: " $elapsed -foreground "green"
$itemtime = Get-Date
write-host "$(get-date) Importing Include Procs" -foreground "green"
& $UnifaceIDFPath $INICorePath /imp $ImportIncludes | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $PSScriptRoot
Convert-Path .
cmd /c start powershell -Command {.\LoadUCData.ps1}

cd $ASNCorePath
Convert-Path .
if ($Patterns.Count -le 0)
{
  $itemtime = Get-Date
  write-host "$(get-date) Importing Components" -foreground "green"
  & $UnifaceIDFPath $INICorePath /imp $ImportAllComponents | Out-null
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
  $itemtime = Get-Date
  write-host "$(get-date) Compiling all Services" -foreground "green"
	& $UnifaceIDFPath $INICorePath /svc
  write-host "$(get-date) Compiling all Forms (at the same time)" -foreground "green"
	& $UnifaceIDFPath $INICorePath /frm | Out-null
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
}
else
{
	$itemtime = Get-Date
	foreach ($file in Get-ChildItem -Path $ComponentFiles | Select-String -pattern $Patterns | Select-Object -Unique path)
	{
		$filespec = $file.path
		$pieces = $filespec.split("\")
		$filename = $pieces[$pieces.count - 1]
		$pieces = $filename.split(".")
		$justname = $pieces[$pieces.count - 2]
		write-host "$(get-date) Importing $justname" -foreground "green"
		& $UnifaceIDFPath $INICorePath /imp $ImportComponent\$justname.cmx | Out-null
		write-host "$(get-date) Compiling $justname" -foreground "green"
		& $UnifaceIDFPath $INICorePath /cpt $justname
	}
	$elapsed = GetElapsedTime $itemtime
	write-host "Elapsed Time: " $elapsed -foreground "green"
}

if ($LocalResourcesFolder.Length -ne "")
{
  $itemtime = Get-Date
  write-host "$(get-date) Copying local resources to production" -foreground "green"
  robocopy "$($LocalResourcesFolder)" "$($ProductionResourcesFolder)" /E /MT:20 /V /LOG:$RoboLog
  $elapsed = GetElapsedTime $itemtime
	write-host "Elapsed Time: " $elapsed -foreground "green"
}

cd $PSScriptRoot
Convert-Path .
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed -foreground "yellow"
write-host "Script Ended at $(get-date)" -foreground "green"
Write-Host "Press any key to continue ..." -foreground "magenta"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
