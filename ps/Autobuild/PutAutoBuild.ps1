<#
Powershell PutAutoBuild
    This script will copy the local .bld script from the working Dir to the TFS dir.
    It then deletes the Working Dir (does not auto checkin the file)
    (Now also Does the v3 HF script)
#>
$status1 = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.bld H:\unicomp\AutoBuild\COMMANDseries\COMMANDseriesBuild.bld -PassThru -ErrorAction silentlyContinue
$status2 = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_hf.bld H:\unicomp\AutoBuild\COMMANDseries\COMMANDseriesBuild_hf.bld -PassThru -ErrorAction silentlyContinue
if ($status1 -And $status2)
{
  $status1
  $status2
  Remove-Item C:\Users\jsmith\Desktop\AutoBuild\* -recurse
  Remove-Item C:\Users\jsmith\Desktop\AutoBuild\
}
else
{
  "Copy failure to TFS directory"
} 
