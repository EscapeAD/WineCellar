import SwiftUI

/// View for Steam installation and game management
struct SteamSetupView: View {
    @EnvironmentObject private var dependencies: Dependencies
    @State private var isInstalling = false
    @State private var installProgress = ""
    @State private var showGames = false
    
    private var steamInstalled: Bool {
        dependencies.steamService.steamPrefix != nil
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                Divider()
                
                if steamInstalled {
                    // Steam is installed
                    steamInstalledSection
                    
                    Divider()
                    
                    // Games library
                    gamesSection
                } else {
                    // Steam installation wizard
                    installationSection
                }
            }
            .padding(24)
        }
        .task {
            await checkSteamStatus()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Steam")
                    .font(.title)
                    .fontWeight(.bold)
                
                if steamInstalled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Steam is installed")
                    }
                    
                    if let library = dependencies.steamService.steamLibrary {
                        Text("\(library.installedGames.count) games installed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                        Text("Steam is not installed")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if steamInstalled {
                Button {
                    launchSteam()
                } label: {
                    Label("Launch Steam", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
    }
    
    // MARK: - Steam Installed Section
    
    private var steamInstalledSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                SteamActionButton(
                    title: "Launch Steam",
                    icon: "play.fill",
                    color: .green
                ) {
                    launchSteam()
                }
                
                SteamActionButton(
                    title: "Big Picture",
                    icon: "tv.fill",
                    color: .blue
                ) {
                    launchBigPicture()
                }
                
                SteamActionButton(
                    title: "Refresh Games",
                    icon: "arrow.clockwise",
                    color: .orange
                ) {
                    Task {
                        await refreshLibrary()
                    }
                }
                
                SteamActionButton(
                    title: "Kill Steam",
                    icon: "xmark.circle",
                    color: .red
                ) {
                    Task {
                        try await dependencies.steamService.killSteam()
                    }
                }
            }
            
            // Prefix info
            if let prefix = dependencies.steamService.steamPrefix {
                HStack {
                    Label("Prefix:", systemImage: "folder")
                    Text(prefix.name)
                    
                    Spacer()
                    
                    Button {
                        dependencies.prefixService.revealInFinder(prefix)
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.borderless)
                }
                .font(.caption)
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Games Section
    
    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Game Library")
                    .font(.headline)
                
                Spacer()
                
                Button("Scan for Games") {
                    Task { await refreshLibrary() }
                }
                .buttonStyle(.bordered)
            }
            
            if let library = dependencies.steamService.steamLibrary {
                if library.games.isEmpty {
                    noGamesView
                } else {
                    // Recently played
                    if !library.recentlyPlayedGames.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recently Played")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ForEach(library.recentlyPlayedGames) { game in
                                SteamGameRow(game: game)
                            }
                        }
                    }
                    
                    // All games
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All Games (\(library.games.count))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(library.games) { game in
                                SteamGameRow(game: game)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning library...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    private var noGamesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No games detected")
                .font(.title3)
            
            Text("Launch Steam and install some games, then click 'Scan for Games'")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Installation Section
    
    private var installationSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Install Steam")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                // Requirements
                VStack(alignment: .leading, spacing: 8) {
                    Text("Requirements")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    RequirementRow(
                        title: "Wine",
                        isInstalled: !dependencies.wineService.installedVersions.isEmpty,
                        description: dependencies.wineService.installedVersions.isEmpty 
                            ? "Please install Wine first" 
                            : "Wine \(dependencies.wineService.defaultVersion?.version ?? "installed")"
                    )
                    
                    RequirementRow(
                        title: "Disk Space",
                        isInstalled: true,
                        description: "At least 5GB recommended"
                    )
                }
                
                // What will be installed
                VStack(alignment: .leading, spacing: 8) {
                    Text("This will:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    BulletPoint(text: "Create a new Wine prefix optimized for Steam")
                    BulletPoint(text: "Install required dependencies (fonts, VC++ runtime)")
                    BulletPoint(text: "Download and install the Steam client")
                    BulletPoint(text: "Configure DXVK for better game performance")
                }
                
                // Important notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Important Notes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Games with anti-cheat (EAC, BattlEye) may not work. Check ProtonDB for game compatibility.")
                            .font(.caption)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Steam will use ~2GB for the client. Games will use additional space.")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            
            // Install button
            if isInstalling {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(installProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Button {
                    installSteam()
                } label: {
                    Label("Install Steam", systemImage: "arrow.down.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
                .disabled(dependencies.wineService.installedVersions.isEmpty)
            }
        }
    }
    
    // MARK: - Actions
    
    private func checkSteamStatus() async {
        _ = await dependencies.steamService.findSteamPrefix()
        
        if dependencies.steamService.steamPrefix != nil {
            await refreshLibrary()
        }
    }
    
    private func refreshLibrary() async {
        do {
            _ = try await dependencies.steamService.scanLibrary()
        } catch {
            dependencies.showError(error)
        }
    }
    
    private func installSteam() {
        isInstalling = true
        
        Task {
            do {
                _ = try await dependencies.steamService.installSteam { progress in
                    Task { @MainActor in
                        installProgress = progress
                    }
                }
            } catch {
                dependencies.showError(error)
            }
            
            isInstalling = false
        }
    }
    
    private func launchSteam() {
        Task {
            do {
                try await dependencies.steamService.launchSteam()
            } catch {
                dependencies.showError(error)
            }
        }
    }
    
    private func launchBigPicture() {
        Task {
            do {
                try await dependencies.steamService.launchSteamBigPicture()
            } catch {
                dependencies.showError(error)
            }
        }
    }
}

// MARK: - Supporting Views

struct SteamActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct SteamGameRow: View {
    let game: SteamGame
    
    @EnvironmentObject private var dependencies: Dependencies
    
    var body: some View {
        HStack {
            Image(systemName: game.isInstalled ? "gamecontroller.fill" : "gamecontroller")
                .foregroundColor(game.isInstalled ? .green : .secondary)
            
            VStack(alignment: .leading) {
                Text(game.name)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if game.isInstalled {
                        Text("Installed")
                            .foregroundColor(.green)
                    }
                    
                    if game.playTime > 0 {
                        Text(game.formattedPlayTime)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if game.isInstalled {
                Button("Play") {
                    Task {
                        try await dependencies.steamService.launchGame(appId: game.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if let url = game.protonDBURL {
                Link(destination: url) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
                .help("View on ProtonDB")
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct RequirementRow: View {
    let title: String
    let isInstalled: Bool
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isInstalled ? .green : .red)
            
            Text(title)
            
            Spacer()
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
        }
    }
}

// MARK: - Steam ViewModel

@MainActor
final class SteamViewModel: ObservableObject {
    @Published var isInstalling = false
    @Published var installProgress = ""
    @Published var steamLibrary: SteamLibrary?
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies = .shared) {
        self.dependencies = dependencies
    }
    
    var steamInstalled: Bool {
        dependencies.steamService.steamPrefix != nil
    }
    
    func checkStatus() async {
        _ = await dependencies.steamService.findSteamPrefix()
        
        if steamInstalled {
            await refreshLibrary()
        }
    }
    
    func refreshLibrary() async {
        do {
            steamLibrary = try await dependencies.steamService.scanLibrary()
        } catch {
            dependencies.showError(error)
        }
    }
    
    func installSteam() async {
        isInstalling = true
        
        do {
            _ = try await dependencies.steamService.installSteam { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.installProgress = progress
                }
            }
        } catch {
            dependencies.showError(error)
        }
        
        isInstalling = false
    }
    
    func launchSteam() async {
        do {
            try await dependencies.steamService.launchSteam()
        } catch {
            dependencies.showError(error)
        }
    }
    
    func launchGame(_ game: SteamGame) async {
        do {
            try await dependencies.steamService.launchGame(appId: game.id)
        } catch {
            dependencies.showError(error)
        }
    }
}

#Preview {
    SteamSetupView()
        .environmentObject(Dependencies.shared)
}

