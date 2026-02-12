#!/bin/bash
# Build WalkMate.app bundle from SPM executable
set -euo pipefail

echo "Building WalkMate..."
swift build -c debug

APP_DIR=".build/WalkMate.app/Contents"
MACOS_DIR="$APP_DIR/MacOS"

# Create app bundle structure
rm -rf .build/WalkMate.app
mkdir -p "$MACOS_DIR"

# Copy executable
cp .build/arm64-apple-macosx/debug/WalkMate "$MACOS_DIR/WalkMate"

# Create Info.plist
cat > "$APP_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>WalkMate</string>
    <key>CFBundleIdentifier</key>
    <string>com.walkmate.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>WalkMate</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>WalkMate wymaga Bluetooth do połączenia z bieżnią i śledzenia treningów.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHealthShareUsageDescription</key>
    <string>WalkMate odczytuje dane zdrowotne do wyświetlania statystyk.</string>
    <key>NSHealthUpdateUsageDescription</key>
    <string>WalkMate zapisuje ukończone treningi na bieżni w Apple Zdrowie.</string>
</dict>
</plist>
PLIST

# Create temporary entitlements for code signing
ENTITLEMENTS_FILE=".build/WalkMate.entitlements"
cat > "$ENTITLEMENTS_FILE" << 'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
ENTITLEMENTS

# Code sign with WalkMate Dev certificate (self-signed, supports HealthKit entitlement)
# Falls back to ad-hoc if certificate not found
SIGN_IDENTITY=$(security find-identity -v -p codesigning | grep "WalkMate Dev" | head -1 | awk -F'"' '{print $2}')
if [ -n "$SIGN_IDENTITY" ]; then
    echo "Signing with: $SIGN_IDENTITY"
    codesign --force --sign "$SIGN_IDENTITY" --entitlements "$ENTITLEMENTS_FILE" .build/WalkMate.app
else
    echo "WalkMate Dev cert not found, using ad-hoc signing (HealthKit may not work)"
    codesign --force --sign - --entitlements "$ENTITLEMENTS_FILE" .build/WalkMate.app
fi
rm "$ENTITLEMENTS_FILE"

echo ""
echo "Build complete: .build/WalkMate.app"
echo "Run with: open .build/WalkMate.app"
