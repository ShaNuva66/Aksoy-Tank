param(
    [Parameter(Mandatory = $true)][string]$Serial,
    [ValidateRange(30, 3600)][int]$Seconds = 1200
)
$ErrorActionPreference = 'Stop'
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if ($Serial.StartsWith('emulator-')) { throw 'This check requires a physical phone.' }
if ((& $adb -s $Serial get-state 2>$null) -ne 'device') { throw 'Physical phone is not connected or USB debugging is not authorized.' }
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$output = Join-Path (Split-Path $root -Parent) ('aksoy-tank-builds\device-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $output | Out-Null
& $adb -s $Serial shell getprop ro.product.model | Set-Content (Join-Path $output 'model.txt')
& $adb -s $Serial shell getprop ro.build.version.release | Set-Content (Join-Path $output 'android.txt')
& $adb -s $Serial shell dumpsys package com.atalay.aksoytank | Set-Content (Join-Path $output 'package.txt')
$deadline = (Get-Date).AddSeconds($Seconds)
Write-Host 'Keep playing stages 58-60. This records memory and battery/thermal data, not certified game FPS.'
while ((Get-Date) -lt $deadline) {
    $stamp = Get-Date -Format 'HHmmss'
    $appProcess = (& $adb -s $Serial shell pidof com.atalay.aksoytank) -join ''
    if (-not $appProcess.Trim()) { throw "Game is not running. Reports: $output" }
    & $adb -s $Serial shell dumpsys meminfo com.atalay.aksoytank | Set-Content (Join-Path $output "$stamp-memory.txt")
    & $adb -s $Serial shell dumpsys battery | Set-Content (Join-Path $output "$stamp-battery.txt")
    & $adb -s $Serial shell dumpsys thermalservice | Set-Content (Join-Path $output "$stamp-thermal.txt")
    Start-Sleep -Seconds 15
}
Write-Host "Evidence collected: $output. Review frame pacing and temperatures before approving the device."
