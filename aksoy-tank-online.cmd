@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\open_online_game.ps1"
if errorlevel 1 pause
