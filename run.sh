#!/bin/bash
set -e

# Detect Xcode 14.3 developer directory
if [ -d "/Users/al14/Desktop/Xcode 2 copy.app" ]; then
    export DEVELOPER_DIR="/Users/al14/Desktop/Xcode 2 copy.app/Contents/Developer"
elif [ -d "/Applications/Xcode.app" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

echo "=================================================="
echo "  CareCircle - Xcode 14.3 Terminal Runner"
echo "=================================================="
echo "Using: $DEVELOPER_DIR"

cd "$(dirname "$0")"

echo "==> [1/4] Building CareCircle..."
xcodebuild -project CareCircle.xcodeproj \
           -scheme CareCircle \
           -destination "platform=iOS Simulator,name=iPhone 14 Pro" \
           build -quiet

echo "==> [2/4] Opening iPhone 14 Pro Simulator..."
xcrun simctl boot "iPhone 14 Pro" 2>/dev/null || true
open -a "$DEVELOPER_DIR/Applications/Simulator.app"

echo "==> [3/4] Installing App onto Simulator..."
APP_PATH=$(find /Users/al14/Library/Developer/Xcode/DerivedData/CareCircle* -name "CareCircle.app" ! -path "*Index.noindex*" -maxdepth 5 2>/dev/null | head -n 1)
xcrun simctl install booted "$APP_PATH"

echo "==> [4/4] Launching CareCircle..."
xcrun simctl launch booted com.carecircle.app

echo "=================================================="
echo "  Success! CareCircle is now running on Simulator"
echo "=================================================="
