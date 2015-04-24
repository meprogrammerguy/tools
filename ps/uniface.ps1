$FileRaw = Read-Host "Enter file to De-Crapify"
$File = Get-ChildItem $FileRaw
$content = [IO.File]::ReadAllText($FileRaw)
$Decode = [System.Net.WebUtility]::HtmlDecode($content)
Start-Sleep 3
$Decode  | Out-File $($File.DirectoryName + "\" + $File.Name + ".uniface")