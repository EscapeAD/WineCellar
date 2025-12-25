import Foundation

/// Service for Steam installation and game management
@MainActor
final class SteamService: ObservableObject {
    private let wineService: WineService
    private let prefixService: PrefixService
    private let winetricksService: WinetricksService
    private let downloadService: DownloadService
    
    @Published private(set) var steamPrefix: WinePrefix?
    @Published private(set) var steamLibrary: SteamLibrary?
    @Published private(set) var isInstalling = false
    @Published private(set) var installProgress: String = ""
    
    init(
        wineService: WineService,
        prefixService: PrefixService,
        winetricksService: WinetricksService,
        downloadService: DownloadService
    ) {
        self.wineService = wineService
        self.prefixService = prefixService
        self.winetricksService = winetricksService
        self.downloadService = downloadService
    }
    
    // MARK: - Steam Detection
    
    /// Find existing Steam prefix
    func findSteamPrefix() async -> WinePrefix? {
        let prefixes = prefixService.prefixes
        
        // Look for prefix with Steam installed
        for prefix in prefixes {
            if await isSteamInstalled(in: prefix) {
                self.steamPrefix = prefix
                return prefix
            }
        }
        
        // Look for prefix named "Steam"
        if let foundPrefix = prefixes.first(where: { $0.name.lowercased() == "steam" }) {
            self.steamPrefix = foundPrefix
            return foundPrefix
        }
        
        return nil
    }
    
    /// Check if Steam is installed in a prefix
    func isSteamInstalled(in prefix: WinePrefix) async -> Bool {
        let steamExe = prefix.driveCPath
            .appendingPathComponent("Program Files (x86)")
            .appendingPathComponent("Steam")
            .appendingPathComponent("steam.exe")
        
        let altSteamExe = prefix.driveCPath
            .appendingPathComponent("Program Files")
            .appendingPathComponent("Steam")
            .appendingPathComponent("steam.exe")
        
        return FileManager.default.fileExists(atPath: steamExe.path) ||
               FileManager.default.fileExists(atPath: altSteamExe.path)
    }
    
    // MARK: - Steam Installation
    
    /// Create a Steam-optimized prefix and install Steam
    func installSteam(
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws -> WinePrefix {
        self.isInstalling = true
        self.installProgress = "Creating Steam prefix..."
        
        defer {
            self.isInstalling = false
        }
        
        let progressHandler: (String) -> Void = { [weak self] message in
            self?.installProgress = message
            onProgress?(message)
        }
        
        progressHandler("Creating Steam-optimized prefix...")
        
        // Create optimized prefix for Steam
        // Using win64 as Steam is dropping 32-bit support in 2026
        let prefix = try await prefixService.createPrefix(
            name: "Steam",
            architecture: .win64,
            windowsVersion: .win10,
            dxvkEnabled: true
        )
        
        progressHandler("Installing dependencies...")
        
        // Install Steam dependencies
        try await winetricksService.installSteamDependencies(
            in: prefix,
            onOutput: progressHandler
        )
        
        progressHandler("Downloading Steam installer...")
        
        // Download Steam installer
        let steamInstaller = try await downloadService.downloadToCache(
            from: DownloadService.steamInstallerURL,
            filename: "SteamSetup.exe"
        )
        
        progressHandler("Installing Steam...")
        
        // Run Steam installer (silent mode)
        _ = try await wineService.runExecutable(
            steamInstaller.path,
            arguments: ["/S"],  // Silent install
            in: prefix
        ) { output in
            progressHandler(output)
        }
        
        // Wait for installation to complete
        try await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds
        
        progressHandler("Configuring Steam...")
        
        // Add Steam to installed apps
        let steamApp = InstalledApp(
            name: "Steam",
            executablePath: "Program Files (x86)/Steam/steam.exe"
        )
        try await prefixService.addApp(steamApp, to: prefix)
        
        self.steamPrefix = prefix
        self.installProgress = "Steam installation complete!"
        
        Logger.shared.info("Steam installed successfully in prefix '\(prefix.name)'", category: .steam)
        
        return prefix
    }
    
    // MARK: - Steam Operations
    
    /// Launch Steam
    func launchSteam(in prefix: WinePrefix? = nil) async throws {
        let targetPrefix = try await resolveSteamPrefix(prefix)
        
        Logger.shared.info("Launching Steam", category: .steam)
        
        let steamPath = "C:\\Program Files (x86)\\Steam\\steam.exe"
        
        _ = try await wineService.runExecutable(
            steamPath,
            arguments: ["-no-cef-sandbox"],  // Helps with stability
            in: targetPrefix
        )
    }
    
    /// Launch Steam in Big Picture mode
    func launchSteamBigPicture(in prefix: WinePrefix? = nil) async throws {
        let targetPrefix = try await resolveSteamPrefix(prefix)
        
        let steamPath = "C:\\Program Files (x86)\\Steam\\steam.exe"
        
        _ = try await wineService.runExecutable(
            steamPath,
            arguments: ["-bigpicture", "-no-cef-sandbox"],
            in: targetPrefix
        )
    }
    
    /// Launch a Steam game by App ID
    func launchGame(appId: Int, in prefix: WinePrefix? = nil) async throws {
        let targetPrefix = try await resolveSteamPrefix(prefix)
        
        Logger.shared.info("Launching Steam game: \(appId)", category: .steam)
        
        let steamPath = "C:\\Program Files (x86)\\Steam\\steam.exe"
        
        _ = try await wineService.runExecutable(
            steamPath,
            arguments: ["-applaunch", String(appId), "-no-cef-sandbox"],
            in: targetPrefix
        )
    }
    
    /// Helper to resolve Steam prefix
    private func resolveSteamPrefix(_ provided: WinePrefix?) async throws -> WinePrefix {
        if let provided = provided {
            return provided
        }
        
        if let currentSteamPrefix = self.steamPrefix {
            return currentSteamPrefix
        }
        
        if let found = await findSteamPrefix() {
            return found
        }
        
        throw SteamError.notInstalled
    }
    
    // MARK: - Game Detection
    
    /// Scan Steam library for installed games
    func scanLibrary(in prefix: WinePrefix? = nil) async throws -> SteamLibrary {
        let steamPrefix = try await resolveSteamPrefix(prefix)
        
        Logger.shared.info("Scanning Steam library", category: .steam)
        
        var games: [SteamGame] = []
        
        // Find Steam installation
        let steamDir = steamPrefix.driveCPath
            .appendingPathComponent("Program Files (x86)")
            .appendingPathComponent("Steam")
        
        // Parse libraryfolders.vdf to find all library locations
        let libraryFolders = steamDir.appendingPathComponent("steamapps/libraryfolders.vdf")
        var libraryPaths = [steamDir.appendingPathComponent("steamapps")]
        
        if FileManager.default.fileExists(atPath: libraryFolders.path) {
            // TODO: Parse VDF to find additional library locations
        }
        
        // Scan for appmanifest files
        for libraryPath in libraryPaths {
            guard FileManager.default.fileExists(atPath: libraryPath.path) else { continue }
            
            let contents = try? FileManager.default.contentsOfDirectory(
                at: libraryPath,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            for file in contents ?? [] {
                guard file.lastPathComponent.hasPrefix("appmanifest_"),
                      file.pathExtension == "acf" else { continue }
                
                if let game = parseAppManifest(at: file) {
                    games.append(game)
                }
            }
        }
        
        let library = SteamLibrary(
            games: games,
            steamPath: steamDir.path,
            lastUpdated: Date()
        )
        
        self.steamLibrary = library
        
        Logger.shared.info("Found \(games.count) Steam games", category: .steam)
        
        return library
    }
    
    /// Parse a Steam appmanifest file
    private func parseAppManifest(at url: URL) -> SteamGame? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        
        var data = [String: String]()
        
        // Simple VDF parser for appmanifest files
        let pattern = #""(\w+)"\s+"([^"]+)""#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(content.startIndex..., in: content)
        
        regex?.enumerateMatches(in: content, range: range) { match, _, _ in
            guard let match = match,
                  let keyRange = Range(match.range(at: 1), in: content),
                  let valueRange = Range(match.range(at: 2), in: content) else {
                return
            }
            
            let key = String(content[keyRange])
            let value = String(content[valueRange])
            data[key] = value
        }
        
        guard let appIdStr = data["appid"],
              let appId = Int(appIdStr),
              let name = data["name"] else {
            return nil
        }
        
        return SteamGame(
            id: appId,
            name: name,
            installPath: data["installdir"],
            isInstalled: true
        )
    }
    
    // MARK: - Steam Configuration
    
    /// Get Steam settings from registry
    func getSteamSettings(in prefix: WinePrefix) async -> [String: String] {
        // TODO: Parse Wine registry for Steam settings
        return [:]
    }
    
    /// Kill Steam and all its processes
    func killSteam(in prefix: WinePrefix? = nil) async throws {
        guard let steamPrefix = prefix ?? self.steamPrefix else {
            return
        }
        
        try await wineService.killPrefix(steamPrefix)
        Logger.shared.info("Killed Steam processes", category: .steam)
    }
}

// MARK: - Steam Errors
enum SteamError: LocalizedError {
    case notInstalled
    case installationFailed(String)
    case launchFailed(String)
    case gameNotFound(Int)
    
    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Steam is not installed. Use the Steam Setup wizard to install it."
        case .installationFailed(let message):
            return "Steam installation failed: \(message)"
        case .launchFailed(let message):
            return "Failed to launch Steam: \(message)"
        case .gameNotFound(let appId):
            return "Game not found: \(appId)"
        }
    }
}

