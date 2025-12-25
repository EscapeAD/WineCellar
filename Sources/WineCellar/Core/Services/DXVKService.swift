import Foundation

/// Service for managing DXVK installations
/// DXVK translates DirectX 9/10/11 to Vulkan for better performance
actor DXVKService {
    private let processRunner: ProcessRunner
    private let downloadService: DownloadService
    private let fileSystemManager: FileSystemManager
    
    /// Current latest DXVK version
    static let latestVersion = "2.4"
    
    init(
        processRunner: ProcessRunner = .shared,
        downloadService: DownloadService = DownloadService(),
        fileSystemManager: FileSystemManager = .shared
    ) {
        self.processRunner = processRunner
        self.downloadService = downloadService
        self.fileSystemManager = fileSystemManager
    }
    
    // MARK: - DXVK Management
    
    /// Install DXVK into a Wine prefix
    func install(
        version: String = DXVKService.latestVersion,
        in prefix: WinePrefix,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws {
        Logger.shared.info("Installing DXVK \(version) in prefix '\(prefix.name)'", category: .wine)
        
        onProgress?("Downloading DXVK \(version)...")
        
        // Download DXVK
        let dxvkArchive = try await downloadDXVK(version: version)
        
        onProgress?("Extracting DXVK...")
        
        // Extract archive
        let extractDir = try await extractDXVK(archive: dxvkArchive, version: version)
        
        onProgress?("Installing DXVK DLLs...")
        
        // Install DLLs
        try await installDLLs(from: extractDir, to: prefix)
        
        // Set DLL overrides
        onProgress?("Configuring DLL overrides...")
        try await setDLLOverrides(in: prefix)
        
        Logger.shared.info("DXVK \(version) installed successfully", category: .wine)
    }
    
    /// Remove DXVK from a prefix
    func uninstall(from prefix: WinePrefix) async throws {
        Logger.shared.info("Removing DXVK from prefix '\(prefix.name)'", category: .wine)
        
        let dllNames = ["d3d9.dll", "d3d10core.dll", "d3d11.dll", "dxgi.dll"]
        
        for dll in dllNames {
            let system32Path = prefix.driveCPath
                .appendingPathComponent("windows/system32")
                .appendingPathComponent(dll)
            
            let syswow64Path = prefix.driveCPath
                .appendingPathComponent("windows/syswow64")
                .appendingPathComponent(dll)
            
            // Remove both 64-bit and 32-bit DLLs
            try? await fileSystemManager.delete(at: system32Path)
            try? await fileSystemManager.delete(at: syswow64Path)
        }
        
        Logger.shared.info("DXVK removed from prefix '\(prefix.name)'", category: .wine)
    }
    
    /// Check if DXVK is installed in a prefix
    func isInstalled(in prefix: WinePrefix) async -> Bool {
        let dxgiPath = prefix.driveCPath
            .appendingPathComponent("windows/system32/dxgi.dll")
        
        guard await fileSystemManager.exists(at: dxgiPath) else {
            return false
        }
        
        // Check if it's actually DXVK (by checking file size or version)
        // DXVK DLLs are typically larger than Wine's built-in ones
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: dxgiPath.path),
              let size = attrs[.size] as? Int64 else {
            return false
        }
        
        // DXVK dxgi.dll is typically > 200KB
        return size > 200_000
    }
    
    /// Get installed DXVK version (if detectable)
    func getInstalledVersion(in prefix: WinePrefix) async -> String? {
        // DXVK stores version info that can be read from the DLL
        // For now, return a generic indicator
        guard await isInstalled(in: prefix) else {
            return nil
        }
        return "Installed"
    }
    
    // MARK: - Private Helpers
    
    private func downloadDXVK(version: String) async throws -> URL {
        let cacheDir = await fileSystemManager.downloadsURL
        let archiveName = "dxvk-\(version).tar.gz"
        let destination = cacheDir.appendingPathComponent(archiveName)
        
        // Check if already cached
        if await fileSystemManager.exists(at: destination) {
            return destination
        }
        
        let url = DownloadService.dxvkURL(version: version)
        return try await downloadService.download(from: url, to: destination)
    }
    
    private func extractDXVK(archive: URL, version: String) async throws -> URL {
        let cacheDir = await fileSystemManager.cacheURL
        let extractDir = cacheDir.appendingPathComponent("dxvk-\(version)")
        
        // Check if already extracted
        if await fileSystemManager.isDirectory(at: extractDir) {
            return extractDir
        }
        
        // Extract using tar
        let result = try await processRunner.runShell(
            "tar -xzf '\(archive.path)' -C '\(cacheDir.path)'"
        )
        
        guard result.isSuccess else {
            throw DXVKError.extractionFailed(result.errorOutput)
        }
        
        return extractDir
    }
    
    private func installDLLs(from extractDir: URL, to prefix: WinePrefix) async throws {
        let system32 = prefix.driveCPath.appendingPathComponent("windows/system32")
        let syswow64 = prefix.driveCPath.appendingPathComponent("windows/syswow64")
        
        let x64Dir = extractDir.appendingPathComponent("x64")
        let x32Dir = extractDir.appendingPathComponent("x32")
        
        let dllNames = ["d3d9.dll", "d3d10core.dll", "d3d11.dll", "dxgi.dll"]
        
        // Install 64-bit DLLs
        if await fileSystemManager.isDirectory(at: x64Dir) {
            for dll in dllNames {
                let source = x64Dir.appendingPathComponent(dll)
                let dest = system32.appendingPathComponent(dll)
                
                if await fileSystemManager.exists(at: source) {
                    try? await fileSystemManager.delete(at: dest)
                    try await fileSystemManager.copyFile(from: source, to: dest)
                }
            }
        }
        
        // Install 32-bit DLLs (for wow64 support)
        let x32Exists = await fileSystemManager.isDirectory(at: x32Dir)
        let syswow64Exists = await fileSystemManager.isDirectory(at: syswow64)
        if x32Exists && syswow64Exists {
            for dll in dllNames {
                let source = x32Dir.appendingPathComponent(dll)
                let dest = syswow64.appendingPathComponent(dll)
                
                if await fileSystemManager.exists(at: source) {
                    try? await fileSystemManager.delete(at: dest)
                    try await fileSystemManager.copyFile(from: source, to: dest)
                }
            }
        }
    }
    
    private func setDLLOverrides(in prefix: WinePrefix) async throws {
        // Create registry file for DLL overrides
        let regContent = """
        Windows Registry Editor Version 5.00

        [HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
        "d3d9"="native,builtin"
        "d3d10core"="native,builtin"
        "d3d11"="native,builtin"
        "dxgi"="native,builtin"
        """
        
        let tempRegFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("dxvk-overrides-\(UUID().uuidString).reg")
        
        try regContent.write(to: tempRegFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempRegFile) }
        
        // Import registry file
        let env = [
            "WINEPREFIX": prefix.winePrefixPath.path,
            "WINEARCH": prefix.architecture.rawValue
        ]
        
        _ = try await processRunner.runShell(
            "wine regedit '\(tempRegFile.path)'",
            environment: env
        )
    }
}

// MARK: - DXVK Errors

enum DXVKError: LocalizedError {
    case downloadFailed(String)
    case extractionFailed(String)
    case installationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed(let message):
            return "Failed to download DXVK: \(message)"
        case .extractionFailed(let message):
            return "Failed to extract DXVK: \(message)"
        case .installationFailed(let message):
            return "Failed to install DXVK: \(message)"
        }
    }
}

// MARK: - DXVK Configuration

struct DXVKConfiguration {
    var hudEnabled: Bool = false
    var hudElements: [DXVKHudElement] = []
    var asyncShaderCompilation: Bool = true
    var logLevel: DXVKLogLevel = .none
    
    /// Generate DXVK environment variables
    var environmentVariables: [String: String] {
        var env = [String: String]()
        
        if hudEnabled {
            let elements = hudElements.isEmpty ? ["fps"] : hudElements.map { $0.rawValue }
            env["DXVK_HUD"] = elements.joined(separator: ",")
        }
        
        if asyncShaderCompilation {
            env["DXVK_ASYNC"] = "1"
        }
        
        env["DXVK_LOG_LEVEL"] = logLevel.rawValue
        
        return env
    }
}

enum DXVKHudElement: String, CaseIterable {
    case fps
    case frametimes
    case submissions
    case drawcalls
    case pipelines
    case memory
    case gpuload
    case version
    case devinfo
    
    var displayName: String {
        switch self {
        case .fps: return "FPS Counter"
        case .frametimes: return "Frame Times"
        case .submissions: return "Submissions"
        case .drawcalls: return "Draw Calls"
        case .pipelines: return "Pipelines"
        case .memory: return "Memory Usage"
        case .gpuload: return "GPU Load"
        case .version: return "Version"
        case .devinfo: return "Device Info"
        }
    }
}

enum DXVKLogLevel: String, CaseIterable {
    case none
    case error
    case warn
    case info
    case debug
    
    var displayName: String {
        rawValue.capitalized
    }
}

