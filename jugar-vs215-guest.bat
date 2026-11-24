@echo off
cd /d "%~dp0"
start "" "build\bin\vf3guest.exe" "roms\vs215.zip" --join 127.0.0.1 --port 7701
