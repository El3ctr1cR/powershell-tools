if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Mail

$TenantId = ''
$ClientId = ''
$ClientSecret = ''
$SenderEmail = ''
$Scopes = @('https://graph.microsoft.com/.default')
$SecureClientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$AppCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $SecureClientSecret
$Today = Get-Date
$Users = Get-ADUser -Filter * -Properties DisplayName, mail, PasswordLastSet, PasswordNeverExpires, PasswordExpired, msDS-UserPasswordExpiryTimeComputed

Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -ClientSecret $SecureClientSecret -Scopes $Scopes

Import-Module ActiveDirectory

foreach ($User in $Users) {
    if ($User.PasswordNeverExpires -eq $true) {
        continue
    }

    $ExpiryDate = [datetime]::FromFileTime([int64]$User.'msDS-UserPasswordExpiryTimeComputed')
    $DaysUntilExpiry = ($ExpiryDate - $Today).TotalDays

    if ($DaysUntilExpiry -le 7 -and $DaysUntilExpiry -ge 0) {
        if ($User.mail) {
            Write-Host "Sending email to $($User.DisplayName) at $($User.mail). Password expires in $([math]::Round($DaysUntilExpiry,0)) days."

            $EmailBody = @"
Beste $($User.DisplayName),

Uw wachtwoord verloopt over $([math]::Round($DaysUntilExpiry,0)) dagen. Verander uw wachtwoord door op CTRL+ALT+END te drukken en te kiezen voor 'Wachtwoord wijzigen'.

Met vriendelijke groet,
Uw IT-afdeling
"@

            $Message = @{
                Subject = 'Wachtwoord verloopt binnenkort'
                Body    = @{
                    ContentType = 'Text'
                    Content     = $EmailBody
                }
                ToRecipients = @(
                    @{
                        EmailAddress = @{
                            Address = $User.mail
                        }
                    }
                )
                From = @{
                    EmailAddress = @{
                        Address = $SenderEmail
                    }
                }
            }

            try {
                Send-MgUserMessage -UserId $SenderEmail -Message $Message -SaveToSentItems:$false
            } catch {
                Write-Host "Failed to send email to $($User.DisplayName): $_"
            }
        } else {
            Write-Host "User $($User.DisplayName) does not have an email address. Skipping."
        }
    }
}

Disconnect-MgGraph
