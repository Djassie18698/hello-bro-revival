@echo off
rem Double-click once: the Hello Bro bot then starts by itself (in a small minimized window) every time Windows starts,
rem so it shows online in Discord whenever this PC is on. Run it again to switch the auto-start off.
rem Not needed since 7 Nov 2026: the bot runs on the cloud server (tools/vps/bot.sh). Only for running it on the PC instead.
cd /d "%~dp0"
echo The bot already runs on the cloud server day and night, so it does not need to start with Windows.
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Hello Bro Discord bot.lnk"
if exist "%LNK%" (
  del "%LNK%"
  echo Auto-start is now OFF. The bot no longer starts with Windows.
  pause
  exit /b
)
powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut($env:LNK); $s.TargetPath='%~dp0START-BOT-ONLINE.bat'; $s.WorkingDirectory='%~dp0'; $s.WindowStyle=7; $s.Description='Keeps the Hello Bro bot online in Discord'; $s.Save()"
if exist "%LNK%" (
  echo Auto-start is now ON. The bot starts by itself every time Windows starts.
  echo Double-click this file again to switch it off.
) else (
  echo Something went wrong: the startup shortcut was not made.
)
pause
