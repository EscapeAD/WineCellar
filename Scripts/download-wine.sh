#!/bin/bash
# download-wine.sh - Helper script to download Wine binaries
# Usage: ./download-wine.sh [version]

set -e

WINE_VERSION="${1:-stable}"
DOWNLOAD_DIR="${HOME}/Library/Application Support/WineCellar/wine"

echo "🍷 WineCellar Wine Downloader"
echo "================================"
echo ""

# Create download directory
mkdir -p "${DOWNLOAD_DIR}"

# Check if Homebrew is installed
if command -v brew &> /dev/null; then
    echo "✅ Homebrew detected"
    
    # Check if gcenx tap is added
    if ! brew tap | grep -q "gcenx/wine"; then
        echo "📦 Adding gcenx/wine tap..."
        brew tap gcenx/wine
    fi
    
    # Install Wine based on version
    case "${WINE_VERSION}" in
        stable)
            echo "📥 Installing wine-stable..."
            brew install --cask wine-stable
            ;;
        devel)
            echo "📥 Installing wine-devel..."
            brew install --cask wine-devel
            ;;
        staging)
            echo "📥 Installing wine-staging..."
            brew install --cask wine-staging
            ;;
        *)
            echo "❌ Unknown version: ${WINE_VERSION}"
            echo "   Available versions: stable, devel, staging"
            exit 1
            ;;
    esac
    
    echo ""
    echo "✅ Wine installed successfully!"
    echo ""
    echo "Installed location:"
    echo "  /Applications/Wine Stable.app (or similar)"
    echo ""
    echo "To verify, run:"
    echo "  wine64 --version"
    
else
    echo "❌ Homebrew not found"
    echo ""
    echo "Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    echo "Or download Wine manually from:"
    echo "  https://github.com/Gcenx/wine-on-mac/releases"
    exit 1
fi


