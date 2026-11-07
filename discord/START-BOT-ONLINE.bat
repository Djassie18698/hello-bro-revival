@echo off
title Hello Bro Discord bot (online)
cd /d "%~dp0"
if not exist .env (
  echo No .env file in this folder: the bot token is missing. See README.md.
  pause
  exit /b
)
rem Since 7 Nov 2026 the bot runs on the cloud server (service hellobro-bot, tools/vps/bot.sh), day and night. A second copy here would
rem post every #server-status message twice, so ask first.
echo The bot already runs on the cloud server day and night. You don't need this window.
echo A second copy here would post every #server-status message twice.
choice /c YN /m "Start a second copy on this PC anyway"
if errorlevel 2 exit /b
:loop
node --env-file=.env online.js
if errorlevel 2 (
  pause
  exit /b
)
echo The bot stopped. Starting it again in 10 seconds... (close this window to take the bot offline)
timeout /t 10 >nul
goto loop
