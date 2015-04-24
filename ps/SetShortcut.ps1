param (
[string]$Action,
[string]$IconPath,
[string]$InstallPath,
[string]$Exe,
[string]$Hotkey,
[string]$IconIndex
)
<#
	This will create or remove icons on the Desktop or the Start Menu. Use it for Wix install projects
	
	Examples:
		Adding Desktop icons:
			.\SetShortcut.ps1 "ADD" "C:\Users\jsmith\Desktop\DualAlley.lnk" "C:\Program Files (x86)\DualAlley\" "DualAlley.exe" "CTRL+SHIFT+D" "0"
			
			.\SetShortcut.ps1 "ADD" "C:\Users\jsmith\Desktop\DualAlleyHelp.lnk" "C:\Users\jsmith\Documents\GitHub\paneltool\bin\Debug\Help\" "Dual Alley.pdf"
			
		Adding Start Menu icons:
			.\SetShortcut.ps1 "ADD" "C:\Users\jsmith\Start Menu\Programs\DualAlley.lnk" "C:\Users\jsmith\Documents\GitHub\paneltool\bin\Debug\" "DualAlley.exe" "CTRL+SHIFT+D" "0"
			
			.\SetShortcut.ps1 "ADD" "C:\Users\jsmith\Start Menu\Programs\DualAlleyHelp.lnk" "C:\Users\jsmith\Documents\GitHub\paneltool\bin\Debug\Help\" "Dual Alley.pdf"
		
		Removing a Desktop icon:
			.\SetShortcut.ps1 "REMOVE" "C:\Users\jsmith\Desktop\DualAlley.lnk"
	
	To Log the Wix install do this
	run cmd and CD to the msi file location then do this:
		msiexec /i "DualAlley.msi" /L*V "install.log" (to install)
		msiexec /x "DualAlley.msi" /L*V "install.log" (to uninstall)
#>
if ($Action -eq "ADD")
{
	$IconArg = "," + $IconIndex
	if ($IconArg -eq ",")
	{
	  $IconArg = ",0"
	}
	$WshShell = New-Object -comObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($IconPath)
	$Shortcut.TargetPath = $InstallPath + $Exe
	if ($Shortcut.TargetPath.toLower() -match ".exe")
	{
		$Shortcut.IconLocation = $Shortcut.TargetPath + $IconArg
	}
	$Shortcut.WorkingDirectory = $InstallPath
	$Shortcut.Hotkey = $Hotkey
	$Shortcut.Save()
}
elseif ($Action -eq "REMOVE")
{
	Remove-Item $IconPath
}
else
{
	$arg = "???Unknown action: " + $Action
	echo $arg
}