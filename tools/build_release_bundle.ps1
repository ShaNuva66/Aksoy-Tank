param(
	[switch]$SkipAssetSync
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$desktopRoot = Split-Path $projectRoot -Parent
$outputDir = Join-Path $desktopRoot "aksoy-tank-builds"
$outputAabPath = Join-Path $outputDir "aksoy-tank-release.aab"
$outputManifestPath = Join-Path $outputDir "aksoy-tank-release-AndroidManifest.xml"
$stagingAabPath = Join-Path $outputDir "godot-staging-release.aab"
$androidBuildDir = Join-Path $projectRoot "android\build"
$gradleBundleDir = Join-Path $androidBuildDir "build\outputs\bundle"
$localAndroidDir = Join-Path $projectRoot "local\android"
$secretConfigPath = Join-Path $localAndroidDir "release-keystore.json"
$releaseKeystorePath = Join-Path $localAndroidDir "aksoy-mucadelisi-release.keystore"

function Get-GodotExecutable {
	$candidates = @(
		(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64_console.exe" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -ExpandProperty FullName),
		(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64.exe" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -ExpandProperty FullName)
	) | Where-Object { $_ }
	if (-not $candidates) { throw "Godot executable bulunamadi." }
	return $candidates[0]
}

function Get-JavaHome {
	$candidate = Get-ChildItem "C:\Program Files\Eclipse Adoptium\jdk-*" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
	if (-not $candidate) { throw "JDK 17 veya ustu bulunamadi." }
	return $candidate.FullName
}

function New-RandomPassword {
	$alphabet = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	return -join (1..24 | ForEach-Object { $alphabet[(Get-Random -Minimum 0 -Maximum $alphabet.Length)] })
}

function Ensure-ReleaseKeystore {
	if (Test-Path $secretConfigPath) {
		$config = Get-Content $secretConfigPath -Raw | ConvertFrom-Json
		if (Test-Path $config.keystore_path) { return $config }
	}
	$keytoolExe = Join-Path (Get-JavaHome) "bin\keytool.exe"
	New-Item -ItemType Directory -Force -Path $localAndroidDir | Out-Null
	$password = New-RandomPassword
	$alias = "aksoymucadelisirelease"
	& $keytoolExe -genkeypair -v -keystore $releaseKeystorePath -alias $alias -keyalg RSA -keysize 2048 -validity 9125 -storepass $password -keypass $password -dname "CN=Aksoy Tank, OU=Mobile Games, O=Atalay, L=Istanbul, ST=Istanbul, C=TR" | Out-Null
	if ($LASTEXITCODE -ne 0) { throw "Release keystore olusturulamadi." }
	$config = [pscustomobject]@{ keystore_path = $releaseKeystorePath; alias = $alias; password = $password; created_at = (Get-Date).ToString("s") }
	$config | ConvertTo-Json | Set-Content -LiteralPath $secretConfigPath
	return $config
}

function Set-AndroidApi36Template {
	$configPath = Join-Path $androidBuildDir "config.gradle"
	$config = Get-Content $configPath -Raw
	$config = $config -replace "(?m)^\s*androidGradlePlugin\s*:\s*'[^']+',", "    androidGradlePlugin: '8.10.1',"
	$config = $config -replace "(?m)^\s*compileSdk\s*:\s*\d+,", "    compileSdk         : 36,"
	$config = $config -replace "(?m)^\s*targetSdk\s*:\s*\d+,", "    targetSdk          : 36,"
	$config = $config -replace "(?m)^\s*buildTools\s*:\s*'[^']+',", "    buildTools         : '36.0.0',"
	[System.IO.File]::WriteAllText($configPath, $config, [System.Text.UTF8Encoding]::new($false))
}

function Disable-AndroidGradleDaemon {
	$propertiesPath = Join-Path $androidBuildDir "gradle.properties"
	$properties = Get-Content $propertiesPath -Raw
	if ($properties -notmatch "(?m)^org\.gradle\.daemon=false$") {
		[System.IO.File]::AppendAllText($propertiesPath, [Environment]::NewLine + "org.gradle.daemon=false" + [Environment]::NewLine)
	}
}

function Ensure-AndroidBuildIgnoredByGodot {
	$ignorePath = Join-Path $projectRoot "android\.gdignore"
	if (-not (Test-Path $ignorePath)) {
		[System.IO.File]::WriteAllText($ignorePath, "")
	}
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$secret = Ensure-ReleaseKeystore
$godotExe = Get-GodotExecutable
Ensure-AndroidBuildIgnoredByGodot
Disable-AndroidGradleDaemon
Remove-Item -LiteralPath $outputAabPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $stagingAabPath -Force -ErrorAction SilentlyContinue

$previousPath = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH
$previousUser = $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER
$previousPassword = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
try {
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $secret.keystore_path
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $secret.alias
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $secret.password
	& $godotExe --headless --path $projectRoot --export-release "Android Release Staging" $stagingAabPath
	if ($LASTEXITCODE -ne 0) { throw "Godot release AAB export basarisiz oldu." }
} finally {
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $previousPath
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $previousUser
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $previousPassword
}

$projectBinary = Join-Path $androidBuildDir "assetPackInstallTime\src\main\assets\project.binary"
if (-not (Test-Path $projectBinary)) { throw "Godot Android project.binary olusturmadi." }
$header = [System.IO.File]::ReadAllBytes($projectBinary)[0..3]
if ([System.Text.Encoding]::ASCII.GetString($header) -ne "ECFG") {
	throw "Godot Android project.binary basligi gecersiz."
}
Set-AndroidApi36Template

$javaHome = Get-JavaHome
$androidSdkPath = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$env:JAVA_HOME = $javaHome
$env:ANDROID_HOME = $androidSdkPath
$env:ANDROID_SDK_ROOT = $androidSdkPath
$gradlew = Join-Path $androidBuildDir "gradlew.bat"
$gradleArgs = @(
	"--no-daemon",
	"bundleStandardRelease",
	"-Pexport_package_name=com.atalay.aksoytank",
	"-Pexport_version_code=25",
	"-Pexport_version_name=2.0.3",
	"-Pexport_version_min_sdk=24",
	"-Pexport_version_target_sdk=36",
	'"-Pexport_enabled_abis=armeabi-v7a|arm64-v8a"',
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
try {
	& $gradlew @gradleArgs
	if ($LASTEXITCODE -ne 0) { throw "Gradle API 36 release AAB basarisiz oldu." }
} finally {
	Pop-Location
}
$builtBundle = Get-ChildItem $gradleBundleDir -Recurse -Filter *.aab | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($builtBundle) {
	Copy-Item -LiteralPath $builtBundle.FullName -Destination $outputAabPath -Force
}
$builtManifest = Join-Path $androidBuildDir "build\intermediates\bundle_manifest\standardRelease\processApplicationManifestStandardReleaseForBundle\AndroidManifest.xml"
if (-not (Test-Path $builtManifest)) { throw "API 36 AAB manifesti uretilmedi: $builtManifest" }
Copy-Item -LiteralPath $builtManifest -Destination $outputManifestPath -Force
Remove-Item -LiteralPath $stagingAabPath -Force -ErrorAction SilentlyContinue
if (-not (Test-Path $outputAabPath)) { throw "API 36 AAB uretilmedi: $outputAabPath" }
Write-Host ""
Write-Host "Release AAB hazir:"
Write-Host " - $outputAabPath"
Write-Host " - $outputManifestPath"
Write-Host " - $secretConfigPath"
