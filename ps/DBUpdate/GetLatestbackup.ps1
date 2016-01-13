<#
    Powershell DBUpdate
#>
$CSVersion = "CS08.2.27"
$UnifaceIDFLocation = "T:\UNIFACE\U9605\X505\common\BIN\idf.exe"
$UnifaceININame = "idf96_jrs.ini"
$pieces = $CSVersion.split(".")
$CSPrefix = $pieces[0]
$CSVersionMajor = $pieces[1]
$CSVersionMinor = $pieces[2]
$CSParent = "CS06"
if ($CSVersionMajor -ne "2")
{
  $CSParent = "CSPV6"
}
$CSMessageLocation = "H:\unicomp\CSCE\" + $CSParent + "\" + $CSVersion + "\USYS"
$CSComponentLocation = "H:\unicomp\CSCE\" + $CSParent + "\" + $CSVersion + "\Components"
$CSModelLocation = "H:\unicomp\CSCE\" + $CSParent + "\" + $CSVersion + "\Models"
$TFSLocation = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$MainLocation = "P:\CS08_2X\" + $CSPrefix +"_" + $CSVersionMajor + "_" + $CSVersionMinor + "\USERS\MAIN\"
$PatternStart = '<DAT name=\"ULABEL\">'
$PatternEnd = "</DAT>"
$Tables = Read-Host -Prompt 'Table(s) ordr,schl(<cr>=all)'
$Pieces = $Tables.split(",")
if ($Pieces[0] -gt "")
{
	foreach ($Piece in $Pieces)
	{
		$Piece = $Piece.ToUpper()
		$Patterns = $Patterns + ($PatternStart + $Piece + $PatternEnd)
	}
}

cd $CSMessageLocation
Convert-Path .
$tf = & $TFSLocation get $/CSCE/ + $CSParent + / + $CSVersion + /USYS/messagesgenerated.uar /noprompt
$tf | Out-null
$tf = & $TFSLocation checkout $/CSCE/ + $CSParent + / + $CSVersion + /USYS/messagesgenerated.uar /noprompt
$tf | Out-null

cd $CSComponentLocation
Convert-Path .
$tf = & $TFSLocation get $/CSCE/ + $CSParent + / + $CSVersion + /Components /recursive
$tf | Out-null

cd $CSModelLocation
Convert-Path .
$tf = & $TFSLocation get $/CSCE/ + $CSParent + / + $CSVersion + /Models /recursive
$tf | Out-null

cd $MainLocation 
Convert-Path .
& $UnifaceIDFLocation /ini= + $MainLocation + /imp XML: + $CSComponentLocation + *.cmx
& $UnifaceIDFLocation /ini= + $MainLocation + $UnifaceININame /imp XML: + $CSModelLocation + *.xml
& $UnifaceIDFLocation /ini= + $MainLocation + $UnifaceININame /con
& $UnifaceIDFLocation /ini= + $MainLocation + $UnifaceININame  /tst gen_messages.aps RSY
if ($Patterns.Count -le 0)
{
	& $UnifaceIDFLocation /ini= + $MainLocation + $UnifaceININame /frm
	& $UnifaceIDFLocation /ini= + $MainLocation + $UnifaceININame /svc
}
else
{
	foreach ($file in Get-ChildItem -Path + $CSComponentLocation + \*.cmx | Select-String -pattern $Patterns | Select-Object -Unique path)
	{
		$filespec = $file.path
		$pieces = $filespec.split("\")
		$filename = $pieces[$pieces.count - 1]
		$pieces = $filename.split(".")
		$justname = $pieces[$pieces.count - 2]
		$justname
		& $UnifaceIDFLocation /ini= + $MainLocation + $UnifaceININame /cpt $justname
	}
}

cd $PSScriptRoot
Convert-Path .