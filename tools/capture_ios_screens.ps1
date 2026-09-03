$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$targets = @(
	@{ Label = '6.9'; Size = '2868x1320'; Directory = 'ios-screenshots-6.9' },
	@{ Label = '6.5'; Size = '2778x1284'; Directory = 'ios-screenshots-6.5' }
)

$godotExe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*-stable_win64_console.exe" -ErrorAction SilentlyContinue |
	Sort-Object Name -Descending |
	Select-Object -First 1 -ExpandProperty FullName
if (-not $godotExe) { throw 'Godot console executable bulunamadi.' }

$captures = @(
	@{ Stage = 1; Delay = 160; File = '01-dust-gate.png' },
	@{ Stage = 4; Delay = 170; File = '02-bastion-ring.png' },
	@{ Stage = 7; Delay = 180; File = '03-echo-yard.png' },
	@{ Stage = 10; Delay = 190; File = '04-final-bastion.png' }
)

foreach ($target in $targets) {
	$screenshotDir = Join-Path $projectRoot "assets\store\listing\$($target.Directory)"
	New-Item -ItemType Directory -Force -Path $screenshotDir | Out-Null
	$expectedWidth, $expectedHeight = $target.Size.Split('x')

	foreach ($capture in $captures) {
		$outputPath = Join-Path $screenshotDir $capture.File
		if (Test-Path -LiteralPath $outputPath) { Remove-Item -LiteralPath $outputPath -Force }

		& $godotExe `
			--path $projectRoot `
			--scene 'res://src/scenes/prototype_arena.tscn' `
			--windowed `
			--single-window `
			--resolution 1434x660 `
			--quit-after 1800 `
			-- `
			"--capture-stage=$($capture.Stage)" `
			"--capture-delay-frames=$($capture.Delay)" `
			"--capture-size=$($target.Size)" `
			"--capture-output=$outputPath"

		if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outputPath)) { throw "Ekran goruntusu olusturulamadi: $outputPath" }
		$image = [System.Drawing.Bitmap]::new($outputPath)
		if ($image.Width -ne [int]$expectedWidth -or $image.Height -ne [int]$expectedHeight) {
			$actual = "$($image.Width)x$($image.Height)"
			$image.Dispose()
			throw "Ekran goruntusu boyutu hatali: $actual"
		}
		if ($image.PixelFormat.ToString() -match 'Alpha|Argb') {
			$image.Dispose()
			throw "Ekran goruntusu alpha kanali iceriyor: $outputPath"
		}
		$image.Dispose()
	}

	Write-Host "iPhone $($target.Label)-inc yatay ekran goruntuleri hazir: $screenshotDir"
}
