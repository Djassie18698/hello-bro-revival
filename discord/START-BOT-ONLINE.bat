@echo off
title Hello Bro Discord bot (online)
cd /d "%~dp0"
if not exist .env (
  echo No .env file in this folder: the bot token is missing. See README.md.
  pause
  exit /b
)
:loop
node --env-file=.env online.js
if errorlevel 2 (
  pause
  exit /b
)
echo The bot stopped. Starting it again in 10 seconds... (close this window to take the bot offline)
timeout /t 10 >nul
goto loop
