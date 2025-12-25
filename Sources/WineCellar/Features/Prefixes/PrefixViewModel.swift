import SwiftUI

/// ViewModel for prefix management
@MainActor
final class PrefixViewModel: ObservableObject {
    @Published var prefixes: [WinePrefix] = []
    @Published var selectedPrefix: WinePrefix?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var sortOrder: PrefixSortOrder = .lastUsed
    
    private let dependencies: Dependencies
    
    var filteredPrefixes: [WinePrefix] {
        var result = prefixes
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter { prefix in
                prefix.name.localizedCaseInsensitiveContains(searchText) ||
                prefix.installedApps.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply sort
        switch sortOrder {
        case .name:
            result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .lastUsed:
            result.sort { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        case .created:
            result.sort { $0.created > $1.created }
        case .size:
            result.sort { ($0.diskSize ?? 0) > ($1.diskSize ?? 0) }
        }
        
        return result
    }
    
    init(dependencies: Dependencies = .shared) {
        self.dependencies = dependencies
        
        // Load prefixes initially
        Task {
            await loadPrefixes()
        }
    }
    
    // MARK: - Actions
    
    func loadPrefixes() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await dependencies.prefixService.loadPrefixes()
        } catch {
            dependencies.showError(error)
        }
    }
    
    func createPrefix(
        name: String,
        architecture: WineArch,
        windowsVersion: WindowsVersion,
        dxvkEnabled: Bool
    ) async throws -> WinePrefix {
        try await dependencies.prefixService.createPrefix(
            name: name,
            architecture: architecture,
            windowsVersion: windowsVersion,
            dxvkEnabled: dxvkEnabled
        )
    }
    
    func deletePrefix(_ prefix: WinePrefix) async {
        do {
            try await dependencies.prefixService.deletePrefix(prefix)
            if selectedPrefix?.id == prefix.id {
                selectedPrefix = nil
            }
        } catch {
            dependencies.showError(error)
        }
    }
    
    func duplicatePrefix(_ prefix: WinePrefix) async {
        do {
            let newName = "\(prefix.name) Copy"
            let newPrefix = try await dependencies.prefixService.duplicatePrefix(prefix, newName: newName)
            selectedPrefix = newPrefix
        } catch {
            dependencies.showError(error)
        }
    }
    
    func openInFinder(_ prefix: WinePrefix) {
        dependencies.prefixService.revealInFinder(prefix)
    }
    
    func openDriveC(_ prefix: WinePrefix) {
        dependencies.prefixService.openDriveC(prefix)
    }
    
    func runWinecfg(in prefix: WinePrefix) async {
        do {
            try await dependencies.wineService.runWinecfg(in: prefix)
        } catch {
            dependencies.showError(error)
        }
    }
    
    func runRegedit(in prefix: WinePrefix) async {
        do {
            try await dependencies.wineService.runRegedit(in: prefix)
        } catch {
            dependencies.showError(error)
        }
    }
    
    func killWineProcesses(in prefix: WinePrefix) async {
        do {
            try await dependencies.wineService.killPrefix(prefix)
        } catch {
            dependencies.showError(error)
        }
    }
    
    func launchApp(_ app: InstalledApp, in prefix: WinePrefix) async {
        do {
            try await dependencies.prefixService.launchApp(app, in: prefix)
        } catch {
            dependencies.showError(error)
        }
    }
}

