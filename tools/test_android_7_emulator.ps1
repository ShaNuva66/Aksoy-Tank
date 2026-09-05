param(
	[string]$ApkPath = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"
$emulator = Join-Path $sdkRoot "emulator\emulator.exe"
$avdManager = Join-Path $sdkRoot "cmdline-tools\latest\bin\avdmanager.bat"
$avdName = "AksoyTank_API24"
$systemImage = "system-images;android-24;default;x86_64"
$outputDir = Join-Path (Split-Path $projectRoot -Parent) "aksoy-tank-builds"
if (-not $ApkPath) {
	$ApkPath = Join-Path $outputDir "aksoy-tank-api24-test.apk"
}

foreach ($required in @($adb, $emulator, $avdManager)) {
	if (-not (Test-Path $required)) { throw "Android emulator araci bulunamadi: $required" }
}

$availableAvds = (& $emulator -list-avds) -split "`r?`n"
if ($availableAvds -notcontains $avdName) {
	"no" | & $avdManager create avd --force --name $avdName --package $systemImage --device "pixel_2"
	if ($LASTEXITCODE -ne 0) { throw "Android 7 AVD olusturulamadi." }
}
$avdConfigPath = Join-Path $env:USERPROFILE ".android\avd\$avdName.avd\config.ini"
if (-not (Test-Path $avdConfigPath)) { throw "Android 7 AVD ayari bulunamadi." }
$avdConfig = Get-Content $avdConfigPath -Raw
$avdConfig = $avdConfig -replace "(?m)^hw\.gpu\.enabled=.*$", "hw.gpu.enabled=yes"
$avdConfig = $avdConfig -replace "(?m)^hw\.gpu\.mode=.*$", "hw.gpu.mode=host"
Set-Content -LiteralPath $avdConfigPath -Value $avdConfig -Encoding ASCII

& (Join-Path $projectRoot "tools\build_phone_apk.ps1") -EnabledAbis "x86_64" -OutputFileName (Split-Path $ApkPath -Leaf)
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $ApkPath)) { throw "Android 7 test APK'si olusturulamadi." }

& $adb kill-server | Out-Null
$emulatorProcess = Start-Process -FilePath $emulator -ArgumentList @(
	"-avd", $avdName,
	"-no-window",
	"-no-audio",
	"-no-boot-anim",
	"-no-snapshot",
	"-gpu", "host",
	"-feature", "GLESDynamicVersion",
	"-memory", "1536",
	"-cores", "2"
) -WindowStyle Hidden -PassThru

try {
	& $adb wait-for-device
	$booted = $false
	for ($attempt = 0; $attempt -lt 120; $attempt++) {
		$bootState = (& $adb shell getprop sys.boot_completed 2>$null).Trim()
		if ($bootState -eq "1") {
			$booted = $true
			break
		}
		Start-Sleep -Seconds 2
	}
	if (-not $booted) { throw "Android 7 emulator 240 saniyede acilmadi." }

	& $adb install -r $ApkPath
	if ($LASTEXITCODE -ne 0) { throw "APK Android 7 emulatora kurulamadi." }
	& $adb shell am force-stop com.atalay.aksoytank | Out-Null
	& $adb shell monkey -p com.atalay.aksoytank -c android.intent.category.LAUNCHER 1 | Out-Null
	Start-Sleep -Seconds 2
	& $adb shell input tap 1230 530 | Out-Null
	Start-Sleep -Seconds 8
	$pidOutput = & $adb shell pidof com.atalay.aksoytank 2>$null
	$appPid = if ($null -eq $pidOutput) { "" } else { "$pidOutput".Trim() }
	if (-not $appPid) {
		$processLine = (& $adb shell ps) | Where-Object { $_ -match "com\.atalay\.aksoytank\s*$" } | Select-Object -First 1
		if ($processLine -and $processLine -match "^\S+\s+(\d+)\s+") {
			$appPid = $Matches[1]
		}
	}
	if (-not $appPid) { throw "Aksoy Tank Android 7 uzerinde calisir durumda degil." }

	$packageInfo = (& $adb shell dumpsys package com.atalay.aksoytank) -join "`n"
	if ($packageInfo -notmatch "versionCode=24" -or $packageInfo -notmatch "versionName=2.0.2") {
		throw "Android 7 cihazdaki paket surumu beklenen degerde degil."
	}
	$logText = (& $adb logcat -d -t 600) -join "`n"
	if ($logText -match "(?s)FATAL EXCEPTION.{0,600}Process: com\.atalay\.aksoytank" -or
		$logText -match "Unable to setup the Godot engine" -or
		$logText -match "Error: Couldn't load project data" -or
		$logText -match "Program linking failed") {
		throw "Android 7 calisma gunlugunde kritik uygulama hatasi bulundu."
	}
	$windowState = (& $adb shell dumpsys window windows) -join "`n"
	if ($windowState -notmatch "com\.atalay\.aksoytank/com\.godot\.game\.GodotApp") {
		throw "Aksoy Tank Android 7 uzerinde gorunur oyun penceresine ulasamadi."
	}

	$remoteShot = "/sdcard/aksoy-tank-api24.png"
	$localShot = Join-Path $outputDir "aksoy-tank-api24-smoke.png"
	& $adb shell screencap -p $remoteShot | Out-Null
	& $adb pull $remoteShot $localShot | Out-Null
	Write-Host "Android 7 / API 24 emulator testi gecti:"
	Write-Host " - PID: $appPid"
	Write-Host " - $localShot"
} finally {
	& $adb emu kill 2>$null | Out-Null
	if ($emulatorProcess -and -not $emulatorProcess.HasExited) {
		$emulatorProcess.WaitForExit(15000) | Out-Null
	}
}
