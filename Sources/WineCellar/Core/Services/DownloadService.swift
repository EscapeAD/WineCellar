import Foundation

/// Download progress information
struct DownloadProgress: Sendable {
    let bytesDownloaded: Int64
    let totalBytes: Int64
    let progress: Double  // 0.0 to 1.0
    
    var formattedProgress: String {
        let downloaded = ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
        if totalBytes > 0 {
            let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            return "\(downloaded) / \(total)"
        }
        return downloaded
    }
    
    var percentageString: String {
        String(format: "%.1f%%", progress * 100)
    }
}

/// Service for downloading files with progress tracking
final class DownloadService: Sendable {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 3600  // 1 hour for large files
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Download a file to a destination
    func download(
        from url: URL,
        to destination: URL,
        progress: (@Sendable (DownloadProgress) -> Void)? = nil
    ) async throws -> URL {
        Logger.shared.info("Starting download: \(url.lastPathComponent)", category: .download)
        
        // Create request
        var request = URLRequest(url: url)
        request.setValue("WineCellar/1.0", forHTTPHeaderField: "User-Agent")
        
        // Download file
        let (tempURL, response) = try await session.download(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DownloadError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        // Ensure destination directory exists
        let destDir = destination.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: destDir.path) {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        }
        
        // Move to destination
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
        
        Logger.shared.info("Download completed: \(destination.lastPathComponent)", category: .download)
        
        return destination
    }
    
    /// Download to the cache directory
    func downloadToCache(from url: URL, filename: String? = nil) async throws -> URL {
        let cacheDir = FileSystemManager.shared.downloadsURL
        let fileName = filename ?? url.lastPathComponent
        let destination = cacheDir.appendingPathComponent(fileName)
        
        return try await download(from: url, to: destination)
    }
}

// MARK: - Download Errors
enum DownloadError: LocalizedError {
    case httpError(statusCode: Int)
    case noData
    case invalidURL
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .noData:
            return "No data received"
        case .invalidURL:
            return "Invalid URL"
        case .cancelled:
            return "Download cancelled"
        }
    }
}

// MARK: - Known Download URLs
extension DownloadService {
    /// Steam installer URL
    static let steamInstallerURL = URL(string: "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe")!
    
    /// Winetricks download URL
    static let winetricksURL = URL(string: "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks")!
    
    /// Get DXVK release URL for a version
    static func dxvkURL(version: String) -> URL {
        URL(string: "https://github.com/doitsujin/dxvk/releases/download/v\(version)/dxvk-\(version).tar.gz")!
    }
}
