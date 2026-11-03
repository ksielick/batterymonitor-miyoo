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

echo "==> Creating release archive: $DIST/BatteryMonitorUI_v2.0_OnionOS.zip"
rm -f "$DIST/BatteryMonitorUI_v2.0_OnionOS.zip"
WIN_DIST=$(cygpath -w "$DIST/BatteryMonitorUI_v2.0_OnionOS")
WIN_STAGE=$(cygpath -w "$ROOT/build/stage")
py -3 -c "import shutil; shutil.make_archive(r'$WIN_DIST', 'zip', r'$WIN_STAGE')"

echo "==> Release package created successfully!"
ls -la "$DIST/BatteryMonitorUI_v2.0_OnionOS.zip"
