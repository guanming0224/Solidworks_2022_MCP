@echo off
setlocal
cd /d "%~dp0"
echo Uninstalling SolidWorks 2022 MCP from: %CD%
echo The items to be deleted are listed first; type YES to continue.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
set EXITCODE=%ERRORLEVEL%
echo.
if %EXITCODE%==0 (echo Finished. See the messages above for what was removed.) else (echo Uninstall FAILED with exit code %EXITCODE%. See the messages above.)
pause
exit /b %EXITCODE%
