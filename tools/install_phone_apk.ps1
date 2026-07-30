param(
	[switch]$Rebuild
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$desktopRoot = Split-Path $projectRoot -Parent
$apkPath = Join-Path $desktopRoot "aksoy-tank-builds\aksoy-tank-debug.apk"
$adbPath = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $adbPath)) {
	throw "adb bulunamadi: $adbPath"
}

if ($Rebuild -or -not (Test-Path $apkPath)) {
	& (Join-Path $projectRoot "tools\build_phone_apk.ps1")
}

$deviceLines = & $adbPath devices | Select-Object -Skip 1 | Where-Object { $_ -match "\sdevice$" }
if (-not $deviceLines) {
	throw "Bagli Android cihaz bulunamadi. Telefonu USB ile baglayip USB debugging ac."
}

& $adbPath install -r $apkPath

Write-Host ""
Write-Host "APK telefona yuklendi:"
Write-Host " - $apkPath"
