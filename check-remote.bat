@echo off
set "SCRIPT_PATH=%~dp0check-remote.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -WindowStyle Hidden -NonInteractive
