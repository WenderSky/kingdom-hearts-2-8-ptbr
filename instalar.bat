@echo off
chcp 65001 >nul
title Traducao PT-BR - KINGDOM HEARTS HD 2.8
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar.ps1" %*
echo.
pause
