import SwiftUI

/// Dependency injection container for all services
/// Following the service locator pattern for easy testing and configuration
@MainActor
final class Dependencies: ObservableObject {
    static let shared = Dependencies()
    
    // MARK: - Infrastructure
    let processRunner: ProcessRunner
    let fileSystemManager: FileSystemManager
    let configurationStore: ConfigurationStore
    let logger: Logger
    
    // MARK: - Services
    let wineService: WineService
    let prefixService: PrefixService
    let downloadService: DownloadService
    let winetricksService: WinetricksService
    let steamService: SteamService
    
    // MARK: - Published State
    @Published var isLoading = false
    @Published var currentError: AppError?
    
    private init() {
        // Infrastructure (singletons)
        self.processRunner = ProcessRunner.shared
        self.fileSystemManager = FileSystemManager.shared
        self.configurationStore = ConfigurationStore.shared
        self.logger = Logger.shared
        
        // Services
        self.downloadService = DownloadService()
        self.wineService = WineService(
            processRunner: processRunner,
            fileSystemManager: fileSystemManager
        )
        self.prefixService = PrefixService(
            wineService: wineService,
            fileSystemManager: fileSystemManager,
            configurationStore: configurationStore
        )
        self.winetricksService = WinetricksService(
            processRunner: processRunner,
            downloadService: downloadService
        )
        self.steamService = SteamService(
            wineService: wineService,
            prefixService: prefixService,
            winetricksService: winetricksService,
            downloadService: downloadService
        )
    }
    
    /// Show an error alert
    func showError(_ error: Error) {
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = .unknown(error.localizedDescription)
        }
    }
    
    /// Clear the current error
    func clearError() {
        currentError = nil
    }
}

// MARK: - App Errors
enum AppError: LocalizedError, Identifiable {
    case wineNotFound
    case prefixCreationFailed(String)
    case processExecutionFailed(String)
    case downloadFailed(String)
    case fileOperationFailed(String)
    case steamInstallationFailed(String)
    case unknown(String)
    
    var id: String { errorDescription ?? "unknown" }
    
    var errorDescription: String? {
        switch self {
        case .wineNotFound:
            return "Wine not found. Please install Wine via Homebrew or download it from the Wine Manager."
        case .prefixCreationFailed(let message):
            return "Failed to create Wine prefix: \(message)"
        case .processExecutionFailed(let message):
            return "Process execution failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .fileOperationFailed(let message):
            return "File operation failed: \(message)"
        case .steamInstallationFailed(let message):
            return "Steam installation failed: \(message)"
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
}

