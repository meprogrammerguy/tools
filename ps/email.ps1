##############################################################################
$From = "YourEmail@gmail.com"
$To = "AnotherEmail@YourDomain.com"
$Cc = "YourBoss@YourDomain.com"
$Attachment = "C:\temp\Some random file.txt"
$Subject = "Email Subject"
$Body = "Insert body text here"
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"
Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject `
-Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `
-Credential (Get-Credential) -Attachments $Attachment
##############################################################################