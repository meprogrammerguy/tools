<#
    Powershell RefreshCore script
#>
$Host.UI.RawUI.WindowTitle = "RefreshCore Script (elevated)"
cd $PSScriptRoot
clear
function GetElapsedTime([datetime]$starttime) 
{
    $runtime = $(get-date) - $starttime
    $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
    $retStr
}
$CurrentUser = [Environment]::UserName
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
$TFSToolPath = $ConfigFile.Settings.TFSToolPath
$UnifaceIDFPath = $ConfigFile.Settings.UnifaceIDFPath
$TempFileLocation = $ConfigFile.Settings.TempFileLocation
$ASNCorePath = $ConfigFile.Settings.ASNCorePath
$INICorePath = $ConfigFile.Settings.INICorePath
$TFSIncludePath = $ConfigFile.Settings.TFSIncludePath
$IncludeArgs = $ConfigFile.Settings.IncludeArgs
$ImportIncludes = $ConfigFile.Settings.ImportIncludes

$TFSModelPath = $ConfigFile.Settings.TFSModelPath
$ModelArgs = $ConfigFile.Settings.ModelArgs
$ImportModels = $ConfigFile.Settings.ImportModels

$TFSComponentPath = $ConfigFile.Settings.TFSComponentPath
$ComponentFiles = $TFSComponentPath + "\*.cmx"
$ComponentArgs = $ConfigFile.Settings.ComponentArgs
$ImportComponent = $ConfigFile.Settings.ImportComponent
$ImportAllComponents = $ImportComponent + "\*.cmx"

<#
    This script's config settings
#>
$LogPath = $ConfigFile.Settings.DBUpdate.LogPath
$ModelPrompt = $ConfigFile.Settings.DBUpdate.ModelPrompt

<#
    This script's model table(s) input
#>
$Tables = Read-Host -Prompt $ModelPrompt

$script:startTime = Get-Date
$CurrentUser
[Environment]::UserDomainName
[Environment]::MachineName
Add-PSSnapin Microsoft.TeamFoundation.PowerShell
write-host "Script Started at $script:startTime" -foreground "green"
write-host "$ModelPrompt $Tables" -foreground "green"

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

cd $TFSComponentPath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Components" -foreground "green"
& $TFSToolPath get $ComponentArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $TFSModelPath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Models" -foreground "green"
& $TFSToolPath get $ModelArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $TFSIncludePath
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Include Procs" -foreground "green"
& $TFSToolPath get $IncludeArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $ASNCorePath 
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Importing Include Procs" -foreground "green"
& $UnifaceIDFPath $INICorePath /imp $ImportIncludes | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"
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

cd $PSScriptRoot
Convert-Path .
cmd /c start powershell -Command {.\LoadUCData.ps1}

cd $ASNCorePath 
Convert-Path .
write-host "$(get-date) Generating R, S and Y messages" -foreground "green"
& $UnifaceIDFPath $INICorePath /tst gen_messages.aps RSY | Out-null

if ($Patterns.Count -le 0)
{
  $itemtime = Get-Date
  write-host "$(get-date) Importing Components" -foreground "green"
  & $UnifaceIDFPath $INICorePath /imp $ImportAllComponents | Out-null
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
  $itemtime = Get-Date
  write-host "$(get-date) Compiling all Services" -foreground "green"
	& $UnifaceIDFPath $INICorePath /svc /inf
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
  $itemtime = Get-Date
  write-host "$(get-date) Compiling all Forms" -foreground "green"
	& $UnifaceIDFPath $INICorePath /frm /inf | Out-null
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
		& $UnifaceIDFPath $INICorePath /cpt /inf $justname
	}
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
