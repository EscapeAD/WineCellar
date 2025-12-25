import SwiftUI

/// Application settings view
struct SettingsView: View {
    @EnvironmentObject private var dependencies: Dependencies
    @StateObject private var config = ConfigurationStore.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // General Settings
                generalSection
                
                Divider()
                
                // Wine Settings
                wineSection
                
                Divider()
                
                // Prefix Defaults
                prefixDefaultsSection
                
                Divider()
                
                // Advanced
                advancedSection
                
                Divider()
                
                // About
                aboutSection
            }
            .padding(24)
        }
    }
    
    // MARK: - General Section
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Theme
                HStack {
                    Text("Appearance")
                    Spacer()
                    Picker("Theme", selection: $config.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                // Check for updates
                Toggle("Check for updates on launch", isOn: $config.checkForUpdatesOnLaunch)
                
                // Show advanced options
                Toggle("Show advanced options", isOn: $config.showAdvancedOptions)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
        }
        .onChange(of: config.theme) { _ in config.save() }
        .onChange(of: config.checkForUpdatesOnLaunch) { _ in config.save() }
        .onChange(of: config.showAdvancedOptions) { _ in config.save() }
    }
    
    // MARK: - Wine Section
    
    private var wineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wine")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Default Wine version
                HStack {
                    Text("Default Wine Version")
                    Spacer()
                    if dependencies.wineService.installedVersions.isEmpty {
                        Text("None installed")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Wine Version", selection: $config.defaultWineVersion) {
                            Text("Auto").tag(nil as String?)
                            ForEach(dependencies.wineService.installedVersions) { version in
                                Text(version.version).tag(version.id as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                }
                
                // Wine debug level
                HStack {
                    VStack(alignment: .leading) {
                        Text("Wine Debug Level")
                        Text("Higher levels produce more log output")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("Debug Level", selection: $config.wineDebugLevel) {
                        ForEach(WineDebugLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
        }
        .onChange(of: config.defaultWineVersion) { _ in config.save() }
        .onChange(of: config.wineDebugLevel) { _ in config.save() }
    }
    
    // MARK: - Prefix Defaults Section
    
    private var prefixDefaultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Default Prefix Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Architecture
                HStack {
                    VStack(alignment: .leading) {
                        Text("Architecture")
                        Text("64-bit is required for Steam and most modern apps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("Architecture", selection: $config.defaultArchitecture) {
                        ForEach(WineArch.allCases, id: \.self) { arch in
                            Text(arch.displayName).tag(arch)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }
                
                // Windows version
                HStack {
                    Text("Windows Version")
                    Spacer()
                    Picker("Windows", selection: $config.defaultWindowsVersion) {
                        ForEach(WindowsVersion.allCases, id: \.self) { version in
                            Text(version.displayName).tag(version)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                
                // DXVK
                Toggle(isOn: $config.enableDXVKByDefault) {
                    VStack(alignment: .leading) {
                        Text("Enable DXVK by default")
                        Text("Translates DirectX to Vulkan for better gaming performance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
        }
        .onChange(of: config.defaultArchitecture) { _ in config.save() }
        .onChange(of: config.defaultWindowsVersion) { _ in config.save() }
        .onChange(of: config.enableDXVKByDefault) { _ in config.save() }
    }
    
    // MARK: - Advanced Section
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Data locations
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Locations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DataLocationRow(
                        label: "Prefixes",
                        path: FileSystemManager.shared.prefixesURL
                    )
                    
                    DataLocationRow(
                        label: "Wine Versions",
                        path: FileSystemManager.shared.wineURL
                    )
                    
                    DataLocationRow(
                        label: "Cache",
                        path: FileSystemManager.shared.cacheURL
                    )
                    
                    DataLocationRow(
                        label: "Logs",
                        path: FileSystemManager.shared.logsURL
                    )
                }
                
                Divider()
                
                // Maintenance
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maintenance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button("Clear Download Cache") {
                            Task {
                                try? await FileSystemManager.shared.delete(
                                    at: FileSystemManager.shared.downloadsURL
                                )
                                try? await FileSystemManager.shared.createDirectory(
                                    at: FileSystemManager.shared.downloadsURL
                                )
                            }
                        }
                        
                        Button("Open Logs Folder") {
                            NSWorkspace.shared.open(FileSystemManager.shared.logsURL)
                        }
                    }
                }
                
                Divider()
                
                // Reset
                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        config.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WineCellar")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("A modern Wine manager for macOS")
                            .foregroundColor(.secondary)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("WineCellar uses Wine to run Windows applications on macOS.")
                        .font(.caption)
                    
                    Text("Wine is an open-source compatibility layer maintained by WineHQ.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Link("Wine HQ", destination: URL(string: "https://www.winehq.org")!)
                    Text("•")
                    Link("ProtonDB", destination: URL(string: "https://www.protondb.com")!)
                    Text("•")
                    Link("Gcenx/wine-on-mac", destination: URL(string: "https://github.com/Gcenx/wine-on-mac")!)
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
}

// MARK: - Data Location Row

struct DataLocationRow: View {
    let label: String
    let path: URL
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(path.path)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            
            Button {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path.path)
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
        }
        .font(.caption)
    }
}

// MARK: - Settings ViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var config: ConfigurationStore
    
    init() {
        self.config = ConfigurationStore.shared
    }
}

#Preview {
    SettingsView()
        .environmentObject(Dependencies.shared)
}

