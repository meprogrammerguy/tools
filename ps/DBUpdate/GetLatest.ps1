<#
    Powershell DBUpdate
#>
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
$CSComponentArgs = "$/CSCE/CS06/CS08.2.27/USYS/Components"
$CSModelLocation = "H:\unicomp\CSCE\" + $CSParent + "\" + $CSVersion + "\Models"
$CSModelArgs = "$/CSCE/CS06/CS08.2.27/USYS/Models"
$TFSLocation = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$AsnLocation = "D:\DBUpdate\MAIN\"
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
<#
cd $CSMessageLocation
Convert-Path .
& $TFSLocation get $CSMessageArgs
& $TFSLocation checkout $CSMessageArgs
#>

cd $CSComponentLocation
Convert-Path .
& $TFSLocation get $CSComponentArgs

cd $CSModelLocation
Convert-Path .
& $TFSLocation get $CSModelArgs 

cd $AsnLocation 
Convert-Path .
& $UnifaceIDFLocation /ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini /imp XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Components\edtordr.cmx
<#
& $UnifaceIDFLocation /ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini /imp XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Components\edtordr.cmx


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
#>
cd $PSScriptRoot
Convert-Path .
