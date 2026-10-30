@echo off
rem One-time setup to host your OWN Hello Bro server. Double-click it. Afterwards use START-SERVER.bat.
cd /d "%~dp0"
title Hello Bro - host your own server

echo == 1/4 Checking the programs you need ==
where node >nul 2>nul || (echo Installing Node.js ... & winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements)
where python >nul 2>nul || (echo Installing Python ... & winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements)
where jarsigner >nul 2>nul || (echo Installing Java JDK ... & winget install -e --id EclipseAdoptium.Temurin.21.JDK --accept-source-agreements --accept-package-agreements)
where node >nul 2>nul && where python >nul 2>nul && where jarsigner >nul 2>nul || (
  echo.
  echo Something was just installed. CLOSE this window and double-click HOST-MY-SERVER.bat again.
  pause & exit /b
)

echo.
echo == 2/4 Your server address ==
set ADDR=
for /f %%i in ('tailscale ip -4 2^>nul') do if not defined ADDR set ADDR=%%i
if defined ADDR (
  echo Tailscale found: your address is %ADDR%
  set /p NEWADDR=Press Enter to use it, or type another address:
) else (
  echo Tailscale not found. Type the address your players will use
  echo ^(Tailscale IP like 100.x.x.x, your LAN IP like 192.168.x.x, or a playit.gg / DuckDNS address^).
  set /p NEWADDR=Address:
)
if defined NEWADDR set ADDR=%NEWADDR%
if not defined ADDR (echo No address given. & pause & exit /b)

echo.
echo == 3/4 Making the game for %ADDR% ==
python -I tools\make_game_for.py %ADDR% || (pause & exit /b)

echo.
echo == 4/4 Opening the firewall (Windows asks for permission) ==
powershell -NoProfile -Command "Start-Process netsh -Verb RunAs -ArgumentList 'advfirewall firewall add rule name=\"Hello Bro server\" dir=in action=allow protocol=TCP localport=18080'"

echo.
echo All set!
echo  - Start the server: double-click START-SERVER.bat and keep that window open.
echo  - Give HelloBro-for-*.xapk (in this folder) to your players; they drag it onto BlueStacks.
echo  - Admin page: http://localhost:18080/admin
pause
