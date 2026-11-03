#!/bin/sh
# Build Battery Monitor V2 for Miyoo Mini / Miyoo Mini Plus (glibc 2.28 compat)
set -e
ROOT=$(cd "$(dirname "$0")" && pwd)

TC=${TOOLCHAIN:-/g/Emulacja/redriver2-miyoo/deps/arm-gnu-toolchain-13.3.rel1-mingw-w64-i686-arm-none-linux-gnueabihf/bin}
CC="$TC/arm-none-linux-gnueabihf-gcc"
STRIP="$TC/arm-none-linux-gnueabihf-strip"

OUT="$ROOT/build"
mkdir -p "$OUT"

export MSYS2_ARG_CONV_EXCL="-Wl,-rpath"

echo "==> Compiling batteryMonitorUI..."
"$CC" -O2 -Wall -marm -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard -march=armv7ve \
	-no-pie -nostartfiles \
	-I"$ROOT/include" -I"$ROOT/src" -I"$ROOT/src/common" -I"$ROOT/src/common/utils" -I"$ROOT/src/common/system" \
	-DPLATFORM_MIYOOMINI \
	-DONION_VERSION="\"4.x.x\"" -include "$ROOT/src/compat/glibc_compat.h" \
	-o "$OUT/batteryMonitorUI" \
	"$ROOT/src/compat/start.S" "$ROOT/src/compat/start_init.c" "$ROOT/src/compat/batmonui_compat.c" \
	-Wl,--wrap=stat64 \
	"$ROOT/src/batteryMonitorUI.c" \
	"$ROOT/src/common/utils/str.c" \
	"$ROOT/src/common/utils/log.c" \
	"$ROOT/src/common/utils/file.c" \
	-L"$ROOT/lib" \
	-Wl,--allow-shlib-undefined -Wl,-rpath=/mnt/SDCARD/.tmp_update/lib \
	-lSDL -lSDL_image -lSDL_ttf -lsqlite3 -lm

echo "==> Stripping binary..."
"$STRIP" "$OUT/batteryMonitorUI"

echo "==> Verifying binary glibc symbols:"
"$TC/arm-none-linux-gnueabihf-objdump" -T "$OUT/batteryMonitorUI" | grep -o 'GLIBC_2\.[0-9]*' | sort -u -t. -k2,2n

echo "==> Build successful: $OUT/batteryMonitorUI"
ls -la "$OUT/batteryMonitorUI"
