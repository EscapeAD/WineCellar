import XCTest
@testable import WineCellar

// MARK: - DXVKConfiguration Tests

final class DXVKConfigurationTests: XCTestCase {
    
    func testDefaultConfiguration() {
        let config = DXVKConfiguration()
        
        XCTAssertFalse(config.hudEnabled)
        XCTAssertTrue(config.hudElements.isEmpty)
        XCTAssertTrue(config.asyncShaderCompilation)
        XCTAssertEqual(config.logLevel, .none)
    }
    
    func testEnvVarsHudDisabled() {
        let config = DXVKConfiguration()
        let env = config.environmentVariables
        
        XCTAssertNil(env["DXVK_HUD"])
        XCTAssertEqual(env["DXVK_ASYNC"], "1")
        XCTAssertEqual(env["DXVK_LOG_LEVEL"], "none")
    }
    
    func testEnvVarsHudEnabledDefault() {
        var config = DXVKConfiguration()
        config.hudEnabled = true
        
        let env = config.environmentVariables
        
        XCTAssertEqual(env["DXVK_HUD"], "fps")
    }
    
    func testEnvVarsHudEnabledCustom() {
        var config = DXVKConfiguration()
        config.hudEnabled = true
        config.hudElements = [.fps, .memory, .gpuload]
        
        let env = config.environmentVariables
        
        XCTAssertEqual(env["DXVK_HUD"], "fps,memory,gpuload")
    }
    
    func testEnvVarsAsyncDisabled() {
        var config = DXVKConfiguration()
        config.asyncShaderCompilation = false
        
        let env = config.environmentVariables
        
        XCTAssertNil(env["DXVK_ASYNC"])
    }
    
    func testEnvVarsLogLevels() {
        for logLevel in DXVKLogLevel.allCases {
            var config = DXVKConfiguration()
            config.logLevel = logLevel
            
            let env = config.environmentVariables
            
            XCTAssertEqual(env["DXVK_LOG_LEVEL"], logLevel.rawValue)
        }
    }
    
    func testAllHudElements() {
        var config = DXVKConfiguration()
        config.hudEnabled = true
        config.hudElements = DXVKHudElement.allCases
        
        let env = config.environmentVariables
        let hudValue = env["DXVK_HUD"]!
        
        for element in DXVKHudElement.allCases {
            XCTAssertTrue(hudValue.contains(element.rawValue))
        }
    }
}

// MARK: - DXVKHudElement Tests

final class DXVKHudElementTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(DXVKHudElement.allCases.count, 9)
    }
    
    func testRawValues() {
        XCTAssertEqual(DXVKHudElement.fps.rawValue, "fps")
        XCTAssertEqual(DXVKHudElement.frametimes.rawValue, "frametimes")
        XCTAssertEqual(DXVKHudElement.submissions.rawValue, "submissions")
        XCTAssertEqual(DXVKHudElement.drawcalls.rawValue, "drawcalls")
        XCTAssertEqual(DXVKHudElement.pipelines.rawValue, "pipelines")
        XCTAssertEqual(DXVKHudElement.memory.rawValue, "memory")
        XCTAssertEqual(DXVKHudElement.gpuload.rawValue, "gpuload")
        XCTAssertEqual(DXVKHudElement.version.rawValue, "version")
        XCTAssertEqual(DXVKHudElement.devinfo.rawValue, "devinfo")
    }
    
    func testDisplayNames() {
        XCTAssertEqual(DXVKHudElement.fps.displayName, "FPS Counter")
        XCTAssertEqual(DXVKHudElement.frametimes.displayName, "Frame Times")
        XCTAssertEqual(DXVKHudElement.submissions.displayName, "Submissions")
        XCTAssertEqual(DXVKHudElement.drawcalls.displayName, "Draw Calls")
        XCTAssertEqual(DXVKHudElement.pipelines.displayName, "Pipelines")
        XCTAssertEqual(DXVKHudElement.memory.displayName, "Memory Usage")
        XCTAssertEqual(DXVKHudElement.gpuload.displayName, "GPU Load")
        XCTAssertEqual(DXVKHudElement.version.displayName, "Version")
        XCTAssertEqual(DXVKHudElement.devinfo.displayName, "Device Info")
    }
}

// MARK: - DXVKLogLevel Tests

final class DXVKLogLevelTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(DXVKLogLevel.allCases.count, 5)
    }
    
    func testRawValues() {
        XCTAssertEqual(DXVKLogLevel.none.rawValue, "none")
        XCTAssertEqual(DXVKLogLevel.error.rawValue, "error")
        XCTAssertEqual(DXVKLogLevel.warn.rawValue, "warn")
        XCTAssertEqual(DXVKLogLevel.info.rawValue, "info")
        XCTAssertEqual(DXVKLogLevel.debug.rawValue, "debug")
    }
    
    func testDisplayNames() {
        for level in DXVKLogLevel.allCases {
            XCTAssertEqual(level.displayName, level.rawValue.capitalized)
        }
    }
}

// MARK: - DXVKService Static Tests

final class DXVKServiceStaticTests: XCTestCase {
    
    func testLatestVersion() {
        XCTAssertFalse(DXVKService.latestVersion.isEmpty)
        
        // Should be a valid version string (e.g., "2.4")
        let components = DXVKService.latestVersion.split(separator: ".")
        XCTAssertGreaterThanOrEqual(components.count, 1)
        XCTAssertNotNil(Int(components[0]))
    }
}
