Import-Module ActiveDirectory
$expiring = @()
$users = Get-ADUser -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $false} -Properties "DisplayName", "mail", "PasswordLastSet"
$max = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
foreach ($user in $users) {
	$now = Get-Date
	$expiredate = $user.PasswordLastSet.AddDays($max)
	$diff = New-TimeSpan $now $expiredate
	if ($diff.Days -le 7 -and $diff.Days -ge 0) {
		$entry = [PSCustomObject]@{
			Name = $user.DisplayName
			Email = $user.mail
			ExpireDate = $expiredate
		}
		$expiring += $entry
	}
}
$expiring | Export-Csv -Path "$PSScriptRoot\expiring_soon.csv" -NoTypeInformation