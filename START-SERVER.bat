@echo off
rem Hello Bro server: starts the server, opens the Server Manager in your browser, and starts the server again
rem when you press Restart in the manager. Close this window to stop the server.
cd /d "%~dp0"
chcp 65001 >nul
title Hello Bro Server
color 0F
set HB_MANAGED=1
where node >nul 2>&1 || (echo. & echo   Node.js is not installed. Get it from https://nodejs.org and run this again. & echo. & pause & exit /b 1)
start "" /b cmd /c "%SystemRoot%System32	imeout.exe /t 3 >nul & start "" http://localhost:18080/manager"
:run
node server.js
if %errorlevel%==3 (echo. & echo   Restarting... & echo. & goto run)
echo.
echo   The server has stopped. Press any key to close this window.
pause >nul
