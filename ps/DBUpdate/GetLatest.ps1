<#
    Powershell DBUpdate
#>
$PatternStart = '<DAT name=\"ULABEL\">'
$PatternEnd = "</DAT>"
$Patterns = @()
$Tables = Read-Host -Prompt 'Table(s) ordr,schl(<cr>=all)'
$Pieces = $Tables.split(",")
if ($Pieces[1] -gt "")
{
	foreach ($Piece in $Pieces)
	{
		$Piece = $Piece.ToUpper()
		$Patterns = $Patterns + ($PatternStart + $Piece + $PatternEnd)
	}
}
$Patterns.Count
if ($Patterns.Count -le 0)
{
	"None";
}
else
{
	$Patterns
}
