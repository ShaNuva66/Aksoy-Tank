param(
	[ValidateSet("BaseOnly", "AssetPackOnly", "Both")]
	[string]$Mode = "Both"
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$baseAssetsDir = Join-Path $projectRoot "android\build\src\main\assets"
$assetPackAssetsDir = Join-Path $projectRoot "android\build\assetPackInstallTime\src\main\assets"
$allAssetTargets = @($baseAssetsDir, $assetPackAssetsDir)
$androidAssetsTargets = switch ($Mode) {
	"BaseOnly" { @($baseAssetsDir) }
	"AssetPackOnly" { @($assetPackAssetsDir) }
	default { @($baseAssetsDir, $assetPackAssetsDir) }
}
$sourceItems = @(
	"project.godot",
	"src",
	"assets",
	".godot"
)

function Remove-UnusedGodotImports {
	param(
		[string]$AndroidAssetsDir
	)

	$importedDir = Join-Path $AndroidAssetsDir ".godot\imported"
	if (-not (Test-Path $importedDir)) {
		return
	}

	$needed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
	Get-ChildItem -LiteralPath $AndroidAssetsDir -Recurse -Filter "*.import" | ForEach-Object {
		Get-Content -LiteralPath $_.FullName | ForEach-Object {
			if ($_ -match 'res://\.godot/imported/([^"\]]+)') {
				$fileName = $Matches[1]
				[void]$needed.Add($fileName)
				[void]$needed.Add([System.IO.Path]::ChangeExtension($fileName, ".md5"))
			}
		}
	}

	Get-ChildItem -LiteralPath $importedDir -File | ForEach-Object {
		if (-not $needed.Contains($_.Name)) {
			Remove-Item -LiteralPath $_.FullName -Force
		}
	}
}

foreach ($androidAssetsDir in $allAssetTargets) {
	if (Test-Path $androidAssetsDir) {
		Remove-Item -LiteralPath $androidAssetsDir -Recurse -Force
	}
}

foreach ($androidAssetsDir in $androidAssetsTargets) {
	New-Item -ItemType Directory -Force -Path $androidAssetsDir | Out-Null

	foreach ($item in $sourceItems) {
		$sourcePath = Join-Path $projectRoot $item
		if (-not (Test-Path $sourcePath)) {
			continue
		}

		Copy-Item -LiteralPath $sourcePath -Destination $androidAssetsDir -Recurse -Force
	}

	$editorDir = Join-Path $androidAssetsDir ".godot\editor"
	$shaderCacheDir = Join-Path $androidAssetsDir ".godot\shader_cache"

	if (Test-Path $editorDir) {
		Remove-Item -LiteralPath $editorDir -Recurse -Force
	}

	if (Test-Path $shaderCacheDir) {
		Remove-Item -LiteralPath $shaderCacheDir -Recurse -Force
	}

	Remove-UnusedGodotImports -AndroidAssetsDir $androidAssetsDir
}

Write-Host "Android asset staging hazir:"
foreach ($targetDir in $androidAssetsTargets) {
	Write-Host " - $targetDir"
}
