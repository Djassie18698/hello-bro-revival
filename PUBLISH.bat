@echo off
rem Saves everything to your private GitHub repo (commit + push).
cd /d "%~dp0"
git add -A
git commit -m "Update %date% %time%" >nul 2>&1
git push
echo Done.
pause
