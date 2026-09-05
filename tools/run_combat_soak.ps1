$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$godotExe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64_console.exe" | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
$outputDir = Join-Path (Split-Path $projectRoot -Parent) 'aksoy-tank-builds'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$ErrorActionPreference = 'Continue'
$output = & $godotExe --headless --fixed-fps 60 --path $projectRoot --script res://tools/combat_soak_test.gd 2>&1 | Tee-Object -FilePath (Join-Path $outputDir 'combat-soak.log')
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
$log = $output -join "`n"
if ($code -ne 0 -or $log -match 'SCRIPT ERROR:|ERROR:|COMBAT: FAIL' -or $log -notmatch 'COMBAT: PASS') {
    throw 'Combat simulation failed; inspect combat-soak.log.'
}
$source = Join-Path $env:APPDATA 'Godot\app_userdata\Aksoy Tank\combat-soak-report.json'
Copy-Item -LiteralPath $source -Destination (Join-Path $outputDir 'combat-soak-report.json') -Force
