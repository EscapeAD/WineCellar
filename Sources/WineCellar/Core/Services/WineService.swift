import Foundation

/// Service for managing Wine installations and executing Wine commands
@MainActor
final class WineService: ObservableObject {
    private let processRunner: ProcessRunner
    private let fileSystemManager: FileSystemManager
    
    @Published private(set) var installedVersions: [WineVersion] = []
    @Published private(set) var defaultVersion: WineVersion?
    
    init(processRunner: ProcessRunner, fileSystemManager: FileSystemManager) {
        self.processRunner = processRunner
        self.fileSystemManager = fileSystemManager
    }
    
    // MARK: - Wine Detection
    
    /// Scan for installed Wine versions
    func detectInstalledVersions() async -> [WineVersion] {
        var versions: [WineVersion] = []
        
        // Check Homebrew Caskroom (Gcenx)
        if let homebrewVersions = await detectHomebrewWine() {
            versions.append(contentsOf: homebrewVersions)
        }
        
        // Check common installation paths
        let commonPaths = [
            "/Applications/Wine Stable.app/Contents/Resources/wine",
            "/Applications/Wine Devel.app/Contents/Resources/wine",
            "/Applications/Wine Staging.app/Contents/Resources/wine",
            "/usr/local/opt/wine/bin",
            "/opt/homebrew/opt/wine/bin"
        ]
        
        for path in commonPaths {
            if let version = await detectWineAt(URL(fileURLWithPath: path)) {
                if !versions.contains(where: { $0.path == version.path }) {
                    versions.append(version)
                }
            }
        }
        
        // Check managed versions (downloaded by WineCellar)
        let managedVersions = await detectManagedVersions()
        versions.append(contentsOf: managedVersions)
        
        // Update published state
        self.installedVersions = versions
        self.defaultVersion = versions.first(where: { $0.isDefault }) ?? versions.first
        
        Logger.shared.info("Detected \(versions.count) Wine versions", category: .wine)
        return versions
    }
    
    /// Detect Wine from Homebrew
    private func detectHomebrewWine() async -> [WineVersion]? {
        guard let caskroom = fileSystemManager.findHomebrewCaskroom() else {
            return nil
        }
        
        var versions: [WineVersion] = []
        let winePackages = ["wine-stable", "wine-devel", "wine-staging", "gcenx-wine-stable"]
        
        for package in winePackages {
            let packagePath = caskroom.appendingPathComponent(package)
            guard await fileSystemManager.isDirectory(at: packagePath) else { continue }
            
            // Get the latest version directory
            guard let versionDirs = try? await fileSystemManager.listDirectory(at: packagePath) else { continue }
            
            for versionDir in versionDirs {
                let winePath = versionDir.appendingPathComponent("Wine Stable.app/Contents/Resources/wine")
                let altWinePath = versionDir.appendingPathComponent("Wine.app/Contents/Resources/wine")
                
                for path in [winePath, altWinePath] {
                    if let version = await detectWineAt(path) {
                        var v = version
                        v = WineVersion(
                            id: "\(package)-\(version.version)",
                            version: version.version,
                            path: path,
                            source: .gcenx,
                            isDefault: versions.isEmpty
                        )
                        versions.append(v)
                        break
                    }
                }
            }
        }
        
        return versions.isEmpty ? nil : versions
    }
    
    /// Detect Wine at a specific path
    private func detectWineAt(_ path: URL) async -> WineVersion? {
        let wine64Path = path.appendingPathComponent("bin/wine64")
        let winePath = path.appendingPathComponent("bin/wine")
        
        // Check if wine64 or wine exists
        let effectiveBinary = await fileSystemManager.exists(at: wine64Path) ? wine64Path : winePath
        guard await fileSystemManager.exists(at: effectiveBinary) else { return nil }
        
        // Get version
        let version = await getWineVersion(at: effectiveBinary)
        
        return WineVersion(
            version: version ?? "Unknown",
            path: path,
            source: .custom,
            isDefault: false
        )
    }
    
    /// Detect managed Wine versions (downloaded by WineCellar)
    private func detectManagedVersions() async -> [WineVersion] {
        var versions: [WineVersion] = []
        
        guard let dirs = try? await fileSystemManager.getAllWineVersionDirectories() else {
            return versions
        }
        
        for dir in dirs {
            if let version = await detectWineAt(dir) {
                var v = version
                v = WineVersion(
                    id: dir.lastPathComponent,
                    version: version.version,
                    path: dir,
                    source: .custom,
                    isDefault: false
                )
                versions.append(v)
            }
        }
        
        return versions
    }
    
    /// Get Wine version string
    private func getWineVersion(at binaryPath: URL) async -> String? {
        guard let result = try? await processRunner.run(
            binaryPath.path,
            arguments: ["--version"]
        ), result.isSuccess else {
            return nil
        }
        
        // Parse version from output like "wine-9.0" or "wine-11.0-rc3"
        let output = result.output
        if let match = output.range(of: #"wine-[\d\.]+([-\w]*)?"#, options: .regularExpression) {
            return String(output[match]).replacingOccurrences(of: "wine-", with: "")
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Wine Execution
    
    /// Run a Windows executable in a Wine prefix
    func runExecutable(
        _ executable: String,
        arguments: [String] = [],
        in prefix: WinePrefix,
        wineVersion: WineVersion? = nil,
        environment: [String: String] = [:],
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws -> Int32 {
        guard let wine = wineVersion ?? defaultVersion else {
            throw WineError.noWineInstalled
        }
        
        let wineBinary = wine.wineBinary(for: prefix.architecture)
        guard await fileSystemManager.exists(at: wineBinary) else {
            throw WineError.wineBinaryNotFound(wine.path.path)
        }
        
        // Build environment
        var env = buildEnvironment(for: prefix, wineVersion: wine)
        for (key, value) in environment {
            env[key] = value
        }
        
        Logger.shared.info(
            "Running: \(executable) in prefix '\(prefix.name)'",
            category: .wine
        )
        
        return try await processRunner.runWine(
            wineBinary: wineBinary,
            executable: executable,
            arguments: arguments,
            prefix: prefix.winePrefixPath,
            arch: prefix.architecture,
            environment: env,
            onOutput: onOutput
        )
    }
    
    /// Run wineboot to initialize or update a prefix
    func runWineboot(
        in prefix: WinePrefix,
        wineVersion: WineVersion? = nil,
        init initPrefix: Bool = false
    ) async throws {
        var args = [String]()
        if initPrefix {
            args.append("--init")
        } else {
            args.append("--update")
        }
        
        let exitCode = try await runExecutable(
            "wineboot",
            arguments: args,
            in: prefix,
            wineVersion: wineVersion
        )
        
        if exitCode != 0 {
            throw WineError.winebootFailed(exitCode)
        }
        
        Logger.shared.info("Wineboot completed for prefix '\(prefix.name)'", category: .wine)
    }
    
    /// Run winecfg to configure a prefix
    func runWinecfg(in prefix: WinePrefix, wineVersion: WineVersion? = nil) async throws {
        _ = try await runExecutable("winecfg", in: prefix, wineVersion: wineVersion)
    }
    
    /// Run regedit
    func runRegedit(in prefix: WinePrefix, regFile: URL? = nil) async throws {
        var args = [String]()
        if let regFile = regFile {
            args.append(regFile.path)
        }
        _ = try await runExecutable("regedit", arguments: args, in: prefix)
    }
    
    /// Kill all Wine processes in a prefix
    func killPrefix(_ prefix: WinePrefix, wineVersion: WineVersion? = nil) async throws {
        guard let wine = wineVersion ?? defaultVersion else {
            throw WineError.noWineInstalled
        }
        
        let wineserver = wine.wineserverPath
        var env = [String: String]()
        env["WINEPREFIX"] = prefix.winePrefixPath.path
        
        _ = try? await processRunner.run(
            wineserver.path,
            arguments: ["-k"],
            environment: env
        )
        
        Logger.shared.info("Killed Wine processes for prefix '\(prefix.name)'", category: .wine)
    }
    
    // MARK: - Environment Building
    
    /// Build the environment dictionary for Wine execution
    private func buildEnvironment(for prefix: WinePrefix, wineVersion: WineVersion) -> [String: String] {
        var env = [String: String]()
        
        // Core Wine environment
        env["WINEPREFIX"] = prefix.winePrefixPath.path
        env["WINEARCH"] = prefix.architecture.rawValue
        env["WINEDEBUG"] = ConfigurationStore.shared.wineDebugLevel.rawValue
        
        // Prevent Wine from showing crash dialogs
        env["WINEDLLOVERRIDES"] = "winemenubuilder.exe=d"
        
        // DXVK environment
        if prefix.dxvkEnabled {
            env["DXVK_LOG_LEVEL"] = "none"
        }
        
        // Add prefix-specific environment
        for (key, value) in prefix.environment {
            env[key] = value
        }
        
        return env
    }
    
    // MARK: - Windows Version Configuration
    
    /// Set the Windows version for a prefix using winecfg or registry
    func setWindowsVersion(_ version: WindowsVersion, in prefix: WinePrefix) async throws {
        // Create a .reg file to set the Windows version
        let regContent = """
        Windows Registry Editor Version 5.00

        [HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion]
        "CurrentVersion"="\(version.registryVersion)"
        "ProductName"="\(version.displayName)"

        [HKEY_CURRENT_USER\\Software\\Wine]
        "Version"="\(version.rawValue)"
        """
        
        let tempRegFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("winver-\(UUID().uuidString).reg")
        try regContent.write(to: tempRegFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempRegFile) }
        
        try await runRegedit(in: prefix, regFile: tempRegFile)
        
        Logger.shared.info(
            "Set Windows version to \(version.displayName) for prefix '\(prefix.name)'",
            category: .wine
        )
    }
}

// MARK: - Wine Errors
enum WineError: LocalizedError {
    case noWineInstalled
    case wineBinaryNotFound(String)
    case winebootFailed(Int32)
    case prefixNotFound(String)
    case executionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noWineInstalled:
            return "No Wine installation found. Please install Wine via Homebrew: brew tap gcenx/wine && brew install --cask wine-stable"
        case .wineBinaryNotFound(let path):
            return "Wine binary not found at: \(path)"
        case .winebootFailed(let code):
            return "Wineboot failed with exit code: \(code)"
        case .prefixNotFound(let name):
            return "Wine prefix not found: \(name)"
        case .executionFailed(let message):
            return "Wine execution failed: \(message)"
        }
    }
}

// MARK: - WindowsVersion Extensions
extension WindowsVersion {
    var registryVersion: String {
        switch self {
        case .win11: return "10.0"
        case .win10: return "10.0"
        case .win81: return "6.3"
        case .win8: return "6.2"
        case .win7: return "6.1"
        case .winxp: return "5.1"
        }
    }
}

