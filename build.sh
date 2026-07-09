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
cp "$SCRIPT_DIR/AgentDashboard/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# 用固定的 bundle identifier 做 ad-hoc 签名。系统通知按签名 identifier 认 app;
# 不签的话 macOS 用文件 hash 当 identifier(每次构建变化),系统认不出同一 app,
# UNUserNotificationCenter 注册不上、系统设置 → 通知 也不列本 app。
codesign --force --identifier "com.lucky.AgentDashboard" --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true

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
