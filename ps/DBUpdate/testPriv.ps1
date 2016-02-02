$ASNCorePath = "D:\DBUpdate\Devo_v2\"
$INICorePath = "/ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini"
$UnifaceLocalIDFPath = "D:\DBUpdate\Temp\idf.exe"
$UnifaceIDFPath = "T:\UNIFACE\U9605\X505\common\BIN\idf.exe"
$ImportComponent = "XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Components"

Copy-Item $UnifaceIDFPath $UnifaceLocalIDFPath -force

cd $ASNCorePath 
Convert-Path .
write-host "$(get-date) Importing edtordr" -foreground "green"
& $UnifaceLocalIDFPath $INICorePath /imp $ImportComponent\edtordr.cmx | Out-null
write-host "$(get-date) Compiling edtordr" -foreground "green"
& $UnifaceLocalIDFPath $INICorePath /cpt /inf edtordr