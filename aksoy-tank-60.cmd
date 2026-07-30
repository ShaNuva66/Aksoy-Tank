@echo off
setlocal

set "PROJECT_ROOT=%~dp0"
set "GODOT_DIR=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
set "GODOT_EXE="

for /f "delims=" %%G in ('dir /b /s /o-n "%GODOT_DIR%\Godot_v*-stable_win64.exe" 2^>nul') do (
  set "GODOT_EXE=%%G"
  goto :found_godot
)

:found_godot
if not defined GODOT_EXE (
  echo Godot bulunamadi. Godot 4.x kurulu olmali.
  pause
  exit /b 1
)

echo Aksoy Tank 60. bolumden baslatiliyor...
start "" "%GODOT_EXE%" --path "%PROJECT_ROOT%" -- --start-stage=60 --auto-start
endlocal
