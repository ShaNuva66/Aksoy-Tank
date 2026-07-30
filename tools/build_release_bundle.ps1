param(
	[switch]$SkipAssetSync
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$desktopRoot = Split-Path $projectRoot -Parent
$androidBuildDir = Join-Path $projectRoot "android\build"
$outputDir = Join-Path $desktopRoot "aksoy-tank-builds"
$outputAabPath = Join-Path $outputDir "aksoy-tank-release.aab"
$gradleBundleDir = Join-Path $androidBuildDir "build\outputs\bundle"
$localAndroidDir = Join-Path $projectRoot "local\android"
$secretConfigPath = Join-Path $localAndroidDir "release-keystore.json"
$releaseKeystorePath = Join-Path $localAndroidDir "aksoy-mucadelisi-release.keystore"

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

function New-RandomPassword {
	$alphabet = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%*+-_"
	return -join (1..24 | ForEach-Object { $alphabet[(Get-Random -Minimum 0 -Maximum $alphabet.Length)] })
}

function Ensure-ReleaseKeystore {
	param(
		[string]$JavaHome
	)

	if (Test-Path $secretConfigPath) {
		$existingConfig = Get-Content $secretConfigPath -Raw | ConvertFrom-Json
		if (Test-Path $existingConfig.keystore_path) {
			return $existingConfig
		}
		if (Test-Path $releaseKeystorePath) {
			$existingConfig.keystore_path = $releaseKeystorePath
			$existingConfig | ConvertTo-Json | Set-Content -Path $secretConfigPath
			return $existingConfig
		}
	}

	$keytoolExe = Join-Path $JavaHome "bin\keytool.exe"
	if (-not (Test-Path $keytoolExe)) {
		throw "keytool bulunamadi: $keytoolExe"
	}

	New-Item -ItemType Directory -Force -Path $localAndroidDir | Out-Null
	$password = New-RandomPassword
	$alias = "aksoymucadelisirelease"
	$dname = "CN=Aksoy Tank, OU=Mobile Games, O=Atalay, L=Istanbul, ST=Istanbul, C=TR"

	& $keytoolExe `
		-genkeypair `
		-v `
		-keystore $releaseKeystorePath `
		-alias $alias `
		-keyalg RSA `
		-keysize 2048 `
		-validity 9125 `
		-storepass $password `
		-keypass $password `
		-dname $dname | Out-Null

	$config = [pscustomobject]@{
		keystore_path = $releaseKeystorePath
		alias = $alias
		password = $password
		created_at = (Get-Date).ToString("s")
	}

	$config | ConvertTo-Json | Set-Content -Path $secretConfigPath
	return $config
}

if (-not $SkipAssetSync) {
	& (Join-Path $projectRoot "tools\sync_android_assets.ps1") -Mode BaseOnly
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$javaHome = Get-JavaHome
$androidSdkPath = Get-AndroidSdkPath
$secret = Ensure-ReleaseKeystore -JavaHome $javaHome

Remove-Item -LiteralPath $outputAabPath -Force -ErrorAction SilentlyContinue

$env:JAVA_HOME = $javaHome
$env:ANDROID_HOME = $androidSdkPath
$env:ANDROID_SDK_ROOT = $androidSdkPath

$gradlew = Join-Path $androidBuildDir "gradlew.bat"
if (-not (Test-Path $gradlew)) {
	throw "gradlew.bat bulunamadi: $gradlew"
}

$gradleArgs = @(
	"--no-daemon",
	"bundleStandardRelease",
	"-Pexport_package_name=com.atalay.aksoytank",
	"-Pexport_version_code=14",
	"-Pexport_version_name=1.4.0",
	"-Pexport_version_min_sdk=24",
	"-Pexport_version_target_sdk=36",
	"-Pexport_enabled_abis=armeabi-v7a,arm64-v8a",
	("-Pexport_path=" + $outputDir.Replace("\", "/")),
	"-Pexport_filename=aksoy-tank-release.aab",
	"-Pexport_edition=standard",
	"-Pexport_build_type=release",
	"-Pexport_format=aab",
	"-Pperform_signing=true",
	"-Pperform_zipalign=true",
	("-Prelease_keystore_file=" + $secret.keystore_path.Replace("\", "/")),
	("-Prelease_keystore_alias=" + $secret.alias),
	("-Prelease_keystore_password=" + $secret.password)
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
	throw "Gradle release bundle basarisiz oldu. ExitCode=$gradleExitCode"
}

if (Test-Path $gradleBundleDir) {
	$builtBundle = Get-ChildItem $gradleBundleDir -Recurse -Filter *.aab | Sort-Object LastWriteTime -Descending | Select-Object -First 1
	if ($builtBundle) {
		Copy-Item -LiteralPath $builtBundle.FullName -Destination $outputAabPath -Force
	}
}

if (-not (Test-Path $outputAabPath)) {
	throw "AAB uretilmedi: $outputAabPath"
}

Write-Host ""
Write-Host "Release AAB hazir:"
Write-Host " - $outputAabPath"
Write-Host " - $secretConfigPath"
