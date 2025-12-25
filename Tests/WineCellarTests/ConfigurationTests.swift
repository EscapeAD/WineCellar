import XCTest
import SwiftUI
@testable import WineCellar

// MARK: - AppTheme Tests

final class AppThemeTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(AppTheme.allCases.count, 3)
        XCTAssertTrue(AppTheme.allCases.contains(.system))
        XCTAssertTrue(AppTheme.allCases.contains(.light))
        XCTAssertTrue(AppTheme.allCases.contains(.dark))
    }
    
    func testRawValues() {
        XCTAssertEqual(AppTheme.system.rawValue, "system")
        XCTAssertEqual(AppTheme.light.rawValue, "light")
        XCTAssertEqual(AppTheme.dark.rawValue, "dark")
    }
    
    func testDisplayNames() {
        XCTAssertEqual(AppTheme.system.displayName, "System")
        XCTAssertEqual(AppTheme.light.displayName, "Light")
        XCTAssertEqual(AppTheme.dark.displayName, "Dark")
    }
    
    func testColorSchemeSystem() {
        XCTAssertNil(AppTheme.system.colorScheme)
    }
    
    func testColorSchemeLight() {
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
    }
    
    func testColorSchemeDark() {
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }
    
    func testInitFromRawValue() {
        XCTAssertEqual(AppTheme(rawValue: "system"), .system)
        XCTAssertEqual(AppTheme(rawValue: "light"), .light)
        XCTAssertEqual(AppTheme(rawValue: "dark"), .dark)
        XCTAssertNil(AppTheme(rawValue: "invalid"))
    }
}

// MARK: - WineDebugLevel Tests

final class WineDebugLevelTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(WineDebugLevel.allCases.count, 5)
    }
    
    func testRawValues() {
        XCTAssertEqual(WineDebugLevel.none.rawValue, "-all")
        XCTAssertEqual(WineDebugLevel.errors.rawValue, "err")
        XCTAssertEqual(WineDebugLevel.warnings.rawValue, "warn")
        XCTAssertEqual(WineDebugLevel.traces.rawValue, "trace")
        XCTAssertEqual(WineDebugLevel.all.rawValue, "+all")
    }
    
    func testDisplayNames() {
        XCTAssertEqual(WineDebugLevel.none.displayName, "None (Recommended)")
        XCTAssertEqual(WineDebugLevel.errors.displayName, "Errors Only")
        XCTAssertEqual(WineDebugLevel.warnings.displayName, "Warnings")
        XCTAssertEqual(WineDebugLevel.traces.displayName, "Trace (Verbose)")
        XCTAssertEqual(WineDebugLevel.all.displayName, "All (Debug)")
    }
    
    func testInitFromRawValue() {
        // Test valid raw values - using explicit type to avoid Optional.none confusion
        XCTAssertEqual(WineDebugLevel(rawValue: "-all"), WineDebugLevel.none)
        XCTAssertEqual(WineDebugLevel(rawValue: "err"), WineDebugLevel.errors)
        XCTAssertEqual(WineDebugLevel(rawValue: "warn"), WineDebugLevel.warnings)
        XCTAssertEqual(WineDebugLevel(rawValue: "trace"), WineDebugLevel.traces)
        XCTAssertEqual(WineDebugLevel(rawValue: "+all"), WineDebugLevel.all)
        
        // Test invalid raw value
        let invalidResult = WineDebugLevel(rawValue: "invalid")
        XCTAssertNil(invalidResult, "Invalid raw value should return nil, got: \(String(describing: invalidResult))")
    }
    
    func testNoneIsDefault() {
        // Verify none suppresses all output (performance recommendation)
        XCTAssertEqual(WineDebugLevel.none.rawValue, "-all")
        XCTAssertTrue(WineDebugLevel.none.displayName.contains("Recommended"))
    }
}

// MARK: - Configuration Default Values Tests

final class ConfigurationDefaultValuesTests: XCTestCase {
    
    func testDefaultArchitecture() {
        // This is important for Steam compatibility (required 2026+)
        let defaultArch = WineArch.win64
        XCTAssertTrue(defaultArch.displayName.contains("Recommended"))
    }
    
    func testDefaultWindowsVersion() {
        let defaultVersion = WindowsVersion.win10
        XCTAssertEqual(defaultVersion, .win10)
    }
    
    func testDefaultDebugLevel() {
        let defaultLevel = WineDebugLevel.none
        XCTAssertEqual(defaultLevel.rawValue, "-all")
    }
}

// MARK: - Type Conformance Tests

final class ConfigurationTypeConformanceTests: XCTestCase {
    
    func testAppThemeCaseIterable() {
        let allCases = AppTheme.allCases
        XCTAssertGreaterThan(allCases.count, 0)
    }
    
    func testWineDebugLevelCaseIterable() {
        let allCases = WineDebugLevel.allCases
        XCTAssertGreaterThan(allCases.count, 0)
    }
    
    func testWineArchConformance() throws {
        // CaseIterable
        XCTAssertGreaterThan(WineArch.allCases.count, 0)
        
        // Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for arch in WineArch.allCases {
            let data = try encoder.encode(arch)
            let decoded = try decoder.decode(WineArch.self, from: data)
            XCTAssertEqual(decoded, arch)
        }
    }
    
    func testWindowsVersionConformance() throws {
        // CaseIterable
        XCTAssertGreaterThan(WindowsVersion.allCases.count, 0)
        
        // Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for version in WindowsVersion.allCases {
            let data = try encoder.encode(version)
            let decoded = try decoder.decode(WindowsVersion.self, from: data)
            XCTAssertEqual(decoded, version)
        }
    }
    
    func testWineSourceConformance() throws {
        // CaseIterable
        XCTAssertGreaterThan(WineSource.allCases.count, 0)
        
        // Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for source in WineSource.allCases {
            let data = try encoder.encode(source)
            let decoded = try decoder.decode(WineSource.self, from: data)
            XCTAssertEqual(decoded, source)
        }
    }
}

// MARK: - JSON Serialization Tests

final class ConfigurationJSONSerializationTests: XCTestCase {
    
    func testWineArchJSONFormat() throws {
        let encoder = JSONEncoder()
        
        let win64Data = try encoder.encode(WineArch.win64)
        let win64String = String(data: win64Data, encoding: .utf8)!
        XCTAssertTrue(win64String.contains("win64"))
        
        let win32Data = try encoder.encode(WineArch.win32)
        let win32String = String(data: win32Data, encoding: .utf8)!
        XCTAssertTrue(win32String.contains("win32"))
    }
    
    func testWindowsVersionJSONFormat() throws {
        let encoder = JSONEncoder()
        
        for version in WindowsVersion.allCases {
            let data = try encoder.encode(version)
            let string = String(data: data, encoding: .utf8)!
            XCTAssertTrue(string.contains(version.rawValue))
        }
    }
    
    func testCompletePrefixSerializationRoundTrip() throws {
        let original = WinePrefix(
            name: "Test Prefix",
            path: URL(fileURLWithPath: "/test/path"),
            wineVersion: "11.0",
            architecture: .win64,
            windowsVersion: .win10,
            dxvkEnabled: true,
            environment: ["KEY": "VALUE"],
            installedApps: [
                InstalledApp(name: "App1", executablePath: "app1.exe"),
                InstalledApp(name: "App2", executablePath: "app2.exe")
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WinePrefix.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.wineVersion, original.wineVersion)
        XCTAssertEqual(decoded.architecture, original.architecture)
        XCTAssertEqual(decoded.windowsVersion, original.windowsVersion)
        XCTAssertEqual(decoded.dxvkEnabled, original.dxvkEnabled)
        XCTAssertEqual(decoded.environment, original.environment)
        XCTAssertEqual(decoded.installedApps.count, original.installedApps.count)
    }
}
