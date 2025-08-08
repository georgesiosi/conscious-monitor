import Foundation
import Combine

// MARK: - Analysis Storage Service

class AnalysisStorageService: ObservableObject, @unchecked Sendable {
    static let shared = AnalysisStorageService() // Singleton for easy access
    
    @Published var analyses: [AnalysisEntry] = []
    
    private let analysesDirectory: URL
    private let backupDirectory: URL
    private let appDir: URL
    
    // Serial queue for thread-safe file operations
    private let fileQueue = DispatchQueue(label: "com.consciousmonitor.analysisStorage", qos: .utility)
    
    // Backup configuration
    private let maxBackupsPerFile: Int = 3
    private let backupRetentionDays: Int = 30
    
    // MARK: - Storage Error Types
    
    enum AnalysisStorageError: Error {
        case fileCorrupted(String)
        case validationFailed(String)
        case diskSpaceInsufficient
        case backupFailed(String)
        case recoveryFailed(String)
        
        var localizedDescription: String {
            switch self {
            case .fileCorrupted(let message):
                return "Analysis data corrupted: \(message)"
            case .validationFailed(let message):
                return "Analysis validation failed: \(message)"
            case .diskSpaceInsufficient:
                return "Insufficient disk space for analysis storage"
            case .backupFailed(let message):
                return "Backup failed: \(message)"
            case .recoveryFailed(let message):
                return "Recovery failed: \(message)"
            }

    // MARK: - Legacy Migration (FocusMonitor -> ConsciousMonitor)
    private func migrateLegacyAnalysesIfNeeded(appSupportDir: URL) {
        let legacyBundleIDs = [
            "com.FocusMonitor",
            "com.cstack.FocusMonitor",
            "com.example.FocusMonitor"
        ]

        let fm = FileManager.default

        for legacy in legacyBundleIDs {
            let legacyBase = appSupportDir.appendingPathComponent(legacy, isDirectory: true)
            let legacyAnalyses = legacyBase.appendingPathComponent("analyses", isDirectory: true)
            let legacyBackups = legacyBase.appendingPathComponent("analyses_backup", isDirectory: true)

            // Copy analyses files
            if fm.fileExists(atPath: legacyAnalyses.path), let files = try? fm.contentsOfDirectory(at: legacyAnalyses, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for src in files where src.pathExtension == "json" {
                    let dst = self.analysesDirectory.appendingPathComponent(src.lastPathComponent)
                    if !fm.fileExists(atPath: dst.path) {
                        do {
                            try fm.copyItem(at: src, to: dst)
                            print("AnalysisStorage: Migrated analysis file \(src.lastPathComponent) from \(legacy)")
                        } catch {
                            print("AnalysisStorage: Failed to migrate \(src.lastPathComponent): \(error.localizedDescription)")
                        }
                    }
                }
            }

            // Copy backup files
            if fm.fileExists(atPath: legacyBackups.path), let files = try? fm.contentsOfDirectory(at: legacyBackups, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for src in files where src.pathExtension == "json" {
                    let dst = self.backupDirectory.appendingPathComponent(src.lastPathComponent)
                    if !fm.fileExists(atPath: dst.path) {
                        do {
                            try fm.copyItem(at: src, to: dst)
                            print("AnalysisStorage: Migrated backup file \(src.lastPathComponent) from \(legacy)")
                        } catch {
                            print("AnalysisStorage: Failed to migrate backup \(src.lastPathComponent): \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Get the Application Support directory URL
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to get Application Support directory.")
        }
        
        // Use the same directory as DataStorage for consistency
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.ConsciousMonitor"
        let appDir = appSupportDir.appendingPathComponent(bundleID, isDirectory: true)
        
        
        // Create the app-specific directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appDir.path) {
            do {
                try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
                print("AnalysisStorage: Created Application Support directory at: \(appDir.path)")
            } catch {
                fatalError("AnalysisStorage: Unable to create Application Support directory: \(error.localizedDescription)")
            }
        }
        
        self.appDir = appDir
        self.analysesDirectory = appDir.appendingPathComponent("analyses", isDirectory: true)
        self.backupDirectory = appDir.appendingPathComponent("analyses_backup", isDirectory: true)
        
        // Create analyses subdirectory if it doesn't exist
        if !FileManager.default.fileExists(atPath: analysesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: analysesDirectory, withIntermediateDirectories: true, attributes: nil)
                print("AnalysisStorage: Created analyses directory at: \(analysesDirectory.path)")
            } catch {
                print("AnalysisStorage: Failed to create analyses directory: \(error.localizedDescription)")
            }
        }
        
        // Create backup subdirectory if it doesn't exist
        if !FileManager.default.fileExists(atPath: backupDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true, attributes: nil)
                print("AnalysisStorage: Created backup directory at: \(backupDirectory.path)")
            } catch {
                print("AnalysisStorage: Failed to create backup directory: \(error.localizedDescription)")
            }
        }
        
        // One-time migration from legacy bundle IDs (FocusMonitor variants)
        migrateLegacyAnalysesIfNeeded(appSupportDir: appSupportDir)

        // Load existing analyses on initialization
        loadAnalyses()
        
        // Start periodic backup cleanup
        startBackupCleanupTimer()
    }
    
    // MARK: - Public Methods
    
    /// Add a new analysis and save to disk
    func addAnalysis(_ analysis: AnalysisEntry) {
        
        // Save individual file first
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.saveIndividualAnalysis(analysis)
                
                // Add to memory only after successful save
                DispatchQueue.main.async {
                    self.analyses.insert(analysis, at: 0)
                }
            } catch {
                print("AnalysisStorage: Failed to save analysis file: \(error.localizedDescription)")
                self.notifyAnalysisError(error as? AnalysisStorageError ?? .fileCorrupted("Unknown error"))
            }
        }
    }
    
    /// Add a new analysis and save to disk using async/await
    func addAnalysis(_ analysis: AnalysisEntry) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            fileQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: AnalysisStorageError.fileCorrupted("Service deallocated"))
                    return
                }
                
                do {
                    try self.saveIndividualAnalysis(analysis)
                    
                    // Add to memory only after successful save
                    DispatchQueue.main.async {
                        self.analyses.insert(analysis, at: 0)
                    }
                    
                    continuation.resume()
                } catch {
                    let storageError = error as? AnalysisStorageError ?? .fileCorrupted("Failed to save analysis: \(error.localizedDescription)")
                    continuation.resume(throwing: storageError)
                }
            }
        }
    }
    
    /// Remove an analysis by ID
    func removeAnalysis(withId id: UUID) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Find the analysis to get its filename
            guard let analysis = self.analyses.first(where: { $0.id == id }) else {
                return
            }
            
            // Delete the file and its backups
            let fileURL = self.analysesDirectory.appendingPathComponent(analysis.fileName)
            do {
                try FileManager.default.removeItem(at: fileURL)
                
                // Remove backup files
                self.removeBackupFiles(for: analysis.fileName)
                
                // Remove from memory after successful file deletion
                DispatchQueue.main.async {
                    self.analyses.removeAll { $0.id == id }
                }
            } catch {
                print("AnalysisStorage: Failed to delete analysis file: \(error.localizedDescription)")
            }
        }
    }
    
    /// Remove an analysis by ID using async/await
    func removeAnalysis(withId id: UUID) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            fileQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: AnalysisStorageError.fileCorrupted("Service deallocated"))
                    return
                }
                
                // Find the analysis to get its filename
                guard let analysis = self.analyses.first(where: { $0.id == id }) else {
                    continuation.resume(throwing: AnalysisStorageError.fileCorrupted("Analysis not found"))
                    return
                }
                
                // Delete the file and its backups
                let fileURL = self.analysesDirectory.appendingPathComponent(analysis.fileName)
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    
                    // Remove backup files
                    self.removeBackupFiles(for: analysis.fileName)
                    
                    // Remove from memory after successful file deletion
                    DispatchQueue.main.async {
                        self.analyses.removeAll { $0.id == id }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: AnalysisStorageError.fileCorrupted("Failed to delete analysis: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    /// Get analyses by type
    func getAnalyses(ofType type: String) -> [AnalysisEntry] {
        return analyses.filter { $0.analysisType == type }
    }
    
    /// Get recent analyses (last 30 days)
    func getRecentAnalyses() -> [AnalysisEntry] {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        return analyses.filter { $0.timestamp > thirtyDaysAgo }
    }
    
    /// Force reload from disk
    func reloadAnalyses() {
        loadAnalyses()
    }
    
    // MARK: - Private Methods
    
    private func saveIndividualAnalysis(_ analysis: AnalysisEntry) throws {
        // Check disk space
        try checkDiskSpace()
        
        // Create file URL
        let fileURL = analysesDirectory.appendingPathComponent(analysis.fileName)
        
        // Validate analysis before saving
        try validateAnalysis(analysis)
        
        // Create backup before writing (if file exists)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try createBackup(for: analysis.fileName)
        }
        
        // Encode analysis
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(analysis)
        
        // Write atomically
        try data.write(to: fileURL, options: .atomic)
        
        // Verify written data
        try verifyWrittenData(at: fileURL, expectedData: data)
    }
    
    private func loadAnalyses() {
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let loadedAnalyses = try self.loadAnalysesFromDirectory()
                
                DispatchQueue.main.async {
                    self.analyses = loadedAnalyses.sorted { $0.timestamp > $1.timestamp }
                }
            } catch {
                print("AnalysisStorage: Error loading analyses: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self.analyses = []
                }
            }
        }
    }
    
    private func loadAnalysesFromDirectory() throws -> [AnalysisEntry] {
        guard FileManager.default.fileExists(atPath: analysesDirectory.path) else {
            return []
        }
        
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: analysesDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "json" }
        
        
        var analyses: [AnalysisEntry] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for fileURL in fileURLs {
            do {
                // Try to load from main file first
                let data = try Data(contentsOf: fileURL)
                let analysis = try decoder.decode(AnalysisEntry.self, from: data)
                
                // Validate loaded analysis
                try validateAnalysis(analysis)
                
                analyses.append(analysis)
            } catch {
                print("AnalysisStorage: Failed to load analysis from \(fileURL.lastPathComponent): \(error.localizedDescription)")
                
                // Try to recover from backup
                if let recoveredAnalysis = tryRecoverFromBackup(fileName: fileURL.lastPathComponent) {
                    analyses.append(recoveredAnalysis)
                    print("AnalysisStorage: Successfully recovered \(fileURL.lastPathComponent) from backup")
                } else {
                    print("AnalysisStorage: Failed to recover \(fileURL.lastPathComponent) from backup")
                }
            }
        }
        
        return analyses
    }
    
    
    private func checkDiskSpace() throws {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: appDir.path),
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return // Can't check, assume it's fine
        }
        
        let requiredSpace: Int64 = 10 * 1024 * 1024 // 10 MB minimum
        if freeSpace < requiredSpace {
            throw AnalysisStorageError.diskSpaceInsufficient
        }
    }
    
    // MARK: - Backup System Methods
    
    /// Create a backup of an analysis file
    private func createBackup(for fileName: String) throws {
        let originalFileURL = analysesDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: originalFileURL.path) else {
            return // No file to backup
        }
        
        // Generate backup filename with timestamp
        let backupFileName = generateBackupFileName(for: fileName)
        let backupURL = backupDirectory.appendingPathComponent(backupFileName)
        
        do {
            try FileManager.default.copyItem(at: originalFileURL, to: backupURL)
            print("AnalysisStorage: Created backup \(backupFileName)")
            
            // Clean up old backups for this file
            try cleanupOldBackups(for: fileName)
        } catch {
            throw AnalysisStorageError.backupFailed("Failed to create backup: \(error.localizedDescription)")
        }
    }
    
    /// Generate a backup filename with timestamp
    private func generateBackupFileName(for fileName: String) -> String {
        let timestamp = DateFormatter.backupTimestamp.string(from: Date())
        let nameWithoutExtension = fileName.replacingOccurrences(of: ".json", with: "")
        return "\(nameWithoutExtension).backup.\(timestamp).json"
    }
    
    /// Try to recover an analysis from backup files
    private func tryRecoverFromBackup(fileName: String) -> AnalysisEntry? {
        let backupFileNames = getBackupFileNames(for: fileName)
        
        // Try backups in reverse chronological order (newest first)
        for backupFileName in backupFileNames.reversed() {
            if let analysis = loadAnalysisFromBackup(backupFileName) {
                // Attempt to restore the main file from this backup
                do {
                    try restoreFromBackup(backupFileName: backupFileName, originalFileName: fileName)
                    return analysis
                } catch {
                    print("AnalysisStorage: Failed to restore from backup \(backupFileName): \(error.localizedDescription)")
                    continue
                }
            }
        }
        
        return nil
    }
    
    /// Load an analysis from a backup file
    private func loadAnalysisFromBackup(_ backupFileName: String) -> AnalysisEntry? {
        let backupURL = backupDirectory.appendingPathComponent(backupFileName)
        
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: backupURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let analysis = try decoder.decode(AnalysisEntry.self, from: data)
            
            // Validate recovered analysis
            try validateAnalysis(analysis)
            
            return analysis
        } catch {
            print("AnalysisStorage: Failed to load backup \(backupFileName): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Restore main file from backup
    private func restoreFromBackup(backupFileName: String, originalFileName: String) throws {
        let backupURL = backupDirectory.appendingPathComponent(backupFileName)
        let originalURL = analysesDirectory.appendingPathComponent(originalFileName)
        
        // Remove corrupted main file if it exists
        if FileManager.default.fileExists(atPath: originalURL.path) {
            try FileManager.default.removeItem(at: originalURL)
        }
        
        // Copy backup to main location
        try FileManager.default.copyItem(at: backupURL, to: originalURL)
    }
    
    /// Get all backup file names for a given analysis file
    private func getBackupFileNames(for fileName: String) -> [String] {
        let nameWithoutExtension = fileName.replacingOccurrences(of: ".json", with: "")
        let backupPrefix = "\(nameWithoutExtension).backup."
        
        do {
            let allBackupFiles = try FileManager.default.contentsOfDirectory(atPath: backupDirectory.path)
            return allBackupFiles
                .filter { $0.hasPrefix(backupPrefix) && $0.hasSuffix(".json") }
                .sorted()
        } catch {
            print("AnalysisStorage: Failed to list backup files: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Remove backup files for a deleted analysis
    private func removeBackupFiles(for fileName: String) {
        let backupFileNames = getBackupFileNames(for: fileName)
        
        for backupFileName in backupFileNames {
            let backupURL = backupDirectory.appendingPathComponent(backupFileName)
            do {
                try FileManager.default.removeItem(at: backupURL)
                print("AnalysisStorage: Removed backup file \(backupFileName)")
            } catch {
                print("AnalysisStorage: Failed to remove backup file \(backupFileName): \(error.localizedDescription)")
            }
        }
    }
    
    /// Clean up old backups, keeping only the most recent ones
    private func cleanupOldBackups(for fileName: String) throws {
        let backupFileNames = getBackupFileNames(for: fileName)
        
        // Keep only the most recent backups
        if backupFileNames.count > maxBackupsPerFile {
            let sortedBackups = backupFileNames.sorted()
            let backupsToRemove = sortedBackups.dropLast(maxBackupsPerFile)
            
            for backupToRemove in backupsToRemove {
                let backupURL = backupDirectory.appendingPathComponent(backupToRemove)
                try FileManager.default.removeItem(at: backupURL)
                print("AnalysisStorage: Removed old backup \(backupToRemove)")
            }
        }
    }
    
    /// Periodic cleanup of old backup files
    private func startBackupCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            self?.performBackupCleanup()
        }
    }
    
    /// Perform cleanup of old backup files
    private func performBackupCleanup() {
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let cutoffDate = Date().addingTimeInterval(-Double(self.backupRetentionDays) * 24 * 60 * 60)
                let allBackupFiles = try FileManager.default.contentsOfDirectory(atPath: self.backupDirectory.path)
                
                for backupFile in allBackupFiles {
                    let backupURL = self.backupDirectory.appendingPathComponent(backupFile)
                    
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: backupURL.path),
                       let creationDate = attributes[.creationDate] as? Date,
                       creationDate < cutoffDate {
                        
                        try FileManager.default.removeItem(at: backupURL)
                        print("AnalysisStorage: Removed old backup file \(backupFile)")
                    }
                }
            } catch {
                print("AnalysisStorage: Failed to perform backup cleanup: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validate an analysis entry
    private func validateAnalysis(_ analysis: AnalysisEntry) throws {
        // Check required fields
        if analysis.insights.isEmpty {
            throw AnalysisStorageError.validationFailed("Analysis insights cannot be empty")
        }
        
        if analysis.analysisType.isEmpty {
            throw AnalysisStorageError.validationFailed("Analysis type cannot be empty")
        }
        
        if analysis.dataPoints < 0 {
            throw AnalysisStorageError.validationFailed("Data points cannot be negative")
        }
        
        if analysis.dataContext.totalEvents < 0 {
            throw AnalysisStorageError.validationFailed("Total events cannot be negative")
        }
        
        if analysis.dataContext.analysisStartDate > analysis.dataContext.analysisEndDate {
            throw AnalysisStorageError.validationFailed("Analysis start date cannot be after end date")
        }
        
        // Check for reasonable timestamp (not too far in the future)
        let maxFutureDate = Date().addingTimeInterval(60 * 60) // 1 hour in future
        if analysis.timestamp > maxFutureDate {
            throw AnalysisStorageError.validationFailed("Analysis timestamp is too far in the future")
        }
    }
    
    /// Verify that written data matches expected data
    private func verifyWrittenData(at url: URL, expectedData: Data) throws {
        let writtenData = try Data(contentsOf: url)
        
        if writtenData != expectedData {
            throw AnalysisStorageError.fileCorrupted("Written data does not match expected data")
        }
    }
    
    /// Notify about analysis errors
    private func notifyAnalysisError(_ error: AnalysisStorageError) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .analysisStorageError,
                object: nil,
                userInfo: ["error": error]
            )
        }
    }
    
    // MARK: - Public Getters for Backup System
    
    /// Get the backup directory URL
    var backupDirectoryURL: URL {
        return backupDirectory
    }
    
    /// Get backup information for diagnostics
    func getBackupInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        
        do {
            let backupFiles = try FileManager.default.contentsOfDirectory(atPath: backupDirectory.path)
            info["totalBackupFiles"] = backupFiles.count
            info["backupDirectoryPath"] = backupDirectory.path
            
            // Calculate total backup size
            var totalSize: Int64 = 0
            for backupFile in backupFiles {
                let backupURL = backupDirectory.appendingPathComponent(backupFile)
                if let attributes = try? FileManager.default.attributesOfItem(atPath: backupURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
            info["totalBackupSizeBytes"] = totalSize
            
        } catch {
            info["error"] = error.localizedDescription
        }
        
        return info
    }
    
    /// Force backup cleanup (for testing/maintenance)
    func forceBackupCleanup() {
        performBackupCleanup()
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let backupTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let analysisStorageError = Notification.Name("AnalysisStorageError")
}

