$installPath = "C:\DuoInstall"
$duoAppName = "Duo Authentication for Windows Logon x64"
$downloadUrl = "https://dl.duosecurity.com/DuoWinLogon_MSIs_Policies_and_Documentation-latest.zip"
$downloadPath = "$installPath\DuoWinLogon.zip"
$specificFile = "DuoWindowsLogon64.msi"

if (Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -eq $duoAppName}) {
    Write-Host "$duoAppName is al geinstalleerd."
} else {
    Write-Host "$duoAppName word nu geinstalleerd..."
    if (Test-Path $installPath) {
        Write-Host "Het pad $installPath bestaat al. Overslaan..."
    } else {
        mkdir $installPath
    }
    Invoke-WebRequest $downloadUrl -o $downloadPath
    $shellApp = New-Object -ComObject Shell.Application
    $zipFile = $shellApp.Namespace($downloadPath)
    $destinationFolder = $shellApp.Namespace($installPath)
    $specificFileItem = $zipFile.Items() | Where-Object { $_.Name -eq $specificFile }
    if ($specificFileItem) {
        $destinationFolder.CopyHere($specificFileItem, 16)
    } else {
        Write-Host "Het bestand $specificFile kon niet worden uitgepakt."
    }
    $msiPath = Join-Path $installPath $specificFile
    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" IKEY=`"XXXXXXXXXXXXXX`" SKEY=`"XXXXXXXXXXXXXX`" HOST=`"XXXXXXXXXXXXXX`" AUTOPUSH=`"#1`" FAILOPEN=`"#0`" ENABLEOFFLINE=`"#0`" SMARTCARD=`"#0`" RDPONLY=`"#0`" USERNAMEFORMAT=`"#2`" UAC_PROTECTMODE=`"#2`" UAC_OFFLINE=`"#0`" /qn" -Wait
    Get-ChildItem $installPath -Recurse | Remove-Item -Force
    Remove-Item $installPath
}