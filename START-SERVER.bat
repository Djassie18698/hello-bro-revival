@echo off
rem Hello Bro server: starts the server, opens the Server Manager in your browser, and starts the server again
rem when you press Restart in the manager. Close this window to stop the server.
cd /d "%~dp0"
chcp 65001 >nul
title Hello Bro Server
color 0F
set HB_MANAGED=1
where node >nul 2>&1 || (echo. & echo   Node.js is not installed. Get it from https://nodejs.org and run this again. & echo. & pause & exit /b 1)
rem Since 2 Nov 2026 the server's files live in the server folder. UPDATE.bat copies new files but never deletes old ones,
rem so remove the old copies that used to sit here (only once the new server folder is there).
if exist "server\server.js" if exist "server.js" (
  for %%f in (admin.html admin.js awardcenter.js border.js boss.js box.js caishen.js consumption.js country.js crosswar.js dailyevents.js db.js drops.js errcodes.js exam.js festival.js flower.js game.js godrecruit.js groupbuy.js growthfund.js guild.js gumplogin.js handlers.js hottreasure.js keeplogin.js limited.js limitsuper.js manager.html manager.js monopoly.js monthcard.js mora.js notices.js panel.html pet.js playerlog.html playerlog.js rankings.js schema.js scratch.js seals.js server.js settings.js sevenday.js signin.js slot.js soultrain.js stagegift.js sudoku.js tear.js totalgift.js tupo.js vip.js war.js wheel.js HOST-YOUR-OWN-SERVER.md PLAY-ON-TAILSCALE.md) do if exist "%%f" del /q "%%f"
  for %%d in (data cdn reference public-template) do if exist "%%d\" rmdir /s /q "%%d"
)
start "" /b cmd /c "%SystemRoot%\System32\timeout.exe /t 3 >nul & start "" http://localhost:18080/manager"
:run
node server\server.js
if %errorlevel%==3 (echo. & echo   Restarting... & echo. & goto run)
echo.
echo   The server has stopped. Press any key to close this window.
pause >nul
