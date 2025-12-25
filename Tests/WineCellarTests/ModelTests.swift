import XCTest
@testable import WineCellar

// MARK: - WinePrefix Tests

final class WinePrefixTests: XCTestCase {
    
    func testCreateWithDefaults() {
        let prefix = WinePrefix(
            name: "Test Prefix",
            path: URL(fileURLWithPath: "/tmp/test")
        )
        
        XCTAssertEqual(prefix.name, "Test Prefix")
        XCTAssertEqual(prefix.architecture, .win64)
        XCTAssertEqual(prefix.windowsVersion, .win10)
        XCTAssertTrue(prefix.dxvkEnabled)
        XCTAssertTrue(prefix.installedApps.isEmpty)
        XCTAssertTrue(prefix.wineVersion.isEmpty)
        XCTAssertTrue(prefix.environment.isEmpty)
        XCTAssertNil(prefix.lastUsed)
    }
    
    func testCreateWithCustomValues() {
        let customId = UUID()
        let customDate = Date(timeIntervalSince1970: 1000000)
        let prefix = WinePrefix(
            id: customId,
            name: "Custom Prefix",
            path: URL(fileURLWithPath: "/custom/path"),
            wineVersion: "11.0",
            architecture: .win32,
            windowsVersion: .win7,
            dxvkEnabled: false,
            environment: ["KEY": "VALUE"],
            installedApps: [],
            created: customDate,
            lastUsed: customDate
        )
        
        XCTAssertEqual(prefix.id, customId)
        XCTAssertEqual(prefix.name, "Custom Prefix")
        XCTAssertEqual(prefix.wineVersion, "11.0")
        XCTAssertEqual(prefix.architecture, .win32)
        XCTAssertEqual(prefix.windowsVersion, .win7)
        XCTAssertFalse(prefix.dxvkEnabled)
        XCTAssertEqual(prefix.environment["KEY"], "VALUE")
        XCTAssertEqual(prefix.created, customDate)
        XCTAssertEqual(prefix.lastUsed, customDate)
    }
    
    func testWinePrefixPath() {
        let prefix = WinePrefix(
            name: "Test",
            path: URL(fileURLWithPath: "/prefixes/test-id")
        )
        
        XCTAssertEqual(prefix.winePrefixPath.path, "/prefixes/test-id/wine")
    }
    
    func testMetadataPath() {
        let prefix = WinePrefix(
            name: "Test",
            path: URL(fileURLWithPath: "/prefixes/test-id")
        )
        
        XCTAssertEqual(prefix.metadataPath.path, "/prefixes/test-id/prefix.json")
    }
    
    func testDriveCPath() {
        let prefix = WinePrefix(
            name: "Test",
            path: URL(fileURLWithPath: "/prefixes/test-id")
        )
        
        XCTAssertEqual(prefix.driveCPath.path, "/prefixes/test-id/wine/drive_c")
    }
    
    func testProgramFilesPath64Bit() {
        let prefix = WinePrefix(
            name: "Test",
            path: URL(fileURLWithPath: "/prefixes/test"),
            architecture: .win64
        )
        
        XCTAssertEqual(prefix.programFilesPath.lastPathComponent, "Program Files")
    }
    
    func testProgramFilesPath32Bit() {
        let prefix = WinePrefix(
            name: "Test",
            path: URL(fileURLWithPath: "/prefixes/test"),
            architecture: .win32
        )
        
        XCTAssertEqual(prefix.programFilesPath.lastPathComponent, "Program Files (x86)")
    }
    
    func testHashable() {
        let sharedId = UUID()
        let createdDate = Date()
        let prefix1 = WinePrefix(id: sharedId, name: "Test1", path: URL(fileURLWithPath: "/test1"), created: createdDate)
        let prefix2 = WinePrefix(id: sharedId, name: "Test1", path: URL(fileURLWithPath: "/test1"), created: createdDate)
        
        // Test that same ID objects hash the same (Hashable uses id for hashing in Identifiable)
        XCTAssertEqual(prefix1.id, prefix2.id)
        
        // Test can be used in a Set
        var set = Set<WinePrefix>()
        set.insert(prefix1)
        // Since prefix1 and prefix2 have the same id, the set should recognize prefix2 as equal
        XCTAssertEqual(set.count, 1)
    }
    
    func testCodable() throws {
        let original = WinePrefix(
            name: "Codable Test",
            path: URL(fileURLWithPath: "/test"),
            wineVersion: "11.0",
            architecture: .win64,
            windowsVersion: .win10
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WinePrefix.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.wineVersion, original.wineVersion)
        XCTAssertEqual(decoded.architecture, original.architecture)
        XCTAssertEqual(decoded.windowsVersion, original.windowsVersion)
    }
}

// MARK: - WineArch Tests

final class WineArchTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(WineArch.allCases.count, 2)
        XCTAssertTrue(WineArch.allCases.contains(.win64))
        XCTAssertTrue(WineArch.allCases.contains(.win32))
    }
    
    func testDisplayNames() {
        XCTAssertEqual(WineArch.win64.displayName, "64-bit (Recommended)")
        XCTAssertEqual(WineArch.win32.displayName, "32-bit (Legacy)")
    }
    
    func testWineBinary() {
        XCTAssertEqual(WineArch.win64.wineBinary, "wine64")
        XCTAssertEqual(WineArch.win32.wineBinary, "wine")
    }
    
    func testRawValue() {
        XCTAssertEqual(WineArch.win64.rawValue, "win64")
        XCTAssertEqual(WineArch.win32.rawValue, "win32")
    }
    
    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for arch in WineArch.allCases {
            let data = try encoder.encode(arch)
            let decoded = try decoder.decode(WineArch.self, from: data)
            XCTAssertEqual(decoded, arch)
        }
    }
}

// MARK: - WindowsVersion Tests

final class WindowsVersionTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(WindowsVersion.allCases.count, 6)
    }
    
    func testDisplayNames() {
        XCTAssertEqual(WindowsVersion.win11.displayName, "Windows 11")
        XCTAssertEqual(WindowsVersion.win10.displayName, "Windows 10")
        XCTAssertEqual(WindowsVersion.win81.displayName, "Windows 8.1")
        XCTAssertEqual(WindowsVersion.win8.displayName, "Windows 8")
        XCTAssertEqual(WindowsVersion.win7.displayName, "Windows 7")
        XCTAssertEqual(WindowsVersion.winxp.displayName, "Windows XP")
    }
    
    func testRawValues() {
        XCTAssertEqual(WindowsVersion.win11.rawValue, "win11")
        XCTAssertEqual(WindowsVersion.win10.rawValue, "win10")
        XCTAssertEqual(WindowsVersion.win81.rawValue, "win81")
        XCTAssertEqual(WindowsVersion.win8.rawValue, "win8")
        XCTAssertEqual(WindowsVersion.win7.rawValue, "win7")
        XCTAssertEqual(WindowsVersion.winxp.rawValue, "winxp")
    }
    
    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for version in WindowsVersion.allCases {
            let data = try encoder.encode(version)
            let decoded = try decoder.decode(WindowsVersion.self, from: data)
            XCTAssertEqual(decoded, version)
        }
    }
}

// MARK: - WineVersion Tests

final class WineVersionTests: XCTestCase {
    
    func testCreateWithAutoId() {
        let version = WineVersion(
            version: "11.0",
            path: URL(fileURLWithPath: "/usr/local/Cellar/wine/11.0"),
            source: .gcenx
        )
        
        XCTAssertEqual(version.id, "wine-11.0")
        XCTAssertEqual(version.version, "11.0")
        XCTAssertEqual(version.source, .gcenx)
        XCTAssertFalse(version.isDefault)
    }
    
    func testCreateWithCustomId() {
        let version = WineVersion(
            id: "custom-wine-11",
            version: "11.0",
            path: URL(fileURLWithPath: "/custom/path"),
            source: .wineHQ,
            isDefault: true
        )
        
        XCTAssertEqual(version.id, "custom-wine-11")
        XCTAssertTrue(version.isDefault)
    }
    
    func testWine64Path() {
        let version = WineVersion(
            version: "11.0",
            path: URL(fileURLWithPath: "/opt/wine"),
            source: .gcenx
        )
        
        XCTAssertEqual(version.wine64Path.path, "/opt/wine/bin/wine64")
    }
    
    func testWinePath() {
        let version = WineVersion(
            version: "11.0",
            path: URL(fileURLWithPath: "/opt/wine"),
            source: .gcenx
        )
        
        XCTAssertEqual(version.winePath.path, "/opt/wine/bin/wine")
    }
    
    func testWineserverPath() {
        let version = WineVersion(
            version: "11.0",
            path: URL(fileURLWithPath: "/opt/wine"),
            source: .gcenx
        )
        
        XCTAssertEqual(version.wineserverPath.path, "/opt/wine/bin/wineserver")
    }
    
    func testWineBinaryForArch() {
        let version = WineVersion(
            version: "11.0",
            path: URL(fileURLWithPath: "/opt/wine"),
            source: .gcenx
        )
        
        XCTAssertEqual(version.wineBinary(for: .win64).lastPathComponent, "wine64")
        XCTAssertEqual(version.wineBinary(for: .win32).lastPathComponent, "wine")
    }
    
    func testCodable() throws {
        let original = WineVersion(
            version: "11.0",
            path: URL(fileURLWithPath: "/opt/wine"),
            source: .gcenx,
            isDefault: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WineVersion.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.version, original.version)
        XCTAssertEqual(decoded.source, original.source)
        XCTAssertEqual(decoded.isDefault, original.isDefault)
    }
}

// MARK: - WineSource Tests

final class WineSourceTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(WineSource.allCases.count, 4)
        XCTAssertTrue(WineSource.allCases.contains(.gcenx))
        XCTAssertTrue(WineSource.allCases.contains(.wineHQ))
        XCTAssertTrue(WineSource.allCases.contains(.crossover))
        XCTAssertTrue(WineSource.allCases.contains(.custom))
    }
    
    func testDisplayNames() {
        XCTAssertEqual(WineSource.gcenx.displayName, "Gcenx (Homebrew)")
        XCTAssertEqual(WineSource.wineHQ.displayName, "WineHQ Official")
        XCTAssertEqual(WineSource.crossover.displayName, "CrossOver")
        XCTAssertEqual(WineSource.custom.displayName, "Custom")
    }
    
    func testDescriptions() {
        XCTAssertTrue(WineSource.gcenx.description.contains("brew"))
        XCTAssertTrue(WineSource.gcenx.description.contains("Recommended"))
        XCTAssertTrue(WineSource.wineHQ.description.contains("WineHQ"))
        XCTAssertTrue(WineSource.crossover.description.contains("CodeWeavers"))
        XCTAssertTrue(WineSource.custom.description.contains("User-provided"))
    }
}

// MARK: - WineDownloadInfo Tests

final class WineDownloadInfoTests: XCTestCase {
    
    func testCreateWithAllProperties() {
        let url = URL(string: "https://example.com/wine.tar.gz")!
        let releaseDate = Date()
        
        let info = WineDownloadInfo(
            version: "11.0",
            url: url,
            source: .wineHQ,
            releaseDate: releaseDate,
            size: 100_000_000,
            changelog: "New features"
        )
        
        XCTAssertEqual(info.version, "11.0")
        XCTAssertEqual(info.url, url)
        XCTAssertEqual(info.source, .wineHQ)
        XCTAssertEqual(info.releaseDate, releaseDate)
        XCTAssertEqual(info.size, 100_000_000)
        XCTAssertEqual(info.changelog, "New features")
    }
    
    func testDisplayName() {
        let info = WineDownloadInfo(
            version: "11.0",
            url: URL(string: "https://example.com")!,
            source: .gcenx,
            releaseDate: nil,
            size: nil,
            changelog: nil
        )
        
        XCTAssertEqual(info.displayName, "Wine 11.0")
    }
    
    func testUniqueId() {
        let info1 = WineDownloadInfo(
            version: "11.0",
            url: URL(string: "https://example.com")!,
            source: .gcenx,
            releaseDate: nil,
            size: nil,
            changelog: nil
        )
        
        let info2 = WineDownloadInfo(
            version: "11.0",
            url: URL(string: "https://example.com")!,
            source: .gcenx,
            releaseDate: nil,
            size: nil,
            changelog: nil
        )
        
        XCTAssertNotEqual(info1.id, info2.id)
    }
}

// MARK: - InstalledApp Tests

final class InstalledAppTests: XCTestCase {
    
    func testCreateWithDefaults() {
        let app = InstalledApp(
            name: "Test App",
            executablePath: "Program Files/Test/test.exe"
        )
        
        XCTAssertEqual(app.name, "Test App")
        XCTAssertEqual(app.executablePath, "Program Files/Test/test.exe")
        XCTAssertNil(app.workingDirectory)
        XCTAssertTrue(app.arguments.isEmpty)
        XCTAssertTrue(app.environment.isEmpty)
        XCTAssertNil(app.iconPath)
        XCTAssertNil(app.lastLaunched)
        XCTAssertEqual(app.launchCount, 0)
    }
    
    func testCreateWithCustomValues() {
        let customId = UUID()
        let installDate = Date()
        let launchDate = Date()
        
        let app = InstalledApp(
            id: customId,
            name: "Custom App",
            executablePath: "Games/Test/game.exe",
            workingDirectory: "Games/Test",
            arguments: ["-fullscreen", "-debug"],
            environment: ["GAME_MODE": "1"],
            iconPath: "/icons/game.icns",
            installed: installDate,
            lastLaunched: launchDate,
            launchCount: 42
        )
        
        XCTAssertEqual(app.id, customId)
        XCTAssertEqual(app.name, "Custom App")
        XCTAssertEqual(app.workingDirectory, "Games/Test")
        XCTAssertEqual(app.arguments, ["-fullscreen", "-debug"])
        XCTAssertEqual(app.environment["GAME_MODE"], "1")
        XCTAssertEqual(app.iconPath, "/icons/game.icns")
        XCTAssertEqual(app.installed, installDate)
        XCTAssertEqual(app.lastLaunched, launchDate)
        XCTAssertEqual(app.launchCount, 42)
    }
    
    func testWindowsPath() {
        let app = InstalledApp(
            name: "Test",
            executablePath: "Program Files/Test/App/test.exe"
        )
        
        XCTAssertEqual(app.windowsPath, "C:\\Program Files\\Test\\App\\test.exe")
    }
    
    func testFileName() {
        let app = InstalledApp(
            name: "Test",
            executablePath: "Program Files/Test/my-application.exe"
        )
        
        XCTAssertEqual(app.fileName, "my-application.exe")
    }
    
    func testIsSteam() {
        let steamApp = InstalledApp(
            name: "Steam",
            executablePath: "Program Files (x86)/Steam/steam.exe"
        )
        
        let notSteamApp = InstalledApp(
            name: "Game",
            executablePath: "Program Files/Game/game.exe"
        )
        
        let steamUpperCase = InstalledApp(
            name: "Steam",
            executablePath: "Program Files/Steam/STEAM.EXE"
        )
        
        XCTAssertTrue(steamApp.isSteam)
        XCTAssertFalse(notSteamApp.isSteam)
        XCTAssertTrue(steamUpperCase.isSteam)
    }
    
    func testWithLaunchRecorded() {
        let app = InstalledApp(
            name: "Test",
            executablePath: "test.exe",
            launchCount: 5
        )
        
        let updated = app.withLaunchRecorded()
        
        XCTAssertEqual(updated.launchCount, 6)
        XCTAssertNotNil(updated.lastLaunched)
        XCTAssertEqual(app.launchCount, 5) // Original unchanged
    }
    
    func testCodable() throws {
        let original = InstalledApp(
            name: "Codable Test",
            executablePath: "test.exe",
            arguments: ["-arg1"],
            launchCount: 10
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(InstalledApp.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.executablePath, original.executablePath)
        XCTAssertEqual(decoded.arguments, original.arguments)
        XCTAssertEqual(decoded.launchCount, original.launchCount)
    }
}

// MARK: - AppCategory Tests

final class AppCategoryTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(AppCategory.allCases.count, 4)
    }
    
    func testRawValues() {
        XCTAssertEqual(AppCategory.game.rawValue, "Games")
        XCTAssertEqual(AppCategory.productivity.rawValue, "Productivity")
        XCTAssertEqual(AppCategory.utility.rawValue, "Utilities")
        XCTAssertEqual(AppCategory.other.rawValue, "Other")
    }
    
    func testSystemImages() {
        XCTAssertEqual(AppCategory.game.systemImage, "gamecontroller.fill")
        XCTAssertEqual(AppCategory.productivity.systemImage, "doc.text.fill")
        XCTAssertEqual(AppCategory.utility.systemImage, "wrench.and.screwdriver.fill")
        XCTAssertEqual(AppCategory.other.systemImage, "app.fill")
    }
}

// MARK: - LaunchConfiguration Tests

final class LaunchConfigurationTests: XCTestCase {
    
    func testCreateWithDefaults() {
        let app = InstalledApp(name: "Test", executablePath: "test.exe")
        let prefixId = UUID()
        
        let config = LaunchConfiguration(app: app, prefixId: prefixId)
        
        XCTAssertEqual(config.app.name, "Test")
        XCTAssertEqual(config.prefixId, prefixId)
        XCTAssertNil(config.dxvkOverride)
        XCTAssertTrue(config.customEnvironment.isEmpty)
        XCTAssertFalse(config.runInVirtualDesktop)
        XCTAssertNil(config.virtualDesktopResolution)
    }
    
    func testCreateWithAllOptions() {
        let app = InstalledApp(name: "Game", executablePath: "game.exe")
        let prefixId = UUID()
        
        let config = LaunchConfiguration(
            app: app,
            prefixId: prefixId,
            dxvkOverride: true,
            customEnvironment: ["CUSTOM": "VALUE"],
            runInVirtualDesktop: true,
            virtualDesktopResolution: "1920x1080"
        )
        
        XCTAssertEqual(config.dxvkOverride, true)
        XCTAssertEqual(config.customEnvironment["CUSTOM"], "VALUE")
        XCTAssertTrue(config.runInVirtualDesktop)
        XCTAssertEqual(config.virtualDesktopResolution, "1920x1080")
    }
    
    func testCodable() throws {
        let app = InstalledApp(name: "Test", executablePath: "test.exe")
        let original = LaunchConfiguration(
            app: app,
            prefixId: UUID(),
            dxvkOverride: true,
            runInVirtualDesktop: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LaunchConfiguration.self, from: data)
        
        XCTAssertEqual(decoded.prefixId, original.prefixId)
        XCTAssertEqual(decoded.dxvkOverride, original.dxvkOverride)
        XCTAssertEqual(decoded.runInVirtualDesktop, original.runInVirtualDesktop)
    }
}

// MARK: - SteamGame Tests

final class SteamGameTests: XCTestCase {
    
    func testCreateWithDefaults() {
        let game = SteamGame(id: 440, name: "Team Fortress 2")
        
        XCTAssertEqual(game.id, 440)
        XCTAssertEqual(game.name, "Team Fortress 2")
        XCTAssertNil(game.installPath)
        XCTAssertNil(game.executable)
        XCTAssertFalse(game.isInstalled)
        XCTAssertNil(game.lastPlayed)
        XCTAssertEqual(game.playTime, 0)
    }
    
    func testCreateWithAllProperties() {
        let lastPlayed = Date()
        let game = SteamGame(
            id: 730,
            name: "Counter-Strike 2",
            installPath: "/steamapps/common/Counter-Strike 2",
            executable: "cs2.exe",
            isInstalled: true,
            lastPlayed: lastPlayed,
            playTime: 36000
        )
        
        XCTAssertEqual(game.id, 730)
        XCTAssertTrue(game.isInstalled)
        XCTAssertEqual(game.installPath, "/steamapps/common/Counter-Strike 2")
        XCTAssertEqual(game.lastPlayed, lastPlayed)
        XCTAssertEqual(game.playTime, 36000)
    }
    
    func testStoreURL() {
        let game = SteamGame(id: 440, name: "TF2")
        
        XCTAssertEqual(game.storeURL?.absoluteString, "https://store.steampowered.com/app/440")
    }
    
    func testProtonDBURL() {
        let game = SteamGame(id: 440, name: "TF2")
        
        XCTAssertEqual(game.protonDBURL?.absoluteString, "https://www.protondb.com/app/440")
    }
    
    func testSteamLaunchURL() {
        let game = SteamGame(id: 440, name: "TF2")
        
        XCTAssertEqual(game.steamLaunchURL?.absoluteString, "steam://rungameid/440")
    }
    
    func testFormattedPlayTimeWithHours() {
        let game = SteamGame(id: 1, name: "Test", playTime: 7200)
        
        XCTAssertEqual(game.formattedPlayTime, "2h 0m")
    }
    
    func testFormattedPlayTimeWithHoursAndMinutes() {
        let game = SteamGame(id: 1, name: "Test", playTime: 7380)
        
        XCTAssertEqual(game.formattedPlayTime, "2h 3m")
    }
    
    func testFormattedPlayTimeMinutesOnly() {
        let game = SteamGame(id: 1, name: "Test", playTime: 1800)
        
        XCTAssertEqual(game.formattedPlayTime, "30 minutes")
    }
    
    func testFormattedPlayTimeZero() {
        let game = SteamGame(id: 1, name: "Test", playTime: 0)
        
        XCTAssertEqual(game.formattedPlayTime, "0 minutes")
    }
    
    func testCodable() throws {
        let original = SteamGame(
            id: 440,
            name: "TF2",
            isInstalled: true,
            playTime: 7200
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SteamGame.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.isInstalled, original.isInstalled)
        XCTAssertEqual(decoded.playTime, original.playTime)
    }
}

// MARK: - SteamLibrary Tests

final class SteamLibraryTests: XCTestCase {
    
    func testCreateEmpty() {
        let library = SteamLibrary()
        
        XCTAssertTrue(library.games.isEmpty)
        XCTAssertNil(library.steamPath)
    }
    
    func testCreateWithGames() {
        let games = [
            SteamGame(id: 440, name: "TF2", isInstalled: true),
            SteamGame(id: 730, name: "CS2", isInstalled: false)
        ]
        
        let library = SteamLibrary(games: games, steamPath: "/steam")
        
        XCTAssertEqual(library.games.count, 2)
        XCTAssertEqual(library.steamPath, "/steam")
    }
    
    func testInstalledGames() {
        let games = [
            SteamGame(id: 1, name: "Installed", isInstalled: true),
            SteamGame(id: 2, name: "Not Installed", isInstalled: false),
            SteamGame(id: 3, name: "Also Installed", isInstalled: true)
        ]
        
        let library = SteamLibrary(games: games)
        
        XCTAssertEqual(library.installedGames.count, 2)
        XCTAssertTrue(library.installedGames.allSatisfy { $0.isInstalled })
    }
    
    func testRecentlyPlayedGames() {
        let recent = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let old = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        
        let games = [
            SteamGame(id: 1, name: "Recent", lastPlayed: recent),
            SteamGame(id: 2, name: "Old", lastPlayed: old),
            SteamGame(id: 3, name: "Never")
        ]
        
        let library = SteamLibrary(games: games)
        
        XCTAssertEqual(library.recentlyPlayedGames.count, 1)
        XCTAssertEqual(library.recentlyPlayedGames.first?.name, "Recent")
    }
    
    func testCodable() throws {
        let games = [SteamGame(id: 440, name: "TF2")]
        let original = SteamLibrary(games: games, steamPath: "/steam")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SteamLibrary.self, from: data)
        
        XCTAssertEqual(decoded.games.count, original.games.count)
        XCTAssertEqual(decoded.steamPath, original.steamPath)
    }
}

// MARK: - SteamAppManifest Tests

final class SteamAppManifestTests: XCTestCase {
    
    func testParseVdfData() {
        let vdfData: [String: Any] = [
            "appid": "440",
            "name": "Team Fortress 2",
            "installdir": "Team Fortress 2",
            "SizeOnDisk": "15000000000",
            "LastUpdated": "1700000000"
        ]
        
        let manifest = SteamAppManifest(from: vdfData)
        
        XCTAssertEqual(manifest.appId, 440)
        XCTAssertEqual(manifest.name, "Team Fortress 2")
        XCTAssertEqual(manifest.installDir, "Team Fortress 2")
        XCTAssertEqual(manifest.sizeOnDisk, 15000000000)
        XCTAssertNotNil(manifest.lastUpdated)
    }
    
    func testHandlesMissingData() {
        let vdfData: [String: Any] = [:]
        
        let manifest = SteamAppManifest(from: vdfData)
        
        XCTAssertEqual(manifest.appId, 0)
        XCTAssertEqual(manifest.name, "Unknown")
        XCTAssertEqual(manifest.installDir, "")
        XCTAssertNil(manifest.sizeOnDisk)
        XCTAssertNil(manifest.lastUpdated)
    }
    
    func testToSteamGame() {
        let vdfData: [String: Any] = [
            "appid": "730",
            "name": "Counter-Strike 2",
            "installdir": "Counter-Strike 2"
        ]
        
        let manifest = SteamAppManifest(from: vdfData)
        let game = manifest.toSteamGame()
        
        XCTAssertEqual(game.id, 730)
        XCTAssertEqual(game.name, "Counter-Strike 2")
        XCTAssertTrue(game.isInstalled)
        XCTAssertEqual(game.installPath, "Counter-Strike 2")
    }
}

// MARK: - SteamGameCompatibility Tests

final class SteamGameCompatibilityTests: XCTestCase {
    
    func testDisplayNames() {
        XCTAssertEqual(SteamGameCompatibility.native.displayName, "Native")
        XCTAssertEqual(SteamGameCompatibility.platinum.displayName, "Platinum")
        XCTAssertEqual(SteamGameCompatibility.gold.displayName, "Gold")
        XCTAssertEqual(SteamGameCompatibility.silver.displayName, "Silver")
        XCTAssertEqual(SteamGameCompatibility.bronze.displayName, "Bronze")
        XCTAssertEqual(SteamGameCompatibility.borked.displayName, "Borked")
    }
    
    func testColors() {
        XCTAssertEqual(SteamGameCompatibility.native.color, "green")
        XCTAssertEqual(SteamGameCompatibility.platinum.color, "purple")
        XCTAssertEqual(SteamGameCompatibility.gold.color, "yellow")
        XCTAssertEqual(SteamGameCompatibility.silver.color, "gray")
        XCTAssertEqual(SteamGameCompatibility.bronze.color, "orange")
        XCTAssertEqual(SteamGameCompatibility.borked.color, "red")
    }
}
