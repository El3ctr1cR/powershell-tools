<#
.SYNOPSIS
	Installs DUO Security
.DESCRIPTION
	This only installs DUO Security on user endpoints through Datto RMM.
.EXAMPLE
	PS> ./duo-endpoint-installer
.LINK
	https://github.com/El3ctr1cR/powershell-tools
.NOTES
	Author: Ruben Ruitenberg
#>

$installPath = "C:\DuoInstall"
$duoAppName = "Duo Authentication for Windows Logon x64"
$downloadUrl = "https://dl.duosecurity.com/DuoWinLogon_MSIs_Policies_and_Documentation-latest.zip"
$downloadPath = "$installPath\DuoWinLogon.zip"
$specificFile = "DuoWindowsLogon64.msi"
$duo_IKEY = $env:duo_IKEY
$duo_SKEY = $env:duo_SKEY
$duo_HOST = $env:duo_HOST

if (IsServer) {
    Write-Host "This script is not allowed to be run on this type of system. Exiting..."
} else {
    if (Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -eq $duoAppName}) {
        Write-Host "$duoAppName is already installed"
    } else {
        Write-Host "$duoAppName is getting installed..."
        if (Test-Path $installPath) {
            Write-Host "The PATH $installPath already exists. Skipping..."
        } else {
            mkdir $installPath
        }
        Invoke-WebRequest $downloadUrl -o $downloadPath
        
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $installPath)

        $msiPath = Join-Path $installPath $specificFile

        Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" IKEY=`"$duo_IKEY`" SKEY=`"$duo_SKEY`" HOST=`"$duo_HOST`" AUTOPUSH=`"#1`" FAILOPEN=`"#0`" ENABLEOFFLINE=`"#0`" SMARTCARD=`"#0`" RDPONLY=`"#0`" USERNAMEFORMAT=`"#2`" UAC_PROTECTMODE=`"#2`" UAC_OFFLINE=`"#0`" /qn" -Wait

        Get-ChildItem $installPath -Recurse | Remove-Item -Recurse -Force
        Remove-Item $installPath -Recurse -Force
    }
}