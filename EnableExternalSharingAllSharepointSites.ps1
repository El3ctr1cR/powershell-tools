Import-Module Microsoft.Online.SharePoint.Powershell -DisableNameChecking
 
#Config Parameters
$AdminSiteURL="https://xxxxxxxxxxxxxx.sharepoint.com/"
 
#Get Credentials to connect to SharePoint Admin Center
$Cred = Get-Credential
 
#Connect to SharePoint Online Admin Center
Connect-SPOService -Url $AdminSiteURL -Credential $Cred
 
#Get All site collections
$SiteCollections = Get-SPOSite -Limit All
Write-Host "Total Number of Site collections Found:"$SiteCollections.count -f Yellow
 
#Array to store Result
$ResultSet = @()
 
#Loop through each site collection and retrieve details
Foreach ($Site in $SiteCollections)
{
    Set-SPOSite -Identity $Site.URL -SharingCapability Disabled
    Set-SPOSite -Identity $Site.URL -SharingCapability ExternalUserSharingOnly
    Set-SPOSite -Identity $Site.URL -SharingCapability ExternalUserAndGuestSharing
    Write-Host "permissions gegeven voor extern delen: "$Site.URL -f Yellow
}