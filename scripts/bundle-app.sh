#!/bin/bash
set -euo pipefail

BUNDLE_NAME="MacDirStat"
BUNDLE_ID="la.lex.macdirstat"
VERSION="${1:-1.0.0}"
BUILD_DIR=".build/release"
APP_DIR="${BUNDLE_NAME}.app"

echo "Building release..."
swift build --configuration release

echo "Creating app bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BUILD_DIR}/MacDirStat" "${APP_DIR}/Contents/MacOS/"

cat > "${APP_DIR}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${BUNDLE_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${BUNDLE_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>MacDirStat</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSystemAdministrationUsageDescription</key>
    <string>MacDirStat needs access to scan disk usage.</string>
    <key>NSDesktopFolderUsageDescription</key>
    <string>MacDirStat needs access to scan your Desktop folder.</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>MacDirStat needs access to scan your Documents folder.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>MacDirStat needs access to scan your Downloads folder.</string>
</dict>
</plist>
PLIST

echo "Created ${APP_DIR} (version ${VERSION})"
echo "To run: open ${APP_DIR}"
echo "To grant Full Disk Access: System Settings > Privacy & Security > Full Disk Access > add ${APP_DIR}"
