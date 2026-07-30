param(
	[switch]$SkipAssetGeneration,
	[switch]$SkipScreenshotCapture,
	[switch]$SkipPhoneApk,
	[switch]$SkipReleaseBundle
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$desktopRoot = Split-Path $projectRoot -Parent
$outputDir = Join-Path $desktopRoot "aksoy-tank-builds"

if (-not $SkipAssetGeneration) {
	& (Join-Path $projectRoot "tools\generate_store_assets.ps1")
}

if (-not $SkipPhoneApk) {
	& (Join-Path $projectRoot "tools\build_phone_apk.ps1")
}

if (-not $SkipReleaseBundle) {
	& (Join-Path $projectRoot "tools\build_release_bundle.ps1")
}

if (-not $SkipScreenshotCapture) {
	& (Join-Path $projectRoot "tools\capture_store_screens.ps1")
}

Write-Host ""
Write-Host "Android ciktilari hazir:"
Write-Host " - $(Join-Path $outputDir 'aksoy-tank-debug.apk')"
Write-Host " - $(Join-Path $outputDir 'aksoy-tank-release.aab')"
Write-Host " - $(Join-Path $projectRoot 'assets\\store\\listing\\screenshots')"
