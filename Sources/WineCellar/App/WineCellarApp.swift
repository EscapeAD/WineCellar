import SwiftUI

/// WineCellar - A modern Wine manager for macOS
/// Fills the gap left by Whisky's discontinuation (April 2025) and PlayOnMac's abandonment (2020)
@main
struct WineCellarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dependencies = Dependencies.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(dependencies)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Prefix...") {
                    NotificationCenter.default.post(name: .createNewPrefix, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .appInfo) {
                Button("Check for Wine Updates...") {
                    NotificationCenter.default.post(name: .checkWineUpdates, object: nil)
                }
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(dependencies)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let createNewPrefix = Notification.Name("createNewPrefix")
    static let checkWineUpdates = Notification.Name("checkWineUpdates")
}

