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
CFLAGS="-O2 -I$ZELDA_DIR/runtime -I$ZELDA_DIR/third_party/smaa/Textures -I$SDL_DIR/include -DPLATFORM_IOS"

OBJ_DIR="$BUILD_DIR/obj"
mkdir -p "$OBJ_DIR"

# Generar smaa_hlsl.inc desde SMAA.hlsl (como hace el Makefile)
INC_DIR="$BUILD_DIR/inc"
mkdir -p "$INC_DIR"
if [ ! -f "$INC_DIR/smaa_hlsl.inc" ]; then
    echo "[SMAA] Generando smaa_hlsl.inc..."
    LC_ALL=C tr -d '\r' < "$ZELDA_DIR/third_party/smaa/SMAA.hlsl" | LC_ALL=C tr '\200-\377' '?' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/^/"/' -e 's/$/\\n"/' > "$INC_DIR/smaa_hlsl.inc"
fi
CFLAGS="$CFLAGS -I$INC_DIR"

# Compilar todo el runtime C (excluyendo Vulkan, FFmpeg/movie.c)
echo "[Runtime] Compilando todas las fuentes C..."
RT_SRCS=$(find "$ZELDA_DIR/runtime" -name "*.c" \
    -not -path "*/platform/*" \
    -not -path "*/vulkan/*" \
    -not -name "movie.c")
RT_SRCS="$RT_SRCS $ZELDA_DIR/runtime/platform/ios.c"
RT_SRCS="$RT_SRCS $ZELDA_DIR/runtime/platform/ios_touch.c"
# nogen_stub si no hay código generado
if [ ! -d "$ZELDA_DIR/generated" ]; then
    RT_SRCS="$RT_SRCS $ZELDA_DIR/tools/nogen_stub.c"
fi

FAILED=0
for src in $RT_SRCS; do
    rel=$(echo "$src" | sed "s|$ZELDA_DIR/||")
    obj="$OBJ_DIR/${rel%.c}.o"
    mkdir -p "$(dirname "$obj")"
    echo "  - $rel"
    if ! $CC $CFLAGS -c "$src" -o "$obj" 2>> "$BUILD_DIR/errors.log"; then
        echo "    ERROR en $rel (ver errors.log)"
        FAILED=1
    fi
done

if [ "$FAILED" = "1" ]; then
    echo ""
    echo "=== ERRORES DE COMPILACIÓN ==="
    grep -E "error:" "$BUILD_DIR/errors.log" | head -30
    exit 1
fi

echo ""
echo "=== Runtime C compilado ==="

# 3. Compilar backend Metal (.m) para iOS
echo "[Metal] Compilando backend Metal..."
METAL_SRCS="$ZELDA_DIR/runtime/nvn/metal.m $ZELDA_DIR/runtime/nvn/renderer.m"
OBJC_FLAGS="-fobjc-arc -framework Foundation -framework Metal -framework MetalFX -framework QuartzCore"

for src in $METAL_SRCS; do
    rel=$(echo "$src" | sed "s|$ZELDA_DIR/||")
    obj="$OBJ_DIR/${rel%.m}.o"
    mkdir -p "$(dirname "$obj")"
    echo "  - $rel"
    if ! $CC $CFLAGS $OBJC_FLAGS -c "$src" -o "$obj" 2>> "$BUILD_DIR/errors.log"; then
        echo "    ERROR en $rel (ver errors.log)"
        FAILED=1
    fi
done

if [ "$FAILED" = "1" ]; then
    echo ""
    echo "=== ERRORES DE COMPILACIÓN (Metal) ==="
    grep -E "error:" "$BUILD_DIR/errors.log" | head -30
    exit 1
fi

echo ""
echo "=== Linkeando ejecutable ==="

# 3b. Compilar UI (.mm) e ImGui para iOS
echo "[UI] Compilando interfaz y trucos..."
CXX="xcrun -sdk iphoneos clang++ -arch arm64 -mios-version-min=17.0 -isysroot $SDK"
CXXFLAGS="-O2 -std=c++17 -I$ZELDA_DIR/runtime -I$ZELDA_DIR/third_party/imgui -I$ZELDA_DIR/third_party/smaa/Textures -I$SDL_DIR/include -DPLATFORM_IOS"

IMGUI_DIR="$ZELDA_DIR/third_party/imgui"
IMGUI_SRCS="$IMGUI_DIR/imgui.cpp $IMGUI_DIR/imgui_draw.cpp $IMGUI_DIR/imgui_tables.cpp $IMGUI_DIR/imgui_widgets.cpp $IMGUI_DIR/backends/imgui_impl_sdl3.cpp"
IMGUI_MM="$IMGUI_DIR/backends/imgui_impl_metal.mm"
# ImGui necesita los headers de backends para imgui_impl_metal.h
CXXFLAGS="$CXXFLAGS -I$IMGUI_DIR/backends"

for src in $IMGUI_SRCS; do
    rel=$(echo "$src" | sed "s|$ZELDA_DIR/||")
    obj="$OBJ_DIR/${rel%.cpp}.o"
    mkdir -p "$(dirname "$obj")"
    echo "  - $rel"
    if ! $CXX $CXXFLAGS -c "$src" -o "$obj" 2>> "$BUILD_DIR/errors.log"; then
        echo "    ERROR en $rel"
        FAILED=1
    fi
done

# imgui_impl_metal.mm (Objective-C++)
rel="third_party/imgui/backends/imgui_impl_metal.mm"
obj="$OBJ_DIR/third_party/imgui/backends/imgui_impl_metal.o"
mkdir -p "$(dirname "$obj")"
echo "  - $rel"
if ! $CXX $CXXFLAGS -fobjc-arc -c "$IMGUI_MM" -o "$obj" 2>> "$BUILD_DIR/errors.log"; then
    echo "    ERROR en $rel"
    FAILED=1
fi

# UI .mm files (launcher, menu, cheats, etc.)
UI_SRCS=$(find "$ZELDA_DIR/runtime/ui" -name "*.mm")
for src in $UI_SRCS; do
    rel=$(echo "$src" | sed "s|$ZELDA_DIR/||")
    obj="$OBJ_DIR/${rel%.mm}.o"
    mkdir -p "$(dirname "$obj")"
    echo "  - $rel"
    if ! $CXX $CXXFLAGS -fobjc-arc -c "$src" -o "$obj" 2>> "$BUILD_DIR/errors.log"; then
        echo "    ERROR en $rel"
        FAILED=1
    fi
done

if [ "$FAILED" = "1" ]; then
    echo ""
    echo "=== ERRORES DE COMPILACIÓN (UI) ==="
    grep -E "error:" "$BUILD_DIR/errors.log" | head -30
    exit 1
fi

echo "[UI] OK"

# 4. Linkear todo en un ejecutable
APP_NAME="LASRecomp"
OBJS=$(find "$OBJ_DIR" -name "*.o")
# Frameworks que SDL3 necesita en iOS (audio, video, bluetooth, sensores, etc.)
LINK_FLAGS="-framework Foundation -framework Metal -framework MetalFX -framework QuartzCore -framework UIKit -framework CoreGraphics -framework AVFoundation -framework AudioToolbox -framework CoreBluetooth -framework ImageIO -framework OpenGLES -framework CoreVideo -framework CoreMedia -framework Security -framework GameController -framework CoreMotion -framework CoreHaptics -framework UserNotifications -framework UniformTypeIdentifiers -lc++"

$CC -o "$BUILD_DIR/$APP_NAME" $OBJS "$SDL_BUILD/libSDL3.a" $LINK_FLAGS 2>> "$BUILD_DIR/errors.log" || {
    echo "ERROR en linkeo (ver errors.log)"
    grep -E "error:" "$BUILD_DIR/errors.log" | head -20
    exit 1
}

echo "[Link] OK: $BUILD_DIR/$APP_NAME"

# 4.5. Compilar hactool para iOS (necesario para extraer el NSP/XCI)
echo "[hactool] Compilando para iOS..."
HACTOOL_DIR="$BUILD_DIR/hactool"
if [ ! -d "$HACTOOL_DIR" ]; then
    git clone --depth 1 https://github.com/SciresM/hactool.git "$HACTOOL_DIR"
fi
HACTOOL_BIN="$BUILD_DIR/hactool-ios"
if [ ! -f "$HACTOOL_BIN" ]; then
    cd "$HACTOOL_DIR"
    # Compilar mbedtls directamente (sin su sistema de build, que falla en iOS)
    echo "[hactool] Compilando mbedtls (directo)..."
    mkdir -p "$BUILD_DIR/hactool-obj"
    MBEDTLS_SRCS=$(ls mbedtls/library/*.c)
    MBEDTLS_OBJS=""
    for src in $MBEDTLS_SRCS; do
        obj="$BUILD_DIR/hactool-obj/mbedtls_$(basename $src .c).o"
        if [ ! -f "$obj" ]; then
            xcrun -sdk iphoneos clang -arch arm64 -mios-version-min=17.0 -isysroot "$SDK" -O2 \
                -I./mbedtls/include -D_BSD_SOURCE -D_POSIX_SOURCE \
                -include stdio.h -include stdlib.h -include string.h \
                -c "$src" -o "$obj" 2>> "$BUILD_DIR/errors.log" || {
                echo "Advertencia: falló $src, continuando"
            }
        fi
        if [ -f "$obj" ]; then
            MBEDTLS_OBJS="$MBEDTLS_OBJS $obj"
        fi
    done
    echo "[hactool] mbedtls: $(echo $MBEDTLS_OBJS | wc -w) objetos"
    MBEDTLS_LIB_DIR=""
    echo "[hactool] Compilando fuentes..."
    HACTOOL_SRCS="save.c sha.c aes.c extkeys.c rsa.c npdm.c bktr.c kip.c packages.c pki.c pfs0.c hfs0.c nca0_romfs.c romfs.c utils.c nax0.c nso.c lz4.c nca.c xci.c main.c filepath.c ConvertUTF.c cJSON.c"
    HACTOOL_CFLAGS="-arch arm64 -mios-version-min=17.0 -isysroot $SDK -O2 -I./mbedtls/include -D_BSD_SOURCE -D_POSIX_SOURCE -D_POSIX_C_SOURCE=200112L -D_DEFAULT_SOURCE -D_FILE_OFFSET_BITS=64"
    HACTOOL_OBJS=""
    for src in $HACTOOL_SRCS; do
        obj="$BUILD_DIR/hactool-obj/$(basename $src .c).o"
        mkdir -p "$BUILD_DIR/hactool-obj"
        if [ ! -f "$obj" ] || [ "$src" -nt "$obj" ]; then
            xcrun -sdk iphoneos clang $HACTOOL_CFLAGS -c "$src" -o "$obj" 2>> "$BUILD_DIR/errors.log" || {
                echo "ERROR compilando hactool: $src"
                grep -E "error:" "$BUILD_DIR/errors.log" | head -10
                exit 1
            }
        fi
        HACTOOL_OBJS="$HACTOOL_OBJS $obj"
    done
    xcrun -sdk iphoneos clang -arch arm64 -mios-version-min=17.0 -isysroot "$SDK" -o "$HACTOOL_BIN" $HACTOOL_OBJS $MBEDTLS_OBJS 2>> "$BUILD_DIR/errors.log" || {
        echo "ERROR linkeando hactool"
        grep -E "error:" "$BUILD_DIR/errors.log" | head -10
        exit 1
    }
    cd "$SCRIPT_DIR"
fi
echo "[hactool] OK: $HACTOOL_BIN"

# 5. Crear .app bundle
echo "[App] Creando bundle..."
APP_BUNDLE="$BUILD_DIR/Payload/$APP_NAME.app"
mkdir -p "$APP_BUNDLE"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/"

# Info.plist
cat > "$APP_BUNDLE/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>LASRecomp</string>
    <key>CFBundleIdentifier</key>
    <string>com.zelda.lasrecomp</string>
    <key>CFBundleName</key>
    <string>LASRecomp</string>
    <key>CFBundleDisplayName</key>
    <string>Zelda LA</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
        <string>metal</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>CFBundleIcons</key>
    <dict>
        <key>CFBundlePrimaryIcon</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>Icon</string>
            </array>
        </dict>
    </dict>
</dict>
</plist>
PLIST

# Iconos
cp "$ZELDA_DIR/icon/Icon-1024.png" "$APP_BUNDLE/Icon-1024.png"
cp "$ZELDA_DIR/icon/Icon-180.png" "$APP_BUNDLE/Icon-180.png"
# iOS busca Icon.png, Icon@2x.png, etc. - crear enlaces
cp "$ZELDA_DIR/icon/Icon-180.png" "$APP_BUNDLE/Icon.png"

# Imagen de fondo personalizada
if [ -f "$ZELDA_DIR/assets/la-bg.webp" ]; then
    cp "$ZELDA_DIR/assets/la-bg.webp" "$APP_BUNDLE/la-bg.webp"
elif [ -f "$ZELDA_DIR/assets/la-bg.png" ]; then
    cp "$ZELDA_DIR/assets/la-bg.png" "$APP_BUNDLE/la-bg.png"
fi

# hactool para extraer el NSP/XCI (va en tools/hactool/ como espera rt_resource)
mkdir -p "$APP_BUNDLE/tools/hactool"
cp "$HACTOOL_BIN" "$APP_BUNDLE/tools/hactool/hactool"
chmod +x "$APP_BUNDLE/tools/hactool/hactool"

# Firmar con identidad ad-hoc (para sideload)
echo "[App] Firmando (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>> "$BUILD_DIR/errors.log" || {
    echo "Advertencia: codesign falló, continuando sin firma"
}

# 6. Crear .ipa
echo "[IPA] Empaquetando..."
cd "$BUILD_DIR"
zip -qr "LASRecomp.ipa" "Payload"
cd "$SCRIPT_DIR"

echo ""
echo "=== Build iOS completado ==="
echo "IPA: $BUILD_DIR/LASRecomp.ipa"
