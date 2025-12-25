import SwiftUI

/// View for managing Wine installations
struct WineManagerView: View {
    @EnvironmentObject private var dependencies: Dependencies
    @State private var isRefreshing = false
    @State private var showInstallGuide = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                Divider()
                
                // Installed versions
                installedVersionsSection
                
                Divider()
                
                // Installation guide
                installationGuideSection
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    refresh()
                } label: {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
            }
        }
        .task {
            await loadWineVersions()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "wineglass.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Wine Versions")
                    .font(.title)
                    .fontWeight(.bold)
                
                if dependencies.wineService.installedVersions.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("No Wine installation detected")
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("\(dependencies.wineService.installedVersions.count) version(s) installed")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Installed Versions Section
    
    private var installedVersionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Installed Versions")
                .font(.headline)
            
            if dependencies.wineService.installedVersions.isEmpty {
                noWineInstalledView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(dependencies.wineService.installedVersions) { version in
                        WineVersionCard(version: version)
                    }
                }
            }
        }
    }
    
    private var noWineInstalledView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wineglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Wine Not Installed")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Install Wine to run Windows applications")
                .foregroundColor(.secondary)
            
            Button {
                showInstallGuide = true
            } label: {
                Label("View Installation Guide", systemImage: "book")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Installation Guide Section
    
    private var installationGuideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Installation Guide")
                .font(.headline)
            
            // Apple Silicon notice
            #if arch(arm64)
            HStack {
                Image(systemName: "apple.logo")
                Text("Apple Silicon detected - Rosetta 2 may be required for some Wine builds")
                    .font(.caption)
            }
            .padding(8)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(6)
            #endif
            
            VStack(alignment: .leading, spacing: 16) {
                // Step 1: XQuartz
                InstallMethodCard(
                    title: "Step 1: Install XQuartz (Required)",
                    description: "XQuartz provides X11 windowing required by Wine. Restart your Mac after installation.",
                    icon: "display",
                    color: .purple,
                    steps: [
                        "Open Terminal",
                        "Run: brew install --cask xquartz",
                        "Log out and back in (or restart)",
                    ],
                    copyableCommand: "brew install --cask xquartz"
                )
                
                // Step 2: Wine
                InstallMethodCard(
                    title: "Step 2: Install Wine (Homebrew)",
                    description: "Install Wine stable via Homebrew. The --no-quarantine flag bypasses macOS Gatekeeper.",
                    icon: "terminal.fill",
                    color: .blue,
                    steps: [
                        "Open Terminal",
                        "Run: brew install --cask --no-quarantine wine-stable",
                        "Click Refresh above when complete"
                    ],
                    copyableCommand: "brew install --cask --no-quarantine wine-stable"
                )
                
                // Optional: Winetricks
                InstallMethodCard(
                    title: "Optional: Install Winetricks",
                    description: "Winetricks helps install Windows libraries like DirectX, .NET, and Visual C++ runtimes.",
                    icon: "wrench.and.screwdriver.fill",
                    color: .green,
                    steps: [
                        "Run: brew install winetricks",
                    ],
                    copyableCommand: "brew install winetricks"
                )
                
                // Apple Silicon users
                InstallMethodCard(
                    title: "Apple Silicon: Install Rosetta 2",
                    description: "M1/M2/M3 Macs need Rosetta 2 to run Intel-based Wine.",
                    icon: "cpu",
                    color: .orange,
                    steps: [
                        "Run: softwareupdate --install-rosetta",
                    ],
                    copyableCommand: "softwareupdate --install-rosetta"
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func refresh() {
        isRefreshing = true
        Task {
            await loadWineVersions()
            isRefreshing = false
        }
    }
    
    private func loadWineVersions() async {
        _ = await dependencies.wineService.detectInstalledVersions()
    }
}

// MARK: - Wine Version Card

struct WineVersionCard: View {
    let version: WineVersion
    
    @EnvironmentObject private var dependencies: Dependencies
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "wineglass.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Wine \(version.version)")
                        .font(.headline)
                    
                    if version.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 12) {
                    Label(version.source.displayName, systemImage: "shippingbox")
                    
                    if version.isValid {
                        Label("Valid", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Invalid", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text(version.path.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: version.path.path)
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
                
                if !version.isDefault {
                    Button {
                        // Set as default
                    } label: {
                        Label("Set as Default", systemImage: "star")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(isHovered ? Color(.selectedControlColor) : Color(.controlBackgroundColor))
        .cornerRadius(12)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Install Method Card

struct InstallMethodCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let steps: [String]
    var copyableCommand: String?
    var link: URL?
    
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text(step)
                            .font(.caption)
                    }
                }
            }
            .padding(.leading, 8)
            
            HStack {
                if let command = copyableCommand {
                    HStack {
                        Text(command)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(command, forType: .string)
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        } label: {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                }
                
                if let url = link {
                    Spacer()
                    Link(destination: url) {
                        Label("Open in Browser", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Wine View Model

@MainActor
final class WineViewModel: ObservableObject {
    @Published var installedVersions: [WineVersion] = []
    @Published var isLoading = false
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies = .shared) {
        self.dependencies = dependencies
    }
    
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        installedVersions = await dependencies.wineService.detectInstalledVersions()
    }
}

#Preview {
    WineManagerView()
        .environmentObject(Dependencies.shared)
}


