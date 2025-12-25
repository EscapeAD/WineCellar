import Foundation

/// Result of a process execution
struct ProcessResult {
    let exitCode: Int32
    let output: String
    let errorOutput: String
    let duration: TimeInterval
    
    var isSuccess: Bool {
        exitCode == 0
    }
    
    var combinedOutput: String {
        if errorOutput.isEmpty {
            return output
        } else if output.isEmpty {
            return errorOutput
        } else {
            return output + "\n" + errorOutput
        }
    }
}

/// Actor for executing shell commands and Wine processes
actor ProcessRunner {
    static let shared = ProcessRunner()
    
    private init() {}
    
    // MARK: - Basic Execution
    
    /// Run a command and wait for completion
    func run(
        _ executable: String,
        arguments: [String] = [],
        environment: [String: String] = [:],
        workingDirectory: URL? = nil
    ) async throws -> ProcessResult {
        let startTime = Date()
        
        Logger.shared.debug(
            "Running: \(executable) \(arguments.joined(separator: " "))",
            category: .process
        )
        
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Merge environments
        var env = ProcessInfo.processInfo.environment
        for (key, value) in environment {
            env[key] = value
        }
        process.environment = env
        
        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = workingDirectory
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                
                process.terminationHandler = { [outputPipe, errorPipe] process in
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                    let duration = Date().timeIntervalSince(startTime)
                    
                    let result = ProcessResult(
                        exitCode: process.terminationStatus,
                        output: output.trimmingCharacters(in: .whitespacesAndNewlines),
                        errorOutput: errorOutput.trimmingCharacters(in: .whitespacesAndNewlines),
                        duration: duration
                    )
                    
                    Logger.shared.debug(
                        "Process completed: exit=\(result.exitCode), duration=\(String(format: "%.2f", duration))s",
                        category: .process
                    )
                    
                    continuation.resume(returning: result)
                }
            } catch {
                Logger.shared.error("Failed to start process: \(error)", category: .process)
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Shell Execution
    
    /// Run a shell command string
    func runShell(_ command: String, environment: [String: String] = [:]) async throws -> ProcessResult {
        try await run(
            "/bin/bash",
            arguments: ["-c", command],
            environment: environment
        )
    }
    
    // MARK: - Streaming Execution
    
    /// Run a command with streaming output
    func runWithStreaming(
        _ executable: String,
        arguments: [String] = [],
        environment: [String: String] = [:],
        workingDirectory: URL? = nil,
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws -> Int32 {
        Logger.shared.debug(
            "Running (streaming): \(executable) \(arguments.joined(separator: " "))",
            category: .process
        )
        
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Merge environments
        var env = ProcessInfo.processInfo.environment
        for (key, value) in environment {
            env[key] = value
        }
        process.environment = env
        
        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = workingDirectory
        }
        
        // Setup output streaming
        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading
        
        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                onOutput(str)
            }
        }
        
        errorHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                onOutput(str)
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                
                process.terminationHandler = { process in
                    outputHandle.readabilityHandler = nil
                    errorHandle.readabilityHandler = nil
                    
                    Logger.shared.debug(
                        "Streaming process completed: exit=\(process.terminationStatus)",
                        category: .process
                    )
                    
                    continuation.resume(returning: process.terminationStatus)
                }
            } catch {
                Logger.shared.error("Failed to start streaming process: \(error)", category: .process)
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Wine-Specific Execution
    
    /// Run a Wine command
    func runWine(
        wineBinary: URL,
        executable: String,
        arguments: [String] = [],
        prefix: URL,
        arch: WineArch,
        environment: [String: String] = [:],
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws -> Int32 {
        var env = environment
        env["WINEPREFIX"] = prefix.path
        env["WINEARCH"] = arch.rawValue
        env["WINEDEBUG"] = env["WINEDEBUG"] ?? "-all"
        
        let args = [executable] + arguments
        
        Logger.shared.info(
            "Running Wine: \(executable) in prefix \(prefix.lastPathComponent)",
            category: .wine
        )
        
        if let onOutput = onOutput {
            return try await runWithStreaming(
                wineBinary.path,
                arguments: args,
                environment: env,
                onOutput: onOutput
            )
        } else {
            let result = try await run(
                wineBinary.path,
                arguments: args,
                environment: env
            )
            return result.exitCode
        }
    }
    
    // MARK: - Utility Methods
    
    /// Check if an executable exists and is runnable
    func isExecutable(at path: String) -> Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }
    
    /// Get the version of an executable (if it supports --version)
    func getVersion(of executable: String) async -> String? {
        guard let result = try? await run(executable, arguments: ["--version"]),
              result.isSuccess else {
            return nil
        }
        
        // Parse first line of output
        return result.output.components(separatedBy: .newlines).first
    }
    
    /// Find executable in PATH
    func which(_ executable: String) async -> URL? {
        guard let result = try? await runShell("which \(executable)"),
              result.isSuccess,
              !result.output.isEmpty else {
            return nil
        }
        
        return URL(fileURLWithPath: result.output)
    }
}

