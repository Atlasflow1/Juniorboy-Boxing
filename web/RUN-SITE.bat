@echo off
title Junior Boy Boxing - Local Site
cd /d "%~dp0"
echo Starting Junior Boy Boxing website...
start "" cmd /c "timeout /t 12 >nul & start http://127.0.0.1:3000"
npm run dev
pause
