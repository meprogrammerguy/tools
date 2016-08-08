cd C:\jsmith\BAMods\Promote\bin\Debug
CommandAlkon.AutoBuild.Promote.exe "CS08 2.28" /log /BAMOD "jsmith" /logfile "C:\Users\jsmith\Desktop\run.log"
pause
cd C:\Users\jsmith\Documents\git\tools\vbs
wscript /nologo email_ba_mods.vbs "C:\Users\jsmith\Desktop\run.log"