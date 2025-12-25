import Foundation

/// Manages file system operations for WineCellar
actor FileSystemManager {
    static let shared = FileSystemManager()
    
    private let fileManager = FileManager.default
    
    // MARK: - Directory URLs (nonisolated since they're computed constants)
    
    /// Application Support directory
    nonisolated var appSupportURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("WineCellar")
    }
    
    /// Prefixes directory
    nonisolated var prefixesURL: URL {
        appSupportURL.appendingPathComponent("prefixes")
    }
    
    /// Wine installations directory
    nonisolated var wineURL: URL {
        appSupportURL.appendingPathComponent("wine")
    }
    
    /// Cache directory
    nonisolated var cacheURL: URL {
        appSupportURL.appendingPathComponent("cache")
    }
    
    /// Downloads cache
    nonisolated var downloadsURL: URL {
        cacheURL.appendingPathComponent("downloads")
    }
    
    /// Icons cache
    nonisolated var iconsURL: URL {
        cacheURL.appendingPathComponent("icons")
    }
    
    /// Winetricks cache
    nonisolated var winetricksURL: URL {
        appSupportURL.appendingPathComponent("winetricks")
    }
    
    /// Logs directory
    nonisolated var logsURL: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs")
            .appendingPathComponent("WineCellar")
    }
    
    /// Configuration file
    nonisolated var configURL: URL {
        appSupportURL.appendingPathComponent("config.json")
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    /// Ensure all application directories exist
    func ensureAppDirectoriesExist() throws {
        let directories = [
            appSupportURL,
            prefixesURL,
            wineURL,
            cacheURL,
            downloadsURL,
            iconsURL,
            winetricksURL,
            logsURL
        ]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                Logger.shared.debug("Created directory: \(directory.path)", category: .general)
            }
        }
    }
    
    // MARK: - Prefix Operations
    
    /// Create a new prefix directory structure
    func createPrefixDirectory(id: UUID) throws -> URL {
        let prefixDir = prefixesURL.appendingPathComponent(id.uuidString)
        try fileManager.createDirectory(at: prefixDir, withIntermediateDirectories: true)
        
        // Create wine subdirectory (actual WINEPREFIX)
        let wineDir = prefixDir.appendingPathComponent("wine")
        try fileManager.createDirectory(at: wineDir, withIntermediateDirectories: true)
        
        Logger.shared.info("Created prefix directory: \(prefixDir.path)", category: .prefix)
        return prefixDir
    }
    
    /// Delete a prefix directory
    func deletePrefixDirectory(id: UUID) throws {
        let prefixDir = prefixesURL.appendingPathComponent(id.uuidString)
        if fileManager.fileExists(atPath: prefixDir.path) {
            try fileManager.removeItem(at: prefixDir)
            Logger.shared.info("Deleted prefix directory: \(prefixDir.path)", category: .prefix)
        }
    }
    
    /// Get all prefix directories
    func getAllPrefixDirectories() throws -> [URL] {
        guard fileManager.fileExists(atPath: prefixesURL.path) else {
            return []
        }
        
        let contents = try fileManager.contentsOfDirectory(
            at: prefixesURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        )
        
        return contents.filter { url in
            var isDirectory: ObjCBool = false
            return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }
    
    // MARK: - Wine Version Operations
    
    /// Get all installed Wine version directories
    func getAllWineVersionDirectories() throws -> [URL] {
        guard fileManager.fileExists(atPath: wineURL.path) else {
            return []
        }
        
        let contents = try fileManager.contentsOfDirectory(
            at: wineURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        )
        
        return contents.filter { url in
            var isDirectory: ObjCBool = false
            return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }
    
    /// Create a directory for a Wine version
    func createWineVersionDirectory(name: String) throws -> URL {
        let versionDir = wineURL.appendingPathComponent(name)
        try fileManager.createDirectory(at: versionDir, withIntermediateDirectories: true)
        return versionDir
    }
    
    // MARK: - File Operations
    
    /// Read JSON file
    func readJSON<T: Decodable>(from url: URL, as type: T.Type) throws -> T {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Write JSON file
    func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }
    
    /// Copy file with progress
    func copyFile(from source: URL, to destination: URL, progress: (@Sendable (Double) -> Void)? = nil) async throws {
        // Get source file size
        let attributes = try fileManager.attributesOfItem(atPath: source.path)
        let totalSize = attributes[.size] as? Int64 ?? 0
        
        // Create parent directory if needed
        let parentDir = destination.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }
        
        // Remove existing file
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        
        // Copy with progress tracking
        let inputStream = InputStream(url: source)!
        let outputStream = OutputStream(url: destination, append: false)!
        
        inputStream.open()
        outputStream.open()
        defer {
            inputStream.close()
            outputStream.close()
        }
        
        let bufferSize = 1024 * 1024  // 1MB buffer
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var totalWritten: Int64 = 0
        
        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                outputStream.write(buffer, maxLength: bytesRead)
                totalWritten += Int64(bytesRead)
                
                if let progress = progress, totalSize > 0 {
                    progress(Double(totalWritten) / Double(totalSize))
                }
            } else if bytesRead < 0 {
                throw inputStream.streamError ?? NSError(domain: "FileSystemManager", code: -1)
            }
        }
        
        progress?(1.0)
    }
    
    /// Get size of directory
    func directorySize(at url: URL) throws -> Int64 {
        try fileManager.allocatedSizeOfDirectory(at: url)
    }
    
    /// Check if path exists
    func exists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
    
    /// Check if path is directory
    func isDirectory(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
    
    /// List directory contents
    func listDirectory(at url: URL) throws -> [URL] {
        try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    }
    
    /// Create directory
    func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    /// Delete item
    func delete(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    /// Move item
    func move(from source: URL, to destination: URL) throws {
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: source, to: destination)
    }
}

// MARK: - Homebrew Detection
extension FileSystemManager {
    /// Common Homebrew paths
    var homebrewPaths: [URL] {
        [
            URL(fileURLWithPath: "/usr/local"),           // Intel Mac
            URL(fileURLWithPath: "/opt/homebrew"),        // Apple Silicon
            URL(fileURLWithPath: "/home/linuxbrew/.linuxbrew")  // Linux
        ]
    }
    
    /// Find Homebrew prefix
    func findHomebrewPrefix() -> URL? {
        for path in homebrewPaths {
            let binPath = path.appendingPathComponent("bin/brew")
            if fileManager.isExecutableFile(atPath: binPath.path) {
                return path
            }
        }
        return nil
    }
    
    /// Find Homebrew Cask directory
    func findHomebrewCaskroom() -> URL? {
        guard let prefix = findHomebrewPrefix() else { return nil }
        let caskroom = prefix.appendingPathComponent("Caskroom")
        return fileManager.fileExists(atPath: caskroom.path) ? caskroom : nil
    }
}

