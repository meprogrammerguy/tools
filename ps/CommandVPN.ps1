$xml = "<MobileConnect><Port>443</Port></MobileConnect>"
$sourceXml=New-Object System.Xml.XmlDocument
$sourceXml.LoadXml($xml)
Add-VpnConnection -Name CommandAlkon -ServerAddress https://bhmvpn.commandalkon.com -SplitTunneling $True -PluginApplicationID SonicWALL.MobileConnect_cw5n1h2txyewy -CustomConfiguration $sourceXml