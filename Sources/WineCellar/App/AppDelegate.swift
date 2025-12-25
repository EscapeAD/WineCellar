import SwiftUI
import AppKit

/// NSApplicationDelegate for handling app lifecycle events and system integration
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.shared.info("WineCellar launched", category: .app)
        
        // Ensure application support directories exist
        Task {
            do {
                try await FileSystemManager.shared.ensureAppDirectoriesExist()
                Logger.shared.info("Application directories verified", category: .app)
            } catch {
                Logger.shared.error("Failed to create app directories: \(error)", category: .app)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Logger.shared.info("WineCellar terminating", category: .app)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Keep running in background for menu bar access
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle .exe file drops or custom URL schemes
        for url in urls {
            if url.pathExtension.lowercased() == "exe" {
                Logger.shared.info("Received .exe file: \(url.path)", category: .app)
                NotificationCenter.default.post(
                    name: .installExecutable,
                    object: nil,
                    userInfo: ["url": url]
                )
            }
        }
    }
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let installExecutable = Notification.Name("installExecutable")
}

