<#
Powershell PutAutoBuild
    This script will copy the local .bld script from the working Dir to the TFS dir.
    It then deletes the Working Dir (does not auto checkin the file)
#>
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.bld H:\unicomp\AutoBuild\COMMANDseries\COMMANDseriesBuild.bld -PassThru -ErrorAction silentlyContinue
if ($status)
{
  $status
  Remove-Item C:\Users\jsmith\Desktop\AutoBuild\* -recurse
  Remove-Item C:\Users\jsmith\Desktop\AutoBuild\
}
else
{
  "Copy failure to TFS directory"
} 
