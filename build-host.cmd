@echo off
setlocal
set DEVKIT=C:\w64devkit\bin
set MAKE=%DEVKIT%\make.exe
set PATH=%DEVKIT%;%PATH%
set SCRATCH=%LOCALAPPDATA%\Temp
cd /d "%~dp0"
if not exist build\bin mkdir build\bin
if not exist build\deps\win\lib mkdir build\deps\win\lib

for /r "freetype\freetype-windows-binaries-2.14.3" %%F in (*freetype*.dll) do (
  echo %%F | findstr /i "win64 x64" >nul && (
    copy /y "%%F" "build\bin\freetype.dll" >nul
  )
)
if not exist "build\bin\freetype.dll" (
  for /r "freetype\freetype-windows-binaries-2.14.3" %%F in (*freetype*.dll) do copy /y "%%F" "build\bin\freetype.dll" >nul
)

gendef "build\bin\freetype.dll" >nul 2>&1
dlltool -d freetype.def -l "build\deps\win\lib\libfreetype.dll.a" >nul 2>&1
if exist freetype.def del freetype.def

"%MAKE%" CXX=g++ ^
  EXTRA_CFLAGS="-Ibuild/deps/win/include" ^
  SDL_CFLAGS="-Ibuild/deps/win/include" ^
  SDL_LIBS="-Lbuild/deps/win/lib -lSDL3 -lgdi32 -lwinmm -limm32 -lversion -lole32 -loleaut32 -lsetupapi -lcfgmgr32 -luuid" ^
  FT_CFLAGS="-Ifreetype/freetype-windows-binaries-2.14.3/include" ^
  FT_LIBS="-Lbuild/deps/win/lib -lfreetype" ^
  LDLIBS="-Lbuild/deps/win/lib -lz -lws2_32 -liphlpapi -lwinhttp" ^
  TMP=%SCRATCH% TEMP=%SCRATCH% TMPDIR=%SCRATCH% build/bin/vf3run build/bin/vf3 -j8
echo.
echo ---- finished (code %ERRORLEVEL%) ----
pause
