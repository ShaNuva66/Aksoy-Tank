$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$relayScript = Join-Path $projectRoot "tools\start_online_relay.ps1"
$editorScript = Join-Path $projectRoot "tools\open_godot_editor.ps1"

Write-Host ""
Write-Host "Online test ortami aciliyor..."
Write-Host "1. Relay ayri PowerShell penceresinde baslayacak."
Write-Host "2. Godot editor acilacak."
Write-Host ""

Start-Process powershell -ArgumentList @(
	"-NoExit",
	"-ExecutionPolicy", "Bypass",
	"-File", $relayScript
)

Start-Sleep -Seconds 2

powershell -ExecutionPolicy Bypass -File $editorScript
