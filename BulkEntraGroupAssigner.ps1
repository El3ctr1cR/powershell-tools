<#
.DESCRIPTION
	Assign users a Entra group through a CSV file.
.LINK
	https://github.com/El3ctr1cR/powershell-tools
.NOTES
	Author: Ruben Ruitenberg
#>

Connect-AzureAD
$csvFilePath = ""
$groupId = ""

if (!(Test-Path $csvFilePath)) {
    Write-Error "CSV file not found at path: $csvFilePath"
    exit
}

$users = Import-Csv -Path $csvFilePath
foreach ($user in $users) {
    $userPrincipalName = $user.userPrincipalName

    try {
        Add-AzureADGroupMember -ObjectId $groupId -RefObjectId (Get-AzureADUser -Filter "UserPrincipalName eq '$userPrincipalName'").ObjectId
        Write-Output "User $userPrincipalName has been added to the group successfully."
    } catch {
        Write-Warning "Failed to add user $userPrincipalName to the group. Error: $_"
    }
}

Write-Output "Script completed."