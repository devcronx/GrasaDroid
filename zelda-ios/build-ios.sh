#!/bin/bash
# build-zelda-ios.sh - Compila LASRecomp para iOS
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZELDA_DIR="$SCRIPT_DIR"
BUILD_DIR="$ZELDA_DIR/build-ios"
SDK=$(xcrun -sdk iphoneos --show-sdk-path)

echo "=== Build LASRecomp para iOS ==="
echo "SDK: $SDK"

mkdir -p "$BUILD_DIR"

# 1. SDL3 para iOS (si no existe)
SDL_DIR="$BUILD_DIR/sdl3"
if [ ! -d "$SDL_DIR" ]; then
    echo "[SDL3] Clonando..."
    git clone --depth 1 https://github.com/libsdl-org/SDL.git "$SDL_DIR"
fi

SDL_BUILD="$SDL_DIR/build-ios"
if [ ! -f "$SDL_BUILD/libSDL3.a" ]; then
    echo "[SDL3] Compilando para iOS..."
    mkdir -p "$SDL_BUILD"
    cd "$SDL_BUILD"
    cmake .. \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_SYSROOT="$SDK" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
        -DSDL_SHARED=OFF \
        -DSDL_STATIC=ON \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build . -j$(sysctl -n hw.ncpu)
    cd "$SCRIPT_DIR"
fi

echo "[SDL3] OK: $SDL_BUILD/libSDL3.a"

# 2. Compilar runtime de LASRecomp para iOS
echo "[Runtime] Compilando fuentes..."

CC="xcrun -sdk iphoneos clang -arch arm64 -mios-version-min=17.0 -isysroot $SDK"
CFLAGS="-O2 -I$ZELDA_DIR/runtime -I$SDL_DIR/include -DPLATFORM_IOS"

OBJ_DIR="$BUILD_DIR/obj"
mkdir -p "$OBJ_DIR"

# Compilar platform/ios.c
echo "  - platform/ios.c"
$CC $CFLAGS -c "$ZELDA_DIR/runtime/platform/ios.c" -o "$OBJ_DIR/ios.o"

# TODO: Compilar resto del runtime
# Esto requiere adaptar el Makefile completo para iOS

echo ""
echo "=== Build base completado ==="
echo "NOTA: Build completo del runtime pendiente - requiere adaptación del Makefile"
echo "para iOS (Metal backend, sin FFmpeg, paths iOS)."
