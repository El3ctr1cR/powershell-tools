<#
.DESCRIPTION
	The script connects to Microsoft Graph with app-only authentication, retrieves all Active Directory users and checks their
    password expiration status. If a user's password is either expired or close to expiration (within 7 days), the script sends
    an email notification to the user. The email includes instructions for changing the password and provides IT contact information
    in case of issues. Users without email addresses are skipped, and the script logs these cases.

    PARAMETERS:
    $TenantId            - The Azure AD tenant ID.
    $ClientId            - The application (client) ID registered in Azure AD.
    $ClientSecret        - The client secret for the Azure AD application.
    $SenderEmail         - The email address from which notifications are sent.

    PREREQUISITES:
    - Set up an Azure AD application with the necessary permissions for Microsoft Graph (User.Read.All, Mail.Send).
    - Run this script on a domain controller.
.LINK
	https://github.com/El3ctr1cR/powershell-tools
.NOTES
	Author: Ruben Ruitenberg
#>

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Mail

$TenantId = ''
$ClientId = ''
$ClientSecret = ''
$SenderEmail = ''

$Today = Get-Date

$SecureClientSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
$ClientSecretCredential = New-Object System.Management.Automation.PSCredential ($ClientId, $SecureClientSecret)
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential

Import-Module ActiveDirectory -ErrorAction Stop

function Send-PasswordExpiryEmail {
    param (
        [string]$UserEmail,
        [string]$UserName,
        [string]$Subject,
        [string]$BodyContent
    )

    $Message = @{
        Subject      = $Subject
        Body         = @{
            ContentType = 'Text'
            Content     = $BodyContent
        }
        ToRecipients = @(
            @{
                EmailAddress = @{
                    Address = $UserEmail
                }
            }
        )
    }

    try {
        Send-MgUserMail -UserId $SenderEmail -Message $Message -SaveToSentItems:$false
        Write-Host "Email sent to $UserName at $UserEmail."
    }
    catch {
        Write-Host "Failed to send email to $UserName : $_"
    }
}

$Users = Get-ADUser -Filter * -Properties DisplayName, mail, PasswordNeverExpires, PasswordExpired, msDS-UserPasswordExpiryTimeComputed

foreach ($User in $Users) {
    if ($User.PasswordNeverExpires -eq $true) { continue }

    $ExpiryDate = [datetime]::FromFileTime([int64]$User.'msDS-UserPasswordExpiryTimeComputed')
    $DaysUntilExpiry = ($ExpiryDate - $Today).TotalDays

    if ($User.PasswordExpired -eq $true -or ($DaysUntilExpiry -le 7 -and $DaysUntilExpiry -ge 0)) {
        if ($User.mail) {
            $ContactInfo = "Als u hulp nodig heeft, kunt u contact opnemen met ######### via e-mail of telefonisch op ##########."
            if ($User.PasswordExpired -eq $true) {
                $Subject = 'Uw wachtwoord is verlopen'
                $Body = @"
Beste $($User.DisplayName),

Uw wachtwoord is verlopen. Verander uw wachtwoord door op CTRL+ALT+END te drukken en te kiezen voor 'Wachtwoord wijzigen'.

$ContactInfo

Met vriendelijke groet,
Uw IT-afdeling
"@
            }
            else {
                $Subject = 'Wachtwoord verloopt binnenkort'
                $Body = @"
Beste $($User.DisplayName),

Uw wachtwoord verloopt over $([math]::Round($DaysUntilExpiry,0)) dagen. Verander uw wachtwoord door op CTRL+ALT+END te drukken en te kiezen voor 'Wachtwoord wijzigen'.

$ContactInfo

Met vriendelijke groet,
Uw IT-afdeling
"@
            }
            Send-PasswordExpiryEmail -UserEmail $User.mail -UserName $User.DisplayName -Subject $Subject -BodyContent $Body
        }
        else {
            Write-Host "User $($User.DisplayName) does not have an email address. Skipping."
        }
    }
}

Disconnect-MgGraph
