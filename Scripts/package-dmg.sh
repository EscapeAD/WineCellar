#!/bin/bash
# package-dmg.sh - Create a distributable DMG for WineCellar
# Usage: ./package-dmg.sh [--notarize]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_NAME="WineCellar"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"

# Configuration
DEVELOPER_ID="${DEVELOPER_ID:-}"  # Set this or pass via environment
APPLE_ID="${APPLE_ID:-}"          # For notarization
TEAM_ID="${TEAM_ID:-}"            # For notarization

NOTARIZE=false
if [[ "$1" == "--notarize" ]]; then
    NOTARIZE=true
fi

echo "📦 WineCellar DMG Packager"
echo "==========================="
echo ""

# Create build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

cd "${PROJECT_DIR}"

# Build the app
echo "🔨 Building ${APP_NAME}..."

# Try Swift Package Manager build first
if [[ -f "Package.swift" ]]; then
    swift build -c release
    
    # For SPM, we need to create the app bundle manually
    APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
    mkdir -p "${APP_BUNDLE}/Contents/MacOS"
    mkdir -p "${APP_BUNDLE}/Contents/Resources"
    
    # Copy executable
    cp .build/release/${APP_NAME} "${APP_BUNDLE}/Contents/MacOS/"
    
    # Create Info.plist
    cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.winecellar.app</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Try Xcode project if it exists
elif [[ -d "${APP_NAME}.xcodeproj" ]]; then
    xcodebuild -project "${APP_NAME}.xcodeproj" \
        -scheme "${APP_NAME}" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        ONLY_ACTIVE_ARCH=NO \
        build
    
    APP_BUNDLE=$(find "${BUILD_DIR}/DerivedData" -name "*.app" -type d | head -1)
else
    echo "❌ No Package.swift or .xcodeproj found"
    exit 1
fi

echo "✅ Build complete"
echo ""

# Code sign if developer ID is provided
if [[ -n "${DEVELOPER_ID}" ]]; then
    echo "🔏 Code signing with: ${DEVELOPER_ID}"
    codesign --deep --force --options runtime \
        --sign "Developer ID Application: ${DEVELOPER_ID}" \
        "${APP_BUNDLE}"
    echo "✅ Code signing complete"
else
    echo "⚠️  Skipping code signing (no DEVELOPER_ID set)"
fi
echo ""

# Create DMG
echo "💿 Creating DMG..."

DMG_PATH="${BUILD_DIR}/${DMG_NAME}"

# Create temporary DMG directory
DMG_TEMP="${BUILD_DIR}/dmg_temp"
mkdir -p "${DMG_TEMP}"

# Copy app to temp directory
cp -R "${APP_BUNDLE}" "${DMG_TEMP}/"

# Create symlink to Applications
ln -s /Applications "${DMG_TEMP}/Applications"

# Create the DMG
hdiutil create -volname "${VOLUME_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov -format UDZO \
    "${DMG_PATH}"

# Clean up
rm -rf "${DMG_TEMP}"

echo "✅ DMG created: ${DMG_PATH}"
echo ""

# Notarize if requested
if [[ "${NOTARIZE}" == true ]]; then
    if [[ -z "${APPLE_ID}" || -z "${TEAM_ID}" ]]; then
        echo "❌ APPLE_ID and TEAM_ID required for notarization"
        exit 1
    fi
    
    echo "📤 Submitting for notarization..."
    
    xcrun notarytool submit "${DMG_PATH}" \
        --apple-id "${APPLE_ID}" \
        --team-id "${TEAM_ID}" \
        --wait
    
    echo "📎 Stapling notarization ticket..."
    xcrun stapler staple "${DMG_PATH}"
    
    echo "✅ Notarization complete"
fi

echo ""
echo "==========================="
echo "✅ Packaging complete!"
echo ""
echo "Output: ${DMG_PATH}"
echo "Size: $(du -h "${DMG_PATH}" | cut -f1)"

