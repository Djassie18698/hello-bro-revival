@echo off
rem Gets the newest version of the Hello Bro server from GitHub. Your save (hellobro.db) is never touched.
cd /d "%~dp0"
title Hello Bro - update
echo == Hello Bro update ==
echo.

rem 1. The server must be stopped
netstat -ano | findstr ":18080 " | findstr "LISTENING" >nul
if not errorlevel 1 (
  echo The server is still running. Close the START-SERVER window first, then run UPDATE.bat again.
  pause & exit /b
)

rem 2. GitHub tool (one time)
where gh >nul 2>nul || (
  echo Installing the GitHub tool ...
  winget install -e --id GitHub.cli --accept-source-agreements --accept-package-agreements
  echo.
  echo Installed. CLOSE this window and double-click UPDATE.bat again.
  pause & exit /b
)

rem 3. Log in to GitHub (one time, opens your browser)
gh auth status >nul 2>nul || (
  echo Log in to GitHub: choose GitHub.com, HTTPS, then "Login with a web browser".
  gh auth login
)
gh auth status >nul 2>nul || (echo Not logged in. & pause & exit /b)

rem 4. Download the newest version
set "TMPDIR=%TEMP%\hb-update"
if exist "%TMPDIR%" rmdir /s /q "%TMPDIR%"
mkdir "%TMPDIR%"
echo Downloading the newest version ...
gh api repos/Djassie18698/hello-bro-revival/zipball/main > "%TMPDIR%\new.zip"
if errorlevel 1 (echo Download failed. Do you have access to the repository? & pause & exit /b)
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%TMPDIR%\new.zip' -DestinationPath '%TMPDIR%\x' -Force"
if errorlevel 1 (echo Unzip failed. & pause & exit /b)

rem 5. Copy over the old files (not the save, not this file, not the big release folder)
for /d %%D in ("%TMPDIR%\x\*") do set "SRC=%%D"
robocopy "%SRC%" "%~dp0." /E /XF *.db *.xapk *.obb UPDATE.bat /XD release re backups .github >nul
if errorlevel 8 (echo Copying failed. & pause & exit /b)
if not exist "release\revival.keystore" (
  if exist "%SRC%\release\revival.keystore" (
    mkdir release 2>nul
    copy "%SRC%\release\revival.keystore" "release\revival.keystore" >nul
  )
)
rmdir /s /q "%TMPDIR%"

echo.
echo Done! You now have the newest version.
echo  1. Start the server again: START-SERVER.bat (keep that window open).
echo  2. In the game, tap Confirm when it asks "confirm update?".
pause
