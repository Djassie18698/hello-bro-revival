@echo off
rem Builds the Bug Fixer app into the folder "Bug Fixer" on your Desktop, with a shortcut next to it.
rem No install needed: it uses the C# compiler and WPF that come with Windows. Close the running Bug Fixer first (tray icon > Quit).
setlocal
set HERE=%~dp0
set FW=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319
if not exist "%FW%\csc.exe" set FW=%WINDIR%\Microsoft.NET\Framework\v4.0.30319
if not exist "%HERE%app.ico" powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%make_icon.ps1"
set DIR=%~1
if "%DIR%"=="" set DIR=%USERPROFILE%\Desktop\Bug Fixer
if not exist "%DIR%" mkdir "%DIR%"
"%FW%\csc.exe" /nologo /target:winexe /optimize+ /codepage:65001 /out:"%DIR%\Bug Fixer.exe" /win32icon:"%HERE%app.ico" ^
  /resource:"%HERE%app.png",app.png /resource:"%HERE%app.ico",app.ico ^
  /r:"%FW%\WPF\PresentationFramework.dll" /r:"%FW%\WPF\PresentationCore.dll" /r:"%FW%\WPF\WindowsBase.dll" /r:System.Xaml.dll ^
  /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:System.Web.Extensions.dll /r:System.Core.dll ^
  "%HERE%Program.cs" "%HERE%Ui.cs" "%HERE%Store.cs" "%HERE%Discord.cs" "%HERE%Parser.cs"
if errorlevel 1 (echo BUILD FAILED & exit /b 1)
copy /y "%HERE%app.ico" "%DIR%\Bug Fixer.ico" >nul
if "%~1"=="" if not exist "%USERPROFILE%\Desktop\Bug Fixer.lnk" powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\Bug Fixer.lnk'); $s.TargetPath='%DIR%\Bug Fixer.exe'; $s.WorkingDirectory='%DIR%'; $s.IconLocation='%DIR%\Bug Fixer.exe,0'; $s.Description='Bug Fixer: the Hello Bro bug pipeline'; $s.Save()"
echo Built: %DIR%\Bug Fixer.exe
