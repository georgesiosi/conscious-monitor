//
//  SQLiteDatabaseManager.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Foundation
import SQLite3
import Combine
import AppKit

/// macOS-optimized SQLite database manager for ConsciousMonitor
/// Handles database file creation, backup, recovery, and macOS-specific optimizations
class SQLiteDatabaseManager: ObservableObject {
    nonisolated(unsafe) static let shared = SQLiteDatabaseManager()
    
    // MARK: - Published Properties
    @Published var databaseStatus: DatabaseStatus = .notInitialized
    @Published var backupStatus: BackupStatus = .idle
    @Published var errorMessage: String?
    
    // MARK: - Database Status Types
    enum DatabaseStatus {
        case notInitialized
        case initializing
        case ready
        case error(String)
        case migrating
        case corrupted
    }
    
    enum BackupStatus {
        case idle
        case creating
        case completed(Date)
        case failed(String)
    }
    
    // MARK: - Database Configuration
    private let databaseName = "conscious_monitor.db"
    private let backupRetentionDays = 30
    private let maxBackupFiles = 10
    
    // MARK: - File URLs
    private let appDir: URL
    private let databasesDir: URL
    private let backupsDir: URL
    private let databaseURL: URL
    
    // MARK: - SQLite Connection
    private var db: OpaquePointer?
    private let fileQueue = DispatchQueue(label: "com.consciousmonitor.sqlite", qos: .utility)
    
    // MARK: - Error Types
    enum DatabaseError: Error, LocalizedError {
        case initializationFailed(String)
        case connectionFailed(String)
        case corruptedDatabase(String)
        case backupFailed(String)
        case recoveryFailed(String)
        case migrationFailed(String)
        case diskSpaceInsufficient
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .initializationFailed(let message):
                return "Database initialization failed: \(message)"
            case .connectionFailed(let message):
                return "Database connection failed: \(message)"
            case .corruptedDatabase(let message):
                return "Database corrupted: \(message)"
            case .backupFailed(let message):
                return "Backup failed: \(message)"
            case .recoveryFailed(let message):
                return "Recovery failed: \(message)"
            case .migrationFailed(let message):
                return "Migration failed: \(message)"
            case .diskSpaceInsufficient:
                return "Insufficient disk space for database operations"
            case .permissionDenied:
                return "Permission denied for database access"
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Get Application Support directory
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to get Application Support directory")
        }
        
        let bundleID = Bundle.main.bundleIdentifier ?? "com.consciousmonitor.app"
        self.appDir = appSupportDir.appendingPathComponent(bundleID, isDirectory: true)
        self.databasesDir = appDir.appendingPathComponent("databases", isDirectory: true)
        self.backupsDir = databasesDir.appendingPathComponent("backups", isDirectory: true)
        self.databaseURL = databasesDir.appendingPathComponent(databaseName)
        
        createDirectoryStructure()
        setupPeriodicMaintenance()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Directory Setup
    private func createDirectoryStructure() {
        let directories = [appDir, databasesDir, backupsDir]
        
        for directory in directories {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                print("SQLiteManager: Created directory: \(directory.path)")
            } catch {
                print("SQLiteManager: Failed to create directory \(directory.path): \(error)")
            }
        }
    }
    
    // MARK: - Database Initialization
    func initializeDatabase() async throws {
        await MainActor.run {
            databaseStatus = .initializing
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            fileQueue.async { @Sendable [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: DatabaseError.initializationFailed("Manager deallocated"))
                    return
                }
                
                do {
                    try self.performDatabaseInitialization()
                    DispatchQueue.main.async {
                        self.databaseStatus = .ready
                    }
                    continuation.resume()
                } catch {
                    DispatchQueue.main.async {
                        self.databaseStatus = .error(error.localizedDescription)
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func performDatabaseInitialization() throws {
        // Check disk space first
        try checkDiskSpace()
        
        // Check for existing database and verify integrity
        if FileManager.default.fileExists(atPath: databaseURL.path) {
            if !verifyDatabaseIntegrity() {
                print("SQLiteManager: Database corruption detected, attempting recovery")
                try recoverFromBackup()
            }
        }
        
        // Open or create database
        try openDatabase()
        
        // Apply macOS-specific optimizations
        try applyMacOSOptimizations()
        
        // Create tables if needed
        try createTables()
        
        print("SQLiteManager: Database initialization completed")
    }
    
    private func openDatabase() throws {
        closeDatabase() // Ensure clean state
        
        let result = sqlite3_open_v2(
            databaseURL.path,
            &db,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        
        guard result == SQLITE_OK else {
            throw DatabaseError.connectionFailed("SQLite error: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        print("SQLiteManager: Database opened: \(databaseURL.path)")
    }
    
    private func closeDatabase() {
        if let db = db {
            sqlite3_close_v2(db)
            self.db = nil
        }
    }
    
    // MARK: - macOS-Specific Optimizations
    private func applyMacOSOptimizations() throws {
        let pragmas = [
            // Enable WAL mode for better performance and crash recovery
            "PRAGMA journal_mode = WAL;",
            
            // Optimize for macOS SSD performance
            "PRAGMA synchronous = NORMAL;",  // Balance safety vs performance
            "PRAGMA cache_size = 10000;",    // 10MB cache for better performance
            "PRAGMA temp_store = MEMORY;",   // Store temp data in memory
            
            // macOS filesystem optimizations
            "PRAGMA mmap_size = 268435456;", // 256MB memory mapping
            "PRAGMA page_size = 4096;",      // Match macOS page size
            
            // Security and integrity
            "PRAGMA foreign_keys = ON;",     // Enable foreign key constraints
            "PRAGMA secure_delete = ON;",    // Secure deletion for privacy
            
            // Performance tuning
            "PRAGMA optimize;",              // Optimize query planner
            "PRAGMA analysis_limit = 1000;", // Limit ANALYZE scope
        ]
        
        for pragma in pragmas {
            let result = sqlite3_exec(db, pragma, nil, nil, nil)
            if result != SQLITE_OK {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("SQLiteManager: Warning - PRAGMA failed: \(pragma) - \(errorMsg)")
                // Continue with other pragmas even if one fails
            }
        }
        
        print("SQLiteManager: Applied macOS-specific optimizations")
    }
    
    // MARK: - Database Integrity
    private func verifyDatabaseIntegrity() -> Bool {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            return false
        }
        
        var checkDb: OpaquePointer?
        let result = sqlite3_open_v2(databaseURL.path, &checkDb, SQLITE_OPEN_READONLY, nil)
        
        guard result == SQLITE_OK else {
            sqlite3_close_v2(checkDb)
            return false
        }
        
        defer { sqlite3_close_v2(checkDb) }
        
        // Run integrity check
        var statement: OpaquePointer?
        let integrityCheck = "PRAGMA integrity_check;"
        
        guard sqlite3_prepare_v2(checkDb, integrityCheck, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let result = String(cString: sqlite3_column_text(statement, 0))
            let isIntact = result == "ok"
            print("SQLiteManager: Integrity check result: \(result)")
            return isIntact
        }
        
        return false
    }
    
    // MARK: - Backup System
    func createBackup() async throws {
        await MainActor.run {
            backupStatus = .creating
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            fileQueue.async { @Sendable [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: DatabaseError.backupFailed("Manager deallocated"))
                    return
                }
                
                do {
                    try self.performBackup()
                    let backupDate = Date()
                    DispatchQueue.main.async {
                        self.backupStatus = .completed(backupDate)
                    }
                    continuation.resume()
                } catch {
                    DispatchQueue.main.async {
                        self.backupStatus = .failed(error.localizedDescription)
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func performBackup() throws {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            throw DatabaseError.backupFailed("No database file to backup")
        }
        
        // Check disk space
        try checkDiskSpace(requiredMultiplier: 2.0) // Need space for original + backup
        
        // Create backup filename with timestamp
        let timestamp = DateFormatter.backupTimestamp.string(from: Date())
        let backupName = "conscious_monitor_backup_\(timestamp).db"
        let backupURL = backupsDir.appendingPathComponent(backupName)
        
        // Copy database file
        try FileManager.default.copyItem(at: databaseURL, to: backupURL)
        
        // Also backup WAL and SHM files if they exist
        let walURL = databaseURL.appendingPathExtension("wal")
        let shmURL = databaseURL.appendingPathExtension("shm")
        
        if FileManager.default.fileExists(atPath: walURL.path) {
            let backupWalURL = backupURL.appendingPathExtension("wal")
            try? FileManager.default.copyItem(at: walURL, to: backupWalURL)
        }
        
        if FileManager.default.fileExists(atPath: shmURL.path) {
            let backupShmURL = backupURL.appendingPathExtension("shm")
            try? FileManager.default.copyItem(at: shmURL, to: backupShmURL)
        }
        
        print("SQLiteManager: Backup created: \(backupURL.path)")
        
        // Cleanup old backups
        try cleanupOldBackups()
    }
    
    // MARK: - Recovery System
    private func recoverFromBackup() throws {
        let backupFiles = try getBackupFiles()
        
        guard !backupFiles.isEmpty else {
            throw DatabaseError.recoveryFailed("No backup files available")
        }
        
        // Try backups in reverse chronological order (newest first)
        for backupURL in backupFiles.reversed() {
            print("SQLiteManager: Attempting recovery from \(backupURL.lastPathComponent)")
            
            do {
                // Test backup integrity before using it
                if verifyBackupIntegrity(backupURL) {
                    try restoreFromBackup(backupURL)
                    print("SQLiteManager: Successfully recovered from \(backupURL.lastPathComponent)")
                    return
                }
            } catch {
                print("SQLiteManager: Failed to restore from \(backupURL.lastPathComponent): \(error)")
                continue
            }
        }
        
        throw DatabaseError.recoveryFailed("All backup files are corrupted or unusable")
    }
    
    private func verifyBackupIntegrity(_ backupURL: URL) -> Bool {
        var checkDb: OpaquePointer?
        let result = sqlite3_open_v2(backupURL.path, &checkDb, SQLITE_OPEN_READONLY, nil)
        
        guard result == SQLITE_OK else {
            sqlite3_close_v2(checkDb)
            return false
        }
        
        defer { sqlite3_close_v2(checkDb) }
        
        // Quick integrity check
        var statement: OpaquePointer?
        let quickCheck = "PRAGMA quick_check;"
        
        guard sqlite3_prepare_v2(checkDb, quickCheck, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let result = String(cString: sqlite3_column_text(statement, 0))
            return result == "ok"
        }
        
        return false
    }
    
    private func restoreFromBackup(_ backupURL: URL) throws {
        // Remove corrupted database
        if FileManager.default.fileExists(atPath: databaseURL.path) {
            try FileManager.default.removeItem(at: databaseURL)
        }
        
        // Remove associated WAL and SHM files
        let walURL = databaseURL.appendingPathExtension("wal")
        let shmURL = databaseURL.appendingPathExtension("shm")
        
        try? FileManager.default.removeItem(at: walURL)
        try? FileManager.default.removeItem(at: shmURL)
        
        // Copy backup to main location
        try FileManager.default.copyItem(at: backupURL, to: databaseURL)
        
        // Restore associated files if they exist
        let backupWalURL = backupURL.appendingPathExtension("wal")
        let backupShmURL = backupURL.appendingPathExtension("shm")
        
        if FileManager.default.fileExists(atPath: backupWalURL.path) {
            try? FileManager.default.copyItem(at: backupWalURL, to: walURL)
        }
        
        if FileManager.default.fileExists(atPath: backupShmURL.path) {
            try? FileManager.default.copyItem(at: backupShmURL, to: shmURL)
        }
    }
    
    // MARK: - Maintenance
    private func setupPeriodicMaintenance() {
        // Setup system event monitoring first
        setupSystemEventMonitoring()
        
        // Daily maintenance timer
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performMaintenance()
            }
        }
    }
    
    private func performMaintenance() async {
        fileQueue.async { @Sendable [weak self] in
            guard let self = self else { return }
            
            do {
                // Cleanup old backups
                try self.cleanupOldBackups()
                
                // Optimize database
                try self.optimizeDatabase()
                
                // Update statistics
                try self.updateDatabaseStatistics()
                
                print("SQLiteManager: Daily maintenance completed")
            } catch {
                print("SQLiteManager: Maintenance failed: \(error)")
            }
        }
    }
    
    private func optimizeDatabase() throws {
        guard let db = db else { return }
        
        let optimizeCommands = [
            "PRAGMA optimize;",
            "VACUUM;",
            "ANALYZE;"
        ]
        
        for command in optimizeCommands {
            let result = sqlite3_exec(db, command, nil, nil, nil)
            if result != SQLITE_OK {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                print("SQLiteManager: Optimization command failed: \(command) - \(errorMsg)")
            }
        }
    }
    
    private func updateDatabaseStatistics() throws {
        guard let db = db else { return }
        
        let result = sqlite3_exec(db, "ANALYZE;", nil, nil, nil)
        if result != SQLITE_OK {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.initializationFailed("Failed to update statistics: \(errorMsg)")
        }
    }
    
    // MARK: - Helper Methods
    private func checkDiskSpace(requiredMultiplier: Double = 1.0) throws {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: appDir.path),
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return // Can't check, assume it's fine
        }
        
        // Calculate required space (current DB size * multiplier + 50MB buffer)
        var requiredSpace: Int64 = 50 * 1024 * 1024 // 50MB buffer
        
        if FileManager.default.fileExists(atPath: databaseURL.path) {
            if let dbAttributes = try? FileManager.default.attributesOfItem(atPath: databaseURL.path),
               let dbSize = dbAttributes[.size] as? Int64 {
                requiredSpace += Int64(Double(dbSize) * requiredMultiplier)
            }
        }
        
        if freeSpace < requiredSpace {
            throw DatabaseError.diskSpaceInsufficient
        }
    }
    
    private func getBackupFiles() throws -> [URL] {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "db" }
        
        // Sort by creation date
        return fileURLs.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return date1 < date2
        }
    }
    
    private func cleanupOldBackups() throws {
        let backupFiles = try getBackupFiles()
        let cutoffDate = Date().addingTimeInterval(-Double(backupRetentionDays) * 24 * 60 * 60)
        
        // Remove files older than retention period
        for backupURL in backupFiles {
            if let resourceValues = try? backupURL.resourceValues(forKeys: [.creationDateKey]),
               let creationDate = resourceValues.creationDate,
               creationDate < cutoffDate {
                
                try FileManager.default.removeItem(at: backupURL)
                print("SQLiteManager: Removed old backup: \(backupURL.lastPathComponent)")
            }
        }
        
        // Also enforce max backup count
        let remainingFiles = try getBackupFiles()
        if remainingFiles.count > maxBackupFiles {
            let filesToRemove = remainingFiles.dropLast(maxBackupFiles)
            for fileURL in filesToRemove {
                try FileManager.default.removeItem(at: fileURL)
                print("SQLiteManager: Removed excess backup: \(fileURL.lastPathComponent)")
            }
        }
    }
    
    private func createTables() throws {
        // This will be implemented when we create the actual schema
        // For now, just ensure the database is accessible
        let testQuery = "SELECT sqlite_version();"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, testQuery, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.initializationFailed("Failed to prepare test query")
        }
        
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let version = String(cString: sqlite3_column_text(statement, 0))
            print("SQLiteManager: SQLite version: \(version)")
        }
    }
    
    // MARK: - Public Getters
    var databaseFileURL: URL {
        return databaseURL
    }
    
    var backupDirectoryURL: URL {
        return backupsDir
    }
    
    var isReady: Bool {
        if case .ready = databaseStatus {
            return true
        }
        return false
    }
    
    // MARK: - Diagnostic Information
    func getDatabaseInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        
        info["databasePath"] = databaseURL.path
        info["backupDirectory"] = backupsDir.path
        info["status"] = "\(databaseStatus)"
        info["backupStatus"] = "\(backupStatus)"
        
        // File size information
        if let attributes = try? FileManager.default.attributesOfItem(atPath: databaseURL.path),
           let fileSize = attributes[.size] as? Int64 {
            info["databaseSizeBytes"] = fileSize
            info["databaseSizeMB"] = Double(fileSize) / (1024 * 1024)
        }
        
        // Backup count
        do {
            let backupFiles = try getBackupFiles()
            info["backupCount"] = backupFiles.count
            if let oldestBackup = backupFiles.first {
                let resourceValues = try? oldestBackup.resourceValues(forKeys: [.creationDateKey])
                info["oldestBackupDate"] = resourceValues?.creationDate?.ISO8601Format()
            }
            if let newestBackup = backupFiles.last {
                let resourceValues = try? newestBackup.resourceValues(forKeys: [.creationDateKey])
                info["newestBackupDate"] = resourceValues?.creationDate?.ISO8601Format()
            }
        } catch {
            info["backupError"] = error.localizedDescription
        }
        
        return info
    }
}

// MARK: - Extensions

// Note: backupTimestamp DateFormatter extension is defined in AnalysisStorageService.swift

// MARK: - Notification Extensions

extension Notification.Name {
    static let sqliteDatabaseError = Notification.Name("SQLiteDatabaseError")
    static let sqliteBackupCompleted = Notification.Name("SQLiteBackupCompleted")
    static let sqliteRecoveryCompleted = Notification.Name("SQLiteRecoveryCompleted")
    static let sqliteMaintenanceCompleted = Notification.Name("SQLiteMaintenanceCompleted")
}

// MARK: - macOS Integration Extensions

extension SQLiteDatabaseManager {
    
    /// Handle macOS system events that might affect database operations
    func handleSystemEvent(_ event: SystemEvent) {
        fileQueue.async { @Sendable [weak self] in
            guard let self = self else { return }
            
            switch event {
            case .systemWillSleep:
                // Checkpoint WAL before sleep
                if let db = self.db {
                    sqlite3_exec(db, "PRAGMA wal_checkpoint(FULL);", nil, nil, nil)
                    print("SQLiteManager: WAL checkpointed before system sleep")
                }
                
            case .systemDidWake:
                // Verify database integrity after wake
                if !self.verifyDatabaseIntegrity() {
                    print("SQLiteManager: Database integrity check failed after wake")
                    DispatchQueue.main.async {
                        self.databaseStatus = .corrupted
                    }
                }
                
            case .lowDiskSpace:
                // Trigger maintenance to free up space
                Task {
                    await self.performMaintenance()
                }
                
            case .systemWillTerminate:
                // Ensure clean shutdown
                if let db = self.db {
                    sqlite3_exec(db, "PRAGMA wal_checkpoint(FULL);", nil, nil, nil)
                    sqlite3_exec(db, "PRAGMA optimize;", nil, nil, nil)
                }
                self.closeDatabase()
            }
        }
    }
    
    /// Setup system event monitoring
    func setupSystemEventMonitoring() {
        // Monitor system sleep/wake
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemEvent(.systemWillSleep)
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemEvent(.systemDidWake)
        }
        
        // Monitor application termination
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemEvent(.systemWillTerminate)
        }
    }
}

// MARK: - System Event Types

enum SystemEvent {
    case systemWillSleep
    case systemDidWake
    case lowDiskSpace
    case systemWillTerminate
}

// MARK: - Database Health Monitoring

extension SQLiteDatabaseManager {
    
    /// Perform health check on database
    func performHealthCheck() async -> DatabaseHealthReport {
        return await withCheckedContinuation { continuation in
            fileQueue.async { @Sendable [weak self] in
                guard let self = self else {
                    continuation.resume(returning: DatabaseHealthReport.failed("Manager not available"))
                    return
                }
                
                let integrityOK = self.verifyDatabaseIntegrity()
                let totalSize = self.getTotalDatabaseSize()
                let backupCount = (try? self.getBackupFiles().count) ?? 0
                
                let report = DatabaseHealthReport(
                    isHealthy: integrityOK,
                    totalSize: totalSize,
                    backupCount: backupCount,
                    lastMaintenanceDate: nil, // TODO: Track maintenance dates
                    issues: integrityOK ? [] : ["Database integrity check failed"]
                )
                
                continuation.resume(returning: report)
            }
        }
    }
    
    /// Get total database size in bytes
    private func getTotalDatabaseSize() -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: databaseURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}

// MARK: - Database Health Report

struct DatabaseHealthReport {
    let isHealthy: Bool
    let totalSize: Int64
    let backupCount: Int
    let lastMaintenanceDate: Date?
    let issues: [String]
    
    var sizeInMB: Double {
        return Double(totalSize) / (1024 * 1024)
    }
    
    var healthStatus: String {
        if isHealthy {
            return "Healthy"
        } else {
            return "Issues Detected"
        }
    }
    
    static func failed(_ reason: String) -> DatabaseHealthReport {
        return DatabaseHealthReport(
            isHealthy: false,
            totalSize: 0,
            backupCount: 0,
            lastMaintenanceDate: nil,
            issues: [reason]
        )
    }
}
