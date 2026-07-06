#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="AgentDashboard"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# 默认构建后自动重启(杀旧实例 + open 新版);传 --no-run 则只构建。
AUTO_RUN=1
if [ "$1" = "--no-run" ]; then
    AUTO_RUN=0
fi

echo "Building $APP_NAME..."
cd "$SCRIPT_DIR"
swift build

echo "Packaging .app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp ".build/debug/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Always copy from the canonical source; convert to binary plist so CoreFoundation
# parses it cleanly (a JSON-formatted Info.plist triggers NSCocoaErrorDomain -3840).
cp "$SCRIPT_DIR/AgentDashboard/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
plutil -convert binary1 "$APP_BUNDLE/Contents/Info.plist"

echo "Done! App bundle at: $APP_BUNDLE"

if [ "$AUTO_RUN" = "1" ]; then
    echo "Restarting..."
    pkill -f "$APP_NAME" 2>/dev/null || true
    sleep 1
    open "$APP_BUNDLE"
    echo "Launched: $APP_BUNDLE"
else
    echo ""
    echo "To run:"
    echo "  open $APP_BUNDLE"
    echo ""
    echo "To kill existing instance first:"
    echo "  pkill -f AgentDashboard; open $APP_BUNDLE"
fi
