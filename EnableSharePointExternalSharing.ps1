<#
.DESCRIPTION
	Enables external sharing on all sharepoint sites.
.LINK
	https://github.com/El3ctr1cR/powershell-tools
.NOTES
	Author: Ruben Ruitenberg
#>

Import-Module Microsoft.Online.SharePoint.Powershell -DisableNameChecking

$AdminSiteURL="https://xxxxxxxxxxxxxx.sharepoint.com/"
$Cred = Get-Credential
Connect-SPOService -Url $AdminSiteURL -Credential $Cred
$SiteCollections = Get-SPOSite -Limit All
Write-Host "Total Number of Site collections Found:"$SiteCollections.count -f Yellow
$ResultSet = @()
Foreach ($Site in $SiteCollections)
{
    Set-SPOSite -Identity $Site.URL -SharingCapability Disabled
    Set-SPOSite -Identity $Site.URL -SharingCapability ExternalUserSharingOnly
    Set-SPOSite -Identity $Site.URL -SharingCapability ExternalUserAndGuestSharing
    Write-Host "permissions gegeven voor extern delen: "$Site.URL -f Yellow
}