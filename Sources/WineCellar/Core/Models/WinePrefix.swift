import Foundation

/// Represents a Wine prefix - an isolated Windows environment
struct WinePrefix: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: URL
    var wineVersion: String
    var architecture: WineArch
    var windowsVersion: WindowsVersion
    var dxvkEnabled: Bool
    var environment: [String: String]
    var installedApps: [InstalledApp]
    var created: Date
    var lastUsed: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        wineVersion: String = "",
        architecture: WineArch = .win64,
        windowsVersion: WindowsVersion = .win10,
        dxvkEnabled: Bool = true,
        environment: [String: String] = [:],
        installedApps: [InstalledApp] = [],
        created: Date = Date(),
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.wineVersion = wineVersion
        self.architecture = architecture
        self.windowsVersion = windowsVersion
        self.dxvkEnabled = dxvkEnabled
        self.environment = environment
        self.installedApps = installedApps
        self.created = created
        self.lastUsed = lastUsed
    }
    
    /// Path to the actual Wine prefix directory (drive_c, etc.)
    var winePrefixPath: URL {
        path.appendingPathComponent("wine")
    }
    
    /// Path to the prefix metadata file
    var metadataPath: URL {
        path.appendingPathComponent("prefix.json")
    }
    
    /// Path to drive_c
    var driveCPath: URL {
        winePrefixPath.appendingPathComponent("drive_c")
    }
    
    /// Path to Program Files
    var programFilesPath: URL {
        if architecture == .win64 {
            return driveCPath.appendingPathComponent("Program Files")
        } else {
            return driveCPath.appendingPathComponent("Program Files (x86)")
        }
    }
    
    /// Check if prefix exists on disk
    var exists: Bool {
        FileManager.default.fileExists(atPath: winePrefixPath.path)
    }
    
    /// Get size of prefix on disk
    var diskSize: Int64? {
        try? FileManager.default.allocatedSizeOfDirectory(at: winePrefixPath)
    }
}

// MARK: - Wine Architecture
enum WineArch: String, Codable, CaseIterable {
    case win64  // Default for Steam (required 2026+)
    case win32  // Legacy 32-bit support
    
    var displayName: String {
        switch self {
        case .win64: return "64-bit (Recommended)"
        case .win32: return "32-bit (Legacy)"
        }
    }
    
    var wineBinary: String {
        switch self {
        case .win64: return "wine64"
        case .win32: return "wine"
        }
    }
}

// MARK: - Windows Version
enum WindowsVersion: String, Codable, CaseIterable {
    case win11 = "win11"
    case win10 = "win10"
    case win81 = "win81"
    case win8 = "win8"
    case win7 = "win7"
    case winxp = "winxp"
    
    var displayName: String {
        switch self {
        case .win11: return "Windows 11"
        case .win10: return "Windows 10"
        case .win81: return "Windows 8.1"
        case .win8: return "Windows 8"
        case .win7: return "Windows 7"
        case .winxp: return "Windows XP"
        }
    }
}

// MARK: - FileManager Extension
extension FileManager {
    func allocatedSizeOfDirectory(at url: URL) throws -> Int64 {
        var size: Int64 = 0
        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey]
        
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys)) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            if resourceValues.isDirectory == false {
                size += Int64(resourceValues.fileSize ?? 0)
            }
        }
        
        return size
    }
}

