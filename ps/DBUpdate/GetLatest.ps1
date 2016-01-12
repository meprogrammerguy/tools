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

$CSVersion 
$CSVersionMajor
$CSVersionMinor
$UnifaceIDFLocation 
$CSMessageLocation 
$CSComponentLocation
$CSModelLocation
$TFSLocation
$MainLocation