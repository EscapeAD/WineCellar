import SwiftUI

/// Sidebar navigation items
enum SidebarItem: String, CaseIterable, Identifiable {
    case prefixes = "Prefixes"
    case applications = "Applications"
    case steam = "Steam"
    case wine = "Wine Versions"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .prefixes: return "folder.fill"
        case .applications: return "app.fill"
        case .steam: return "gamecontroller.fill"
        case .wine: return "wineglass.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    var description: String {
        switch self {
        case .prefixes: return "Manage Wine prefixes"
        case .applications: return "Installed Windows apps"
        case .steam: return "Steam games"
        case .wine: return "Manage Wine installations"
        case .settings: return "App preferences"
        }
    }
}

/// Main application view with sidebar navigation
struct MainView: View {
    @EnvironmentObject private var dependencies: Dependencies
    @State private var selection: SidebarItem? = .prefixes
    @State private var showNewPrefixSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showNewPrefixSheet) {
            CreatePrefixSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewPrefix)) { _ in
            showNewPrefixSheet = true
        }
        .alert(item: $dependencies.currentError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.errorDescription ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    dependencies.clearError()
                }
            )
        }
        .task {
            await loadInitialData()
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Logo header
            VStack(spacing: 8) {
                Image(systemName: "wineglass.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.purple)
                Text("WineCellar")
                    .font(.headline)
            }
            .padding(.vertical, 20)
            
            Divider()
            
            // Navigation items
            List(selection: $selection) {
                Section {
                    ForEach(SidebarItem.allCases) { item in
                        NavigationLink(value: item) {
                            Label(item.rawValue, systemImage: item.icon)
                        }
                    }
                }
                
                Section("Recent Prefixes") {
                    if dependencies.configurationStore.recentPrefixes.isEmpty {
                        Text("No recent prefixes")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(dependencies.configurationStore.recentPrefixes.prefix(5), id: \.self) { prefixId in
                            if let prefix = dependencies.prefixService.prefixes.first(where: { $0.id == prefixId }) {
                                Button {
                                    selection = .prefixes
                                    // TODO: Select specific prefix
                                } label: {
                                    Label(prefix.name, systemImage: "folder")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            
            Divider()
            
            // Bottom toolbar
            HStack {
                Button {
                    showNewPrefixSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Create New Prefix")
                
                Spacer()
                
                Button {
                    Task {
                        await loadInitialData()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }
            .padding(10)
        }
        .frame(minWidth: 220)
    }
    
    // MARK: - Detail Content
    
    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .prefixes:
            PrefixListView()
        case .applications:
            AppLibraryView()
        case .steam:
            SteamSetupView()
        case .wine:
            WineManagerView()
        case .settings:
            SettingsView()
        case .none:
            WelcomeView()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        do {
            // Detect Wine versions
            _ = await dependencies.wineService.detectInstalledVersions()
            
            // Load prefixes
            _ = try await dependencies.prefixService.loadPrefixes()
            
            // Find Steam prefix
            _ = await dependencies.steamService.findSteamPrefix()
        } catch {
            dependencies.showError(error)
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @EnvironmentObject private var dependencies: Dependencies
    @State private var showNewPrefixSheet = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wineglass.fill")
                .font(.system(size: 80))
                .foregroundStyle(.purple)
            
            Text("Welcome to WineCellar")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Run Windows applications and games on your Mac")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
                .frame(maxWidth: 300)
            
            VStack(spacing: 16) {
                WelcomeActionButton(
                    title: "Create New Prefix",
                    description: "Set up a new Wine environment",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showNewPrefixSheet = true
                }
                
                WelcomeActionButton(
                    title: "Install Steam",
                    description: "Play your Steam library on Mac",
                    icon: "gamecontroller.fill",
                    color: .green
                ) {
                    // Navigate to Steam setup
                    NotificationCenter.default.post(name: .navigateToSteam, object: nil)
                }
                
                WelcomeActionButton(
                    title: "Manage Wine Versions",
                    description: "Download and configure Wine",
                    icon: "wineglass.fill",
                    color: .purple
                ) {
                    NotificationCenter.default.post(name: .navigateToWine, object: nil)
                }
            }
            .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .sheet(isPresented: $showNewPrefixSheet) {
            CreatePrefixSheet()
        }
    }
}

struct WelcomeActionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Additional Notifications

extension Notification.Name {
    static let navigateToSteam = Notification.Name("navigateToSteam")
    static let navigateToWine = Notification.Name("navigateToWine")
}

#Preview {
    MainView()
        .environmentObject(Dependencies.shared)
}


