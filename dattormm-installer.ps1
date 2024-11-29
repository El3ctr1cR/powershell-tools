<#
.DESCRIPTION
	This script downloads and installs the Datto RMM Agent for a specified platform and site,
    then cleans up the installer after installation. Designed for use with Microsoft Intune.
.LINK
	https://github.com/El3ctr1cR/powershell-tools
.NOTES
	Author: Ruben Ruitenberg
#>

# --- Configuration Parameters ---
$Platform = "pinotage"
$SiteID = "1c409201-4211-4489-b9a6-cb9256991a83"

# --- Initial Check: Exit if Agent is already installed ---
If (Get-Service CagService -ErrorAction SilentlyContinue) {
    Write-Output "Datto RMM Agent is already installed on this device. Exiting..."
    exit
}

# --- Define Agent Download URL ---
$AgentURL = "https://$Platform.centrastage.net/csm/profile/downloadAgent/$SiteID"
Write-Output "Datto RMM Agent Deployment Script Initialized."
Write-Output "Platform: $Platform | Site ID: $SiteID"
Write-Output "Agent URL: $AgentURL"

# --- Download the Agent Installer ---
$DownloadStart = Get-Date
Write-Output "Starting Agent download at $(Get-Date -Format HH:mm)..."

# Ensure TLS 1.2 is enabled for secure download
try {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
} catch {
    Write-Output "Cannot proceed: Invalid or unsupported security protocol. 
    Ensure TLS 1.2 is enabled on this system and try again."
    exit 1
}

# Attempt to download the installer
try {
    (New-Object System.Net.WebClient).DownloadFile($AgentURL, "$env:TEMP\DRMMSetup.exe")
    Write-Output "Agent download completed successfully in $((Get-Date).Subtract($DownloadStart).Seconds) seconds."
} catch {
    Write-Output "Agent download failed. Error details:`r`n$_"
    exit 1
}

# --- Install the Agent ---
$InstallStart = Get-Date
Write-Output "Starting Agent installation at $(Get-Date -Format HH:mm)..."

try {
    & "$env:TEMP\DRMMSetup.exe" | Out-Null
    Write-Output "Agent installation completed successfully at $(Get-Date -Format HH:mm) 
    in $((Get-Date).Subtract($InstallStart).Seconds) seconds."
} catch {
    Write-Output "Agent installation failed. Error details:`r`n$_"
    exit 1
}

# --- Clean Up Installer ---
Write-Output "Cleaning up temporary files..."
Remove-Item "$env:TEMP\DRMMSetup.exe" -Force -ErrorAction SilentlyContinue
Write-Output "Deployment completed successfully. Exiting script."
exit
