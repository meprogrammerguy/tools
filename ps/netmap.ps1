<#
    From a priv powershell you need to map your networked drives, like this:
 

 cd c:\tools
 $trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
 $trigger
 Register-ScheduledJob -Trigger $trigger -FilePath "C:\tools\netmap.ps1" -Name netmap
 Get-ScheduledJob
 
 To delete drives:
  Net use driveletter: /delete
 
#>
 net use p: \\al-devnas-s00\CS_Prod /persist:yes
 net use h: \\al-filesrv-s01\users\j_smith /persist:yes
 net use t: \\al-devnas-s00\Dev_tools /persist:yes