import SwiftUI

/// Detailed view for a Wine prefix
struct PrefixDetailView: View {
    let prefix: WinePrefix
    
    @EnvironmentObject private var dependencies: Dependencies
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedWindowsVersion: WindowsVersion = .win10
    @State private var editedDxvkEnabled = true
    @State private var showDeleteConfirmation = false
    @State private var showInstallAppSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                Divider()
                
                // Configuration
                configurationSection
                
                Divider()
                
                // Installed Applications
                applicationsSection
                
                Divider()
                
                // Actions
                actionsSection
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    isEditing.toggle()
                    if isEditing {
                        editedName = prefix.name
                        editedWindowsVersion = prefix.windowsVersion
                        editedDxvkEnabled = prefix.dxvkEnabled
                    }
                } label: {
                    Label(isEditing ? "Done" : "Edit", systemImage: isEditing ? "checkmark" : "pencil")
                }
                
                Menu {
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
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Prefix", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Delete Prefix?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    try await dependencies.prefixService.deletePrefix(prefix)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete '\(prefix.name)' and all its contents. This action cannot be undone.")
        }
        .sheet(isPresented: $showInstallAppSheet) {
            InstallAppSheet(prefix: prefix)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(prefix.isSteamPrefix ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: prefix.isSteamPrefix ? "gamecontroller.fill" : "folder.fill")
                    .font(.system(size: 40))
                    .foregroundColor(prefix.isSteamPrefix ? .green : .purple)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if isEditing {
                    TextField("Prefix Name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title)
                } else {
                    Text(prefix.name)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                HStack(spacing: 12) {
                    Label(prefix.architecture.displayName, systemImage: "cpu")
                    Label(prefix.windowsVersion.displayName, systemImage: "desktopcomputer")
                    
                    if prefix.dxvkEnabled {
                        Label("DXVK Enabled", systemImage: "bolt.fill")
                            .foregroundColor(.orange)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Text("Created: \(prefix.created, style: .date)")
                    
                    if let lastUsed = prefix.lastUsed {
                        Text("Last used: \(lastUsed, style: .relative)")
                    }
                    
                    if let size = prefix.diskSize {
                        Text("Size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ConfigurationCard(
                    title: "Windows Version",
                    value: prefix.windowsVersion.displayName,
                    icon: "desktopcomputer",
                    isEditing: isEditing
                ) {
                    Picker("Windows Version", selection: $editedWindowsVersion) {
                        ForEach(WindowsVersion.allCases, id: \.self) { version in
                            Text(version.displayName).tag(version)
                        }
                    }
                }
                
                ConfigurationCard(
                    title: "Architecture",
                    value: prefix.architecture.displayName,
                    icon: "cpu",
                    isEditing: false
                ) {
                    Text(prefix.architecture.displayName)
                }
                
                ConfigurationCard(
                    title: "DXVK",
                    value: prefix.dxvkEnabled ? "Enabled" : "Disabled",
                    icon: "bolt.fill",
                    isEditing: isEditing
                ) {
                    Toggle("DXVK", isOn: $editedDxvkEnabled)
                        .labelsHidden()
                }
                
                ConfigurationCard(
                    title: "Wine Version",
                    value: prefix.wineVersion.isEmpty ? "Default" : prefix.wineVersion,
                    icon: "wineglass.fill",
                    isEditing: false
                ) {
                    Text(prefix.wineVersion.isEmpty ? "Default" : prefix.wineVersion)
                }
            }
            
            // Path info
            HStack {
                Text("Path:")
                    .foregroundColor(.secondary)
                Text(prefix.path.path)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                
                Button {
                    dependencies.prefixService.revealInFinder(prefix)
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
            }
            .font(.caption)
        }
    }
    
    // MARK: - Applications Section
    
    private var applicationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Installed Applications")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showInstallAppSheet = true
                } label: {
                    Label("Install App", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
            
            if prefix.installedApps.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "app.dashed")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No applications installed")
                            .foregroundColor(.secondary)
                        Button("Install Application") {
                            showInstallAppSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 200), spacing: 16)
                ], spacing: 16) {
                    ForEach(prefix.installedApps) { app in
                        AppCard(app: app, prefix: prefix)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                ActionButton(
                    title: "Wine Config",
                    icon: "gearshape",
                    color: .blue
                ) {
                    Task {
                        try await dependencies.wineService.runWinecfg(in: prefix)
                    }
                }
                
                ActionButton(
                    title: "Registry",
                    icon: "doc.text",
                    color: .green
                ) {
                    Task {
                        try await dependencies.wineService.runRegedit(in: prefix)
                    }
                }
                
                ActionButton(
                    title: "Kill Processes",
                    icon: "xmark.circle",
                    color: .orange
                ) {
                    Task {
                        try await dependencies.wineService.killPrefix(prefix)
                    }
                }
                
                ActionButton(
                    title: "Open Drive C:",
                    icon: "internaldrive",
                    color: .purple
                ) {
                    dependencies.prefixService.openDriveC(prefix)
                }
            }
        }
    }
}

// MARK: - Configuration Card

struct ConfigurationCard<Content: View>: View {
    let title: String
    let value: String
    let icon: String
    let isEditing: Bool
    @ViewBuilder let editContent: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isEditing {
                editContent()
            } else {
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - App Card

struct AppCard: View {
    let app: InstalledApp
    let prefix: WinePrefix
    
    @EnvironmentObject private var dependencies: Dependencies
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: app.isSteam ? "gamecontroller.fill" : "app.fill")
                    .font(.title2)
                    .foregroundColor(app.isSteam ? .green : .blue)
                
                VStack(alignment: .leading) {
                    Text(app.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(app.fileName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            HStack {
                if app.launchCount > 0 {
                    Text("Launched \(app.launchCount) times")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Launch") {
                    Task {
                        try await dependencies.prefixService.launchApp(app, in: prefix)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(isHovered ? Color(.selectedControlColor) : Color(.controlBackgroundColor))
        .cornerRadius(10)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
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
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PrefixDetailView(prefix: WinePrefix(
        name: "Test Prefix",
        path: URL(fileURLWithPath: "/tmp/test")
    ))
    .environmentObject(Dependencies.shared)
}


