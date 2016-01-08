<#
    Powershell DBUpdate
#>
h:
cd H:\unicomp\CSCE\CS06\CS08.2.27\USYS
$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" get $/CSCE/CS06/CS08.2.27/USYS/messagesgenerated.uar /noprompt
$tf | Out-null
$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" checkout $/CSCE/CS06/CS08.2.27/USYS/messagesgenerated.uar /noprompt
$tf | Out-null
cd C:\Users\jsmith\Documents\GitHub\tools\ps\DBUpdate