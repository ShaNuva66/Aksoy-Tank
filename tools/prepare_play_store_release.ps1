$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$desktopRoot = Split-Path $projectRoot -Parent
$outputDir = Join-Path $desktopRoot "aksoy-tank-builds"
$outputAabPath = Join-Path $outputDir "aksoy-tank-release.aab"
$outputApkPath = Join-Path $outputDir "aksoy-tank-debug.apk"
$releaseNotesSource = Join-Path $projectRoot "docs\play-store-guncelleme-notlari.md"
$releaseNotesOutput = Join-Path $outputDir "guncelleme-notlari-1.9.2.txt"

function Get-GodotExecutable {
	$candidates = @(
		(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64_console.exe" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -ExpandProperty FullName),
		(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64.exe" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -ExpandProperty FullName)
	) | Where-Object { $_ }

	if (-not $candidates) {
		throw "Godot executable bulunamadi."
	}

	return $candidates[0]
}

function Get-JavaHome {
	$candidate = Get-ChildItem "C:\Program Files\Eclipse Adoptium\jdk-*" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
	if (-not $candidate) {
		throw "JDK 17 veya ustu bulunamadi."
	}

	return $candidate.FullName
}

function Invoke-Step {
	param(
		[string]$Name,
		[scriptblock]$Script
	)

	Write-Host ""
	Write-Host "== $Name =="
	& $Script
}

function Test-AabAbiSupport {
	param(
		[string]$AabPath
	)

	if (-not (Test-Path $AabPath)) {
		throw "AAB bulunamadi: $AabPath"
	}

	$jarExe = Join-Path (Get-JavaHome) "bin\jar.exe"
	if (-not (Test-Path $jarExe)) {
		throw "jar.exe bulunamadi: $jarExe"
	}

	$entries = & $jarExe tf $AabPath
	if ($LASTEXITCODE -ne 0) {
		throw "AAB icerigi okunamadi."
	}

	if (-not ($entries -match "^base/lib/armeabi-v7a/.+\.so$")) {
		throw "AAB icinde armeabi-v7a native kutuphanesi yok."
	}

	if (-not ($entries -match "^base/lib/arm64-v8a/.+\.so$")) {
		throw "AAB icinde arm64-v8a native kutuphanesi yok."
	}
}

function Test-AndroidPackageMetadata {
	param(
		[string]$ApkPath
	)

	$aaptExe = Join-Path $env:LOCALAPPDATA "Android\Sdk\build-tools\36.0.0\aapt.exe"
	if (-not (Test-Path $aaptExe)) {
		throw "Android Build Tools 36.0.0 bulunamadi: $aaptExe"
	}
	if (-not (Test-Path $ApkPath)) {
		throw "APK bulunamadi: $ApkPath"
	}

	$badging = (& $aaptExe dump badging $ApkPath) -join "`n"
	if ($LASTEXITCODE -ne 0) { throw "APK manifest bilgisi okunamadi." }
	if ($badging -notmatch "package: name='com\.atalay\.aksoytank' versionCode='21' versionName='1\.9\.2'") {
		throw "APK paket veya surum bilgisi beklenen degerde degil."
	}
	if ($badging -notmatch "sdkVersion:'24'") { throw "APK minimum SDK 24 degil." }
	if ($badging -notmatch "targetSdkVersion:'36'") { throw "APK hedef SDK 36 degil." }
	if ($badging -notmatch "native-code:.*'armeabi-v7a'" -or $badging -notmatch "native-code:.*'arm64-v8a'") {
		throw "APK ARMv7 ve ARM64 mimarilerini birlikte icermiyor."
	}
}

function Test-AabSignature {
	param(
		[string]$AabPath
	)

	$jarsignerExe = Join-Path (Get-JavaHome) "bin\jarsigner.exe"
	& $jarsignerExe -verify $AabPath | Out-Null
	if ($LASTEXITCODE -ne 0) { throw "AAB imza dogrulamasi basarisiz." }
}

function Test-AabManifestMetadata {
	$manifestPath = Join-Path $projectRoot "android\build\build\intermediates\bundle_manifest\standardRelease\processApplicationManifestStandardReleaseForBundle\AndroidManifest.xml"
	if (-not (Test-Path $manifestPath)) { throw "AAB release manifesti bulunamadi." }
	$manifest = Get-Content $manifestPath -Raw
	if ($manifest -notmatch 'package="com\.atalay\.aksoytank"') { throw "AAB paket adi hatali." }
	if ($manifest -notmatch 'android:versionCode="21"' -or $manifest -notmatch 'android:versionName="1\.9\.2"') {
		throw "AAB surum bilgisi hatali."
	}
	if ($manifest -notmatch 'android:minSdkVersion="24"' -or $manifest -notmatch 'android:targetSdkVersion="36"') {
		throw "AAB Android API bilgisi hatali."
	}
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$godotExe = Get-GodotExecutable

Push-Location $projectRoot
try {
	Invoke-Step "Bolum katalog testi" {
		& $godotExe --headless --path $projectRoot --script res://tools/audit_all_stages.gd
		if ($LASTEXITCODE -ne 0) { throw "Bolum katalog testi basarisiz." }
	}

	Invoke-Step "Oynanis regresyon testi" {
		& $godotExe --headless --path $projectRoot --script res://tools/gameplay_regression_test.gd
		if ($LASTEXITCODE -ne 0) { throw "Oynanis regresyon testi basarisiz." }
	}

	Invoke-Step "Profesyonel hitbox regresyon testi" {
		& $godotExe --headless --path $projectRoot --script res://tools/hitbox_regression_test.gd
		if ($LASTEXITCODE -ne 0) { throw "Hitbox regresyon testi basarisiz." }
	}

	Invoke-Step "Duvar ve kose carpisma testi" {
		& $godotExe --headless --path $projectRoot --script res://tools/wall_collision_regression_test.gd
		if ($LASTEXITCODE -ne 0) { throw "Duvar carpisma testi basarisiz." }
	}

	Invoke-Step "Tank temas ve ayrilma testi" {
		& $godotExe --headless --path $projectRoot --script res://tools/tank_separation_regression_test.gd
		if ($LASTEXITCODE -ne 0) { throw "Tank ayrilma testi basarisiz." }
	}

	Invoke-Step "Cevrim ici yumusatma testi" {
		& $godotExe --headless --path $projectRoot --script res://tools/network_smoothing_test.gd
		if ($LASTEXITCODE -ne 0) { throw "Cevrim ici yumusatma testi basarisiz." }
	}

	Invoke-Step "Mobil kontrol smoke testi" {
		& $godotExe --headless --path $projectRoot --script res://tools/mobile_touch_smoke_test.gd
		if ($LASTEXITCODE -ne 0) { throw "Mobil kontrol smoke testi basarisiz." }
	}

	Invoke-Step "60. bolum baslangic testi" {
		& $godotExe --headless --path $projectRoot --script res://tools/start_stage_60_smoke_test.gd -- --start-stage=60 --auto-start
		if ($LASTEXITCODE -ne 0) { throw "60. bolum baslangic testi basarisiz." }
	}

	Invoke-Step "Android ciktilari" {
		& (Join-Path $projectRoot "tools\export_android.ps1")
		if ($LASTEXITCODE -ne 0) { throw "Android export basarisiz." }
	}

	Invoke-Step "AAB mimari kontrolu" {
		Test-AabAbiSupport -AabPath $outputAabPath
	}

	Invoke-Step "Android API ve surum kontrolu" {
		Test-AndroidPackageMetadata -ApkPath $outputApkPath
		Test-AabManifestMetadata
	}

	Invoke-Step "AAB imza kontrolu" {
		Test-AabSignature -AabPath $outputAabPath
	}

	Get-ChildItem $outputDir -Filter "guncelleme-notlari-*.txt" -File -ErrorAction SilentlyContinue |
		Where-Object { $_.FullName -ne $releaseNotesOutput } |
		Remove-Item -Force
	Copy-Item -LiteralPath $releaseNotesSource -Destination $releaseNotesOutput -Force

	Write-Host ""
	Write-Host "Play Store paketi hazir:"
	Write-Host " - $outputAabPath"
	Write-Host " - $releaseNotesOutput"
	Write-Host " - $(Join-Path $projectRoot 'assets\store\listing')"
	Start-Process explorer.exe $outputDir
} finally {
	Pop-Location
}
