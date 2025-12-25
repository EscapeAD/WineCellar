import SwiftUI

/// View showing all installed Windows applications across prefixes
struct AppLibraryView: View {
    @EnvironmentObject private var dependencies: Dependencies
    @State private var searchText = ""
    @State private var selectedApp: AppWithPrefix?
    @State private var showInstallSheet = false
    @State private var sortOrder: AppSortOrder = .name
    
    /// Wrapper to associate apps with their prefix
    struct AppWithPrefix: Identifiable, Hashable {
        let app: InstalledApp
        let prefix: WinePrefix
        
        var id: UUID { app.id }
        
        static func == (lhs: AppWithPrefix, rhs: AppWithPrefix) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    private var allApps: [AppWithPrefix] {
        var apps: [AppWithPrefix] = []
        for prefix in dependencies.prefixService.prefixes {
            for app in prefix.installedApps {
                apps.append(AppWithPrefix(app: app, prefix: prefix))
            }
        }
        return apps
    }
    
    private var filteredApps: [AppWithPrefix] {
        var apps = allApps
        
        // Filter
        if !searchText.isEmpty {
            apps = apps.filter { item in
                item.app.name.localizedCaseInsensitiveContains(searchText) ||
                item.prefix.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort
        switch sortOrder {
        case .name:
            apps.sort { $0.app.name < $1.app.name }
        case .lastLaunched:
            apps.sort { ($0.app.lastLaunched ?? .distantPast) > ($1.app.lastLaunched ?? .distantPast) }
        case .launchCount:
            apps.sort { $0.app.launchCount > $1.app.launchCount }
        case .prefix:
            apps.sort { $0.prefix.name < $1.prefix.name }
        }
        
        return apps
    }
    
    private var favoriteApps: [AppWithPrefix] {
        filteredApps.filter { dependencies.configurationStore.isFavorite($0.app.id) }
    }
    
    private var recentApps: [AppWithPrefix] {
        filteredApps.filter { $0.app.lastLaunched != nil }
            .sorted { ($0.app.lastLaunched ?? .distantPast) > ($1.app.lastLaunched ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                TextField("Search applications...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                
                Spacer()
                
                Picker("Sort by", selection: $sortOrder) {
                    ForEach(AppSortOrder.allCases, id: \.self) { order in
                        Text(order.displayName).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                
                Button {
                    showInstallSheet = true
                } label: {
                    Label("Install App", systemImage: "plus")
                }
            }
            .padding()
            
            Divider()
            
            if allApps.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Favorites section
                        if !favoriteApps.isEmpty {
                            appSection(title: "Favorites", apps: Array(favoriteApps), icon: "star.fill")
                        }
                        
                        // Recent section
                        if !recentApps.isEmpty {
                            appSection(title: "Recently Launched", apps: Array(recentApps), icon: "clock.fill")
                        }
                        
                        // All apps
                        appSection(title: "All Applications", apps: filteredApps, icon: "app.fill")
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showInstallSheet) {
            SelectPrefixSheet { prefix in
                InstallAppSheet(prefix: prefix)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.dashed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Applications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Install Windows applications to see them here")
                .foregroundColor(.secondary)
            
            Button {
                showInstallSheet = true
            } label: {
                Label("Install Application", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func appSection(title: String, apps: [AppWithPrefix], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.headline)
                Text("(\(apps.count))")
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 280), spacing: 16)
            ], spacing: 16) {
                ForEach(apps) { item in
                    AppLibraryCard(app: item.app, prefix: item.prefix)
                }
            }
        }
    }
}

// MARK: - App Library Card

struct AppLibraryCard: View {
    let app: InstalledApp
    let prefix: WinePrefix
    
    @EnvironmentObject private var dependencies: Dependencies
    @State private var isHovered = false
    @State private var isLaunching = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(app.isSteam ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: app.isSteam ? "gamecontroller.fill" : "app.fill")
                    .font(.title2)
                    .foregroundColor(app.isSteam ? .green : .blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if dependencies.configurationStore.isFavorite(app.id) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                HStack(spacing: 8) {
                    Label(prefix.name, systemImage: "folder")
                    
                    if app.launchCount > 0 {
                        Text("•")
                        Text("\(app.launchCount) launches")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    dependencies.configurationStore.toggleFavorite(app.id)
                } label: {
                    Image(systemName: dependencies.configurationStore.isFavorite(app.id) ? "star.fill" : "star")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.yellow)
                
                Button {
                    launchApp()
                } label: {
                    if isLaunching {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Label("Launch", systemImage: "play.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isLaunching)
            }
        }
        .padding()
        .background(isHovered ? Color(.selectedControlColor) : Color(.controlBackgroundColor))
        .cornerRadius(12)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button {
                launchApp()
            } label: {
                Label("Launch", systemImage: "play.fill")
            }
            
            Button {
                dependencies.configurationStore.toggleFavorite(app.id)
            } label: {
                Label(
                    dependencies.configurationStore.isFavorite(app.id) ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: dependencies.configurationStore.isFavorite(app.id) ? "star.slash" : "star"
                )
            }
            
            Divider()
            
            Button {
                dependencies.prefixService.openDriveC(prefix)
            } label: {
                Label("Open Prefix", systemImage: "folder")
            }
            
            Button(role: .destructive) {
                Task {
                    try await dependencies.prefixService.removeApp(app, from: prefix)
                }
            } label: {
                Label("Remove from Library", systemImage: "trash")
            }
        }
    }
    
    private func launchApp() {
        isLaunching = true
        Task {
            defer { isLaunching = false }
            do {
                try await dependencies.prefixService.launchApp(app, in: prefix)
            } catch {
                dependencies.showError(error)
            }
        }
    }
}

// MARK: - App Sort Order

enum AppSortOrder: CaseIterable {
    case name
    case lastLaunched
    case launchCount
    case prefix
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .lastLaunched: return "Last Launched"
        case .launchCount: return "Most Used"
        case .prefix: return "Prefix"
        }
    }
}

// MARK: - Select Prefix Sheet

struct SelectPrefixSheet<Content: View>: View {
    @EnvironmentObject private var dependencies: Dependencies
    @Environment(\.dismiss) private var dismiss
    
    let content: (WinePrefix) -> Content
    
    @State private var selectedPrefix: WinePrefix?
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Select a Prefix")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Divider()
            
            if dependencies.prefixService.prefixes.isEmpty {
                VStack(spacing: 16) {
                    Text("No prefixes available")
                        .foregroundColor(.secondary)
                    Text("Create a prefix first to install applications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List(selection: $selectedPrefix) {
                    ForEach(dependencies.prefixService.prefixes) { prefix in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.purple)
                            Text(prefix.name)
                            Spacer()
                            Text("\(prefix.installedApps.count) apps")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .tag(prefix)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
        }
        .frame(width: 400, height: 300)
        .sheet(item: $selectedPrefix) { prefix in
            content(prefix)
        }
    }
}

#Preview {
    AppLibraryView()
        .environmentObject(Dependencies.shared)
}

