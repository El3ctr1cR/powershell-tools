Import-Module ActiveDirectory
$expiring = @()
$users = Get-ADUser -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $false} -Properties "DisplayName", "mail", "PasswordLastSet"
$max = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
foreach ($user in $users) {
	$now = Get-Date
	$expiredate = $user.PasswordLastSet.AddDays($max)
	$diff = New-TimeSpan $now $expiredate
	if ($diff.Days -le 7 -and $diff.Days -ge 0) {
		$subject = "Your Password Is Expiring This Week"
		$from = "x@x.com"
		$to = @($user.email)
		$cc = @()
		$bcc = @()
		$body = "<h3>Your password will be expring in $diff day(s).  Please change it as soon as possible.</h3>"
		$priority = "Normal"
		$attachments = @()
		Send-Email($subject, $body, $from, $to, $cc, $bcc, $priority, $attachments)
	}
}