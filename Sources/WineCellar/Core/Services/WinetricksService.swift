import Foundation

/// Known winetricks verbs (packages that can be installed)
enum WinetricksVerb: String, CaseIterable {
    // Fonts
    case corefonts
    case tahoma
    case arial
    case times
    case courier
    case lucida
    case allfonts
    
    // Visual C++ Runtimes
    case vcrun6
    case vcrun2005
    case vcrun2008
    case vcrun2010
    case vcrun2012
    case vcrun2013
    case vcrun2015
    case vcrun2017
    case vcrun2019
    case vcrun2022
    
    // .NET
    case dotnet20
    case dotnet40
    case dotnet45
    case dotnet48
    case dotnetdesktop6
    case dotnetdesktop7
    
    // DirectX
    case d3dx9
    case d3dx10
    case d3dx11_43
    case d3dcompiler_43
    case d3dcompiler_47
    case dxvk
    
    // Common dependencies
    case physx
    case xact
    case xact_x64
    case xinput
    case xlive
    case msxml3
    case msxml6
    case gdiplus
    case riched20
    case riched30
    case ie8
    case mfc42
    case quartz
    case wmp9
    case wmp11
    case flash
    case mono28
    
    var displayName: String {
        switch self {
        case .corefonts: return "Core Fonts"
        case .tahoma: return "Tahoma Font"
        case .arial: return "Arial Font"
        case .times: return "Times New Roman"
        case .courier: return "Courier Font"
        case .lucida: return "Lucida Font"
        case .allfonts: return "All Fonts"
        case .vcrun6: return "VC++ 6"
        case .vcrun2005: return "VC++ 2005"
        case .vcrun2008: return "VC++ 2008"
        case .vcrun2010: return "VC++ 2010"
        case .vcrun2012: return "VC++ 2012"
        case .vcrun2013: return "VC++ 2013"
        case .vcrun2015: return "VC++ 2015"
        case .vcrun2017: return "VC++ 2017"
        case .vcrun2019: return "VC++ 2019"
        case .vcrun2022: return "VC++ 2022"
        case .dotnet20: return ".NET 2.0"
        case .dotnet40: return ".NET 4.0"
        case .dotnet45: return ".NET 4.5"
        case .dotnet48: return ".NET 4.8"
        case .dotnetdesktop6: return ".NET Desktop 6"
        case .dotnetdesktop7: return ".NET Desktop 7"
        case .d3dx9: return "DirectX 9"
        case .d3dx10: return "DirectX 10"
        case .d3dx11_43: return "DirectX 11"
        case .d3dcompiler_43: return "D3D Compiler 43"
        case .d3dcompiler_47: return "D3D Compiler 47"
        case .dxvk: return "DXVK"
        case .physx: return "PhysX"
        case .xact: return "XACT"
        case .xact_x64: return "XACT x64"
        case .xinput: return "XInput"
        case .xlive: return "Games for Windows Live"
        case .msxml3: return "MSXML 3"
        case .msxml6: return "MSXML 6"
        case .gdiplus: return "GDI+"
        case .riched20: return "Rich Edit 2.0"
        case .riched30: return "Rich Edit 3.0"
        case .ie8: return "Internet Explorer 8"
        case .mfc42: return "MFC 4.2"
        case .quartz: return "Quartz (DirectShow)"
        case .wmp9: return "Windows Media Player 9"
        case .wmp11: return "Windows Media Player 11"
        case .flash: return "Flash Player"
        case .mono28: return "Mono 2.8"
        }
    }
    
    var category: WinetricksCategory {
        switch self {
        case .corefonts, .tahoma, .arial, .times, .courier, .lucida, .allfonts:
            return .fonts
        case .vcrun6, .vcrun2005, .vcrun2008, .vcrun2010, .vcrun2012, .vcrun2013, .vcrun2015, .vcrun2017, .vcrun2019, .vcrun2022:
            return .vcpp
        case .dotnet20, .dotnet40, .dotnet45, .dotnet48, .dotnetdesktop6, .dotnetdesktop7:
            return .dotnet
        case .d3dx9, .d3dx10, .d3dx11_43, .d3dcompiler_43, .d3dcompiler_47, .dxvk:
            return .directx
        default:
            return .other
        }
    }
}

enum WinetricksCategory: String, CaseIterable {
    case fonts = "Fonts"
    case vcpp = "Visual C++ Runtime"
    case dotnet = ".NET Framework"
    case directx = "DirectX"
    case other = "Other"
}

/// Service for managing winetricks
actor WinetricksService {
    private let processRunner: ProcessRunner
    private let downloadService: DownloadService
    
    private var winetricksPath: URL?
    
    init(processRunner: ProcessRunner, downloadService: DownloadService) {
        self.processRunner = processRunner
        self.downloadService = downloadService
    }
    
    // MARK: - Winetricks Management
    
    /// Ensure winetricks is available
    func ensureWinetricksAvailable() async throws -> URL {
        // Check if already cached
        if let path = winetricksPath, FileManager.default.isExecutableFile(atPath: path.path) {
            return path
        }
        
        // Check system winetricks
        if let systemPath = await processRunner.which("winetricks") {
            winetricksPath = systemPath
            Logger.shared.info("Using system winetricks at \(systemPath.path)", category: .wine)
            return systemPath
        }
        
        // Download winetricks
        let cacheDir = FileSystemManager.shared.winetricksURL
        let winetricksFile = cacheDir.appendingPathComponent("winetricks")
        
        if FileManager.default.isExecutableFile(atPath: winetricksFile.path) {
            winetricksPath = winetricksFile
            return winetricksFile
        }
        
        Logger.shared.info("Downloading winetricks...", category: .wine)
        
        let downloadedPath = try await downloadService.download(
            from: DownloadService.winetricksURL,
            to: winetricksFile
        )
        
        // Make executable
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: downloadedPath.path
        )
        
        winetricksPath = downloadedPath
        Logger.shared.info("Winetricks downloaded successfully", category: .wine)
        return downloadedPath
    }
    
    // MARK: - Installation
    
    /// Install winetricks verbs in a prefix
    func install(
        _ verbs: [String],
        in prefix: WinePrefix,
        wineVersion: WineVersion? = nil,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws {
        let winetricks = try await ensureWinetricksAvailable()
        
        Logger.shared.info(
            "Installing winetricks verbs: \(verbs.joined(separator: ", ")) in '\(prefix.name)'",
            category: .wine
        )
        
        // Build environment
        var env = [String: String]()
        env["WINEPREFIX"] = prefix.winePrefixPath.path
        env["WINEARCH"] = prefix.architecture.rawValue
        env["WINEDEBUG"] = "-all"
        
        // Set Wine binary path if specified
        if let wine = wineVersion {
            env["WINE"] = wine.wineBinary(for: prefix.architecture).path
            env["WINESERVER"] = wine.wineserverPath.path
        }
        
        // Run winetricks with each verb
        for verb in verbs {
            Logger.shared.info("Installing winetricks verb: \(verb)", category: .wine)
            
            let exitCode = try await processRunner.runWithStreaming(
                winetricks.path,
                arguments: ["-q", verb],
                environment: env,
                onOutput: onOutput ?? { _ in }
            )
            
            if exitCode != 0 {
                Logger.shared.warning("Winetricks verb '\(verb)' may have failed (exit code: \(exitCode))", category: .wine)
            }
        }
        
        Logger.shared.info("Winetricks installation completed", category: .wine)
    }
    
    /// Install from WinetricksVerb enum
    func install(
        _ verbs: [WinetricksVerb],
        in prefix: WinePrefix,
        wineVersion: WineVersion? = nil,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws {
        try await install(
            verbs.map { $0.rawValue },
            in: prefix,
            wineVersion: wineVersion,
            onOutput: onOutput
        )
    }
    
    // MARK: - Common Bundles
    
    /// Install common Steam dependencies
    func installSteamDependencies(
        in prefix: WinePrefix,
        wineVersion: WineVersion? = nil,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws {
        let verbs: [WinetricksVerb] = [
            .corefonts,
            .vcrun2022,
            .d3dcompiler_47
        ]
        
        try await install(verbs, in: prefix, wineVersion: wineVersion, onOutput: onOutput)
    }
    
    /// Install common game dependencies
    func installGameDependencies(
        in prefix: WinePrefix,
        wineVersion: WineVersion? = nil,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws {
        let verbs: [WinetricksVerb] = [
            .corefonts,
            .vcrun2022,
            .vcrun2019,
            .d3dx9,
            .d3dcompiler_47,
            .physx,
            .xact
        ]
        
        try await install(verbs, in: prefix, wineVersion: wineVersion, onOutput: onOutput)
    }
    
    /// Install .NET for applications
    func installDotNet(
        version: WinetricksVerb = .dotnet48,
        in prefix: WinePrefix,
        wineVersion: WineVersion? = nil,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws {
        try await install([version], in: prefix, wineVersion: wineVersion, onOutput: onOutput)
    }
    
    // MARK: - Query
    
    /// List available winetricks verbs (from winetricks itself)
    func listAvailableVerbs() async throws -> [String] {
        let winetricks = try await ensureWinetricksAvailable()
        
        let result = try await processRunner.run(
            winetricks.path,
            arguments: ["list-all"]
        )
        
        return result.output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }
}


