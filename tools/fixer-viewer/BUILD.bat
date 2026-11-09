@echo off
rem Builds BUG-FIXER-VIEWER.exe on your Desktop (no install needed: uses the C# compiler that comes with Windows).
setlocal
set CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
if not exist "%CSC%" set CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe
set OUT=%~1
if "%OUT%"=="" set OUT=%USERPROFILE%\Desktop\BUG-FIXER-VIEWER.exe
"%CSC%" /nologo /target:winexe /optimize+ /codepage:65001 /out:"%OUT%" ^
  /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:System.Web.Extensions.dll /r:System.Core.dll ^
  "%~dp0FixerViewer.cs"
if errorlevel 1 (echo BUILD FAILED & exit /b 1)
echo Built: %OUT%
