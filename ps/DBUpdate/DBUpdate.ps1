<#
    Powershell DBUpdate
#>
h:
cd H:\unicomp\CSCE\CS06\CS08.2.27\USYS
$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" get $/CSCE/CS06/CS08.2.27/USYS/messagesgenerated.uar /noprompt
$tf | Out-null
$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" checkout $/CSCE/CS06/CS08.2.27/USYS/messagesgenerated.uar /noprompt
$tf | Out-null
cd H:\unicomp\CSCE\CS06\CS08.2.27\Components
$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" get $/CSCE/CS06/CS08.2.27/Components /recursive
$tf | Out-null
cd H:\unicomp\CSCE\CS06\CS08.2.27\Models
$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" get $/CSCE/CS06/CS08.2.27/Models /recursive
$tf | Out-null
p:
cd \\AL-DEVNAS-S00\CS_Prod\CS08_2X\CS08_2_27\USERS\MAIN\
& 'T:\UNIFACE\U9605\X505\common\BIN\idf.exe' /ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini /imp XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Components\*.cmx
& 'T:\UNIFACE\U9605\X505\common\BIN\idf.exe' /ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini /imp XML:H:\Unicomp\CSCE\CS06\CS08.2.27\Models\*.xml
& 'T:\UNIFACE\U9605\X505\common\BIN\idf.exe' /ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini /con
& 'T:\UNIFACE\U9605\X505\common\BIN\idf.exe' /ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini /tst gen_messages.aps RSY
foreach ($file in Get-ChildItem -Path H:\unicomp\CSCE\CS06\CS08.2.27\Components\*.cmx | Select-String -pattern '<DAT name=\"ULABEL\">FCUS</DAT>' | Select-Object -Unique path)
{
  $filespec = $file.path
  $pieces=$filespec.split("\")
  $filename=$pieces[$pieces.count-1]
  $pieces=$filename.split(".")
  $justname=$pieces[$pieces.count-2]
  $justname
  & 'T:\UNIFACE\U9605\X505\common\BIN\idf.exe' /ini=P:\CS08_2X\CS08_2_27\USERS\MAIN\idf96.ini /cpt $justname
}
c: