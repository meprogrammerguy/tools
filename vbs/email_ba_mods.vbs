Dim str
Dim line
dim crNumber
dim userName
dim fileName
Dim input, listFile, listLines
Dim fso

Main()

Sub Main()
Set fso=CreateObject("Scripting.FileSystemObject")

input = "C:\Users\jsmith\Desktop\run.log"
listFile = fso.OpenTextFile(input).ReadAll
listLines = Split(listFile, vbCrLf)
i = 0

For Each line In listLines
  str = MultilineTrim(LCase(line))
  result = InStr(1, str,"cr", 1)
  If(result = 1) Then 
  	colon = InStr(1, str, ":", 1)
  	If(colon >0) Then 
  		crNumber = Mid(str, 4, colon - 4)
  	End If  
  End If  
  result = InStr(1, str," file ", 1)
  If(result > 0) Then 
  	userName = Mid(str, 1, result - 1)
  	fileName = Mid(str, result + 6)
  	SendEmail userName, crNumber, "Test E-mails", fileName
  End If
  Next
End Sub

Function MultilineTrim (Byval TextData)
    Dim textRegExp
    Set textRegExp = new regexp
    textRegExp.Pattern = "\s{0,}(\S{1}[\s,\S]*\S{1})\s{0,}"
    textRegExp.Global = False
    textRegExp.IgnoreCase = True
    textRegExp.Multiline = True

    If textRegExp.Test (TextData) Then
    	MultilineTrim = textRegExp.Replace (TextData, "$1")
    Else
    	MultilineTrim = ""
    End If
End Function

Sub SendEmail(ByVal	userName, ByVal crNumber, ByVal subject, ByVal fileName)
	dim strSMTPFrom
	dim strSMTPTo
	dim strSMTPRelay
	dim strTextBody
	dim strSubject
	dim strAttachment
    dim oMessage

	strSMTPFrom = "cs2autobuild@commandalkon.com"
	strSMTPTo = userName + "@commandalkon.com"
	strSMTPRelay = "mail.commandalkon.com"
	strTextBody = fileName
	strSubject = "Check CR: " + crNumber + " " + subject
	Set oMessage = CreateObject("CDO.Message")
	oMessage.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2 
	oMessage.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") = strSMTPRelay
	oMessage.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25 
	oMessage.Configuration.Fields.Update
	oMessage.Subject = strSubject
	oMessage.From = strSMTPFrom
	oMessage.To = strSMTPTo
	oMessage.TextBody = strTextBody
	oMessage.Send
End Sub 