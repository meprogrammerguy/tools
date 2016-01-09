<#
    Powershell DBUpdate
#>
$CSVersion = "2.27"
$pieces = $CSVersion.split(".")
$CSVersionMajor = $pieces[0]
$CSVersionMinor = $pieces[1]
$UnifaceIDFLocation = "T:\UNIFACE\U9605\X505\common\BIN\idf.exe"
$CSMessageLocation = "H:\unicomp\CSCE\CS06\CS08." + $CSVersion + "\USYS"
$CSComponentLocation = "H:\unicomp\CSCE\CS06\CS08." + $CSVersion + "\Components"
$CSModelLocation = "H:\unicomp\CSCE\CS06\CS08." + $CSVersion + "\Models"
$TFSLocation = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$MainLocation = "P:\CS08_2X\CS08_" + $CSVersionMajor + "_" + $CSVersionMinor + "\USERS\MAIN\"
$PatternStart = '<DAT name=\"ULABEL\">'
$PatternEnd = "</DAT>"

cd $CSMessageLocation
$tf = & $TFSLocation get $/CSCE/CS06/CS08. + $CSVersion + /USYS/messagesgenerated.uar /noprompt
$tf | Out-null
$tf = & $TFSLocation checkout $/CSCE/CS06/CS08. + $CSVersion + /USYS/messagesgenerated.uar /noprompt
$tf | Out-null

cd $CSComponentLocation
$tf = & $TFSLocation get $/CSCE/CS06/CS08. + $CSVersion + /Components /recursive
$tf | Out-null

cd $CSModelLocation
$tf = & $TFSLocation get $/CSCE/CS06/CS08. + $CSVersion + /Models /recursive
$tf | Out-null

cd $MainLocation 
& $UnifaceIDFLocation /ini= + $MainLocation + /imp XML: + $CSComponentLocation + *.cmx
& $UnifaceIDFLocation /ini= + $MainLocation + idf96.ini /imp XML: + $CSModelLocation + *.xml
& $UnifaceIDFLocation /ini= + $MainLocation + idf96.ini /con
& $UnifaceIDFLocation /ini= + $MainLocation + idf96.ini /tst gen_messages.aps RSY
foreach ($file in Get-ChildItem -Path + $CSComponentLocation + \*.cmx | Select-String -pattern + $PatternStart + "FCUS" + $PatternEnd + | Select-Object -Unique path)
{
  $filespec = $file.path
  $pieces = $filespec.split("\")
  $filename = $pieces[$pieces.count - 1]
  $pieces = $filename.split(".")
  $justname = $pieces[$pieces.count - 2]
  $justname
  & $UnifaceIDFLocation /ini= + $MainLocation + idf96.ini /cpt $justname
}

cd $PSScriptRoot