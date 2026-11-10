@echo off
rem Builds BUG-FIXER-VIEWER.exe on your Desktop (no install needed: uses the C# compiler that comes with Windows).
rem The page (app.html) and the icon are put inside the exe. Close the running Bug fixer first (tray icon > Quit).
setlocal
set HERE=%~dp0
set CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
if not exist "%CSC%" set CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe
if not exist "%HERE%app.ico" powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%make_icon.ps1"
set OUT=%~1
if "%OUT%"=="" set OUT=%USERPROFILE%\Desktop\BUG-FIXER-VIEWER.exe
"%CSC%" /nologo /target:winexe /optimize+ /codepage:65001 /out:"%OUT%" /win32icon:"%HERE%app.ico" ^
  /resource:"%HERE%app.html",app.html /resource:"%HERE%app.png",app.png /resource:"%HERE%app.ico",app.ico ^
  /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:System.Web.Extensions.dll /r:System.Core.dll ^
  "%HERE%FixerViewer.cs"
if errorlevel 1 (echo BUILD FAILED & exit /b 1)
echo Built: %OUT%
