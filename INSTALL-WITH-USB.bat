@echo off
rem Installs a Hello Bro game file (.xapk) on an Android phone or tablet from this PC, over a USB cable or Wi-Fi (adb).
rem Use it when the phone's own XAPK installer gives an error. Drag the .xapk onto this file, or put it in this folder.
setlocal
cd /d "%~dp0"
title Hello Bro - install on a phone or tablet (USB cable or Wi-Fi)

rem 1. Android's USB tool (adb), one time. HB_ADB = use another adb.exe instead.
set "ADB=adb"
if defined HB_ADB set "ADB=%HB_ADB%"
if defined HB_ADB goto haveadb
"%SystemRoot%\System32\where.exe" adb >nul 2>nul && goto haveadb
rem Not on this PC: download Google's own copy into %LOCALAPPDATA%\HelloBro, one time. (winget's Google.PlatformTools was dropped on
rem 10 Nov 2026: its manifest pointed at a version Google had removed, 404. The "latest" link below always exists.)
set "PT=%LOCALAPPDATA%\HelloBro"
if exist "%PT%\platform-tools\adb.exe" (set "ADB=%PT%\platform-tools\adb.exe" & goto haveadb)
echo Downloading Android's USB tool (adb) from Google, one time (about 7 MB) ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol='Tls12'; New-Item -ItemType Directory -Force -Path $env:PT | Out-Null; $z=Join-Path $env:PT 'pt.zip'; Invoke-WebRequest -UseBasicParsing -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $z; Expand-Archive -Force -Path $z -DestinationPath $env:PT; Remove-Item $z"
if exist "%PT%\platform-tools\adb.exe" (set "ADB=%PT%\platform-tools\adb.exe" & echo Done. & echo. & goto haveadb)
echo.
echo Could not download adb. Download it by hand:
echo   https://dl.google.com/android/repository/platform-tools-latest-windows.zip
echo unzip it, and put the folder "platform-tools" in %PT%  - then double-click INSTALL-WITH-USB.bat again.
pause & exit /b
:haveadb

rem 2. Which game file: the one dragged onto this file, else the newest HelloBro-for-*.xapk here, else another Hello Bro .xapk
set "XAPK=%~1"
if not defined XAPK for /f "delims=" %%f in ('dir /b /o-d "HelloBro-for-*.xapk" 2^>nul') do if not defined XAPK set "XAPK=%%f"
if not defined XAPK for /f "delims=" %%f in ('dir /b /o-d "HelloBro*.xapk" 2^>nul ^| "%SystemRoot%\System32\findstr.exe" /v /i "base"') do if not defined XAPK set "XAPK=%%f"
if not defined XAPK (
  echo No Hello Bro game file found. Make one with HOST-MY-SERVER.bat, or drag the .xapk onto this file.
  pause & exit /b
)
echo Game file: %XAPK%
set "WORK=%TEMP%\hellobro-usb-install"
rmdir /s /q "%WORK%" 2>nul
mkdir "%WORK%"
"%SystemRoot%\System32\tar.exe" -xf "%XAPK%" -C "%WORK%" 2>nul
if not exist "%WORK%\com.hello.bro.yo.apk" (
  echo This file is not a Hello Bro game file: %XAPK%
  pause & exit /b
)

rem 3. The phone or tablet
echo.
echo == On your phone or tablet ==
echo  1. Settings - About phone - Software information: tap "Build number" 7 times (turns on Developer options)
echo  2. Settings - Developer options: turn on "USB debugging"
echo  3. Connect it to this PC with a USB cable and tap "Allow" when it asks about USB debugging
echo.
"%ADB%" start-server >nul 2>nul
:waitdevice
set N=0
set "SERIAL="
set WAITALLOW=
for /f "skip=1 tokens=1,2" %%a in ('call "%ADB%" devices') do (
  if "%%b"=="device" (set /a N+=1 & set "SERIAL=%%a")
  if "%%b"=="unauthorized" set WAITALLOW=1
)
if defined ANDROID_SERIAL set "SERIAL=%ANDROID_SERIAL%" & set N=1
if defined WAITALLOW if "%N%"=="0" (
  echo Tap "Allow" on the phone or tablet, then press a key here.
  pause >nul & goto waitdevice
)
if not "%N%"=="0" goto onedevice
echo No phone or tablet found yet. Do the 3 steps above, then press Enter here.
echo No cable? Type W and press Enter to connect over Wi-Fi instead.
set "ANS="
set /p ANS=
if /i not "%ANS%"=="W" goto waitdevice
rem Wi-Fi: Developer options - Wireless debugging (phone and PC on the same Wi-Fi). Pairing is only needed once per PC.
echo.
echo On the phone: Developer options - turn on "Wireless debugging" - tap it - "Pair device with pairing code".
set "PAIR="
set /p PAIR=Pairing IP address and port shown in that popup (like 192.168.1.20:37123), or just Enter if this PC paired before:
if not defined PAIR goto wificonnect
set "CODE="
set /p CODE=6-digit pairing code:
"%ADB%" pair %PAIR% %CODE%
:wificonnect
echo Now close the popup. The Wireless debugging screen shows "IP address and Port" (another port than the popup).
set "CONN="
set /p CONN=That IP address and port:
if defined CONN "%ADB%" connect %CONN%
goto waitdevice
:onedevice
if not "%N%"=="1" (
  echo More than one device is connected, for example BlueStacks. Close BlueStacks or unplug the other one, then press a key.
  pause >nul & goto waitdevice
)
echo Found: %SERIAL%

rem 4. Install the app. New Android (14+) refuses game files made before 2 Nov 2026; adb can still install them.
echo.
echo == Installing the game (about a minute) ==
:install
"%ADB%" -s %SERIAL% install -r "%WORK%\com.hello.bro.yo.apk" > "%WORK%\out.txt" 2>&1
"%SystemRoot%\System32\findstr.exe" /c:"Success" "%WORK%\out.txt" >nul && goto obb
"%SystemRoot%\System32\findstr.exe" /c:"DEPRECATED_SDK_VERSION" "%WORK%\out.txt" >nul && (
  "%ADB%" -s %SERIAL% install -r --bypass-low-target-sdk-block "%WORK%\com.hello.bro.yo.apk" > "%WORK%\out.txt" 2>&1
  "%SystemRoot%\System32\findstr.exe" /c:"Success" "%WORK%\out.txt" >nul && goto obb
)
"%SystemRoot%\System32\findstr.exe" /c:"NO_MATCHING_ABIS" "%WORK%\out.txt" >nul && (
  echo This phone or tablet can't run Hello Bro: its processor only runs 64-bit apps and the game is 32-bit.
  pause & exit /b
)
"%SystemRoot%\System32\findstr.exe" /c:"UPDATE_INCOMPATIBLE" /c:"signatures do not match" "%WORK%\out.txt" >nul || goto failed
echo.
echo An older Hello Bro is on the device and can't be replaced. It has to be uninstalled first.
echo A guest account (PLAY) is tied to the device: link it first in the game with Change - Login with Gumptech - Signup if you want to keep it.
"%SystemRoot%\System32\choice.exe" /c YN /m "Uninstall the old Hello Bro now"
if errorlevel 2 exit /b
"%ADB%" -s %SERIAL% uninstall com.hello.bro.yo
goto install
:failed
echo Installing failed. What Android said:
type "%WORK%\out.txt"
pause & exit /b

rem 5. The game's data file (.obb) goes to Android/obb/com.hello.bro.yo/
:obb
echo App installed. Copying the game data (about 110 MB) ...
"%ADB%" -s %SERIAL% shell mkdir -p /sdcard/Android/obb/com.hello.bro.yo
set "OBB=%WORK%\Android\obb\com.hello.bro.yo\main.28.com.hello.bro.yo.obb"
"%ADB%" -s %SERIAL% push "%OBB%" /sdcard/Android/obb/com.hello.bro.yo/main.28.com.hello.bro.yo.obb
rem adb prints its progress straight to the screen, so check the copy by its size
for %%A in ("%OBB%") do set LSIZE=%%~zA
set RSIZE=0
for /f %%r in ('call "%ADB%" -s %SERIAL% shell stat -c %%s /sdcard/Android/obb/com.hello.bro.yo/main.28.com.hello.bro.yo.obb') do set RSIZE=%%r
if not "%RSIZE%"=="%LSIZE%" (
  echo Copying the game data failed: %RSIZE% of %LSIZE% bytes arrived. Check the cable and run this file again.
  pause & exit /b
)
rmdir /s /q "%WORK%" 2>nul
echo.
echo Done! Open Hello Bro on the device, tap PLAY, then Confirm when it asks to update.
echo You can turn USB debugging / Wireless debugging off again now.
pause
