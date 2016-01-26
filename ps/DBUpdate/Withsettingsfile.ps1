<#
    Powershell DBUpdate script
#>
$Host.UI.RawUI.WindowTitle = "DBUpdate Script"
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
$LogPath = $ConfigFile.Settings.DBUpdate.LogPath
$UnifaceIDFPath = $ConfigFile.Settings.UnifaceIDFPath
$CSPrompt = 'DBUpdate script - Table(s) ordr,schl or (<cr>=all[slow])'
<#
$Tables = Read-Host -Prompt $CSPrompt
#>
$script:startTime = Get-Date
$CurrentUser
[Environment]::UserDomainName
[Environment]::MachineName
Add-PSSnapin Microsoft.TeamFoundation.PowerShell
write-host "Script Started at $script:startTime" -foreground "green"

$LogPath
$UnifaceIDFPath

cd $PSScriptRoot
Convert-Path .
write-host "Script Ended at $(get-date)" -foreground "green"
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed;
exit

cmd /c start powershell -NoExit -Command {.\GenerateUAR.ps1}

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

cd $CSComponentLocation
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Components" -foreground "green"
& $TFSLocation get $CSComponentArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $CSModelLocation
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Models" -foreground "green"
& $TFSLocation get $CSModelArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $CSIncludeLocation
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Getting Latest Include Procs" -foreground "green"
& $TFSLocation get $CSIncludeArgs | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $AsnLocation 
Convert-Path .
$itemtime = Get-Date
write-host "$(get-date) Importing Include Procs" -foreground "green"
& $UnifaceIDFLocation $INILocation /imp $ImportIncludes | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"
$itemtime = Get-Date
write-host "$(get-date) Importing Models" -foreground "green"
& $UnifaceIDFLocation $INILocation /imp $ImportModels | Out-null
$elapsed = GetElapsedTime $itemtime
write-host "Elapsed Time: " $elapsed -foreground "green"
$itemtime = Get-Date
write-host "$(get-date) Analyizing Models" -foreground "green"
& $UnifaceIDFLocation $INILocation /con | Out-null
$elapsed = GetElapsedTime $itemtime 
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $PSScriptRoot
Convert-Path .
cmd /c start powershell -NoExit -Command {.\LoadUCData.ps1}

cd $AsnLocation 
Convert-Path .
write-host "$(get-date) Generating R, S and Y messages (in parallel)" -foreground "magenta"
& $UnifaceIDFLocation $INILocation /tst gen_messages.aps RSY

if ($Patterns.Count -le 0)
{
  $itemtime = Get-Date
  write-host "$(get-date) Importing Components" -foreground "green"
  & $UnifaceIDFLocation $INILocation /imp $ImportAllComponents | Out-null
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
  $itemtime = Get-Date
  write-host "$(get-date) Compiling all Services" -foreground "green"
	& $UnifaceIDFLocation $INILocation /svc /inf | Out-null
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
  $itemtime = Get-Date
  write-host "$(get-date) Compiling all Forms" -foreground "green"
	& $UnifaceIDFLocation $INILocation /frm /inf | Out-null
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
}
else
{
  $itemtime = Get-Date
	foreach ($file in Get-ChildItem -Path $CSComponentFiles | Select-String -pattern $Patterns | Select-Object -Unique path)
	{
		$filespec = $file.path
		$pieces = $filespec.split("\")
		$filename = $pieces[$pieces.count - 1]
		$pieces = $filename.split(".")
		$justname = $pieces[$pieces.count - 2]
    write-host "$(get-date) Importing $justname" -foreground "green"
    & $UnifaceIDFLocation $INILocation /imp $ImportComponent\$justname.cmx | Out-null
		write-host "$(get-date) Compiling $justname" -foreground "green"
		& $UnifaceIDFLocation $INILocation /cpt /inf $justname | Out-null
	}
  $elapsed = GetElapsedTime $itemtime
  write-host "Elapsed Time: " $elapsed -foreground "green"
}

cd $PSScriptRoot
Convert-Path .
write-host "Script Ended at $(get-date)" -foreground "green"
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed;
