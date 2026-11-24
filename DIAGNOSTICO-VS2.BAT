@echo off
setlocal
set PATH=C:\msys64\mingw64\bin;%PATH%
set ROM=C:\ai\recomp\Trabajorecomp\vf3-recomp-worksnosound\ROMs\vs215.zip

set "VF3_DATA=%~dp0"
if "%VF3_DATA:~-1%"=="\" set "VF3_DATA=%VF3_DATA:~0,-1%"
cd /d "%~dp0"

if not exist "build\bin\vf3.exe" (
  echo build\bin\vf3.exe no se encuentra en build\bin\
  pause
  exit /b 1
)

rem --- DIRECTIVAS DE DIAGNÓSTICO DE SONIDO ---
set VF3_PIC_LOG=1
set VF3_MIDI_LOG=60
set VF3_MENU_SOUND=1

echo Ejecutando Virtua Striker 2 con captura de audio activa...
"build\bin\vf3.exe" "%ROM%" %*

echo.
echo ---- Analisis finalizado. El registro completo se guardo en log.txt ----
pause
