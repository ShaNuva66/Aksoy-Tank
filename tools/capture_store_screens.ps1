$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$screenshotDir = Join-Path $projectRoot "assets\store\listing\screenshots"

New-Item -ItemType Directory -Force -Path $screenshotDir | Out-Null

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

$godotExe = Get-GodotExecutable
$captures = @(
	@{ Stage = 1; Delay = 160; File = "01-dust-gate.png" },
	@{ Stage = 4; Delay = 170; File = "02-bastion-ring.png" },
	@{ Stage = 7; Delay = 180; File = "03-echo-yard.png" },
	@{ Stage = 10; Delay = 190; File = "04-final-bastion.png" }
)

foreach ($capture in $captures) {
	$outputPath = Join-Path $screenshotDir $capture.File
	if (Test-Path $outputPath) {
		Remove-Item -LiteralPath $outputPath -Force
	}

	& $godotExe `
		--path $projectRoot `
		--scene "res://src/scenes/prototype_arena.tscn" `
		--windowed `
		--single-window `
		--resolution 1920x1080 `
		--quit-after 1800 `
		-- `
		"--capture-stage=$($capture.Stage)" `
		"--capture-delay-frames=$($capture.Delay)" `
		"--capture-output=$outputPath"

	if (-not (Test-Path $outputPath)) {
		throw "Screenshot olusturulamadi: $outputPath"
	}
}

Write-Host "Store screenshotlari kaydedildi: $screenshotDir"
