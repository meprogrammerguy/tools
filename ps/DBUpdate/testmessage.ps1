$UnifaceIDFPath = "T:\UNIFACE\U9605\X505\common\BIN\idf.exe"
$TempFileLocation = "D:\DBUpdate\Temp\"
$UnifaceLocalIDFPath = $TempFileLocation + "idf.exe"
$ASNCorePath = "D:\DBUpdate\Devo_v2\"
$INICorePath = "/ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini"

cd $ASNCorePath 
Convert-Path .
write-host "$(get-date) Generating R, S and Y messages" -foreground "green"
& $UnifaceIDFPath $INICorePath /tst gen_messages.aps RSY | Out-null