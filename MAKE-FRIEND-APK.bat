@echo off
rem Makes a copy of the game that connects to a different server address (for a friend who is NOT on your Wi-Fi).
rem Usage: double-click, type the address your friend must use (for example 26.12.34.56 from Radmin VPN or Tailscale) and press Enter.
set /p IP=Server address your friend will connect to (IP only):
if "%IP%"=="" exit /b
cd /d "%~dp0"
python -I -c "import zipfile;z=zipfile.ZipFile(r'..\HelloBro-revival.xapk');open('base_for_patch.apk','wb').write(z.read('com.hello.bro.yo.apk'))"
python tools\patch_apk.py base_for_patch.apk "..\HelloBro-for-%IP%.apk" %IP%:18080
del base_for_patch.apk
echo.
echo Done: the file HelloBro-for-%IP%.apk is on your Desktop.
echo Your friend also needs the big data file (OBB). See FRIENDS-README.txt.
pause
