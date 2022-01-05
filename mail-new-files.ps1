Param (
    [string]$Path = "",
    [string]$PathOud = "",
    [string]$SMTPServer = "",
    [string]$From = "",
    [string]$To = "",
    [string]$Subject = ""
	)

[array]$attachments = Get-ChildItem $Path *.pdf | Where { $_.LastWriteTime -ge [datetime]::Now.AddMinutes(-15) }
Start-Sleep -Seconds 3

$SMTPMessage = @{
    To = $To
    From = $From
    Subject = "$Subject at $Path"
    Smtpserver = $SMTPServer
    Attachments = $attachments.fullname
}

$File = Get-ChildItem $Path *.pdf | Where { $_.LastWriteTime -ge [datetime]::Now.AddMinutes(-15) }
If ($File)
{
    $SMTPBody = ""
    Send-MailMessage @SMTPMessage -Body $SMTPBody
    Start-Sleep -Seconds 4
    $File | ForEach { Move-Item -Path "$($_.FullName)" -Destination $PathOud } -Verbose
}