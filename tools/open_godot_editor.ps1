$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotGui = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64.exe" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
$godotConsole = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64_console.exe" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
$godotExe = if ($godotGui) { $godotGui } else { $godotConsole }

if (-not $godotExe) {
	throw "Godot bulunamadi. Godot 4.x kurulumu gerekiyor."
}

Write-Host "Godot aciliyor..."
Start-Process -FilePath $godotExe -ArgumentList @("--editor", "--path", $projectRoot)
