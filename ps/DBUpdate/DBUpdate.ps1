<#
    Powershell CompileForms
#>
clear
$CSVersion = "CS08.2.27"
$UnifaceIDFLocation = "T:\UNIFACE\U9605\X505\common\BIN\idf.exe"
$UnifaceININame = "idf96.ini"
$pieces = $CSVersion.split(".")
$CSPrefix = $pieces[0]
$CSVersionMajor = $pieces[1]
$CSVersionMinor = $pieces[2]
$CSParent = "CS06"
if ($CSVersionMajor -ne "2")
{
  $CSParent = "CSPV6"
}
$CSMessageLocation = "d:\messages"
$CSMessageArgs = "$/CSCE/CS06/CS08.2.27/USYS/messagesgenerated.uar" 
$CSComponentLocation = "H:\unicomp\CSCE\" + $CSParent + "\" + $CSVersion + "\Components"
$CSComponentFiles = $CSComponentLocation + "\*.cmx"
$CSComponentArgs = "$/CSCE/CS06/CS08.2.27/USYS/Components"
$CSIncludeLocation = "H:\unicomp\CSCE\CS06\CS08.2.27\IncludeProcs"
$CSIncludeArgs = "$/CSCE/CS06/CS08.2.27/USYS/IncludeProcs"
$CSModelLocation = "H:\unicomp\CSCE\" + $CSParent + "\" + $CSVersion + "\Models"
$CSModelArgs = "$/CSCE/CS06/CS08.2.27/USYS/Models"
$TFSLocation = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$AsnLocation = "D:\DBUpdate\Devo_v2\"
$INILocation = "/ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini"
$ImportIncludes = "XML:H:\Unicomp\CSCE\CS06\CS08.2.27\IncludeProcs\*.ipx"
$ImportAllComponents = "XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Components\*.cmx"
$ImportComponent = "XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Components"
$ImportModels = "XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Models\*.xml"
$PatternStart = '<DAT name=\"ULABEL\">'
$PatternEnd = "</DAT>"
$AsnGenerated = "D:\DBUpdate\MessagesGenerated_v2\"
$URRGenerated = "D:\DBUpdate\MessagesGenerated_v2\messagesgenerated.uar"
$INIGenerated = "/ini=D:\DBUpdate\MessagesGenerated_v2\idf96.ini"
$ResourcesGenerated = "D:\DBUpdate\MessagesGenerated_v2\resources\msg"
$ZipLocation = "D:\DBUpdate\MessagesGenerated_v2\7za.exe"
$ZipArgs = "a -tzip "
$DevoLogs = "D:\DBUpdate\Devo_v2\Logs\"
$GeneratedLogs = "D:\DBUpdate\MessagesGenerated_v2\Logs\"
$CurrentUser = [Environment]::UserName
$CSPrompt = $CSVersion + ' DBUpdate script - Table(s) ordr,schl or (<cr>=all[slow])'
$LoadUCDataLocation = $AsnLocation  + "loaducdata.exe"
$LoadUCDataFile = "P:\CS08_2X\CS08_2_27\UTILS\LoadUCData.sql"
$LoadUCDataTempFile = $AsnLocation  + "LoadUCData.sql"
$LoadUCDataOld = $AsnLocation  + "LoadUCData.old"
$LoadUCDataASN = $AsnLocation + "idf.asn"
$LoadUCDataArgs = $LoadUCDataASN + "," + $LoadUCDataFile
function GetElapsedTime([datetime]$starttime) 
{
    $runtime = $(get-date) - $starttime
    $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
    $retStr
}

$Tables = Read-Host -Prompt $CSPrompt

$script:startTime = Get-Date
[Environment]::UserName
[Environment]::UserDomainName
[Environment]::MachineName
Add-PSSnapin Microsoft.TeamFoundation.PowerShell
write-host "Script Started at $script:startTime" -foreground "green"
$HostName = "GenerateUAR script"
cmd /c start powershell -NoExit -Command {$Host.UI.RawUI.WindowTitle = "$HostName;".\GenerateUAR.ps1}
exit

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

cd $DevoLogs
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
$HostName = "LoadUCData script"
cmd /c start powershell -NoExit -Command {$Host.UI.RawUI.WindowTitle = "$HostName"; .\LoadUCData.ps1}

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
