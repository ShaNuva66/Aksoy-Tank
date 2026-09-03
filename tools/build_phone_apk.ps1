param(
	[switch]$SkipAssetSync
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$desktopRoot = Split-Path $projectRoot -Parent
$androidBuildDir = Join-Path $projectRoot "android\build"
$outputDir = Join-Path $desktopRoot "aksoy-tank-builds"
$outputApkPath = Join-Path $outputDir "aksoy-tank-debug.apk"
$gradleApkPath = Join-Path $androidBuildDir "build\outputs\apk\standard\debug\android_debug.apk"
$debugKeystorePath = Join-Path $env:APPDATA "Godot\keystores\debug.keystore"

function Get-JavaHome {
	$candidate = Get-ChildItem "C:\Program Files\Eclipse Adoptium\jdk-*" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
	if (-not $candidate) {
		throw "JDK 17 veya ustu bulunamadi."
	}

	return $candidate.FullName
}

function Get-AndroidSdkPath {
	$path = Join-Path $env:LOCALAPPDATA "Android\Sdk"
	if (-not (Test-Path $path)) {
		throw "Android SDK bulunamadi: $path"
	}

	return $path
}

function Ensure-DebugKeystore {
	param(
		[string]$JavaHome
	)

	if (Test-Path $debugKeystorePath) {
		return
	}

	$keytoolExe = Join-Path $JavaHome "bin\keytool.exe"
	if (-not (Test-Path $keytoolExe)) {
		throw "keytool bulunamadi: $keytoolExe"
	}

	New-Item -ItemType Directory -Force -Path (Split-Path $debugKeystorePath -Parent) | Out-Null
	& $keytoolExe `
		-genkeypair `
		-v `
		-keystore $debugKeystorePath `
		-alias androiddebugkey `
		-keyalg RSA `
		-keysize 2048 `
		-validity 10000 `
		-storepass android `
		-keypass android `
		-dname "CN=Android Debug,O=Android,C=US" | Out-Null
}

if (-not $SkipAssetSync) {
	& (Join-Path $projectRoot "tools\sync_android_assets.ps1") -Mode BaseOnly
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$javaHome = Get-JavaHome
$androidSdkPath = Get-AndroidSdkPath
Ensure-DebugKeystore -JavaHome $javaHome

Remove-Item -LiteralPath $outputApkPath -Force -ErrorAction SilentlyContinue

$env:JAVA_HOME = $javaHome
$env:ANDROID_HOME = $androidSdkPath
$env:ANDROID_SDK_ROOT = $androidSdkPath

$gradlew = Join-Path $androidBuildDir "gradlew.bat"
if (-not (Test-Path $gradlew)) {
	throw "gradlew.bat bulunamadi: $gradlew"
}

$gradleArgs = @(
	"--no-daemon",
	"assembleStandardDebug",
	"-Pexport_package_name=com.atalay.aksoytank",
	"-Pexport_version_code=21",
	"-Pexport_version_name=1.9.2",
	"-Pexport_version_min_sdk=24",
	"-Pexport_version_target_sdk=36",
	"-Pexport_enabled_abis=armeabi-v7a,arm64-v8a",
	("-Pexport_path=" + $outputDir.Replace("\", "/")),
	"-Pexport_filename=aksoy-tank-debug.apk",
	"-Pexport_edition=standard",
	"-Pexport_build_type=debug",
	"-Pexport_format=apk",
	"-Pperform_signing=true",
	"-Pperform_zipalign=true",
	("-Pdebug_keystore_file=" + $debugKeystorePath.Replace("\", "/")),
	"-Pdebug_keystore_password=android",
	"-Pdebug_keystore_alias=androiddebugkey"
)

Push-Location $androidBuildDir
$previousDebug = $env:DEBUG
$env:DEBUG = ""
$gradleExitCode = 0
try {
	& $gradlew @gradleArgs
	$gradleExitCode = $LASTEXITCODE
} finally {
	if ($null -eq $previousDebug) {
		Remove-Item Env:DEBUG -ErrorAction SilentlyContinue
	} else {
		$env:DEBUG = $previousDebug
	}
	Pop-Location
}

if ($gradleExitCode -ne 0) {
	throw "Gradle debug APK basarisiz oldu. ExitCode=$gradleExitCode"
}

if (Test-Path $gradleApkPath) {
	Copy-Item -LiteralPath $gradleApkPath -Destination $outputApkPath -Force
}

if (-not (Test-Path $outputApkPath)) {
	throw "APK uretilmedi: $outputApkPath"
}

Write-Host ""
Write-Host "Kurulabilir APK hazir:"
Write-Host " - $outputApkPath"
