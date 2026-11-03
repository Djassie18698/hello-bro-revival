@echo off
rem Updates the public server in the cloud (ninjaonline) to the newest version on GitHub. Your PC's own servers are not touched.
rem It shows what is new first and asks before updating. If the game server itself changed, players are logged out for a few seconds.
title Hello Bro - update the cloud server
set "SSH=%SystemRoot%\System32\OpenSSH\ssh.exe"
set "KEY=%USERPROFILE%\.ssh\hellobro-oracle.key"
set "SERVER=ubuntu@ninjaonline.duckdns.org"
if not exist "%KEY%" (echo The key file is missing: %KEY% & pause & exit /b 1)
"%SSH%" -i "%KEY%" -o StrictHostKeyChecking=accept-new %SERVER% "sudo sh /opt/hellobro/tools/vps/update.sh check"
if errorlevel 1 (echo. & echo Could not reach the cloud server. & pause & exit /b 1)
echo.
"%SystemRoot%\System32\choice.exe" /c YN /m "Update the cloud server now"
if errorlevel 2 exit /b
"%SSH%" -i "%KEY%" %SERVER% "sudo sh /opt/hellobro/tools/vps/update.sh"
echo.
pause
