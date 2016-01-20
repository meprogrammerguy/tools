$DevoLogs = "D:\DBUpdate\Devo_v2\Logs\"
$GeneratedLogs = "D:\DBUpdate\MessagesGenerated_v2\Logs\"
$CurrentUser = [Environment]::UserName

Add-PSSnapin Microsoft.TeamFoundation.PowerShell
cd $DevoLogs
Convert-Path .
write-host "$(get-date) Removing old log files" -foreground "green"
foreach ($file in Get-ChildItem -name)
{
  if ($file -match $CurrentUser)
  {
    Remove-Item $file -force
  } 
}
cd $GeneratedLogs
Convert-Path .
write-host "$(get-date) Removing old log files" -foreground "green"
foreach ($file in Get-ChildItem -name)
{
  if ($file -match $CurrentUser)
  {
    Remove-Item $file -force
  } 
}
cd $PSScriptRoot
Convert-Path .