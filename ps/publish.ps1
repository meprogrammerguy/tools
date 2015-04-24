param(
[string]$a
)
<# 
.\go.ps1 "Text Comment for Commit"
#>
if (!$a)
{ 
	$a = Read-Host 'comment: or (<cr> for generic comment)'
}
if (!$a)
{
	$a = Get-Date
	$a = $a + " page updated."
}
git add -A
git commit -m $a
git push
echo "Copying webpage to Google Drive"
copy "$env:USERPROFILE\Documents\github\webpage\index.html" "$env:USERPROFILE\Google Drive\ftp sync\index.html"