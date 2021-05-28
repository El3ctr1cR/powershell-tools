Import-Module Hyper-V
$backuppath = ""
$vms = Get-VM
$today = Get-Date -Format MM-dd-yy

foreach ($vm in $vms) {
    $vmname = $vm.Name
    Write-Host "Backing up $vmname..."
    New-Item -ItemType Directory -Path "$backuppath\$vmname" # We run this in case it is a new VM. Normally it will fail if the VM folder already exists, which is fine
    New-Item -ItemType Directory -Path "$backuppath\$vmname\$today"
    Export-VM -VM $vm -Path "$backuppath\$vmname\$today"
    New-BurntToastNotification -Text "$vmname has been exported." -AppLogo $null -Silent
    # Remove any backups older than the past 7 days
    Get-ChildItem "$backuppath\$vmname" | Sort-Object -Property CreationTime -Descending | Select-Object -Skip 7 | Remove-Item -Recurse
}