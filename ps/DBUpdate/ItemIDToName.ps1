# Given ItemID return Filename
param (
    [string]$projno =  $( Read-Host "Enter ItemID # (e.g. 3436291)" )
)

[string]$tfpt = "C:\Program Files (x86)\Microsoft Team Foundation Server 2013 Power Tools\TFPT.EXE"
[string]$svr = "http://al-tfs2012-vm1:8080/tfs/defaultcollection"
[string]$query = "SELECT * FROM WorkItems "
<# +
    "WHERE ID = '$projno' "
#>
$data = & $tfpt query /collection:$svr /wiql:$query /include:data

if ($data -ne $null) {
    $line = ($data | select -first 1)
    $taskid = $line.split("`t")[0]
    $taskid | clip
}
$data

Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")