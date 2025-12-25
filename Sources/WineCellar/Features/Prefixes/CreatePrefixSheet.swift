import SwiftUI

/// Sheet for creating a new Wine prefix
struct CreatePrefixSheet: View {
    @EnvironmentObject private var dependencies: Dependencies
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var architecture: WineArch = .win64
    @State private var windowsVersion: WindowsVersion = .win10
    @State private var enableDXVK = true
    @State private var selectedWineVersion: WineVersion?
    @State private var isCreating = false
    @State private var creationProgress = ""
    @State private var showAdvanced = false
    @State private var installDependencies = true
    @State private var selectedDependencies: Set<WinetricksVerb> = [.corefonts, .vcrun2022]
    
    private var canCreate: Bool {
        !name.isEmpty && !isCreating && !dependencies.wineService.installedVersions.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create New Prefix")
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
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Basic Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Settings")
                            .font(.headline)
                        
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prefix Name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("My Windows Apps", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Architecture
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Architecture")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Architecture", selection: $architecture) {
                                ForEach(WineArch.allCases, id: \.self) { arch in
                                    Text(arch.displayName).tag(arch)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Text("64-bit is recommended for Steam and modern applications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Windows Version
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Windows Version")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Windows Version", selection: $windowsVersion) {
                                ForEach(WindowsVersion.allCases, id: \.self) { version in
                                    Text(version.displayName).tag(version)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text("Windows 10 provides the best compatibility with modern software")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Wine Version
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wine Version")
                            .font(.headline)
                        
                        if dependencies.wineService.installedVersions.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("No Wine installation found. Please install Wine first.")
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            Picker("Wine Version", selection: $selectedWineVersion) {
                                Text("Default").tag(nil as WineVersion?)
                                ForEach(dependencies.wineService.installedVersions) { version in
                                    Text("\(version.version) (\(version.source.displayName))")
                                        .tag(version as WineVersion?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    Divider()
                    
                    // DXVK
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $enableDXVK) {
                            VStack(alignment: .leading) {
                                Text("Enable DXVK")
                                    .font(.headline)
                                Text("Translates DirectX 9/10/11 to Vulkan for better game performance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Advanced Options
                    DisclosureGroup("Advanced Options", isExpanded: $showAdvanced) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Install dependencies
                            Toggle(isOn: $installDependencies) {
                                VStack(alignment: .leading) {
                                    Text("Install Common Dependencies")
                                    Text("Installs fonts and Visual C++ runtime (recommended)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if installDependencies {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Select dependencies:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 8) {
                                        ForEach([WinetricksVerb.corefonts, .vcrun2022, .vcrun2019, .d3dcompiler_47], id: \.self) { verb in
                                            Toggle(verb.displayName, isOn: Binding(
                                                get: { selectedDependencies.contains(verb) },
                                                set: { isSelected in
                                                    if isSelected {
                                                        selectedDependencies.insert(verb)
                                                    } else {
                                                        selectedDependencies.remove(verb)
                                                    }
                                                }
                                            ))
                                            .toggleStyle(.checkbox)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                if isCreating {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(creationProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Create Prefix") {
                    createPrefix()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!canCreate)
            }
            .padding()
        }
        .frame(width: 500, height: 650)
    }
    
    private func createPrefix() {
        isCreating = true
        creationProgress = "Creating prefix..."
        
        Task {
            do {
                let prefix = try await dependencies.prefixService.createPrefix(
                    name: name,
                    architecture: architecture,
                    windowsVersion: windowsVersion,
                    dxvkEnabled: enableDXVK,
                    wineVersion: selectedWineVersion
                )
                
                if installDependencies && !selectedDependencies.isEmpty {
                    creationProgress = "Installing dependencies..."
                    try await dependencies.winetricksService.install(
                        Array(selectedDependencies),
                        in: prefix,
                        wineVersion: selectedWineVersion
                    ) { progress in
                        Task { @MainActor in
                            creationProgress = progress
                        }
                    }
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    dependencies.showError(error)
                }
            }
        }
    }
}

#Preview {
    CreatePrefixSheet()
        .environmentObject(Dependencies.shared)
}

