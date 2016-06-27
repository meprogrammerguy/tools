Add-Type -Path "C:\oracle\instantclient_10_2\odp.net\managed\common\Oracle.ManagedDataAccess.dll"
<#
$username = Read-Host -Prompt "Enter database username"
$password = Read-Host -Prompt "Enter database password"
$datasource = Read-Host -Prompt "Enter database TNS name"
#>
$username = "CS08_2_28_JRS_REP"
$password = "CS08_2_28_JRS_REP"
$datasource = "ALORADEVS00"
$query = "SELECT ulabel,ulan,ucomment FROM usource WHERE uvar = 'USER' AND ulabel LIKE 'MSG_R%' ORDER BY ulan,ulabel"

$connectionString = 'User Id=' + $username + ';Password=' + $password + ';Data Source=' + $datasource
<#
$hoststr = "al-oradev-s00"
$port = "1521"
$serviceName = "orcl10g"
$connectionString = "User Id=$username;Password=$password;Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$hoststr)(PORT=$port))(CONNECT_DATA=(SERVICE_NAME=$serviceName)))"
#>
$connectionString

$connection = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($connectionString)
$connection.open()
$command=$connection.CreateCommand()
$command.CommandText=$query
$reader=$command.ExecuteReader()

while ($reader.Read()) {
  $reader.GetString(0) + ', ' + $reader.GetString(1) + ', ' + $reader.GetString(2)
}
$connection.Close()