@echo off
rem Builds "Ninja Online" for PC into the folder "Ninja Online" on your Desktop (or the folder you give as the first argument):
rem   Ninja Online.exe   the small program (Launcher.cs, built with the C# compiler that comes with Windows)
rem   game\              the whole rewritten game with its pictures and sounds (a copy of server\webclient)
rem   server.txt         the game server it plays on (first line; change it to play on another server)
rem Add "zip" as the second argument to also make NinjaOnline-PC.zip next to the folder (the file to share).
rem Needs: server\webclient\assets (node tools\build_webclient.js, and node tools\build_hd.js for the HD pictures).
setlocal
set HERE=%~dp0
set ROOT=%HERE%..\..
set FW=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319
if not exist "%FW%\csc.exe" set FW=%WINDIR%\Microsoft.NET\Framework\v4.0.30319
set DIR=%~1
if "%DIR%"=="" set DIR=%USERPROFILE%\Desktop\Ninja Online
if not exist "%ROOT%\server\webclient\assets\frames.json" (echo The game files are missing: run  node tools\build_webclient.js  first. & exit /b 1)
if not exist "%DIR%" mkdir "%DIR%"
if not exist "%HERE%app.ico" node "%ROOT%\tools\make_game_icon.js" --ico "%HERE%app.ico" >nul 2>nul
set ICON=
if exist "%HERE%app.ico" set ICON=/win32icon:"%HERE%app.ico"
"%FW%\csc.exe" /nologo /target:winexe /optimize+ /codepage:65001 /out:"%DIR%\Ninja Online.exe" %ICON% /r:System.Windows.Forms.dll /r:System.Core.dll "%HERE%Launcher.cs"
if errorlevel 1 (echo BUILD FAILED & exit /b 1)
rem the game folder: everything of server\webclient except the phone-app-in-a-browser (emu) and notes
robocopy "%ROOT%\server\webclient" "%DIR%\game" /MIR /XD emu /XF README.md *.map /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >nul
if errorlevel 8 (echo COPY FAILED & exit /b 1)
if exist "%DIR%\game\assets\emu" rmdir /s /q "%DIR%\game\assets\emu"
if not exist "%DIR%\server.txt" (
  echo http://ninjaonline.duckdns.org:18080> "%DIR%\server.txt"
  echo # The first line is the game server this copy plays on. Change it to play on another server, then start the game again.>> "%DIR%\server.txt"
)
echo Built: %DIR%\Ninja Online.exe
if /i "%~2"=="zip" (
  if exist "%DIR%\..\NinjaOnline-PC.zip" del "%DIR%\..\NinjaOnline-PC.zip"
  powershell -NoProfile -Command "Compress-Archive -Path '%DIR%\*' -DestinationPath '%DIR%\..\NinjaOnline-PC.zip' -CompressionLevel Fastest"
  echo Zip: %DIR%\..\NinjaOnline-PC.zip
)
exit /b 0
