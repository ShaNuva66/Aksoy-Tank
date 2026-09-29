[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Godot)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logRoot = Join-Path $root 'build\source-tests'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$previousAppData = $env:APPDATA
$env:APPDATA = Join-Path $logRoot ('userdata-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$engine = $Godot.Replace('_console.exe', '.exe')
if (-not (Test-Path -LiteralPath $engine)) { $engine = $Godot }
try {
    $tests = @('validate_ios_source', 'control_selection_test', 'floating_analog_test', 'mobile_touch_smoke_test',
        'online_ui_smoke_test', 'room_browser_test', 'lifecycle_regression_test', 'pause_touch_regression_test', 'campaign_progression_test',
        'gameplay_regression_test', 'tank_separation_regression_test',
        'wall_collision_regression_test', 'hitbox_regression_test',
        'network_start_test', 'network_resilience_test', 'network_smoothing_test',
        'snapshot_codec_test', 'authority_transfer_test', 'vs_rules_test',
        'onboarding_regression_test', 'audit_all_stages', 'stage_completion_regression_test')
    foreach ($test in $tests) {
        $stdout = Join-Path $logRoot "$test.stdout.log"
        $stderr = Join-Path $logRoot "$test.stderr.log"
        $arguments = @('--headless', '--path', ('"' + $root + '"'), '--script', "res://tools/$test.gd")
        if ($test -eq 'online_ui_smoke_test') {
            $arguments = @('--windowed', '--resolution', '1434x660', '--path', ('"' + $root + '"'), '--script', "res://tools/$test.gd")
        }
        $process = Start-Process -FilePath $engine -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $null = $process.Handle
        if (-not $process.WaitForExit(180000)) {
            $process.Kill()
            $process.WaitForExit()
            throw "Test timed out: $test"
        }
        $process.WaitForExit()
        $code = $process.ExitCode
        $output = @(Get-Content -LiteralPath $stdout) + @(Get-Content -LiteralPath $stderr)
        $output | Set-Content -LiteralPath (Join-Path $logRoot "$test.log") -Encoding UTF8
        if ($code -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:|FAIL')) {
            $output | Write-Host
            throw "Test failed: $test ($code)"
        }
        Write-Host "PASS: $test"
    }
    Write-Host 'IOS_SOURCE_SUITE: PASS - desktop runtime only; physical iOS testing still required.'
} finally {
    $env:APPDATA = $previousAppData
}
