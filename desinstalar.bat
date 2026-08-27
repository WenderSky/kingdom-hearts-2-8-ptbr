@echo off
chcp 65001 >nul
title Desinstalar traducao PT-BR
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0desinstalar.ps1" %*
echo.
pause
