import SwiftUI
import Combine

/// ViewModel for the main application state
@MainActor
final class MainViewModel: ObservableObject {
    @Published var selectedSidebarItem: SidebarItem? = .prefixes
    @Published var selectedPrefixId: UUID?
    @Published var isLoading = false
    @Published var loadingMessage = ""
    
    private let dependencies: Dependencies
    private var cancellables = Set<AnyCancellable>()
    
    init(dependencies: Dependencies = .shared) {
        self.dependencies = dependencies
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .navigateToSteam)
            .sink { [weak self] _ in
                self?.selectedSidebarItem = .steam
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .navigateToWine)
            .sink { [weak self] _ in
                self?.selectedSidebarItem = .wine
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadData() async {
        isLoading = true
        loadingMessage = "Loading..."
        
        defer {
            isLoading = false
            loadingMessage = ""
        }
        
        do {
            loadingMessage = "Detecting Wine installations..."
            _ = await dependencies.wineService.detectInstalledVersions()
            
            loadingMessage = "Loading prefixes..."
            _ = try await dependencies.prefixService.loadPrefixes()
            
            loadingMessage = "Checking Steam..."
            _ = await dependencies.steamService.findSteamPrefix()
        } catch {
            dependencies.showError(error)
        }
    }
    
    // MARK: - Navigation
    
    func selectPrefix(_ prefix: WinePrefix) {
        selectedPrefixId = prefix.id
        selectedSidebarItem = .prefixes
    }
    
    func selectSteam() {
        selectedSidebarItem = .steam
    }
    
    // MARK: - Quick Actions
    
    func createNewPrefix() {
        NotificationCenter.default.post(name: .createNewPrefix, object: nil)
    }
    
    // MARK: - Computed Properties
    
    var wineInstalled: Bool {
        !dependencies.wineService.installedVersions.isEmpty
    }
    
    var steamInstalled: Bool {
        dependencies.steamService.steamPrefix != nil
    }
    
    var prefixCount: Int {
        dependencies.prefixService.prefixes.count
    }
    
    var appCount: Int {
        dependencies.prefixService.prefixes.reduce(0) { $0 + $1.installedApps.count }
    }
}

