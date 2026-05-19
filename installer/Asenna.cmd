@echo off
REM Asenna.cmd — kaksoisklikkaa tata.
REM Kutsuu Asenna.ps1:n PowerShell-ExecutionPolicy:n ohi.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Asenna.ps1"
