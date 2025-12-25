import Foundation
import SwiftUI

/// Manages application configuration and user preferences
@MainActor
final class ConfigurationStore: ObservableObject {
    static let shared = ConfigurationStore()
    
    // MARK: - Published Properties
    
    @Published var defaultWineVersion: String?
    @Published var defaultArchitecture: WineArch = .win64
    @Published var defaultWindowsVersion: WindowsVersion = .win10
    @Published var enableDXVKByDefault: Bool = true
    @Published var showAdvancedOptions: Bool = false
    @Published var theme: AppTheme = .system
    @Published var checkForUpdatesOnLaunch: Bool = true
    @Published var wineDebugLevel: WineDebugLevel = .none
    @Published var recentPrefixes: [UUID] = []
    @Published var favoriteApps: [UUID] = []
    
    // MARK: - Private Storage
    
    private let defaults = UserDefaults.standard
    private let configURL: URL
    
    private struct Keys {
        static let defaultWineVersion = "defaultWineVersion"
        static let defaultArchitecture = "defaultArchitecture"
        static let defaultWindowsVersion = "defaultWindowsVersion"
        static let enableDXVKByDefault = "enableDXVKByDefault"
        static let showAdvancedOptions = "showAdvancedOptions"
        static let theme = "theme"
        static let checkForUpdatesOnLaunch = "checkForUpdatesOnLaunch"
        static let wineDebugLevel = "wineDebugLevel"
        static let recentPrefixes = "recentPrefixes"
        static let favoriteApps = "favoriteApps"
    }
    
    // MARK: - Initialization
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        configURL = appSupport.appendingPathComponent("WineCellar").appendingPathComponent("config.json")
        
        load()
    }
    
    // MARK: - Load & Save
    
    private func load() {
        defaultWineVersion = defaults.string(forKey: Keys.defaultWineVersion)
        
        if let archRaw = defaults.string(forKey: Keys.defaultArchitecture),
           let arch = WineArch(rawValue: archRaw) {
            defaultArchitecture = arch
        }
        
        if let winVerRaw = defaults.string(forKey: Keys.defaultWindowsVersion),
           let winVer = WindowsVersion(rawValue: winVerRaw) {
            defaultWindowsVersion = winVer
        }
        
        enableDXVKByDefault = defaults.object(forKey: Keys.enableDXVKByDefault) as? Bool ?? true
        showAdvancedOptions = defaults.bool(forKey: Keys.showAdvancedOptions)
        
        if let themeRaw = defaults.string(forKey: Keys.theme),
           let loadedTheme = AppTheme(rawValue: themeRaw) {
            theme = loadedTheme
        }
        
        checkForUpdatesOnLaunch = defaults.object(forKey: Keys.checkForUpdatesOnLaunch) as? Bool ?? true
        
        if let debugRaw = defaults.string(forKey: Keys.wineDebugLevel),
           let debug = WineDebugLevel(rawValue: debugRaw) {
            wineDebugLevel = debug
        }
        
        if let recentData = defaults.data(forKey: Keys.recentPrefixes),
           let decoded = try? JSONDecoder().decode([UUID].self, from: recentData) {
            recentPrefixes = decoded
        }
        
        if let favData = defaults.data(forKey: Keys.favoriteApps),
           let decoded = try? JSONDecoder().decode([UUID].self, from: favData) {
            favoriteApps = decoded
        }
        
        Logger.shared.debug("Configuration loaded", category: .general)
    }
    
    func save() {
        defaults.set(defaultWineVersion, forKey: Keys.defaultWineVersion)
        defaults.set(defaultArchitecture.rawValue, forKey: Keys.defaultArchitecture)
        defaults.set(defaultWindowsVersion.rawValue, forKey: Keys.defaultWindowsVersion)
        defaults.set(enableDXVKByDefault, forKey: Keys.enableDXVKByDefault)
        defaults.set(showAdvancedOptions, forKey: Keys.showAdvancedOptions)
        defaults.set(theme.rawValue, forKey: Keys.theme)
        defaults.set(checkForUpdatesOnLaunch, forKey: Keys.checkForUpdatesOnLaunch)
        defaults.set(wineDebugLevel.rawValue, forKey: Keys.wineDebugLevel)
        
        if let recentData = try? JSONEncoder().encode(recentPrefixes) {
            defaults.set(recentData, forKey: Keys.recentPrefixes)
        }
        
        if let favData = try? JSONEncoder().encode(favoriteApps) {
            defaults.set(favData, forKey: Keys.favoriteApps)
        }
        
        Logger.shared.debug("Configuration saved", category: .general)
    }
    
    // MARK: - Recent Prefixes
    
    func addRecentPrefix(_ id: UUID) {
        recentPrefixes.removeAll { $0 == id }
        recentPrefixes.insert(id, at: 0)
        if recentPrefixes.count > 10 {
            recentPrefixes = Array(recentPrefixes.prefix(10))
        }
        save()
    }
    
    func removeRecentPrefix(_ id: UUID) {
        recentPrefixes.removeAll { $0 == id }
        save()
    }
    
    // MARK: - Favorite Apps
    
    func toggleFavorite(_ appId: UUID) {
        if favoriteApps.contains(appId) {
            favoriteApps.removeAll { $0 == appId }
        } else {
            favoriteApps.append(appId)
        }
        save()
    }
    
    func isFavorite(_ appId: UUID) -> Bool {
        favoriteApps.contains(appId)
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        defaultWineVersion = nil
        defaultArchitecture = .win64
        defaultWindowsVersion = .win10
        enableDXVKByDefault = true
        showAdvancedOptions = false
        theme = .system
        checkForUpdatesOnLaunch = true
        wineDebugLevel = .none
        recentPrefixes = []
        favoriteApps = []
        save()
        
        Logger.shared.info("Configuration reset to defaults", category: .general)
    }
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Wine Debug Level
enum WineDebugLevel: String, CaseIterable {
    case none = "-all"
    case errors = "err"
    case warnings = "warn"
    case traces = "trace"
    case all = "+all"
    
    var displayName: String {
        switch self {
        case .none: return "None (Recommended)"
        case .errors: return "Errors Only"
        case .warnings: return "Warnings"
        case .traces: return "Trace (Verbose)"
        case .all: return "All (Debug)"
        }
    }
}


