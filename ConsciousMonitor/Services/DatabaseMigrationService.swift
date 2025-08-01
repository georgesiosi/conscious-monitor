//
//  DatabaseMigrationService.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

/// Service responsible for migrating data from JSON-based storage to SQLite
/// Handles data integrity validation and provides rollback capabilities
class DatabaseMigrationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var migrationState: MigrationState = .notStarted
    @Published var progress: Double = 0.0
    @Published var currentStep: String = ""
    @Published var error: Error?
    @Published var validationResults: ValidationResults?
    
    // MARK: - Migration State
    enum MigrationState {
        case notStarted
        case inProgress
        case validating
        case completed
        case failed
        case rolledBack
    }
    
    // MARK: - Validation Results
    struct ValidationResults {
        let totalEventsExpected: Int
        let totalEventsMigrated: Int
        let totalContextSwitchesExpected: Int
        let totalContextSwitchesMigrated: Int
        let dataIntegrityPassed: Bool
        let migrationDuration: TimeInterval
        let issues: [ValidationIssue]
    }
    
    struct ValidationIssue {
        let type: IssueType
        let description: String
        let affectedItemId: String?
        
        enum IssueType {
            case missingData
            case corruptedData
            case duplicateData
            case timestampInconsistency
        }
    }
    
    // MARK: - Dependencies
    private let eventStorageService = EventStorageService.shared
    private let sqliteStorageService = SQLiteStorageService.shared
    private let dataStorage = DataStorage.shared
    
    // MARK: - Migration Process
    
    /// Perform complete migration from JSON to SQLite with validation
    func performMigration() async {
        await MainActor.run {
            migrationState = .inProgress
            progress = 0.0
            error = nil
            currentStep = "Initializing migration..."
        }
        
        let startTime = Date()
        
        do {
            // Step 1: Create backup of existing data
            await updateProgress(0.1, "Creating backup of existing data...")
            try await createBackup()
            
            // Step 2: Load source data
            await updateProgress(0.2, "Loading existing JSON data...")
            let sourceData = try await loadSourceData()
            
            // Step 3: Validate source data integrity
            await updateProgress(0.3, "Validating source data...")
            let sourceValidation = validateSourceData(sourceData)
            if !sourceValidation.isValid {
                throw MigrationError.sourceDataCorrupted(sourceValidation.issues)
            }
            
            // Step 4: Migrate events
            await updateProgress(0.4, "Migrating app activation events...")
            try await migrateEvents(sourceData.events)
            
            // Step 5: Migrate context switches
            await updateProgress(0.6, "Migrating context switch metrics...")
            try await migrateContextSwitches(sourceData.contextSwitches)
            
            // Step 6: Validate migrated data
            await updateProgress(0.8, "Validating migrated data...")
            let validationResults = try await validateMigratedData(sourceData)
            
            await MainActor.run {
                self.validationResults = validationResults
            }
            
            if !validationResults.dataIntegrityPassed {
                throw MigrationError.validationFailed(validationResults.issues)
            }
            
            // Step 7: Finalize migration
            await updateProgress(0.9, "Finalizing migration...")
            try await finalizeMigration()
            
            // Step 8: Complete
            await updateProgress(1.0, "Migration completed successfully!")
            
            let migrationDuration = Date().timeIntervalSince(startTime)
            print("Migration completed in \(migrationDuration) seconds")
            
            await MainActor.run {
                migrationState = .completed
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                migrationState = .failed
                currentStep = "Migration failed: \(error.localizedDescription)"
            }
            
            // Attempt rollback
            try? await rollbackMigration()
        }
    }
    
    // MARK: - Source Data Loading
    
    private struct SourceData {
        let events: [AppActivationEvent]
        let contextSwitches: [ContextSwitchMetrics]
        let loadedAt: Date
        let sourceFiles: [String]
    }
    
    private func loadSourceData() async throws -> SourceData {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    // Load from EventStorageService (modern approach)
                    let events = self.eventStorageService.events
                    let contextSwitches = self.eventStorageService.contextSwitches
                    
                    // Also check legacy DataStorage for any additional data
                    let legacyEvents = self.dataStorage.loadEvents()
                    let legacyContextSwitches = self.dataStorage.loadContextSwitches()
                    
                    // Merge data, preferring EventStorageService data
                    let allEvents = self.mergeEvents(modern: events, legacy: legacyEvents)
                    let allContextSwitches = self.mergeContextSwitches(modern: contextSwitches, legacy: legacyContextSwitches)
                    
                    let sourceData = SourceData(
                        events: allEvents,
                        contextSwitches: allContextSwitches,
                        loadedAt: Date(),
                        sourceFiles: ["EventStorageService", "DataStorage (legacy)"]
                    )
                    
                    continuation.resume(returning: sourceData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func mergeEvents(modern: [AppActivationEvent], legacy: [AppActivationEvent]) -> [AppActivationEvent] {
        var eventMap: [UUID: AppActivationEvent] = [:]
        
        // Add legacy events first
        for event in legacy {
            eventMap[event.id] = event
        }
        
        // Override with modern events (they take precedence)
        for event in modern {
            eventMap[event.id] = event
        }
        
        return Array(eventMap.values).sorted { $0.timestamp < $1.timestamp }
    }
    
    private func mergeContextSwitches(modern: [ContextSwitchMetrics], legacy: [ContextSwitchMetrics]) -> [ContextSwitchMetrics] {
        var switchMap: [UUID: ContextSwitchMetrics] = [:]
        
        // Add legacy switches first
        for contextSwitch in legacy {
            switchMap[contextSwitch.id] = contextSwitch
        }
        
        // Override with modern switches
        for contextSwitch in modern {
            switchMap[contextSwitch.id] = contextSwitch
        }
        
        return Array(switchMap.values).sorted { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Data Validation
    
    private struct SourceValidation {
        let isValid: Bool
        let issues: [ValidationIssue]
        let totalEvents: Int
        let totalContextSwitches: Int
    }
    
    private func validateSourceData(_ sourceData: SourceData) -> SourceValidation {
        var issues: [ValidationIssue] = []
        
        // Check for duplicate event IDs
        let eventIds = sourceData.events.map { $0.id }
        let uniqueEventIds = Set(eventIds)
        if eventIds.count != uniqueEventIds.count {
            issues.append(ValidationIssue(
                type: .duplicateData,
                description: "Found duplicate event IDs in source data",
                affectedItemId: nil
            ))
        }
        
        // Check for duplicate context switch IDs
        let switchIds = sourceData.contextSwitches.map { $0.id }
        let uniqueSwitchIds = Set(switchIds)
        if switchIds.count != uniqueSwitchIds.count {
            issues.append(ValidationIssue(
                type: .duplicateData,
                description: "Found duplicate context switch IDs in source data",
                affectedItemId: nil
            ))
        }
        
        // Check timestamp consistency
        let sortedEvents = sourceData.events.sorted { $0.timestamp < $1.timestamp }
        for i in 1..<sortedEvents.count {
            if sortedEvents[i].timestamp < sortedEvents[i-1].timestamp {
                issues.append(ValidationIssue(
                    type: .timestampInconsistency,
                    description: "Events are not in chronological order",
                    affectedItemId: sortedEvents[i].id.uuidString
                ))
                break
            }
        }
        
        // Check for corrupted data (missing required fields)
        for event in sourceData.events {
            if event.appName?.isEmpty == true {
                issues.append(ValidationIssue(
                    type: .corruptedData,
                    description: "Event has empty app name",
                    affectedItemId: event.id.uuidString
                ))
            }
        }
        
        return SourceValidation(
            isValid: issues.isEmpty,
            issues: issues,
            totalEvents: sourceData.events.count,
            totalContextSwitches: sourceData.contextSwitches.count
        )
    }
    
    // MARK: - Migration Steps
    
    private func createBackup() async throws {
        let backupURL = getBackupURL()
        
        // Create backup directory
        try FileManager.default.createDirectory(at: backupURL.deletingLastPathComponent(),
                                              withIntermediateDirectories: true)
        
        // Backup existing data files
        let bundleID = Bundle.main.bundleIdentifier ?? "com.consciousmonitor"
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory,
                                                   in: .userDomainMask).first!
        let dataDirectory = appSupportURL.appendingPathComponent(bundleID)
        
        if FileManager.default.fileExists(atPath: dataDirectory.path) {
            try FileManager.default.copyItem(at: dataDirectory, to: backupURL)
        }
        
        print("Backup created at: \(backupURL.path)")
    }
    
    private func migrateEvents(_ events: [AppActivationEvent]) async throws {
        let batchSize = 100
        let batches = events.chunked(into: batchSize)
        
        for (index, batch) in batches.enumerated() {
            try await sqliteStorageService.addEvents(batch)
            
            let batchProgress = Double(index + 1) / Double(batches.count)
            let overallProgress = 0.4 + (batchProgress * 0.2) // Events are 40%-60% of migration
            await updateProgress(overallProgress, "Migrating events batch \(index + 1) of \(batches.count)...")
        }
    }
    
    private func migrateContextSwitches(_ contextSwitches: [ContextSwitchMetrics]) async throws {
        for (index, contextSwitch) in contextSwitches.enumerated() {
            try await sqliteStorageService.addContextSwitch(contextSwitch)
            
            if index % 50 == 0 { // Update progress every 50 items
                let progress = 0.6 + (Double(index) / Double(contextSwitches.count) * 0.2) // 60%-80%
                await updateProgress(progress, "Migrating context switches: \(index + 1)/\(contextSwitches.count)")
            }
        }
    }
    
    private func validateMigratedData(_ sourceData: SourceData) async throws -> ValidationResults {
        await MainActor.run {
            migrationState = .validating
        }
        
        // Load migrated data from SQLite
        let migratedEvents = try await sqliteStorageService.loadEvents()
        let migratedContextSwitches = try await sqliteStorageService.loadContextSwitches()
        
        var issues: [ValidationIssue] = []
        
        // Check counts match
        if migratedEvents.count != sourceData.events.count {
            issues.append(ValidationIssue(
                type: .missingData,
                description: "Event count mismatch: expected \(sourceData.events.count), got \(migratedEvents.count)",
                affectedItemId: nil
            ))
        }
        
        if migratedContextSwitches.count != sourceData.contextSwitches.count {
            issues.append(ValidationIssue(
                type: .missingData,
                description: "Context switch count mismatch: expected \(sourceData.contextSwitches.count), got \(migratedContextSwitches.count)",
                affectedItemId: nil
            ))
        }
        
        // Sample validation of data integrity
        let sampleSize = min(100, sourceData.events.count)
        for i in 0..<sampleSize {
            let sourceEvent = sourceData.events[i]
            if let migratedEvent = migratedEvents.first(where: { $0.id == sourceEvent.id }) {
                if migratedEvent.timestamp != sourceEvent.timestamp ||
                   migratedEvent.appName != sourceEvent.appName {
                    issues.append(ValidationIssue(
                        type: .corruptedData,
                        description: "Data integrity check failed for event",
                        affectedItemId: sourceEvent.id.uuidString
                    ))
                }
            }
        }
        
        let migrationDuration = Date().timeIntervalSince(sourceData.loadedAt)
        
        return ValidationResults(
            totalEventsExpected: sourceData.events.count,
            totalEventsMigrated: migratedEvents.count,
            totalContextSwitchesExpected: sourceData.contextSwitches.count,
            totalContextSwitchesMigrated: migratedContextSwitches.count,
            dataIntegrityPassed: issues.isEmpty,
            migrationDuration: migrationDuration,
            issues: issues
        )
    }
    
    private func finalizeMigration() async throws {
        // Mark migration as complete in user defaults
        UserDefaults.standard.set(true, forKey: "SQLiteMigrationCompleted")
        UserDefaults.standard.set(Date(), forKey: "SQLiteMigrationDate")
        
        // Optionally archive old JSON files instead of deleting them
        try await archiveOldDataFiles()
    }
    
    private func archiveOldDataFiles() async throws {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.consciousmonitor"
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory,
                                                   in: .userDomainMask).first!
        let dataDirectory = appSupportURL.appendingPathComponent(bundleID)
        let archiveDirectory = dataDirectory.appendingPathComponent("archived_json_data")
        
        try FileManager.default.createDirectory(at: archiveDirectory,
                                              withIntermediateDirectories: true)
        
        // Archive individual event files
        let eventFiles = try FileManager.default.contentsOfDirectory(at: dataDirectory,
                                                                    includingPropertiesForKeys: nil)
        
        for file in eventFiles {
            if file.pathExtension == "json" && !file.path.contains("archived") {
                let archiveURL = archiveDirectory.appendingPathComponent(file.lastPathComponent)
                try FileManager.default.moveItem(at: file, to: archiveURL)
            }
        }
        
        print("Archived JSON files to: \(archiveDirectory.path)")
    }
    
    // MARK: - Rollback Support
    
    private func rollbackMigration() async throws {
        await MainActor.run {
            migrationState = .rolledBack
            currentStep = "Rolling back migration..."
        }
        
        // Restore from backup if available
        let backupURL = getBackupURL()
        if FileManager.default.fileExists(atPath: backupURL.path) {
            let bundleID = Bundle.main.bundleIdentifier ?? "com.consciousmonitor"
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory,
                                                       in: .userDomainMask).first!
            let dataDirectory = appSupportURL.appendingPathComponent(bundleID)
            
            // Remove current data directory
            if FileManager.default.fileExists(atPath: dataDirectory.path) {
                try FileManager.default.removeItem(at: dataDirectory)
            }
            
            // Restore from backup
            try FileManager.default.copyItem(at: backupURL, to: dataDirectory)
            
            print("Migration rolled back successfully")
        }
        
        // Clear migration flags
        UserDefaults.standard.removeObject(forKey: "SQLiteMigrationCompleted")
        UserDefaults.standard.removeObject(forKey: "SQLiteMigrationDate")
    }
    
    // MARK: - Utility Methods
    
    private func updateProgress(_ progress: Double, _ step: String) async {
        await MainActor.run {
            self.progress = progress
            self.currentStep = step
        }
    }
    
    private func getBackupURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("ConsciousMonitor_Migration_Backup_\(Date().timeIntervalSince1970)")
    }
    
    // MARK: - Static Utility Methods
    
    /// Check if migration has been completed
    static func isMigrationCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: "SQLiteMigrationCompleted")
    }
    
    /// Get migration completion date
    static func getMigrationDate() -> Date? {
        return UserDefaults.standard.object(forKey: "SQLiteMigrationDate") as? Date
    }
}

// MARK: - Migration Errors
enum MigrationError: LocalizedError {
    case sourceDataCorrupted([DatabaseMigrationService.ValidationIssue])
    case validationFailed([DatabaseMigrationService.ValidationIssue])
    case backupFailed(Error)
    case rollbackFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .sourceDataCorrupted(let issues):
            return "Source data is corrupted: \(issues.map { $0.description }.joined(separator: ", "))"
        case .validationFailed(let issues):
            return "Migration validation failed: \(issues.map { $0.description }.joined(separator: ", "))"
        case .backupFailed(let error):
            return "Backup creation failed: \(error.localizedDescription)"
        case .rollbackFailed(let error):
            return "Rollback failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Array Extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}