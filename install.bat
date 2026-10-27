@echo off
setlocal
cd /d "%~dp0"
echo Installing SolidWorks 2022 MCP in: %CD%
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
set EXITCODE=%ERRORLEVEL%
echo.
if %EXITCODE%==0 (echo Install complete. Next: open SolidWorks 2022, start Claude Code in this folder, approve the solidworks MCP, then run sw_status.) else (echo Install FAILED with exit code %EXITCODE%. See the messages above. Running this file again is safe.)
pause
exit /b %EXITCODE%
