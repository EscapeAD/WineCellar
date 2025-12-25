import Foundation
import AppKit

/// Represents a Windows application installed in a Wine prefix
struct InstalledApp: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var executablePath: String  // Relative path from drive_c
    var workingDirectory: String?
    var arguments: [String]
    var environment: [String: String]
    var iconPath: String?  // Path to cached icon
    var installed: Date
    var lastLaunched: Date?
    var launchCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        executablePath: String,
        workingDirectory: String? = nil,
        arguments: [String] = [],
        environment: [String: String] = [:],
        iconPath: String? = nil,
        installed: Date = Date(),
        lastLaunched: Date? = nil,
        launchCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.executablePath = executablePath
        self.workingDirectory = workingDirectory
        self.arguments = arguments
        self.environment = environment
        self.iconPath = iconPath
        self.installed = installed
        self.lastLaunched = lastLaunched
        self.launchCount = launchCount
    }
    
    /// Get the Windows-style path (C:\...)
    var windowsPath: String {
        "C:\\" + executablePath.replacingOccurrences(of: "/", with: "\\")
    }
    
    /// Get the executable filename
    var fileName: String {
        URL(fileURLWithPath: executablePath).lastPathComponent
    }
    
    /// Check if this is Steam
    var isSteam: Bool {
        fileName.lowercased() == "steam.exe"
    }
    
    /// Create a mutated copy with updated launch info
    func withLaunchRecorded() -> InstalledApp {
        var copy = self
        copy.lastLaunched = Date()
        copy.launchCount += 1
        return copy
    }
}

// MARK: - App Category
enum AppCategory: String, Codable, CaseIterable {
    case game = "Games"
    case productivity = "Productivity"
    case utility = "Utilities"
    case other = "Other"
    
    var systemImage: String {
        switch self {
        case .game: return "gamecontroller.fill"
        case .productivity: return "doc.text.fill"
        case .utility: return "wrench.and.screwdriver.fill"
        case .other: return "app.fill"
        }
    }
}

// MARK: - Launch Configuration
struct LaunchConfiguration: Codable {
    var app: InstalledApp
    var prefixId: UUID
    var dxvkOverride: Bool?
    var customEnvironment: [String: String]
    var runInVirtualDesktop: Bool
    var virtualDesktopResolution: String?
    
    init(
        app: InstalledApp,
        prefixId: UUID,
        dxvkOverride: Bool? = nil,
        customEnvironment: [String: String] = [:],
        runInVirtualDesktop: Bool = false,
        virtualDesktopResolution: String? = nil
    ) {
        self.app = app
        self.prefixId = prefixId
        self.dxvkOverride = dxvkOverride
        self.customEnvironment = customEnvironment
        self.runInVirtualDesktop = runInVirtualDesktop
        self.virtualDesktopResolution = virtualDesktopResolution
    }
}


