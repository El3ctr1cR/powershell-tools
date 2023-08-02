$users = Get-ADUser -Filter { Enabled -eq $true -and PasswordNeverExpires -eq $false } -Properties "DisplayName", "mail", "PasswordLastSet"

foreach ($user in $users) {
    $firstname = $user.givenName
    $daysleft = (([datetime]::FromFileTime((Get-ADUser –Identity $user.SamAccountName -Properties "msDS-UserPasswordExpiryTimeComputed")."msDS-UserPasswordExpiryTimeComputed")) - (Get-Date)).Days

    if ($daysleft -lt 0) {
        $Subject = "Your password has expired!"
        $Body = "Dear $firstname,<br><br>"
        $Body += "We want to inform you that your password has expired.<br>"
        $Body += "To unlock this account, please contact our support department. We can be reached at xxx-xxxxxxx or via xxx@xxxxxxxxx.nl.<br><br>"
        $Body += "Best regards,<br><br>"
        $Body += "<br>"
    } elseif ($daysleft -lt 15) {
        $Subject = "Your password will expire soon!"
        $Body = "Dear $firstname,<br><br>"
        $Body += "We want to inform you that your password will expire in $daysleft days. We recommend changing it as soon as possible.<br>"
        $Body += "You can do this most easily by clicking on this link: https://xxxxxxxxx.nl/RDWeb/Pages/en-US/password.aspx<br>"
        $Body += "For any questions, feel free to contact us at xxx-xxxxxxx or via xxx@xxxxxxxxx.nl.<br><br>"
        $Body += "Best regards,<br>"
        $Body += "<br>"
    } else {
        continue
    }

    $From = ""
    $To = $user.mail
    $SMTPServer = ""
    $SMTPPort = "25"

    Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -BodyAsHtml -Priority High -SmtpServer $SMTPServer -Port $SMTPPort
}
