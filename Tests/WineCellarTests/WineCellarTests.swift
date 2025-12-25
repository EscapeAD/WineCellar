import XCTest
@testable import WineCellar

final class WineCellarTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func testWinePrefixCreation() {
        let prefix = WinePrefix(
            name: "Test Prefix",
            path: URL(fileURLWithPath: "/tmp/test")
        )
        
        XCTAssertEqual(prefix.name, "Test Prefix")
        XCTAssertEqual(prefix.architecture, .win64)
        XCTAssertEqual(prefix.windowsVersion, .win10)
        XCTAssertTrue(prefix.dxvkEnabled)
    }
    
    func testWineArchDisplayName() {
        XCTAssertEqual(WineArch.win64.displayName, "64-bit (Recommended)")
        XCTAssertEqual(WineArch.win32.displayName, "32-bit (Legacy)")
    }
    
    func testWindowsVersionDisplayName() {
        XCTAssertEqual(WindowsVersion.win10.displayName, "Windows 10")
        XCTAssertEqual(WindowsVersion.win7.displayName, "Windows 7")
        XCTAssertEqual(WindowsVersion.winxp.displayName, "Windows XP")
    }
    
    func testInstalledAppCreation() {
        let app = InstalledApp(
            name: "Test App",
            executablePath: "Program Files/Test/test.exe"
        )
        
        XCTAssertEqual(app.name, "Test App")
        XCTAssertEqual(app.fileName, "test.exe")
        XCTAssertEqual(app.windowsPath, "C:\\Program Files\\Test\\test.exe")
        XCTAssertFalse(app.isSteam)
    }
    
    func testSteamAppDetection() {
        let steamApp = InstalledApp(
            name: "Steam",
            executablePath: "Program Files (x86)/Steam/steam.exe"
        )
        
        XCTAssertTrue(steamApp.isSteam)
    }
    
    func testSteamGameCreation() {
        let game = SteamGame(
            id: 440,
            name: "Team Fortress 2",
            isInstalled: true,
            playTime: 7200
        )
        
        XCTAssertEqual(game.id, 440)
        XCTAssertEqual(game.formattedPlayTime, "2h 0m")
        XCTAssertNotNil(game.storeURL)
        XCTAssertNotNil(game.protonDBURL)
    }
    
    // MARK: - Configuration Tests
    
    func testWineDebugLevelRawValues() {
        XCTAssertEqual(WineDebugLevel.none.rawValue, "-all")
        XCTAssertEqual(WineDebugLevel.errors.rawValue, "err")
        XCTAssertEqual(WineDebugLevel.all.rawValue, "+all")
    }
    
    func testAppThemeColorScheme() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }
    
    // MARK: - Winetricks Tests
    
    func testWinetricksVerbCategories() {
        XCTAssertEqual(WinetricksVerb.corefonts.category, .fonts)
        XCTAssertEqual(WinetricksVerb.vcrun2022.category, .vcpp)
        XCTAssertEqual(WinetricksVerb.dotnet48.category, .dotnet)
        XCTAssertEqual(WinetricksVerb.d3dx9.category, .directx)
    }
    
    // MARK: - DXVK Tests
    
    func testDXVKConfiguration() {
        var config = DXVKConfiguration()
        config.hudEnabled = true
        config.hudElements = [.fps, .memory]
        
        let env = config.environmentVariables
        
        XCTAssertEqual(env["DXVK_HUD"], "fps,memory")
        XCTAssertEqual(env["DXVK_LOG_LEVEL"], "none")
    }
    
    // MARK: - Download Tests
    
    func testDownloadProgressFormatting() {
        let progress = DownloadProgress(
            bytesDownloaded: 1024 * 1024,  // 1 MB
            totalBytes: 10 * 1024 * 1024,  // 10 MB
            progress: 0.1
        )
        
        XCTAssertEqual(progress.percentageString, "10.0%")
        XCTAssertTrue(progress.formattedProgress.contains("MB"))
    }
    
    // MARK: - Wine Version Tests
    
    func testWineVersionBinaryPath() {
        let version = WineVersion(
            version: "11.0",
            path: URL(fileURLWithPath: "/usr/local/Cellar/wine/11.0"),
            source: .gcenx
        )
        
        XCTAssertEqual(
            version.wine64Path.path,
            "/usr/local/Cellar/wine/11.0/bin/wine64"
        )
        XCTAssertEqual(
            version.wineserverPath.path,
            "/usr/local/Cellar/wine/11.0/bin/wineserver"
        )
    }
    
    func testWineSourceDescription() {
        XCTAssertTrue(WineSource.gcenx.description.contains("Homebrew"))
        XCTAssertTrue(WineSource.wineHQ.description.contains("WineHQ"))
    }
}

// MARK: - ProcessResult Tests

final class ProcessResultTests: XCTestCase {
    
    func testSuccessfulResult() {
        let result = ProcessResult(
            exitCode: 0,
            output: "Success",
            errorOutput: "",
            duration: 1.0
        )
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.combinedOutput, "Success")
    }
    
    func testFailedResult() {
        let result = ProcessResult(
            exitCode: 1,
            output: "",
            errorOutput: "Error message",
            duration: 0.5
        )
        
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.combinedOutput, "Error message")
    }
    
    func testCombinedOutput() {
        let result = ProcessResult(
            exitCode: 0,
            output: "stdout",
            errorOutput: "stderr",
            duration: 0.1
        )
        
        XCTAssertEqual(result.combinedOutput, "stdout\nstderr")
    }
}


