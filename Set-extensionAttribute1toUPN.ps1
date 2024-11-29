<#
.DESCRIPTION
	This script sets extensionAttribute1 to the main UPN of the device, so you can make dynamic Entra groups with devices. 
.LINK
	https://github.com/El3ctr1cR/powershell-tools
.NOTES
	Author: Ruben Ruitenberg

    PREREQUISITES:
    - Set up an Azure AD application with the necessary permissions for Microsoft Graph (Device.ReadWrite.All, Directory.ReadWrite.All and User.Read.All).
#>

$ClientId = ""
$ClientSecret = ""
$TenantId = ""

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage

    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

$logFile = ".\Update_DevicePrimaryUserUPN.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "`n`n--- Script execution started at $timestamp ---"
Write-Log "Script started"

try {
    $SecureClientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force

    $ClientSecretCredential = New-Object System.Management.Automation.PSCredential($ClientId, $SecureClientSecret)

    Connect-MgGraph -ClientSecretCredential $ClientSecretCredential -TenantId $TenantId
    Write-Log "Connected to Microsoft Graph using app-only authentication"
}
catch {
    Write-Log "Failed to connect to Microsoft Graph: $_" -Level "ERROR"
    exit 1
}

$devices = @()
$nextLink = "https://graph.microsoft.com/v1.0/devices?`$select=id,displayName,extensionAttributes"

while ($nextLink) {
    try {
        $response = Invoke-MgGraphRequest -Method GET -Uri $nextLink
        $devices += $response.value
        $nextLink = $response.'@odata.nextLink'
    }
    catch {
        Write-Log "Failed to retrieve devices: $_" -Level "ERROR"
        exit 1
    }
}

Write-Log "Total managed devices retrieved: $($managedDevices.Count)"

$managedDevicesHashtable = @{}
foreach ($md in $managedDevices) {
    if ($md.azureADDeviceId -and $md.userPrincipalName) {
        $managedDevicesHashtable[$md.azureADDeviceId] = $md.userPrincipalName
    }
}

$successCount = 0
$failureCount = 0

foreach ($device in $devices) {
    $deviceName = $device.displayName
    $deviceId = $device.id

    Write-Log "Processing device: $deviceName"

    $primaryUserUPN = $null

    if ($managedDevicesHashtable.ContainsKey($deviceId)) {
        $primaryUserUPN = $managedDevicesHashtable[$deviceId]
        Write-Log "Primary user found via managedDevices: $primaryUserUPN"
    }

    if (-not $primaryUserUPN) {
        try {
            $registeredOwnersUri = "https://graph.microsoft.com/v1.0/devices/$deviceId/registeredOwners"
            $registeredOwnersResponse = Invoke-MgGraphRequest -Uri $registeredOwnersUri -Method GET

            if ($registeredOwnersResponse.value.Count -gt 0) {
                foreach ($owner in $registeredOwnersResponse.value) {
                    if ($owner.'@odata.type' -eq "#microsoft.graph.user") {
                        $primaryUserUPN = $owner.userPrincipalName
                        Write-Log "Primary user found via registeredOwners: $primaryUserUPN"
                        break
                    }
                }
            }
            else {
                Write-Log "No registeredOwners found for device $deviceName" -Level "WARNING"
            }
        }
        catch {
            Write-Log "Error retrieving registeredOwners: $_" -Level "ERROR"
        }
    }

    if ($primaryUserUPN) {
        try {
            $updateUri = "https://graph.microsoft.com/v1.0/devices/$deviceId"
            $body = @{
                extensionAttributes = @{
                    extensionAttribute1 = "$primaryUserUPN"
                }
            }

            Invoke-MgGraphRequest -Uri $updateUri -Method PATCH -Body ($body | ConvertTo-Json -Compress)
            Write-Log "Successfully updated extensionAttribute1 for device $deviceName" -Level "SUCCESS"
            $successCount++
        }
        catch {
            Write-Log "Failed to update extensionAttribute1 for device $deviceName : $_" -Level "ERROR"
            $failureCount++
        }
    }
    else {
        Write-Log "No primary user found for device $deviceName" -Level "WARNING"
        $failureCount++
    }
}

Write-Progress -Activity "Processing Devices" -Completed

Write-Log "Device details update process completed."
Write-Log "Total devices processed: $deviceCount"
Write-Log "Successful updates: $successCount" -Level "SUCCESS"
Write-Log "Failed updates: $failureCount" -Level $(if ($failureCount -eq 0) { "SUCCESS" } else { "WARNING" })

Write-Log "Script completed"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "--- Script execution ended at $timestamp ---`n"