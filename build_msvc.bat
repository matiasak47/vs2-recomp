@echo off
rem ============================================================================
rem  MSVC x64 build for vs2-recomp-project (fv2 fork)
rem  Produces:  build\bin\vf3run.exe   (headless diagnostic tool)
rem             build\bin\vf3.exe      (graphical host)
rem  Links against the shared global deps in
rem    C:\ai\recomp\Trabajorecomp\vf3-recomp\build\deps
rem  (zlib sources, SDL3.lib/.dll, freetype.lib, prebuilt rmlui.lib)
rem ============================================================================
setlocal enabledextensions

set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%
cd /d "%ROOT%"

set DEPS=C:\ai\recomp\Trabajorecomp\vf3-recomp\build\deps
set ZLIB=%DEPS%\zlib-1.3.1
set SDLINC=%DEPS%\SDL3-3.4.18\include
set FTINC=%DEPS%\freetype-2.14.3\include

rem ---- MSVC x64 environment ----
where cl.exe >nul 2>nul
if errorlevel 1 (
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" >nul 2>nul
)
where cl.exe >nul 2>nul || (echo [ERROR] cl.exe not found. & exit /b 1)

rem ---- version.h (shown in the menu) ----
if not exist build\obj mkdir build\obj
>build\obj\version.h echo #define VF3_VERSION "fv2"
>>build\obj\version.h echo #define VF3_DATE "Oct 30 2026"

rem ---- common flags ----
set CXXFLAGS=/O2 /EHsc /std:c++20 /D"__int128=__int64" /D"__builtin_bswap32=_byteswap_ulong" /D"__builtin_bswap16=_byteswap_ushort" /D"__x86_64__" /D"VF3_COMMIT=\"fv2\"" /D"NOMINMAX" /D"VF_LOBBY_URL=\"\""
set INC=/I src /I src\core /I src\core\shim_include /I scsp\src\sound /I third_party\sljit /I third_party\mame /I third_party\mame\315-5881 /I "%ZLIB%" /I build\obj /I "%SDLINC%" /I "%DEPS%\SDL3-3.4.18\include\SDL3" /I third_party\rmlui\Include /I third_party\rmlui\Backends
set INC_HOST=%INC% /I third_party\rmlui\Include /I third_party\rmlui\Backends /I "%FTINC%"
rem ---- core sources (shared by both binaries) ----
set CORE=src\ppc\ppc.cpp src\machine\model3.cpp src\machine\romset.cpp src\machine\fv2_portraits.cpp src\host\input_script.cpp src\rec\ppc_rec.cpp src\rec\vf3_map.cpp src\rec\fv2_map.cpp src\video\tilegen.cpp src\video\r3d_scene.cpp src\video\r3d_raster.cpp src\video\tex3d_hd.cpp src\video\tilehd.cpp src\sound\soundboard.cpp src\sound\scsp.cpp src\sound\scspdsp.cpp src\sound\scsp_mame.cpp scsp\src\sound\scsp_trace.cpp scsp\src\sound\scsp_select.cpp scsp\src\sound\scsp_own.cpp scsp\src\sound\dsp_own.cpp src\core\mame_shim.cpp third_party\mame\m68000\m68000.cpp third_party\mame\m68000\m68000-decode.cpp third_party\mame\m68000\m68000-sdf.cpp third_party\mame\m68000\m68000-sdp.cpp third_party\mame\315-5881\crypt_315_5881.cpp src\machine\profile.cpp src\video\hud_names.cpp src\video\dural_cell.cpp src\rec\vf3tb_map.cpp src\machine\dural.cpp src\net\http.cpp src\net\link.cpp src\net\room_link.cpp src\net\session.cpp src\net\stun.cpp src\host\online.cpp src\host\menu.cpp src\host\sysinfo.cpp src\host\vf3_netplay.cpp
set SLJIT=third_party\sljit\sljitLir.c

echo.
echo [BUILD] vf3run.exe (headless) ...
cl.exe %CXXFLAGS% /DRMLUI_SDL_VERSION_MAJOR=3 %INC% tools\vf3run.cpp %CORE% %SLJIT% "%ZLIB%\adler32.c" "%ZLIB%\compress.c" "%ZLIB%\crc32.c" "%ZLIB%\deflate.c" "%ZLIB%\infback.c" "%ZLIB%\inffast.c" "%ZLIB%\inflate.c" "%ZLIB%\inftrees.c" "%ZLIB%\trees.c" "%ZLIB%\uncompr.c" "%ZLIB%\zutil.c" /Fe:build\bin\vf3run.exe /link /SUBSYSTEM:CONSOLE "%DEPS%\sdl-build\Release\SDL3.lib" "%DEPS%\ft-build\Release\freetype.lib" "%DEPS%\rmlui.lib" d3d11.lib dxgi.lib advapi32.lib user32.lib winhttp.lib ws2_32.lib /OPT:REF
if errorlevel 1 (echo [ERROR] vf3run build failed. & exit /b 1)

echo.
echo [BUILD] vf3.exe (graphical host) ...
cl.exe %CXXFLAGS% %INC_HOST% /DRMLUI_SDL_VERSION_MAJOR=3 /DRMLUI_STATIC_LIB /DRMLUI_FONT_ENGINE_FREETYPE /Dpopen=_popen /Dpclose=_pclose src\host\main.cpp src\host\d3d11_map.cpp src\gpu\r3d_gpu.cpp %CORE% %SLJIT% "%ZLIB%\adler32.c" "%ZLIB%\compress.c" "%ZLIB%\crc32.c" "%ZLIB%\deflate.c" "%ZLIB%\infback.c" "%ZLIB%\inffast.c" "%ZLIB%\inflate.c" "%ZLIB%\inftrees.c" "%ZLIB%\trees.c" "%ZLIB%\uncompr.c" "%ZLIB%\zutil.c" /Fe:build\bin\vf3.exe /link /SUBSYSTEM:WINDOWS "%DEPS%\sdl-build\Release\SDL3.lib" "%DEPS%\ft-build\Release\freetype.lib" "%DEPS%\rmlui.lib" d3d11.lib dxgi.lib advapi32.lib user32.lib winhttp.lib ws2_32.lib
if errorlevel 1 (echo [ERROR] vf3 build failed. & exit /b 1)

rem ---- runtime DLL next to the exes ----
copy /y "%DEPS%\sdl-build\Release\SDL3.dll" build\bin\SDL3.dll >nul

echo.
echo ---- finished: build\bin\vf3run.exe + build\bin\vf3.exe ----
dir build\bin\*.exe
endlocal
