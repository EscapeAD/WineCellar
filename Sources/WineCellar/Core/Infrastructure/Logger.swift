import Foundation
import os.log

/// Centralized logging utility using OSLog
final class Logger {
    static let shared = Logger()
    
    private let subsystem = "com.winecellar.app"
    
    private lazy var loggers: [Category: os.Logger] = {
        var dict = [Category: os.Logger]()
        for category in Category.allCases {
            dict[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
        return dict
    }()
    
    private let logFileURL: URL
    private let fileHandle: FileHandle?
    private let dateFormatter: DateFormatter
    
    private init() {
        // Setup date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Setup log file
        let logsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs")
            .appendingPathComponent("WineCellar")
        
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        logFileURL = logsDirectory.appendingPathComponent("winecellar-\(dateString).log")
        
        // Create file if needed
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
        
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        fileHandle?.seekToEndOfFile()
    }
    
    deinit {
        try? fileHandle?.close()
    }
    
    // MARK: - Public API
    
    func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Private
    
    private func log(level: Level, message: String, category: Category, file: String, function: String, line: Int) {
        let logger = loggers[category]!
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let contextInfo = "[\(fileName):\(line) \(function)]"
        
        // Log to OSLog
        switch level {
        case .debug:
            logger.debug("\(contextInfo) \(message)")
        case .info:
            logger.info("\(contextInfo) \(message)")
        case .warning:
            logger.warning("\(contextInfo) \(message)")
        case .error:
            logger.error("\(contextInfo) \(message)")
        }
        
        // Log to file
        writeToFile(level: level, category: category, message: message, context: contextInfo)
    }
    
    private func writeToFile(level: Level, category: Category, message: String, context: String) {
        let timestamp = dateFormatter.string(from: Date())
        let logLine = "[\(timestamp)] [\(level.rawValue.uppercased())] [\(category.rawValue)] \(context) \(message)\n"
        
        if let data = logLine.data(using: .utf8) {
            fileHandle?.write(data)
        }
    }
    
    /// Get the path to the current log file
    var currentLogFilePath: URL {
        logFileURL
    }
    
    /// Get all log files
    func getAllLogFiles() -> [URL] {
        let logsDirectory = logFileURL.deletingLastPathComponent()
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        
        return contents.filter { $0.pathExtension == "log" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return date1 > date2
            }
    }
}

// MARK: - Log Level
extension Logger {
    enum Level: String {
        case debug
        case info
        case warning
        case error
    }
}

// MARK: - Log Category
extension Logger {
    enum Category: String, CaseIterable {
        case general
        case app
        case wine
        case prefix
        case process
        case download
        case steam
        case ui
    }
}


