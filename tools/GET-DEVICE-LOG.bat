@echo off
rem Saves the Hello Bro error log of a phone or tablet (over the USB cable) to the Desktop, for bug reports such as a black screen at start.
rem Needs USB debugging on the device and Android's USB tool (adb): INSTALL-WITH-USB.bat installs it the first time.
title Hello Bro - get the game log from a phone or tablet
set "ADB=adb"
if defined HB_ADB set "ADB=%HB_ADB%"
if not defined HB_ADB "%SystemRoot%\System32\where.exe" adb >nul 2>nul || (echo Android's USB tool ^(adb^) is missing: run INSTALL-WITH-USB.bat once first. & pause & exit /b)
set "OUT=%USERPROFILE%\Desktop\hellobro-device-log.txt"
if defined HB_LOG set "OUT=%HB_LOG%"
echo Connect the phone or tablet with the USB cable (USB debugging on) and tap "Allow" if it asks.
"%ADB%" wait-for-device
echo Found it.
"%ADB%" shell am force-stop com.hello.bro.yo
"%ADB%" logcat -c
echo.
echo Now OPEN Hello Bro on the device and wait until the problem shows (for example the black screen, about 30 seconds).
echo Then come back here and press a key.
pause >nul
> "%OUT%" echo Android version and model:
"%ADB%" shell getprop ro.build.version.release >> "%OUT%"
"%ADB%" shell getprop ro.product.model >> "%OUT%"
"%ADB%" shell "dumpsys package com.hello.bro.yo | grep -E 'versionName|targetSdk'" >> "%OUT%"
>> "%OUT%" echo ---- log
"%ADB%" logcat -d -v time >> "%OUT%"
echo.
echo Saved: %OUT%
echo Send this file to Claude or in Discord #bugs-and-issues.
pause
