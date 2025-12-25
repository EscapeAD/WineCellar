import XCTest
@testable import WineCellar

// MARK: - ProcessResult Tests

final class ProcessResultTests: XCTestCase {
    
    func testSuccessWhenExitCodeZero() {
        let result = ProcessResult(
            exitCode: 0,
            output: "Success output",
            errorOutput: "",
            duration: 1.5
        )
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.duration, 1.5)
    }
    
    func testFailureWhenExitCodeNonZero() {
        for exitCode: Int32 in [1, -1, 127, 255] {
            let result = ProcessResult(
                exitCode: exitCode,
                output: "",
                errorOutput: "Error",
                duration: 0.1
            )
            
            XCTAssertFalse(result.isSuccess, "Exit code \(exitCode) should indicate failure")
        }
    }
    
    func testCombinedOutputOnlyStdout() {
        let result = ProcessResult(
            exitCode: 0,
            output: "Standard output",
            errorOutput: "",
            duration: 0.1
        )
        
        XCTAssertEqual(result.combinedOutput, "Standard output")
    }
    
    func testCombinedOutputOnlyStderr() {
        let result = ProcessResult(
            exitCode: 1,
            output: "",
            errorOutput: "Error output",
            duration: 0.1
        )
        
        XCTAssertEqual(result.combinedOutput, "Error output")
    }
    
    func testCombinedOutputBoth() {
        let result = ProcessResult(
            exitCode: 0,
            output: "stdout content",
            errorOutput: "stderr content",
            duration: 0.1
        )
        
        XCTAssertEqual(result.combinedOutput, "stdout content\nstderr content")
    }
    
    func testCombinedOutputBothEmpty() {
        let result = ProcessResult(
            exitCode: 0,
            output: "",
            errorOutput: "",
            duration: 0.0
        )
        
        XCTAssertEqual(result.combinedOutput, "")
    }
    
    func testDurationCaptured() {
        let result = ProcessResult(
            exitCode: 0,
            output: "",
            errorOutput: "",
            duration: 42.5
        )
        
        XCTAssertEqual(result.duration, 42.5)
    }
}

// MARK: - DownloadProgress Tests

final class DownloadProgressTests: XCTestCase {
    
    func testProgressPercentage() {
        let progress = DownloadProgress(
            bytesDownloaded: 50,
            totalBytes: 100,
            progress: 0.5
        )
        
        XCTAssertEqual(progress.percentageString, "50.0%")
    }
    
    func testProgressPercentageEdgeCases() {
        let testCases: [(Int64, Int64, Double, String)] = [
            (0, 100, 0.0, "0.0%"),
            (100, 100, 1.0, "100.0%"),
            (33, 100, 0.333, "33.3%")
        ]
        
        for (downloaded, total, progress, expected) in testCases {
            let downloadProgress = DownloadProgress(
                bytesDownloaded: downloaded,
                totalBytes: total,
                progress: progress
            )
            
            XCTAssertEqual(downloadProgress.percentageString, expected)
        }
    }
    
    func testFormattedProgressWithTotal() {
        let progress = DownloadProgress(
            bytesDownloaded: 1024 * 1024,
            totalBytes: 10 * 1024 * 1024,
            progress: 0.1
        )
        
        XCTAssertTrue(progress.formattedProgress.contains("MB"))
        XCTAssertTrue(progress.formattedProgress.contains("/"))
    }
    
    func testFormattedProgressWithoutTotal() {
        let progress = DownloadProgress(
            bytesDownloaded: 1024 * 1024,
            totalBytes: 0,
            progress: 0.0
        )
        
        XCTAssertFalse(progress.formattedProgress.contains("/"))
    }
    
    func testFormattedProgressVariousSizes() {
        // Bytes
        let bytesProgress = DownloadProgress(bytesDownloaded: 500, totalBytes: 1000, progress: 0.5)
        XCTAssertFalse(bytesProgress.formattedProgress.isEmpty)
        
        // Kilobytes
        let kbProgress = DownloadProgress(bytesDownloaded: 500 * 1024, totalBytes: 1000 * 1024, progress: 0.5)
        XCTAssertTrue(kbProgress.formattedProgress.contains("KB"))
        
        // Gigabytes
        let gbProgress = DownloadProgress(bytesDownloaded: Int64(1.5 * 1024 * 1024 * 1024), totalBytes: Int64(3 * 1024 * 1024 * 1024), progress: 0.5)
        XCTAssertTrue(gbProgress.formattedProgress.contains("GB"))
    }
    
    func testSendable() async {
        let progress = DownloadProgress(
            bytesDownloaded: 100,
            totalBytes: 200,
            progress: 0.5
        )
        
        // Test that it can be passed across concurrency boundaries
        await Task {
            XCTAssertEqual(progress.progress, 0.5)
        }.value
    }
}

// MARK: - DownloadError Tests

final class DownloadErrorTests: XCTestCase {
    
    func testHttpErrorDescription() {
        let error = DownloadError.httpError(statusCode: 404)
        
        XCTAssertTrue(error.errorDescription?.contains("404") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("HTTP") ?? false)
    }
    
    func testNoDataErrorDescription() {
        let error = DownloadError.noData
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }
    
    func testInvalidURLErrorDescription() {
        let error = DownloadError.invalidURL
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("url") ?? false)
    }
    
    func testCancelledErrorDescription() {
        let error = DownloadError.cancelled
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("cancel") ?? false)
    }
    
    func testAllErrorCasesConformToLocalizedError() {
        let errors: [DownloadError] = [
            .httpError(statusCode: 500),
            .noData,
            .invalidURL,
            .cancelled
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
}

// MARK: - DownloadService Static URLs Tests

final class DownloadServiceURLsTests: XCTestCase {
    
    func testSteamInstallerURL() {
        let url = DownloadService.steamInstallerURL
        
        XCTAssertEqual(url.scheme, "https")
        XCTAssertTrue(url.host?.contains("steam") ?? false)
        XCTAssertEqual(url.pathExtension, "exe")
    }
    
    func testWinetricksURL() {
        let url = DownloadService.winetricksURL
        
        XCTAssertEqual(url.scheme, "https")
        XCTAssertTrue(url.host?.contains("github") ?? false)
        XCTAssertEqual(url.lastPathComponent, "winetricks")
    }
    
    func testDxvkURL() {
        let url = DownloadService.dxvkURL(version: "2.4")
        
        XCTAssertEqual(url.scheme, "https")
        XCTAssertTrue(url.host?.contains("github") ?? false)
        XCTAssertTrue(url.absoluteString.contains("2.4"))
        XCTAssertEqual(url.pathExtension, "gz")
    }
    
    func testDxvkURLVersions() {
        for version in ["1.0", "2.0", "2.4", "3.0"] {
            let url = DownloadService.dxvkURL(version: version)
            
            XCTAssertTrue(url.absoluteString.contains(version))
            XCTAssertTrue(url.absoluteString.contains("dxvk-\(version)"))
        }
    }
}

// MARK: - DXVKError Tests

final class DXVKErrorTests: XCTestCase {
    
    func testDownloadFailedDescription() {
        let error = DXVKError.downloadFailed("Network timeout")
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Network timeout") ?? false)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("download") ?? false)
    }
    
    func testExtractionFailedDescription() {
        let error = DXVKError.extractionFailed("Invalid archive")
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Invalid archive") ?? false)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("extract") ?? false)
    }
    
    func testInstallationFailedDescription() {
        let error = DXVKError.installationFailed("Permission denied")
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Permission denied") ?? false)
        XCTAssertTrue(error.errorDescription?.lowercased().contains("install") ?? false)
    }
    
    func testAllDXVKErrorsConformToLocalizedError() {
        let errors: [DXVKError] = [
            .downloadFailed("test"),
            .extractionFailed("test"),
            .installationFailed("test")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
}

// MARK: - FileManager Extension Tests

final class FileManagerExtensionTests: XCTestCase {
    
    func testEmptyDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let size = try FileManager.default.allocatedSizeOfDirectory(at: tempDir)
        
        XCTAssertEqual(size, 0)
    }
    
    func testDirectoryWithFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Create test files
        let testData = Data(repeating: 0x42, count: 1000)
        try testData.write(to: tempDir.appendingPathComponent("file1.txt"))
        try testData.write(to: tempDir.appendingPathComponent("file2.txt"))
        
        let size = try FileManager.default.allocatedSizeOfDirectory(at: tempDir)
        
        XCTAssertGreaterThanOrEqual(size, 2000)
    }
    
    func testNestedDirectories() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        let subDir = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Create files in both directories
        let testData = Data(repeating: 0x42, count: 500)
        try testData.write(to: tempDir.appendingPathComponent("root.txt"))
        try testData.write(to: subDir.appendingPathComponent("nested.txt"))
        
        let size = try FileManager.default.allocatedSizeOfDirectory(at: tempDir)
        
        XCTAssertGreaterThanOrEqual(size, 1000)
    }
}
