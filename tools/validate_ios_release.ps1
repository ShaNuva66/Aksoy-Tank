[CmdletBinding()]
param(
	[switch]$SkipAccountChecks,
	[switch]$SkipScreenshots
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$presetPath = Join-Path $projectRoot 'export_presets.cfg'
$projectPath = Join-Path $projectRoot 'project.godot'
$iconPath = Join-Path $projectRoot 'assets\store\icons\ios-app-icon-1024.png'
$screenshotDirs = @(
	@{ Label = '6.9'; Path = (Join-Path $projectRoot 'assets\store\listing\ios-screenshots-6.9'); Sizes = @('2736x1260', '2796x1290', '2868x1320') },
	@{ Label = '6.5'; Path = (Join-Path $projectRoot 'assets\store\listing\ios-screenshots-6.5'); Sizes = @('2778x1284', '2688x1242') }
)
$failures = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$Message) { $failures.Add($Message) }
function Add-Warning([string]$Message) { $warnings.Add($Message) }

$preset = [System.IO.File]::ReadAllText($presetPath)
$project = [System.IO.File]::ReadAllText($projectPath)

if ($preset -notmatch '(?m)^name="iOS"$') { Add-Failure 'iOS export preset bulunamadi.' }
if ($preset -notmatch '(?m)^platform="iOS"$') { Add-Failure 'iOS export platformu ayarli degil.' }
if ($preset -notmatch '(?m)^application/bundle_identifier="com\.atalay\.aksoytank"$') { Add-Failure 'Bundle ID com.atalay.aksoytank degil.' }
if ($preset -notmatch '(?m)^application/short_version="1\.0"$') { Add-Failure 'App Store iOS kisa surumu 1.0 degil.' }
if ($preset -notmatch '(?m)^application/version="(?:__BUILD_NUMBER__|[1-9][0-9]*)"$') { Add-Failure 'iOS build numarasi gecersiz.' }
if ($preset -notmatch '(?m)^application/min_ios_version="15\.0"$') { Add-Failure 'Minimum iOS surumu 15.0 degil.' }
if ($preset -notmatch '(?m)^application/targeted_device_family=0$') { Add-Failure 'Hedef cihaz ailesi yalnizca iPhone olarak ayarlanmamis.' }
if ($preset -notmatch '(?m)^architectures/arm64=true$') { Add-Failure 'arm64 mimarisi etkin degil.' }
if ($preset -notmatch 'ITSAppUsesNonExemptEncryption') { Add-Failure 'Sifreleme ihracat uygunluk anahtari eksik.' }
if ($preset -notmatch '(?m)^privacy/tracking_enabled=false$') { Add-Failure 'Takip kapali olarak beyan edilmemis.' }
if ($project -notmatch '(?m)^config/features=PackedStringArray\("4\.6"\)$') { Add-Failure 'Proje Godot 4.6 olarak ayarli degil.' }
if ($project -notmatch '(?m)^window/handheld/orientation=0$') { Add-Failure 'Oyun yatay ekran yonune sabitlenmemis.' }

if (-not $SkipAccountChecks) {
	if ($preset -cmatch '(?m)^application/app_store_team_id="([A-Z0-9]{10})"$') {
		if ($Matches[1] -eq 'YOURTEAMID') {
			Add-Failure 'YOURTEAMID yerine Apple Developer Membership sayfasindaki gercek Team ID girilmeli.'
		}
	} else {
		Add-Failure 'Apple Team ID tam olarak 10 buyuk harf/rakam olmali.'
	}
}

if (-not (Test-Path -LiteralPath $iconPath)) {
	Add-Failure '1024x1024 iOS App Store ikonu eksik.'
} else {
	$icon = [System.Drawing.Bitmap]::new($iconPath)
	if ($icon.Width -ne 1024 -or $icon.Height -ne 1024) { Add-Failure 'iOS App Store ikonu 1024x1024 degil.' }
	if ($icon.PixelFormat.ToString() -match 'Alpha|Argb') { Add-Failure 'iOS App Store ikonunda alpha kanali var.' }
	$icon.Dispose()
}

$sourceFiles = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src') -Recurse -File |
	Where-Object { $_.Extension -in @('.gd', '.tscn') }
$insecureEndpoints = $sourceFiles | Select-String -SimpleMatch 'ws://' |
	Where-Object { $_.Line -notmatch 'ws://(127\.0\.0\.1|localhost)' }
if ($insecureEndpoints) {
	$insecureEndpoint = $insecureEndpoints | Select-Object -First 1
	Add-Failure "Kaynakta guvensiz yapim ws:// adresi var: $($insecureEndpoint.Path):$($insecureEndpoint.LineNumber)"
}
$sessionSource = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'src\scripts\game_session.gd'))
if ($sessionSource -notmatch 'const ONLINE_AVAILABLE := true') {
	Add-Failure 'Online 1V1 modu UI tarafinda etkin degil.'
}
if ($sessionSource -notmatch 'const DEFAULT_SERVER_URL := "wss://atify\.com\.tr/aksoy-tank/ws"') {
	Add-Failure 'Online 1V1 yapim WSS adresi beklenen guvenli adres degil.'
}

if (-not $SkipScreenshots) {
	foreach ($screenshotSet in $screenshotDirs) {
		$screenshots = @(Get-ChildItem -LiteralPath $screenshotSet.Path -File -ErrorAction SilentlyContinue |
			Where-Object { $_.Extension.ToLowerInvariant() -in @('.png', '.jpg', '.jpeg') })
		if ($screenshots.Count -lt 1 -or $screenshots.Count -gt 10) {
			Add-Failure "App Store $($screenshotSet.Label)-inc bolumu icin 1-10 adet iPhone ekran goruntusu gerekli."
		}
		foreach ($file in $screenshots) {
			$image = [System.Drawing.Bitmap]::new($file.FullName)
			$size = "$($image.Width)x$($image.Height)"
			if ($screenshotSet.Sizes -notcontains $size) { Add-Failure "$($file.Name) Apple iPhone $($screenshotSet.Label)-inc olculerinden birinde degil: $size" }
			if ($image.PixelFormat.ToString() -match 'Alpha|Argb') { Add-Failure "$($file.Name) alpha kanali iceriyor." }
			$image.Dispose()
		}
	}
}

if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'docs\aksoy-tank-gizlilik.html'))) {
	Add-Failure 'Yayinlanacak gizlilik politikasi HTML dosyasi eksik.'
}

foreach ($warning in $warnings) { Write-Warning $warning }
if ($failures.Count -gt 0) {
	Write-Host 'iOS yayin kontrolu BASARISIZ:' -ForegroundColor Red
	foreach ($failure in $failures) { Write-Host " - $failure" -ForegroundColor Red }
	exit 1
}

Write-Host 'iOS kaynak ve magazaya hazirlik kontrolleri BASARILI.' -ForegroundColor Green
