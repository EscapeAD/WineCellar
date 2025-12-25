import Foundation

/// Service for managing Wine prefixes
@MainActor
final class PrefixService: ObservableObject {
    private let wineService: WineService
    private let fileSystemManager: FileSystemManager
    private let configurationStore: ConfigurationStore
    
    @Published private(set) var prefixes: [WinePrefix] = []
    
    init(
        wineService: WineService,
        fileSystemManager: FileSystemManager,
        configurationStore: ConfigurationStore
    ) {
        self.wineService = wineService
        self.fileSystemManager = fileSystemManager
        self.configurationStore = configurationStore
    }
    
    // MARK: - CRUD Operations
    
    /// Load all prefixes from disk
    func loadPrefixes() async throws -> [WinePrefix] {
        var loadedPrefixes: [WinePrefix] = []
        
        let prefixDirs = try await fileSystemManager.getAllPrefixDirectories()
        
        for dir in prefixDirs {
            let metadataURL = dir.appendingPathComponent("prefix.json")
            
            if await fileSystemManager.exists(at: metadataURL) {
                do {
                    let prefix = try await fileSystemManager.readJSON(from: metadataURL, as: WinePrefix.self)
                    loadedPrefixes.append(prefix)
                } catch {
                    Logger.shared.warning("Failed to load prefix at \(dir.path): \(error)", category: .prefix)
                }
            } else {
                // Legacy prefix without metadata - try to create metadata
                if let prefix = await createMetadataForLegacyPrefix(at: dir) {
                    loadedPrefixes.append(prefix)
                }
            }
        }
        
        // Sort by last used (most recent first), then by name
        loadedPrefixes.sort { p1, p2 in
            if let d1 = p1.lastUsed, let d2 = p2.lastUsed {
                return d1 > d2
            } else if p1.lastUsed != nil {
                return true
            } else if p2.lastUsed != nil {
                return false
            }
            return p1.name < p2.name
        }
        
        self.prefixes = loadedPrefixes
        
        Logger.shared.info("Loaded \(loadedPrefixes.count) prefixes", category: .prefix)
        return loadedPrefixes
    }
    
    /// Create a new Wine prefix
    func createPrefix(
        name: String,
        architecture: WineArch = .win64,
        windowsVersion: WindowsVersion = .win10,
        dxvkEnabled: Bool = true,
        wineVersion: WineVersion? = nil
    ) async throws -> WinePrefix {
        let id = UUID()
        
        Logger.shared.info("Creating prefix '\(name)' with id \(id)", category: .prefix)
        
        // Create directory structure
        let prefixPath = try await fileSystemManager.createPrefixDirectory(id: id)
        
        // Create prefix object
        let prefix = WinePrefix(
            id: id,
            name: name,
            path: prefixPath,
            wineVersion: wineVersion?.version ?? wineService.defaultVersion?.version ?? "",
            architecture: architecture,
            windowsVersion: windowsVersion,
            dxvkEnabled: dxvkEnabled
        )
        
        // Initialize the Wine prefix with wineboot
        do {
            try await wineService.runWineboot(in: prefix, wineVersion: wineVersion, init: true)
        } catch {
            // Clean up on failure
            try? await fileSystemManager.delete(at: prefixPath)
            throw PrefixError.initializationFailed(error.localizedDescription)
        }
        
        // Set Windows version
        try await wineService.setWindowsVersion(windowsVersion, in: prefix)
        
        // Save metadata
        try await savePrefix(prefix)
        
        // Update prefixes list
        self.prefixes.insert(prefix, at: 0)
        
        Logger.shared.info("Created prefix '\(name)' successfully", category: .prefix)
        return prefix
    }
    
    /// Update a prefix's metadata
    func updatePrefix(_ prefix: WinePrefix) async throws {
        try await savePrefix(prefix)
        
        // Update in-memory list
        if let index = self.prefixes.firstIndex(where: { $0.id == prefix.id }) {
            self.prefixes[index] = prefix
        }
    }
    
    /// Delete a prefix
    func deletePrefix(_ prefix: WinePrefix) async throws {
        Logger.shared.info("Deleting prefix '\(prefix.name)'", category: .prefix)
        
        // Kill any running Wine processes
        try? await wineService.killPrefix(prefix)
        
        // Delete directory
        try await fileSystemManager.deletePrefixDirectory(id: prefix.id)
        
        // Remove from configuration
        self.configurationStore.removeRecentPrefix(prefix.id)
        self.prefixes.removeAll { $0.id == prefix.id }
        
        Logger.shared.info("Deleted prefix '\(prefix.name)'", category: .prefix)
    }
    
    /// Duplicate a prefix
    func duplicatePrefix(_ prefix: WinePrefix, newName: String) async throws -> WinePrefix {
        let newId = UUID()
        let newPath = fileSystemManager.prefixesURL.appendingPathComponent(newId.uuidString)
        
        Logger.shared.info("Duplicating prefix '\(prefix.name)' to '\(newName)'", category: .prefix)
        
        // Copy directory
        try await fileSystemManager.copyFile(from: prefix.path, to: newPath)
        
        // Create new prefix object
        let newPrefix = WinePrefix(
            id: newId,
            name: newName,
            path: newPath,
            wineVersion: prefix.wineVersion,
            architecture: prefix.architecture,
            windowsVersion: prefix.windowsVersion,
            dxvkEnabled: prefix.dxvkEnabled,
            environment: prefix.environment,
            installedApps: prefix.installedApps,
            created: Date()
        )
        
        // Save metadata
        try await savePrefix(newPrefix)
        
        // Update prefixes list
        self.prefixes.insert(newPrefix, at: 0)
        
        return newPrefix
    }
    
    // MARK: - Prefix Operations
    
    /// Get a prefix by ID
    func getPrefix(id: UUID) -> WinePrefix? {
        prefixes.first { $0.id == id }
    }
    
    /// Record that a prefix was used
    func recordPrefixUsage(_ prefix: WinePrefix) async throws {
        var updatedPrefix = prefix
        updatedPrefix.lastUsed = Date()
        try await updatePrefix(updatedPrefix)
        configurationStore.addRecentPrefix(prefix.id)
    }
    
    /// Open the prefix directory in Finder
    nonisolated func revealInFinder(_ prefix: WinePrefix) {
        Task { @MainActor in
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: prefix.path.path)
        }
    }
    
    /// Open drive_c in Finder
    nonisolated func openDriveC(_ prefix: WinePrefix) {
        Task { @MainActor in
            let driveCPath = prefix.driveCPath
            if FileManager.default.fileExists(atPath: driveCPath.path) {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: driveCPath.path)
            }
        }
    }
    
    // MARK: - App Management
    
    /// Add an installed app to a prefix
    func addApp(_ app: InstalledApp, to prefix: WinePrefix) async throws {
        var updatedPrefix = prefix
        updatedPrefix.installedApps.append(app)
        try await updatePrefix(updatedPrefix)
    }
    
    /// Remove an app from a prefix
    func removeApp(_ app: InstalledApp, from prefix: WinePrefix) async throws {
        var updatedPrefix = prefix
        updatedPrefix.installedApps.removeAll { $0.id == app.id }
        try await updatePrefix(updatedPrefix)
    }
    
    /// Update an app in a prefix
    func updateApp(_ app: InstalledApp, in prefix: WinePrefix) async throws {
        var updatedPrefix = prefix
        if let index = updatedPrefix.installedApps.firstIndex(where: { $0.id == app.id }) {
            updatedPrefix.installedApps[index] = app
        }
        try await updatePrefix(updatedPrefix)
    }
    
    /// Launch an app
    func launchApp(_ app: InstalledApp, in prefix: WinePrefix) async throws {
        Logger.shared.info("Launching app '\(app.name)' in prefix '\(prefix.name)'", category: .wine)
        
        // Update last launched
        let updatedApp = app.withLaunchRecorded()
        try await updateApp(updatedApp, in: prefix)
        try await recordPrefixUsage(prefix)
        
        // Build full executable path
        let exePath = prefix.driveCPath.appendingPathComponent(app.executablePath).path
        let windowsPath = app.windowsPath
        
        // Run the executable
        _ = try await wineService.runExecutable(
            windowsPath,
            arguments: app.arguments,
            in: prefix,
            environment: app.environment
        )
    }
    
    // MARK: - Private Helpers
    
    /// Save prefix metadata to disk
    private func savePrefix(_ prefix: WinePrefix) async throws {
        let metadataURL = prefix.metadataPath
        try await fileSystemManager.writeJSON(prefix, to: metadataURL)
    }
    
    /// Create metadata for a legacy prefix (without prefix.json)
    private func createMetadataForLegacyPrefix(at path: URL) async -> WinePrefix? {
        guard let idString = UUID(uuidString: path.lastPathComponent) ?? nil else {
            // Check if it's a named prefix (like "steam")
            let id = UUID()
            let name = path.lastPathComponent
            
            let prefix = WinePrefix(
                id: id,
                name: name.capitalized,
                path: path,
                architecture: .win64,
                windowsVersion: .win10,
                dxvkEnabled: true
            )
            
            try? await savePrefix(prefix)
            return prefix
        }
        
        let prefix = WinePrefix(
            id: idString,
            name: "Imported Prefix",
            path: path,
            architecture: .win64,
            windowsVersion: .win10,
            dxvkEnabled: true
        )
        
        try? await savePrefix(prefix)
        return prefix
    }
}

// MARK: - Prefix Errors
enum PrefixError: LocalizedError {
    case initializationFailed(String)
    case notFound(String)
    case saveFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Failed to initialize prefix: \(message)"
        case .notFound(let name):
            return "Prefix not found: \(name)"
        case .saveFailed(let message):
            return "Failed to save prefix: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete prefix: \(message)"
        }
    }
}

import AppKit

