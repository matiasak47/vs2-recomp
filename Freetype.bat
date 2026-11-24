@echo off
cd /d C:\ai\recomp\Trabajorecomp\vs2-recomp-120
if exist build\deps\freetype.tar.gz del build\deps\freetype.tar.gz
if exist build\deps\freetype-2.14.3 rmdir /s /q build\deps\freetype-2.14.3

git clone --depth 1 --branch VER-2-14-3 https://github.com build\deps\freetype-2.14.3

set "PATH=C:\w64devkit\bin;%PATH%"
cmake -S build/deps/freetype-2.14.3 -B build/deps/ft-build -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=build/deps/win -DBUILD_SHARED_LIBS=OFF -DFT_DISABLE_ZLIB=ON -DFT_DISABLE_BZIP2=ON -DFT_DISABLE_PNG=ON -DFT_DISABLE_HARFBUZZ=ON -DFT_DISABLE_BROTLI=ON
cmake --build build/deps/ft-build -j8
cmake --install build/deps/ft-build
pause
