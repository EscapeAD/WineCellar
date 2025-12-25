import Foundation

/// Represents an installed Wine version
struct WineVersion: Identifiable, Codable, Hashable {
    let id: String  // e.g., "wine-11.0"
    var version: String
    var path: URL
    var source: WineSource
    var isDefault: Bool
    
    init(
        id: String? = nil,
        version: String,
        path: URL,
        source: WineSource,
        isDefault: Bool = false
    ) {
        self.id = id ?? "wine-\(version)"
        self.version = version
        self.path = path
        self.source = source
        self.isDefault = isDefault
    }
    
    /// Path to wine64 binary
    var wine64Path: URL {
        path.appendingPathComponent("bin/wine64")
    }
    
    /// Path to wine binary (32-bit)
    var winePath: URL {
        path.appendingPathComponent("bin/wine")
    }
    
    /// Path to wineserver
    var wineserverPath: URL {
        path.appendingPathComponent("bin/wineserver")
    }
    
    /// Check if this Wine version exists and is valid
    var isValid: Bool {
        FileManager.default.isExecutableFile(atPath: wine64Path.path) ||
        FileManager.default.isExecutableFile(atPath: winePath.path)
    }
    
    /// Get the appropriate wine binary based on architecture
    func wineBinary(for arch: WineArch) -> URL {
        switch arch {
        case .win64: return wine64Path
        case .win32: return winePath
        }
    }
}

// MARK: - Wine Source
enum WineSource: String, Codable, CaseIterable {
    case gcenx      // Homebrew tap gcenx/wine (recommended)
    case wineHQ     // Official WineHQ builds
    case crossover  // CrossOver Wine (if detected)
    case custom     // User-provided binary
    
    var displayName: String {
        switch self {
        case .gcenx: return "Gcenx (Homebrew)"
        case .wineHQ: return "WineHQ Official"
        case .crossover: return "CrossOver"
        case .custom: return "Custom"
        }
    }
    
    var description: String {
        switch self {
        case .gcenx:
            return "Recommended. Install via: brew tap gcenx/wine && brew install --cask wine-stable"
        case .wineHQ:
            return "Official builds from WineHQ.org"
        case .crossover:
            return "Commercial Wine distribution from CodeWeavers"
        case .custom:
            return "User-provided Wine installation"
        }
    }
}

// MARK: - Wine Download Info
struct WineDownloadInfo: Identifiable {
    let id = UUID()
    let version: String
    let url: URL
    let source: WineSource
    let releaseDate: Date?
    let size: Int64?
    let changelog: String?
    
    var displayName: String {
        "Wine \(version)"
    }
}

