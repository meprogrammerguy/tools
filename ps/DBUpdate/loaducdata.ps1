<#
    Powershell DBUpdate
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
$CSModelLocation = "H:\unicomp\CSCE\" + $CSParent + "\" + $CSVersion + "\Models"
$CSModelArgs = "$/CSCE/CS06/CS08.2.27/USYS/Models"
$TFSLocation = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$AsnLocation = "D:\DBUpdate\Devo_v2\"
$INILocation = "/ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini"
$ImportComponents = "XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Components\*.cmx"
$ImportModels = "XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Models\*.xml"
$PatternStart = '<DAT name=\"ULABEL\">'
$PatternEnd = "</DAT>"
$CSPrompt = $CSVersion + ' DBUpdate script - Table(s) ordr,schl (<cr>=all)'
function GetElapsedTime([datetime]$starttime) 
{
    $runtime = $(get-date) - $starttime
    $retStr = [string]::format("{0} hours(s), {1} minutes(s), {2} seconds(s)", $runtime.Hours, $runtime.Minutes, $runtime.Seconds)
    $retStr
}
<#
$Tables = Read-Host -Prompt $CSPrompt
#>
$script:startTime = Get-Date
write-host "Script Started at $script:startTime" -foreground "green"
<#
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

cd $CSMessageLocation
Convert-Path .
$LockTest = & $TFSLocation status /user:* /format:detailed $CSMessageArgs
if ($LockTest -match "no pending")
{
  write-host "Checking out the messagesgenerated.uar file" -foreground "green"
  & $TFSLocation get $CSMessageArgs | Out-null
  & $TFSLocation checkout $CSMessageArgs | Out-null
  & $TFSLocation status /user:* /format:detailed $CSMessageArgs | Out-null
}
else
{
  write-host "Someone Is Running The Updates Tool - exiting now" -foreground "red"
  $LockTest
  cd $PSScriptRoot
  Convert-Path .
  write-host "Script Ended at $(get-date)" -foreground "red"
  $elapsed = GetElapsedTime $script:startTime
  write-host "Total Elapsed Time: " $elapsed;
  Exit
}
cd $CSComponentLocation
Convert-Path .
write-host "$(get-date) Getting Latest Components" -foreground "green"
& $TFSLocation get $CSComponentArgs | Out-null
$elapsed = GetElapsedTime $script:startTime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $CSModelLocation
Convert-Path .
write-host "$(get-date) Getting Latest Models" -foreground "green"
& $TFSLocation get $CSModelArgs | Out-null
$elapsed = GetElapsedTime $script:startTime
write-host "Elapsed Time: " $elapsed -foreground "green"

cd $AsnLocation 
Convert-Path .

write-host "$(get-date) Importing Components" -foreground "green"
& $UnifaceIDFLocation $INILocation /imp $ImportComponents | Out-null
$elapsed = GetElapsedTime $script:startTime
write-host "Elapsed Time: " $elapsed -foreground "green"
write-host "$(get-date) Importing Models" -foreground "green"
& $UnifaceIDFLocation $INILocation /imp $ImportModels | Out-null
$elapsed = GetElapsedTime $script:startTime
write-host "Elapsed Time: " $elapsed -foreground "green"
write-host "$(get-date) Analyizing Models" -foreground "green"
& $UnifaceIDFLocation $INILocation /con | Out-null
$elapsed = GetElapsedTime $script:startTime
write-host "Elapsed Time: " $elapsed -foreground "green"
write-host "$(get-date) Generating R, S and Y messages" -foreground "green"
& $UnifaceIDFLocation $INILocation /tst gen_messages.aps RSY | Out-null
$elapsed = GetElapsedTime $script:startTime
write-host "Elapsed Time: " $elapsed -foreground "green"

if ($Patterns.Count -le 0)
{
  write-host "$(get-date) Compiling all Services" -foreground "green"
	& $UnifaceIDFLocation $INILocation /svc | Out-null
  $elapsed = GetElapsedTime $script:startTime
  write-host "Elapsed Time: " $elapsed -foreground "green"
  write-host "$(get-date) Compiling all Forms" -foreground "green"
	& $UnifaceIDFLocation $INILocation /frm | Out-null
}
else
{
$Patterns
	foreach ($file in Get-ChildItem -Path $CSComponentFiles | Select-String -pattern $Patterns | Select-Object -Unique path)
	{
		$filespec = $file.path
		$pieces = $filespec.split("\")
		$filename = $pieces[$pieces.count - 1]
		$pieces = $filename.split(".")
		$justname = $pieces[$pieces.count - 2]
		write-host "$(get-date) Compiling $justname" -foreground "green"
		& $UnifaceIDFLocation $INILocation /cpt $justname | Out-null
	}
}
$elapsed = GetElapsedTime $script:startTime
write-host "Elapsed Time: " $elapsed -foreground "green"
#>
cd $PSScriptRoot
Convert-Path .
write-host "Script Ended at $(get-date)" -foreground "green"
$elapsed = GetElapsedTime $script:startTime
write-host "Total Elapsed Time: " $elapsed;
