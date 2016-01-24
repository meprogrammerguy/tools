<#
    Powershell Drop Table Testing script
#>

$theServer = "al-jsmith-sp3\sqlexpress"
$theDB = "v2_24"
$theUser = "cmdseries"
$thePassword = "cmdseries"
$theTest = "SELECT COUNT(1) FROM rsnc WHERE 0=1;"
$theQuery = "Drop table rsnc;"
$theResult = Invoke-Sqlcmd -erroraction 'silentlycontinue' -ServerInstance $theServer -Database $theDB -U $theUser -P $thePassword -Query $theTest
if ($theResult)
{
	Invoke-Sqlcmd -ServerInstance $theServer -Database $theDB -U $theUser -P $thePassword -Query $theQuery
}
else
{
	"Table not found"
}





