//
//  SQLiteStorageService.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Foundation
import SQLite
import Combine
import SwiftUI

/// SQLite-based storage service for ConsciousMonitor
/// Provides high-performance database operations while maintaining SwiftUI reactive patterns
class SQLiteStorageService: ObservableObject, StorageServiceProtocol {
    static let shared = SQLiteStorageService()
    
    // MARK: - Published Properties for SwiftUI Integration
    @Published var events: [AppActivationEvent] = []
    @Published var contextSwitches: [ContextSwitchMetrics] = []
    @Published var isLoading: Bool = false
    @Published var migrationProgress: Double = 0.0
    @Published var lastError: Error?
    
    // MARK: - Database Connection
    private var db: Connection?
    private let dbQueue = DispatchQueue(label: "com.consciousmonitor.sqlite", qos: .utility)
    
    // MARK: - Table Definitions
    private let eventsTable = Table("app_activation_events")
    private let contextSwitchesTable = Table("context_switch_metrics")
    private let categoriesTable = Table("app_categories")
    private let sessionsTable = Table("sessions")
    private let analysisTable = Table("analysis_entries")
    
    // MARK: - Column Expressions for Events Table
    private let eventId = Expression<String>("id")
    private let timestamp = Expression<Date>("timestamp")
    private let appName = Expression<String?>("app_name")
    private let bundleIdentifier = Expression<String?>("bundle_identifier")
    private let chromeTabTitle = Expression<String?>("chrome_tab_title")
    private let chromeTabUrl = Expression<String?>("chrome_tab_url")
    private let siteDomain = Expression<String?>("site_domain")
    private let categoryName = Expression<String>("category_name")
    private let sessionId = Expression<String?>("session_id")
    private let sessionStartTime = Expression<Date?>("session_start_time")
    private let sessionEndTime = Expression<Date?>("session_end_time")
    private let isSessionStart = Expression<Bool>("is_session_start")
    private let isSessionEnd = Expression<Bool>("is_session_end")
    private let sessionSwitchCount = Expression<Int>("session_switch_count")
    private let createdAt = Expression<Date>("created_at")
    
    // MARK: - Column Expressions for Context Switches Table
    private let switchId = Expression<String>("id")
    private let fromApp = Expression<String>("from_app")
    private let toApp = Expression<String>("to_app")
    private let fromBundleId = Expression<String?>("from_bundle_id")
    private let toBundleId = Expression<String?>("to_bundle_id")
    private let switchTimestamp = Expression<Date>("timestamp")
    private let timeSpent = Expression<Double>("time_spent")
    private let switchType = Expression<String>("switch_type")
    private let fromCategory = Expression<String>("from_category")
    private let toCategory = Expression<String>("to_category")
    private let switchSessionId = Expression<String?>("session_id")
    private let switchCreatedAt = Expression<Date>("created_at")
    
    // MARK: - Prepared Statements (for performance)
    private var insertEventStatement: Statement?
    private var insertSwitchStatement: Statement?
    
    // MARK: - Database File Location
    private var databaseURL: URL {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                   in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.consciousmonitor"
        let appDirectory = appSupportURL.appendingPathComponent(bundleID)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: appDirectory, 
                                               withIntermediateDirectories: true)
        
        return appDirectory.appendingPathComponent("ConsciousMonitor.sqlite")
    }
    
    // MARK: - StorageServiceProtocol Compliance
    var storageType: StorageType { return .sqlite }
    var supportsMigrationFrom: [StorageType] { return [.json] }
    
    // MARK: - Initialization
    private init() {
        setupDatabase()
    }
    
    // MARK: - Database Setup
    private func setupDatabase() {
        dbQueue.async { [weak self] in
            self?.initializeDatabase()
        }
    }
    
    private func initializeDatabase() {
        do {
            // Connect to database
            db = try Connection(databaseURL.path)
            
            // Configure database settings
            try db?.execute("PRAGMA foreign_keys = ON")
            try db?.execute("PRAGMA journal_mode = WAL")
            try db?.execute("PRAGMA synchronous = NORMAL")
            try db?.execute("PRAGMA cache_size = 10000")
            try db?.execute("PRAGMA temp_store = MEMORY")
            
            // Create tables if they don't exist
            try createTables()
            
            // Prepare frequently used statements
            try prepareStatements()
            
            print("SQLite database initialized successfully at: \(databaseURL.path)")
            
        } catch {
            DispatchQueue.main.async {
                self.lastError = error
            }
            print("Database initialization error: \(error)")
        }
    }
    
    private func createTables() throws {
        guard let db = db else { throw DatabaseError.connectionFailed }
        
        // Create events table
        try db.run(eventsTable.create(ifNotExists: true) { t in
            t.column(eventId, primaryKey: true)
            t.column(timestamp)
            t.column(appName)
            t.column(bundleIdentifier)
            t.column(chromeTabTitle)
            t.column(chromeTabUrl)
            t.column(siteDomain)
            t.column(categoryName, defaultValue: "Other")
            t.column(sessionId)
            t.column(sessionStartTime)
            t.column(sessionEndTime)
            t.column(isSessionStart, defaultValue: false)
            t.column(isSessionEnd, defaultValue: false)
            t.column(sessionSwitchCount, defaultValue: 1)
            t.column(createdAt, defaultValue: Date())
        })
        
        // Create context switches table
        try db.run(contextSwitchesTable.create(ifNotExists: true) { t in
            t.column(switchId, primaryKey: true)
            t.column(fromApp)
            t.column(toApp)
            t.column(fromBundleId)
            t.column(toBundleId)
            t.column(switchTimestamp)
            t.column(timeSpent)
            t.column(switchType)
            t.column(fromCategory)
            t.column(toCategory)
            t.column(switchSessionId)
            t.column(switchCreatedAt, defaultValue: Date())
        })
        
        // Create indexes for performance
        try createIndexes()
    }
    
    private func createIndexes() throws {
        guard let db = db else { return }
        
        // Events table indexes
        try db.run("CREATE INDEX IF NOT EXISTS idx_events_timestamp ON app_activation_events(timestamp DESC)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_events_app_name ON app_activation_events(app_name)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_events_category ON app_activation_events(category_name)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_events_session ON app_activation_events(session_id)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_events_date ON app_activation_events(date(timestamp))")
        
        // Context switches indexes
        try db.run("CREATE INDEX IF NOT EXISTS idx_switches_timestamp ON context_switch_metrics(timestamp DESC)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_switches_apps ON context_switch_metrics(from_app, to_app)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_switches_time_spent ON context_switch_metrics(time_spent DESC)")
    }
    
    private func prepareStatements() throws {
        guard let db = db else { return }
        
        // Prepared statement for inserting events
        insertEventStatement = try db.prepare(eventsTable.insert(
            eventId <- ?,
            timestamp <- ?,
            appName <- ?,
            bundleIdentifier <- ?,
            chromeTabTitle <- ?,
            chromeTabUrl <- ?,
            siteDomain <- ?,
            categoryName <- ?,
            sessionId <- ?,
            sessionStartTime <- ?,
            sessionEndTime <- ?,
            isSessionStart <- ?,
            isSessionEnd <- ?,
            sessionSwitchCount <- ?
        ))
        
        // Prepared statement for inserting context switches
        insertSwitchStatement = try db.prepare(contextSwitchesTable.insert(
            switchId <- ?,
            fromApp <- ?,
            toApp <- ?,
            fromBundleId <- ?,
            toBundleId <- ?,
            switchTimestamp <- ?,
            timeSpent <- ?,
            switchType <- ?,
            fromCategory <- ?,
            toCategory <- ?,
            switchSessionId <- ?
        ))
    }
}

// MARK: - Event Operations
extension SQLiteStorageService {
    
    /// Add a new app activation event
    func addEvent(_ event: AppActivationEvent) async throws {
        try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let statement = self.insertEventStatement else {
                        throw DatabaseError.statementNotPrepared
                    }
                    
                    try statement.run([
                        event.id.uuidString,
                        event.timestamp,
                        event.appName,
                        event.bundleIdentifier,
                        event.chromeTabTitle,
                        event.chromeTabUrl,
                        event.siteDomain,
                        event.category.name,
                        event.sessionId?.uuidString,
                        event.sessionStartTime,
                        event.sessionEndTime,
                        event.isSessionStart,
                        event.isSessionEnd,
                        event.sessionSwitchCount
                    ])
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Add multiple events in a batch transaction
    func addEvents(_ events: [AppActivationEvent]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let db = self.db else {
                        throw DatabaseError.connectionFailed
                    }
                    
                    try db.transaction {
                        for event in events {
                            guard let statement = self.insertEventStatement else {
                                throw DatabaseError.statementNotPrepared
                            }
                            
                            try statement.run([
                                event.id.uuidString,
                                event.timestamp,
                                event.appName,
                                event.bundleIdentifier,
                                event.chromeTabTitle,
                                event.chromeTabUrl,
                                event.siteDomain,
                                event.category.name,
                                event.sessionId?.uuidString,
                                event.sessionStartTime,
                                event.sessionEndTime,
                                event.isSessionStart,
                                event.isSessionEnd,
                                event.sessionSwitchCount
                            ])
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Load events for a specific date range
    func loadEvents(from startDate: Date? = nil, to endDate: Date? = nil, limit: Int? = nil) async throws -> [AppActivationEvent] {
        return try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let db = self.db else {
                        throw DatabaseError.connectionFailed
                    }
                    
                    var query = self.eventsTable.order(self.timestamp.desc)
                    
                    // Apply date range filter
                    if let startDate = startDate {
                        query = query.filter(self.timestamp >= startDate)
                    }
                    if let endDate = endDate {
                        query = query.filter(self.timestamp <= endDate)
                    }
                    
                    // Apply limit
                    if let limit = limit {
                        query = query.limit(limit)
                    }
                    
                    let events = try db.prepare(query).compactMap { row -> AppActivationEvent? in
                        try self.eventFromRow(row)
                    }
                    
                    continuation.resume(returning: events)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Convert database row to AppActivationEvent
    private func eventFromRow(_ row: Row) throws -> AppActivationEvent? {
        guard let id = UUID(uuidString: try row.get(eventId)) else { return nil }
        
        let sessionIdString = try row.get(sessionId)
        let sessionUUID = sessionIdString.flatMap { UUID(uuidString: $0) }
        
        let categoryName = try row.get(categoryName)
        let category = AppCategory.fromName(categoryName)
        
        return AppActivationEvent(
            id: id,
            timestamp: try row.get(timestamp),
            appName: try row.get(appName),
            bundleIdentifier: try row.get(bundleIdentifier),
            chromeTabTitle: try row.get(chromeTabTitle),
            chromeTabUrl: try row.get(chromeTabUrl),
            siteDomain: try row.get(siteDomain),
            category: category,
            appIcon: nil, // Will be loaded separately
            siteFavicon: nil, // Will be loaded separately
            sessionId: sessionUUID,
            sessionStartTime: try row.get(sessionStartTime),
            sessionEndTime: try row.get(sessionEndTime),
            isSessionStart: try row.get(isSessionStart),
            isSessionEnd: try row.get(isSessionEnd),
            sessionSwitchCount: try row.get(sessionSwitchCount)
        )
    }
}

// MARK: - Context Switch Operations
extension SQLiteStorageService {
    
    /// Add a new context switch metric
    func addContextSwitch(_ contextSwitch: ContextSwitchMetrics) async throws {
        try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let statement = self.insertSwitchStatement else {
                        throw DatabaseError.statementNotPrepared
                    }
                    
                    try statement.run([
                        contextSwitch.id.uuidString,
                        contextSwitch.fromApp,
                        contextSwitch.toApp,
                        contextSwitch.fromBundleId,
                        contextSwitch.toBundleId,
                        contextSwitch.timestamp,
                        contextSwitch.timeSpent,
                        contextSwitch.switchType.rawValue,
                        contextSwitch.fromCategory.name,
                        contextSwitch.toCategory.name,
                        contextSwitch.sessionId?.uuidString
                    ])
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Load context switches for a specific date range
    func loadContextSwitches(from startDate: Date? = nil, to endDate: Date? = nil, limit: Int? = nil) async throws -> [ContextSwitchMetrics] {
        return try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let db = self.db else {
                        throw DatabaseError.connectionFailed
                    }
                    
                    var query = self.contextSwitchesTable.order(self.switchTimestamp.desc)
                    
                    // Apply date range filter
                    if let startDate = startDate {
                        query = query.filter(self.switchTimestamp >= startDate)
                    }
                    if let endDate = endDate {
                        query = query.filter(self.switchTimestamp <= endDate)
                    }
                    
                    // Apply limit
                    if let limit = limit {
                        query = query.limit(limit)
                    }
                    
                    let switches = try db.prepare(query).compactMap { row -> ContextSwitchMetrics? in
                        try self.contextSwitchFromRow(row)
                    }
                    
                    continuation.resume(returning: switches)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Convert database row to ContextSwitchMetrics
    private func contextSwitchFromRow(_ row: Row) throws -> ContextSwitchMetrics? {
        guard let id = UUID(uuidString: try row.get(switchId)) else { return nil }
        
        let sessionIdString = try row.get(switchSessionId)
        let sessionUUID = sessionIdString.flatMap { UUID(uuidString: $0) }
        
        let switchTypeString = try row.get(switchType)
        let switchTypeEnum = SwitchType(rawValue: switchTypeString) ?? .normal
        
        let fromCategoryName = try row.get(fromCategory)
        let toCategoryName = try row.get(toCategory)
        let fromCategoryEnum = AppCategory.fromName(fromCategoryName)
        let toCategoryEnum = AppCategory.fromName(toCategoryName)
        
        return ContextSwitchMetrics(
            id: id,
            fromApp: try row.get(fromApp),
            toApp: try row.get(toApp),
            fromBundleId: try row.get(fromBundleId),
            toBundleId: try row.get(toBundleId),
            timestamp: try row.get(switchTimestamp),
            timeSpent: try row.get(timeSpent),
            switchType: switchTypeEnum,
            fromCategory: fromCategoryEnum,
            toCategory: toCategoryEnum,
            sessionId: sessionUUID
        )
    }
}

// MARK: - Migration Support
extension SQLiteStorageService {
    
    /// Migrate data from EventStorageService to SQLite
    func migrateFromEventStorageService() async throws {
        await MainActor.run {
            isLoading = true
            migrationProgress = 0.0
        }
        
        do {
            // Load existing data from EventStorageService
            let existingEvents = EventStorageService.shared.events
            let existingContextSwitches = EventStorageService.shared.contextSwitches
            
            let totalItems = existingEvents.count + existingContextSwitches.count
            var processedItems = 0
            
            // Migrate events in batches
            let eventBatches = existingEvents.chunked(into: 100)
            for batch in eventBatches {
                try await addEvents(batch)
                processedItems += batch.count
                
                await MainActor.run {
                    migrationProgress = Double(processedItems) / Double(totalItems)
                }
            }
            
            // Migrate context switches in batches
            for contextSwitch in existingContextSwitches {
                try await addContextSwitch(contextSwitch)
                processedItems += 1
                
                await MainActor.run {
                    migrationProgress = Double(processedItems) / Double(totalItems)
                }
            }
            
            await MainActor.run {
                isLoading = false
                migrationProgress = 1.0
            }
            
            print("Migration completed successfully: \(existingEvents.count) events, \(existingContextSwitches.count) context switches")
            
        } catch {
            await MainActor.run {
                isLoading = false
                lastError = error
            }
            throw error
        }
    }
}

// MARK: - Analytics Queries
extension SQLiteStorageService {
    
    /// Get app usage statistics for a specific date range
    func getAppUsageStats(from startDate: Date, to endDate: Date) async throws -> [AppUsageStat] {
        return try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let db = self.db else {
                        throw DatabaseError.connectionFailed
                    }
                    
                    let query = """
                        SELECT app_name, bundle_identifier, category_name,
                               COUNT(*) as activation_count,
                               MAX(timestamp) as last_activation
                        FROM app_activation_events 
                        WHERE timestamp BETWEEN ? AND ? 
                          AND app_name IS NOT NULL
                        GROUP BY app_name, bundle_identifier, category_name
                        ORDER BY activation_count DESC
                    """
                    
                    let statement = try db.prepare(query)
                    var stats: [AppUsageStat] = []
                    
                    for row in try statement.run([startDate, endDate]) {
                        let appName = row[0] as? String ?? "Unknown"
                        let bundleId = row[1] as? String
                        let categoryName = row[2] as? String ?? "Other"
                        let activationCount = row[3] as? Int64 ?? 0
                        let lastActive = row[4] as? Date ?? Date()
                        
                        let category = AppCategory.fromName(categoryName)
                        
                        let stat = AppUsageStat(
                            id: UUID(),
                            appName: appName,
                            bundleIdentifier: bundleId,
                            activationCount: Int(activationCount),
                            lastActiveTimestamp: lastActive,
                            category: category,
                            siteBreakdown: nil // TODO: Implement site breakdown
                        )
                        
                        stats.append(stat)
                    }
                    
                    continuation.resume(returning: stats)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Database Errors
enum DatabaseError: LocalizedError {
    case connectionFailed
    case statementNotPrepared
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to database"
        case .statementNotPrepared:
            return "Database statement not prepared"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        }
    }
}

// MARK: - Array Extension for Batching
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - AppCategory Extension for Name-based Lookup
extension AppCategory {
    static func fromName(_ name: String) -> AppCategory {
        // Map common category names to predefined categories
        switch name.lowercased() {
        case "productivity":
            return .productivity
        case "communication":
            return .communication
        case "social media":
            return .socialMedia
        case "development":
            return .development
        case "entertainment":
            return .entertainment
        case "design":
            return .design
        case "utilities":
            return .utilities
        case "education":
            return .education
        case "finance":
            return .finance
        case "health & fitness", "health":
            return .health
        case "lifestyle":
            return .lifestyle
        case "news":
            return .news
        case "shopping":
            return .shopping
        case "travel":
            return .travel
        case "knowledge management":
            return .knowledgeManagement
        case "other":
            return .other
        default:
            // Create a custom category for unknown names
            return AppCategory(id: UUID(), name: name)
        }
    }
}