<#
Powershell TestAutoBuild
    This script will copy the local .bld script to all of the build servers (creating a backup)
#>
Rename-Item -force -path \\al-csbuild-s04\build\COMMANDseries\COMMANDseriesBuild.bld -newname COMMANDseriesBuild.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.bld \\al-csbuild-s04\build\COMMANDseries\COMMANDseriesBuild.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-s04"} 
Rename-Item -force -path \\al-csbuild-s05\build\COMMANDseries\COMMANDseriesBuild.bld -newname COMMANDseriesBuild.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.bld \\al-csbuild-s05\build\COMMANDseries\COMMANDseriesBuild.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-s05"} 
Rename-Item -force -path \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild.bld -newname COMMANDseriesBuild.old
$status = Copy-Item C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.bld \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild.bld -PassThru -ErrorAction silentlyContinue
if ($status) { $status }
else { "Copy failure on al-csbuild-vm1"} 
