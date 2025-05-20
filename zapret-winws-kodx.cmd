@echo off
chcp 65001 >nul
:: 65001 - UTF-8 

"%~dp0bin\elevator.exe" cmd /k "%~dp0bin\zapret-winws-kodx-control.cmd"
