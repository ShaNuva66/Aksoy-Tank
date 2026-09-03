[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[ValidatePattern('(?-i)^[A-Z0-9]{10}$')]
	[string]$TeamId,

	[ValidatePattern('(?-i)^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$')]
	[string]$BundleId = 'com.atalay.aksoytank',

	[ValidatePattern('^[0-9]+(?:\.[0-9]+){1,2}$')]
	[string]$ShortVersion = '1.9.2',

	[ValidatePattern('^[0-9]+(?:\.[0-9]+){0,2}$')]
	[string]$BuildNumber = '21'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$presetPath = Join-Path $projectRoot 'export_presets.cfg'
$projectPath = Join-Path $projectRoot 'project.godot'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Set-ConfigLine {
	param(
		[string]$Text,
		[string]$Key,
		[string]$Value
	)

	$pattern = '(?m)^' + [regex]::Escape($Key) + '=.*$'
	if (-not [regex]::IsMatch($Text, $pattern)) {
		throw "Ayar bulunamadi: $Key"
	}
	return [regex]::Replace($Text, $pattern, ($Key + '="' + $Value + '"'), 1)
}

$presetText = [System.IO.File]::ReadAllText($presetPath)
$presetText = Set-ConfigLine -Text $presetText -Key 'application/app_store_team_id' -Value $TeamId
$presetText = Set-ConfigLine -Text $presetText -Key 'application/bundle_identifier' -Value $BundleId
$presetText = Set-ConfigLine -Text $presetText -Key 'application/short_version' -Value $ShortVersion
$presetText = Set-ConfigLine -Text $presetText -Key 'application/version' -Value $BuildNumber
[System.IO.File]::WriteAllText($presetPath, $presetText, $utf8NoBom)

$projectText = [System.IO.File]::ReadAllText($projectPath)
$projectText = Set-ConfigLine -Text $projectText -Key 'config/version' -Value $ShortVersion
[System.IO.File]::WriteAllText($projectPath, $projectText, $utf8NoBom)

Write-Host 'iOS kimlik ayarlari guncellendi:'
Write-Host " - Team ID: $TeamId"
Write-Host " - Bundle ID: $BundleId"
Write-Host " - Version: $ShortVersion ($BuildNumber)"
Write-Host ''
Write-Host 'Simdi .\tools\validate_ios_release.ps1 komutunu calistir.'
