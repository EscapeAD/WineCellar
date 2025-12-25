import Foundation

/// Represents a Steam game detected in the Steam library
struct SteamGame: Identifiable, Codable, Hashable {
    let id: Int  // Steam App ID
    var name: String
    var installPath: String?
    var executable: String?
    var isInstalled: Bool
    var lastPlayed: Date?
    var playTime: TimeInterval  // In seconds
    
    init(
        id: Int,
        name: String,
        installPath: String? = nil,
        executable: String? = nil,
        isInstalled: Bool = false,
        lastPlayed: Date? = nil,
        playTime: TimeInterval = 0
    ) {
        self.id = id
        self.name = name
        self.installPath = installPath
        self.executable = executable
        self.isInstalled = isInstalled
        self.lastPlayed = lastPlayed
        self.playTime = playTime
    }
    
    /// Steam store URL for this game
    var storeURL: URL? {
        URL(string: "https://store.steampowered.com/app/\(id)")
    }
    
    /// ProtonDB compatibility URL
    var protonDBURL: URL? {
        URL(string: "https://www.protondb.com/app/\(id)")
    }
    
    /// Steam launch URL (opens Steam and launches game)
    var steamLaunchURL: URL? {
        URL(string: "steam://rungameid/\(id)")
    }
    
    /// Formatted play time
    var formattedPlayTime: String {
        let hours = Int(playTime / 3600)
        let minutes = Int((playTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
}

// MARK: - Steam Library
struct SteamLibrary: Codable {
    var games: [SteamGame]
    var steamPath: String?
    var lastUpdated: Date
    
    init(games: [SteamGame] = [], steamPath: String? = nil, lastUpdated: Date = Date()) {
        self.games = games
        self.steamPath = steamPath
        self.lastUpdated = lastUpdated
    }
    
    /// Get installed games
    var installedGames: [SteamGame] {
        games.filter { $0.isInstalled }
    }
    
    /// Get recently played games (last 30 days)
    var recentlyPlayedGames: [SteamGame] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return games.filter { game in
            guard let lastPlayed = game.lastPlayed else { return false }
            return lastPlayed > thirtyDaysAgo
        }.sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
    }
}

// MARK: - Steam App Manifest
/// Parsed from appmanifest_*.acf files
struct SteamAppManifest: Codable {
    let appId: Int
    let name: String
    let installDir: String
    let sizeOnDisk: Int64?
    let lastUpdated: Date?
    
    init(from vdfData: [String: Any]) {
        self.appId = Int(vdfData["appid"] as? String ?? "0") ?? 0
        self.name = vdfData["name"] as? String ?? "Unknown"
        self.installDir = vdfData["installdir"] as? String ?? ""
        
        if let sizeStr = vdfData["SizeOnDisk"] as? String {
            self.sizeOnDisk = Int64(sizeStr)
        } else {
            self.sizeOnDisk = nil
        }
        
        if let timestampStr = vdfData["LastUpdated"] as? String,
           let timestamp = TimeInterval(timestampStr) {
            self.lastUpdated = Date(timeIntervalSince1970: timestamp)
        } else {
            self.lastUpdated = nil
        }
    }
    
    /// Convert to SteamGame
    func toSteamGame() -> SteamGame {
        SteamGame(
            id: appId,
            name: name,
            installPath: installDir,
            isInstalled: true,
            lastPlayed: lastUpdated
        )
    }
}

// MARK: - Known Good Steam Games
/// Games known to work well with Wine
enum SteamGameCompatibility {
    case native      // Works natively on macOS
    case platinum    // Works flawlessly with Wine
    case gold        // Works with minor issues
    case silver      // Works with tweaks
    case bronze      // Runs but with issues
    case borked      // Doesn't work (e.g., anti-cheat)
    
    var displayName: String {
        switch self {
        case .native: return "Native"
        case .platinum: return "Platinum"
        case .gold: return "Gold"
        case .silver: return "Silver"
        case .bronze: return "Bronze"
        case .borked: return "Borked"
        }
    }
    
    var color: String {
        switch self {
        case .native: return "green"
        case .platinum: return "purple"
        case .gold: return "yellow"
        case .silver: return "gray"
        case .bronze: return "orange"
        case .borked: return "red"
        }
    }
}

