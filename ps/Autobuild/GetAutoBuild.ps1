<#
    Powershell GetAutoBuild
    I prefer to work on my box local. This script will go to all the build servers and obtain the current copy of COMMANDseriesBuild.
    It will Name them so you know what box they came from. The script then checks out the COMMANDseriesBuild and copies it to my working Folder
    I will then do Compares of the build server files (manually using beyond compare). update my .bld so it is current. make my changes.
    ( Added v3 HF script to this tool as well)
#>
New-Item -Force -ItemType directory -Path C:\Users\jsmith\Desktop\AutoBuild
Copy-Item \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild.bld C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.s04
Copy-Item \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild.bld C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.s05
Copy-Item \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild.bld C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.vm1

Copy-Item \\al-csbuild-s04\c\build\COMMANDseries\COMMANDseriesBuild_hf.bld C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_hf.s04
Copy-Item \\al-csbuild-s05\c\build\COMMANDseries\COMMANDseriesBuild_hf.bld C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_hf.s05
Copy-Item \\al-csbuild-vm1\build\COMMANDseries\COMMANDseriesBuild_hf.bld C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_hf.vm1

h:
cd H:\unicomp\AutoBuild\COMMANDseries
$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" get /force $/AutoBuild/COMMANDseries/COMMANDseriesBuild.bld /noprompt
$tf | Out-null
$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" checkout $/AutoBuild/COMMANDseries/COMMANDseriesBuild.bld /noprompt
$tf | Out-null

$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" get /force $/AutoBuild/COMMANDseries/COMMANDseriesBuild_hf.bld /noprompt
$tf | Out-null
$tf = &"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" checkout $/AutoBuild/COMMANDseries/COMMANDseriesBuild_hf.bld /noprompt
$tf | Out-null

c:
Copy-Item H:\unicomp\AutoBuild\COMMANDseries\COMMANDseriesBuild.bld C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild.bld

Copy-Item H:\unicomp\AutoBuild\COMMANDseries\COMMANDseriesBuild_hf.bld C:\Users\jsmith\Desktop\AutoBuild\COMMANDseriesBuild_hf.bld