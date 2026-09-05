param(
	[switch]$SkipAssetSync,
	[string]$EnabledAbis = "armeabi-v7a,arm64-v8a",
	[string]$OutputFileName = "aksoy-tank-debug.apk"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$desktopRoot = Split-Path $projectRoot -Parent
$outputDir = Join-Path $desktopRoot "aksoy-tank-builds"
$outputApkPath = Join-Path $outputDir $OutputFileName
$stagingApkPath = Join-Path $outputDir ("godot-staging-" + $OutputFileName)
$androidBuildDir = Join-Path $projectRoot "android\build"
$gradleApkPath = Join-Path $androidBuildDir "build\outputs\apk\standard\debug\android_debug.apk"
$debugKeystorePath = Join-Path $env:APPDATA "Godot\keystores\debug.keystore"

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

function Ensure-DebugKeystore {
	if (Test-Path $debugKeystorePath) { return }
	$keytoolExe = Join-Path (Get-JavaHome) "bin\keytool.exe"
	New-Item -ItemType Directory -Force -Path (Split-Path $debugKeystorePath -Parent) | Out-Null
	& $keytoolExe -genkeypair -v -keystore $debugKeystorePath -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -storepass android -keypass android -dname "CN=Android Debug,O=Android,C=US" | Out-Null
	if ($LASTEXITCODE -ne 0) { throw "Android debug keystore olusturulamadi." }
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

$presetName = switch ($EnabledAbis) {
	"x86_64" { "Android API24 Test" }
	"armeabi-v7a,arm64-v8a" { "Android Debug APK" }
	default { throw "Desteklenmeyen debug ABI listesi: $EnabledAbis" }
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Ensure-DebugKeystore
Remove-Item -LiteralPath $outputApkPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $stagingApkPath -Force -ErrorAction SilentlyContinue
$godotExe = Get-GodotExecutable
Ensure-AndroidBuildIgnoredByGodot
Disable-AndroidGradleDaemon

$previousPath = $env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH
$previousUser = $env:GODOT_ANDROID_KEYSTORE_DEBUG_USER
$previousPassword = $env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD
try {
	$env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH = $debugKeystorePath
	$env:GODOT_ANDROID_KEYSTORE_DEBUG_USER = "androiddebugkey"
	$env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = "android"
	& $godotExe --headless --path $projectRoot --export-debug $presetName $stagingApkPath
	if ($LASTEXITCODE -ne 0) { throw "Godot debug APK export basarisiz oldu." }
} finally {
	$env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH = $previousPath
	$env:GODOT_ANDROID_KEYSTORE_DEBUG_USER = $previousUser
	$env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = $previousPassword
}

$projectBinary = Join-Path $androidBuildDir "src\main\assets\project.binary"
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
	"assembleStandardDebug",
	"-Pexport_package_name=com.atalay.aksoytank",
	"-Pexport_version_code=24",
	"-Pexport_version_name=2.0.2",
	"-Pexport_version_min_sdk=24",
	"-Pexport_version_target_sdk=36",
	('"-Pexport_enabled_abis=' + $EnabledAbis.Replace(",", "|") + '"'),
	("-Pexport_path=" + $outputDir.Replace("\", "/")),
	("-Pexport_filename=" + $OutputFileName),
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
try {
	& $gradlew @gradleArgs
	if ($LASTEXITCODE -ne 0) { throw "Gradle API 36 debug APK basarisiz oldu." }
} finally {
	Pop-Location
}
if (Test-Path $gradleApkPath) {
	Copy-Item -LiteralPath $gradleApkPath -Destination $outputApkPath -Force
}
Remove-Item -LiteralPath $stagingApkPath -Force -ErrorAction SilentlyContinue
if (-not (Test-Path $outputApkPath)) { throw "API 36 APK uretilmedi: $outputApkPath" }
Write-Host ""
Write-Host "Kurulabilir APK hazir:"
Write-Host " - $outputApkPath"
