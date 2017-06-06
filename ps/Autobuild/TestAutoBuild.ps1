<#
Powershell TestAutoBuild
    This script will copy the local .bld script to all of the build servers (creating a backup)
    (Now Does the v3 HF script as well)
#>
If (Test-Path \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild_2XXX.old)
{
	Remove-Item \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild_2XXX.old
}
Rename-Item -force -path \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild_2XXX.bld -newname COMMANDseriesBuild_2XXX.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_2XXX.bld \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild_2XXX.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-s04"} 
If (Test-Path \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild.old)
{
	Remove-Item \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild.old
}
Rename-Item -force -path \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild.bld -newname COMMANDseriesBuild.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.bld \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-s04"}

If (Test-Path \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild_2XXX.old)
{
	Remove-Item \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild_2XXX.old
}
Rename-Item -force -path \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild_2XXX.bld -newname COMMANDseriesBuild_2XXX.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_2XXX.bld \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild_2XXX.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-s05"} 
If (Test-Path \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild.old)
{
	Remove-Item \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild.old
}
Rename-Item -force -path \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild.bld -newname COMMANDseriesBuild.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.bld \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-s05"}

If (Test-Path \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild_2XXX.old)
{
	Remove-Item \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild_2XXX.old
}
Rename-Item -force -path \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild_2XXX.bld -newname COMMANDseriesBuild_2XXX.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_2XXX.bld \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild_2XXX.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-vm1"} 

If (Test-Path \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild.old)
{
	Remove-Item \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild.old
}
Rename-Item -force -path \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild.bld -newname COMMANDseriesBuild.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.bld \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-vm1"} 

If (Test-Path \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild_hf.old)
{
	Remove-Item \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild_hf.old
}
Rename-Item -force -path \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild_hf.bld -newname COMMANDseriesBuild_hf.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_hf.bld \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild_hf.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-s04"} 
If (Test-Path \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild_hf.old)
{
	Remove-Item \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild_hf.old
}
Rename-Item -force -path \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild_hf.bld -newname COMMANDseriesBuild_hf.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_hf.bld \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild_hf.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-s05"} 
If (Test-Path \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild_hf.old)
{
	Remove-Item \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild_hf.old
}
Rename-Item -force -path \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild_hf.bld -newname COMMANDseriesBuild_hf.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_hf.bld \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild_hf.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-vm1"} 

