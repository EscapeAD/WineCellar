import SwiftUI
import UniformTypeIdentifiers

/// Sheet for installing a Windows application (.exe) into a prefix
struct InstallAppSheet: View {
    let prefix: WinePrefix
    
    @EnvironmentObject private var dependencies: Dependencies
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFile: URL?
    @State private var appName = ""
    @State private var isInstalling = false
    @State private var installProgress = ""
    @State private var isDragOver = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Install Application")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            VStack(spacing: 24) {
                // Target prefix info
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.purple)
                    Text("Installing to:")
                        .foregroundColor(.secondary)
                    Text(prefix.name)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                // File drop zone
                dropZone
                
                // App name
                if selectedFile != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Application Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter name for this application", text: $appName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Install progress
                if isInstalling {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text(installProgress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding()
            
            Spacer()
            
            Divider()
            
            // Footer
            HStack {
                if let file = selectedFile {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    Text(file.lastPathComponent)
                        .font(.caption)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Install") {
                    installApp()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFile == nil || appName.isEmpty || isInstalling)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }
    
    // MARK: - Drop Zone
    
    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDragOver ? Color.blue : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDragOver ? Color.blue.opacity(0.1) : Color.clear)
                )
            
            if let file = selectedFile {
                VStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text(file.lastPathComponent)
                        .font(.headline)
                    
                    Button("Choose Different File") {
                        selectFile()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Drop .exe file here")
                        .font(.headline)
                    
                    Text("or")
                        .foregroundColor(.secondary)
                    
                    Button("Choose File...") {
                        selectFile()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(height: 180)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Actions
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "exe")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a Windows executable (.exe) to install"
        
        if panel.runModal() == .OK, let url = panel.url {
            selectedFile = url
            if appName.isEmpty {
                // Use filename without extension as default name
                appName = url.deletingPathExtension().lastPathComponent
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.pathExtension.lowercased() == "exe" else {
                return
            }
            
            Task { @MainActor in
                selectedFile = url
                if appName.isEmpty {
                    appName = url.deletingPathExtension().lastPathComponent
                }
            }
        }
        
        return true
    }
    
    private func installApp() {
        guard let file = selectedFile else { return }
        
        isInstalling = true
        installProgress = "Starting installation..."
        
        Task {
            do {
                // Run the installer
                installProgress = "Running installer..."
                
                _ = try await dependencies.wineService.runExecutable(
                    file.path,
                    in: prefix
                ) { output in
                    Task { @MainActor in
                        installProgress = output.trimmingCharacters(in: .whitespacesAndNewlines)
                            .components(separatedBy: .newlines).last ?? "Installing..."
                    }
                }
                
                // After installation, ask user to locate the installed .exe
                installProgress = "Installation complete. Registering application..."
                
                // For now, we'll create an app entry assuming standard installation path
                // In a real implementation, we'd scan for new .exe files or ask the user
                let installedApp = InstalledApp(
                    name: appName,
                    executablePath: file.lastPathComponent  // This should be the actual installed path
                )
                
                try await dependencies.prefixService.addApp(installedApp, to: prefix)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    dependencies.showError(error)
                }
            }
        }
    }
}

// MARK: - App View Model

@MainActor
final class AppViewModel: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var selectedApp: InstalledApp?
    @Published var searchText = ""
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies = .shared) {
        self.dependencies = dependencies
    }
    
    var allApps: [(app: InstalledApp, prefix: WinePrefix)] {
        var result: [(InstalledApp, WinePrefix)] = []
        for prefix in dependencies.prefixService.prefixes {
            for app in prefix.installedApps {
                result.append((app, prefix))
            }
        }
        return result
    }
    
    func launchApp(_ app: InstalledApp, in prefix: WinePrefix) async {
        do {
            try await dependencies.prefixService.launchApp(app, in: prefix)
        } catch {
            dependencies.showError(error)
        }
    }
    
    func removeApp(_ app: InstalledApp, from prefix: WinePrefix) async {
        do {
            try await dependencies.prefixService.removeApp(app, from: prefix)
        } catch {
            dependencies.showError(error)
        }
    }
}

#Preview {
    InstallAppSheet(prefix: WinePrefix(
        name: "Test",
        path: URL(fileURLWithPath: "/tmp")
    ))
    .environmentObject(Dependencies.shared)
}


