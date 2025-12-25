# WineCellar

A modern, native macOS application for managing Wine installations and running Windows applications, including Steam and Steam games.

**WineCellar fills the gap left by Whisky's discontinuation (April 2025) and PlayOnMac's abandonment (2020).**

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![Wine](https://img.shields.io/badge/Wine-11.0+-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 🍷 **Wine Version Management** - Detect, download, and manage multiple Wine versions
- 📁 **Prefix Management** - Create and configure isolated Wine environments
- 🎮 **Steam Integration** - One-click Steam installation with optimized settings
- 🖥️ **64-bit Support** - Ready for Steam's January 2026 64-bit requirement
- ⚡ **DXVK Support** - DirectX 9/10/11 to Vulkan translation for better gaming performance
- 🔧 **Winetricks Integration** - Install common Windows dependencies
- 🎨 **Native macOS UI** - Built with SwiftUI for a beautiful, native experience

## Requirements

- **macOS 13.0 (Ventura)** or later
- **Intel Mac** (Apple Silicon support planned)
- **Wine** installed via Homebrew (see below)

## Installation

### 1. Install Wine (Required)

```bash
# Add the Gcenx tap (recommended Wine builds for macOS)
brew tap gcenx/wine

# Install Wine Stable
brew install --cask wine-stable
```

### 2. Install WineCellar

Download the latest release from the [Releases](https://github.com/yourusername/WineCellar/releases) page, or build from source:

```bash
# Clone the repository
git clone https://github.com/yourusername/WineCellar.git
cd WineCellar

# Build with Swift Package Manager
swift build -c release

# Or open in Xcode
open WineCellar.xcodeproj
```

## Quick Start

### Running Steam

1. Open WineCellar
2. Go to **Steam** in the sidebar
3. Click **Install Steam**
4. Wait for the installation to complete
5. Click **Launch Steam** and log in

### Creating a Prefix

1. Click the **+** button or go to **File > New Prefix**
2. Enter a name for your prefix
3. Select architecture (64-bit recommended)
4. Choose Windows version (Windows 10 recommended)
5. Click **Create Prefix**

### Installing a Windows Application

1. Select a prefix from the sidebar
2. Click **Install App** or drag an `.exe` file onto the window
3. Follow the Windows installer
4. The app will appear in your library

## Project Structure

```
WineCellar/
├── Sources/WineCellar/
│   ├── App/                    # App entry point and dependencies
│   ├── Core/
│   │   ├── Models/             # Data models (WinePrefix, InstalledApp, etc.)
│   │   ├── Services/           # Business logic (WineService, SteamService, etc.)
│   │   └── Infrastructure/     # Low-level utilities (ProcessRunner, FileSystem, etc.)
│   ├── Features/
│   │   ├── Main/               # Main window and navigation
│   │   ├── Prefixes/           # Prefix management views
│   │   ├── Applications/       # App library views
│   │   ├── Wine/               # Wine version management
│   │   ├── Steam/              # Steam integration
│   │   └── Settings/           # App preferences
│   └── Resources/              # Assets and resources
├── Tests/                      # Unit tests
├── Scripts/                    # Build and distribution scripts
└── Package.swift               # Swift Package Manager manifest
```

## Configuration

WineCellar stores its data in:

| Location | Contents |
|----------|----------|
| `~/Library/Application Support/WineCellar/prefixes/` | Wine prefixes |
| `~/Library/Application Support/WineCellar/wine/` | Downloaded Wine versions |
| `~/Library/Application Support/WineCellar/cache/` | Download cache |
| `~/Library/Logs/WineCellar/` | Application logs |

## Troubleshooting

### Wine not detected

Make sure Wine is installed and accessible:

```bash
wine64 --version
```

If not found, install via Homebrew:

```bash
brew tap gcenx/wine
brew install --cask wine-stable
```

### Steam not launching

1. Kill any existing Wine processes: **Actions > Kill Wine Processes**
2. Try launching Steam again
3. Check the logs at `~/Library/Logs/WineCellar/`

### Game not working

1. Check [ProtonDB](https://www.protondb.com) for compatibility reports
2. Try installing additional dependencies via Winetricks
3. Games with anti-cheat (EAC, BattlEye) generally do not work with Wine

### Performance issues

1. Enable DXVK in prefix settings for DirectX games
2. Close unnecessary applications
3. Check that your Wine version is up to date

## Building from Source

### Requirements

- Xcode 15.0 or later
- Swift 5.9 or later
- macOS 13.0 SDK

### Build

```bash
# Using Swift Package Manager
swift build -c release

# Using Xcode
xcodebuild -scheme WineCellar -configuration Release build
```

### Create DMG

```bash
# Without notarization
./Scripts/package-dmg.sh

# With notarization (requires Apple Developer account)
DEVELOPER_ID="Your Name" APPLE_ID="email@example.com" TEAM_ID="XXXXXXXXXX" \
    ./Scripts/package-dmg.sh --notarize
```

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting a pull request.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the tests: `swift test`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Wine](https://www.winehq.org/) - The Wine compatibility layer
- [Gcenx](https://github.com/Gcenx/wine-on-mac) - macOS Wine builds
- [DXVK](https://github.com/doitsujin/dxvk) - DirectX to Vulkan translation
- [Winetricks](https://github.com/Winetricks/winetricks) - Windows dependency installer
- [Whisky](https://github.com/Whisky-App/Whisky) - Inspiration for modern macOS Wine management

## Related Projects

- [ProtonDB](https://www.protondb.com) - Game compatibility database
- [Lutris](https://lutris.net) - Linux game manager
- [Bottles](https://usebottles.com) - Linux Wine prefix manager

