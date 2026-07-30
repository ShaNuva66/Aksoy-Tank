param(
	[switch]$InstallRequirementsOnly
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$requirementsPath = Join-Path $projectRoot "online-relay\requirements.txt"
$serverPath = Join-Path $projectRoot "online-relay\server.py"

Write-Host ""
Write-Host "Aksoy Tank relay hazirlaniyor..."
Write-Host "Proje: $projectRoot"
Write-Host ""

python -m pip install -r $requirementsPath

if ($InstallRequirementsOnly) {
	Write-Host ""
	Write-Host "Gerekli Python paketi kuruldu."
	return
}

Write-Host ""
Write-Host "Relay baslatiliyor..."
Write-Host "Adres: ws://127.0.0.1:8765/ws"
Write-Host "Bu pencere acik kaldigi surece relay calisir."
Write-Host ""

python $serverPath
