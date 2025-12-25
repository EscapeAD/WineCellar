import SwiftUI

/// List view showing all Wine prefixes
struct PrefixListView: View {
    @EnvironmentObject private var dependencies: Dependencies
    @State private var selectedPrefix: WinePrefix?
    @State private var showCreateSheet = false
    @State private var searchText = ""
    @State private var sortOrder: PrefixSortOrder = .lastUsed
    
    private var filteredPrefixes: [WinePrefix] {
        var prefixes = dependencies.prefixService.prefixes
        
        // Apply search filter
        if !searchText.isEmpty {
            prefixes = prefixes.filter { prefix in
                prefix.name.localizedCaseInsensitiveContains(searchText) ||
                prefix.installedApps.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply sort
        switch sortOrder {
        case .name:
            prefixes.sort { $0.name < $1.name }
        case .lastUsed:
            prefixes.sort { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        case .created:
            prefixes.sort { $0.created > $1.created }
        case .size:
            prefixes.sort { ($0.diskSize ?? 0) > ($1.diskSize ?? 0) }
        }
        
        return prefixes
    }
    
    var body: some View {
        HSplitView {
            // Prefix list
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    TextField("Search prefixes...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Sort", selection: $sortOrder) {
                        ForEach(PrefixSortOrder.allCases, id: \.self) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                .padding()
                
                Divider()
                
                // List
                if filteredPrefixes.isEmpty {
                    emptyStateView
                } else {
                    List(selection: $selectedPrefix) {
                        ForEach(filteredPrefixes) { prefix in
                            PrefixRowView(prefix: prefix)
                                .tag(prefix)
                                .contextMenu {
                                    prefixContextMenu(for: prefix)
                                }
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            }
            .frame(minWidth: 300)
            
            // Detail view
            if let prefix = selectedPrefix {
                PrefixDetailView(prefix: prefix)
            } else {
                noSelectionView
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("New Prefix", systemImage: "plus")
                }
                
                Button {
                    Task {
                        _ = try? await dependencies.prefixService.loadPrefixes()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreatePrefixSheet()
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Prefixes")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a new Wine prefix to run Windows applications")
                .foregroundColor(.secondary)
            
            Button("Create Prefix") {
                showCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noSelectionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Select a prefix")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func prefixContextMenu(for prefix: WinePrefix) -> some View {
        Button {
            dependencies.prefixService.revealInFinder(prefix)
        } label: {
            Label("Show in Finder", systemImage: "folder")
        }
        
        Button {
            dependencies.prefixService.openDriveC(prefix)
        } label: {
            Label("Open Drive C:", systemImage: "internaldrive")
        }
        
        Divider()
        
        Button {
            Task {
                try await dependencies.wineService.runWinecfg(in: prefix)
            }
        } label: {
            Label("Wine Configuration", systemImage: "gearshape")
        }
        
        Button {
            Task {
                try await dependencies.wineService.runRegedit(in: prefix)
            }
        } label: {
            Label("Registry Editor", systemImage: "doc.text")
        }
        
        Divider()
        
        Button(role: .destructive) {
            Task {
                try await dependencies.wineService.killPrefix(prefix)
            }
        } label: {
            Label("Kill Wine Processes", systemImage: "xmark.circle")
        }
        
        Button(role: .destructive) {
            Task {
                try await dependencies.prefixService.deletePrefix(prefix)
            }
        } label: {
            Label("Delete Prefix", systemImage: "trash")
        }
    }
}

// MARK: - Prefix Row View

struct PrefixRowView: View {
    let prefix: WinePrefix
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(prefix.isSteamPrefix ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: prefix.isSteamPrefix ? "gamecontroller.fill" : "folder.fill")
                    .font(.title2)
                    .foregroundColor(prefix.isSteamPrefix ? .green : .purple)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(prefix.name)
                        .font(.headline)
                    
                    if prefix.dxvkEnabled {
                        Text("DXVK")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 8) {
                    Label(prefix.architecture.rawValue, systemImage: "cpu")
                    Label(prefix.windowsVersion.displayName, systemImage: "desktopcomputer")
                    
                    if !prefix.installedApps.isEmpty {
                        Label("\(prefix.installedApps.count) apps", systemImage: "app.fill")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Last used
            if let lastUsed = prefix.lastUsed {
                Text(lastUsed, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

extension WinePrefix {
    var isSteamPrefix: Bool {
        name.lowercased() == "steam" ||
        installedApps.contains { $0.isSteam }
    }
}

// MARK: - Sort Order

enum PrefixSortOrder: CaseIterable {
    case lastUsed
    case name
    case created
    case size
    
    var displayName: String {
        switch self {
        case .lastUsed: return "Last Used"
        case .name: return "Name"
        case .created: return "Created"
        case .size: return "Size"
        }
    }
}

#Preview {
    PrefixListView()
        .environmentObject(Dependencies.shared)
}

