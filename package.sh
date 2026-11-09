#!/bin/sh
# Package Battery Monitor V2 release ZIP for Onion OS
set -e
ROOT=$(cd "$(dirname "$0")" && pwd)

if [ ! -f "$ROOT/build/batteryMonitorUI" ]; then
    echo "==> Binary not found, building first..."
    "$ROOT/build.sh"
fi

STAGE="$ROOT/build/stage/BatteryMonitorUI"
DIST="$ROOT/dist"

rm -rf "$ROOT/build/stage"
mkdir -p "$STAGE/res" "$DIST"

echo "==> Staging release files..."
cp "$ROOT/build/batteryMonitorUI" "$STAGE/batteryMonitorUI"
cp "$ROOT/config.json" "$STAGE/config.json"
cp "$ROOT/launch.sh" "$STAGE/launch.sh"
cp "$ROOT/README.md" "$STAGE/README.md"
cp "$ROOT/res/"* "$STAGE/res/"

ZIP_NAME="BatteryMonitorUI_${VERSION:-v2.2.1}_OnionOS"
echo "==> Creating release archive: $DIST/$ZIP_NAME.zip"
rm -f "$DIST/$ZIP_NAME.zip"
if command -v cygpath >/dev/null 2>&1; then
    # Windows (Git Bash / MSYS2)
    WIN_DIST=$(cygpath -w "$DIST/$ZIP_NAME")
    WIN_STAGE=$(cygpath -w "$ROOT/build/stage")
    py -3 -c "import shutil; shutil.make_archive(r'$WIN_DIST', 'zip', r'$WIN_STAGE')"
elif command -v zip >/dev/null 2>&1; then
    # Linux / macOS (GitHub Actions); -X drops extra attributes, keeps exec bits
    (cd "$ROOT/build/stage" && zip -r -X -q "$DIST/$ZIP_NAME.zip" BatteryMonitorUI)
else
    python3 -c "import shutil; shutil.make_archive('$DIST/$ZIP_NAME', 'zip', '$ROOT/build/stage')"
fi

echo "==> Release package created successfully!"
ls -la "$DIST/$ZIP_NAME.zip"
