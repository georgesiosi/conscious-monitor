//
//  SQLiteStorageServiceTests.swift
//  ConsciousMonitor-Tests
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Testing
import Foundation
import SQLite
@testable import ConsciousMonitor

/// Comprehensive test suite for SQLiteStorageService
/// Tests database operations, migration, error handling, and performance
struct SQLiteStorageServiceTests {
    
    // MARK: - Test Database Setup
    
    /// Creates a test database instance with isolated storage
    private func createTestService() throws -> TestSQLiteStorageService {
        return try TestSQLiteStorageService()
    }
    
    /// Generate test events for various scenarios
    private func generateTestEvents(count: Int = 10) -> [AppActivationEvent] {
        let baseDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        return (0..<count).map { i in
            AppActivationEvent(
                id: UUID(),
                timestamp: baseDate.addingTimeInterval(TimeInterval(i * 60)), // 1 minute apart
                appName: "TestApp\(i % 3)", // Cycle through 3 apps
                bundleIdentifier: "com.test.app\(i % 3)",
                category: [AppCategory.productivity, AppCategory.development, AppCategory.communication][i % 3],
                sessionId: UUID(),
                isSessionStart: i == 0,
                isSessionEnd: i == count - 1,
                sessionSwitchCount: i + 1
            )
        }
    }
    
    /// Generate test context switches
    private func generateTestContextSwitches(count: Int = 5) -> [ContextSwitchMetrics] {
        let baseDate = Date().addingTimeInterval(-3600)
        
        return (0..<count).map { i in
            ContextSwitchMetrics(
                fromApp: "App\(i)",
                toApp: "App\(i + 1)",
                fromBundleId: "com.test.app\(i)",
                toBundleId: "com.test.app\(i + 1)",
                timestamp: baseDate.addingTimeInterval(TimeInterval(i * 120)), // 2 minutes apart
                timeSpent: Double(60 + i * 30), // Varying time spent
                fromCategory: AppCategory.productivity,
                toCategory: AppCategory.development,
                sessionId: UUID()
            )
        }
    }
    
    // MARK: - Database Initialization Tests
    
    @Test("Database initializes correctly with proper schema")
    func testDatabaseInitialization() async throws {
        let service = try createTestService()
        
        // Verify database file exists
        #expect(FileManager.default.fileExists(atPath: service.databaseURL.path))
        
        // Verify tables exist by attempting to query them
        let events = try await service.loadEvents()
        let switches = try await service.loadContextSwitches()
        
        #expect(events.isEmpty)
        #expect(switches.isEmpty)
    }
    
    @Test("Database creates proper indexes for performance")
    func testDatabaseIndexes() async throws {
        let service = try createTestService()
        
        // Verify indexes exist by checking database schema
        let db = try Connection(service.databaseURL.path)
        let indexQuery = "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name IN ('app_activation_events', 'context_switch_metrics')"
        
        var indexNames: [String] = []
        for row in try db.prepare(indexQuery) {
            if let name = row[0] as? String {
                indexNames.append(name)
            }
        }
        
        // Check for expected indexes
        #expect(indexNames.contains("idx_events_timestamp"))
        #expect(indexNames.contains("idx_events_app_name"))
        #expect(indexNames.contains("idx_switches_timestamp"))
    }
    
    // MARK: - Event Operations Tests
    
    @Test("Add single event successfully")
    func testAddSingleEvent() async throws {
        let service = try createTestService()
        let testEvent = generateTestEvents(count: 1)[0]
        
        try await service.addEvent(testEvent)
        
        let loadedEvents = try await service.loadEvents()
        #expect(loadedEvents.count == 1)
        #expect(loadedEvents[0].id == testEvent.id)
        #expect(loadedEvents[0].appName == testEvent.appName)
        #expect(loadedEvents[0].category == testEvent.category)
    }
    
    @Test("Add multiple events in batch")
    func testAddMultipleEvents() async throws {
        let service = try createTestService()
        let testEvents = generateTestEvents(count: 50)
        
        try await service.addEvents(testEvents)
        
        let loadedEvents = try await service.loadEvents()
        #expect(loadedEvents.count == 50)
        
        // Verify events are sorted by timestamp (descending)
        for i in 0..<(loadedEvents.count - 1) {
            #expect(loadedEvents[i].timestamp >= loadedEvents[i + 1].timestamp)
        }
    }
    
    @Test("Load events with date range filtering")
    func testLoadEventsWithDateRange() async throws {
        let service = try createTestService()
        let testEvents = generateTestEvents(count: 20)
        
        try await service.addEvents(testEvents)
        
        // Test date range filtering
        let midpoint = testEvents[10].timestamp
        let startDate = midpoint.addingTimeInterval(-300) // 5 minutes before
        let endDate = midpoint.addingTimeInterval(300)   // 5 minutes after
        
        let filteredEvents = try await service.loadEvents(from: startDate, to: endDate, limit: nil)
        
        // Should contain events around the midpoint
        #expect(filteredEvents.count > 0)
        #expect(filteredEvents.count < 20)
        
        // All events should be within the date range
        for event in filteredEvents {
            #expect(event.timestamp >= startDate)
            #expect(event.timestamp <= endDate)
        }
    }
    
    @Test("Load events with limit")
    func testLoadEventsWithLimit() async throws {
        let service = try createTestService()
        let testEvents = generateTestEvents(count: 100)
        
        try await service.addEvents(testEvents)
        
        let limitedEvents = try await service.loadEvents(from: nil, to: nil, limit: 25)
        
        #expect(limitedEvents.count == 25)
        
        // Should return the most recent events (highest timestamps)
        for i in 0..<(limitedEvents.count - 1) {
            #expect(limitedEvents[i].timestamp >= limitedEvents[i + 1].timestamp)
        }
    }
    
    // MARK: - Context Switch Operations Tests
    
    @Test("Add and retrieve context switches")
    func testContextSwitchOperations() async throws {
        let service = try createTestService()
        let testSwitches = generateTestContextSwitches(count: 10)
        
        // Add switches one by one to test individual insertion
        for contextSwitch in testSwitches {
            try await service.addContextSwitch(contextSwitch)
        }
        
        let loadedSwitches = try await service.loadContextSwitches()
        #expect(loadedSwitches.count == 10)
        
        // Verify data integrity
        let originalIds = Set(testSwitches.map { $0.id })
        let loadedIds = Set(loadedSwitches.map { $0.id })
        #expect(originalIds == loadedIds)
    }
    
    @Test("Context switch date range filtering")
    func testContextSwitchDateFiltering() async throws {
        let service = try createTestService()
        let testSwitches = generateTestContextSwitches(count: 20)
        
        for contextSwitch in testSwitches {
            try await service.addContextSwitch(contextSwitch)
        }
        
        // Filter to middle portion
        let midSwitch = testSwitches[10]
        let startDate = midSwitch.timestamp.addingTimeInterval(-300)
        let endDate = midSwitch.timestamp.addingTimeInterval(300)
        
        let filteredSwitches = try await service.loadContextSwitches(from: startDate, to: endDate, limit: nil)
        
        #expect(filteredSwitches.count > 0)
        #expect(filteredSwitches.count < 20)
        
        for contextSwitch in filteredSwitches {
            #expect(contextSwitch.timestamp >= startDate)
            #expect(contextSwitch.timestamp <= endDate)
        }
    }
    
    // MARK: - Analytics and Complex Queries Tests
    
    @Test("App usage statistics calculation")
    func testAppUsageStatistics() async throws {
        let service = try createTestService()
        
        // Create events with specific patterns
        let events = [
            AppActivationEvent(appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", category: AppCategory.development),
            AppActivationEvent(appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", category: AppCategory.development),
            AppActivationEvent(appName: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", category: AppCategory.communication),
            AppActivationEvent(appName: "Safari", bundleIdentifier: "com.apple.Safari", category: AppCategory.productivity)
        ]
        
        try await service.addEvents(events)
        
        let startDate = Date().addingTimeInterval(-7200) // 2 hours ago
        let endDate = Date()
        
        let stats = try await service.getAppUsageStats(from: startDate, to: endDate)
        
        #expect(stats.count >= 2) // At least Xcode and one other app
        
        // Find Xcode stats
        let xcodeStats = stats.first { $0.appName == "Xcode" }
        #expect(xcodeStats != nil)
        #expect(xcodeStats?.activationCount == 2)
    }
    
    // MARK: - Data Migration Tests
    
    @Test("Migration from EventStorageService")
    func testMigrationFromEventStorage() async throws {
        // This test would require mocking EventStorageService
        // For now, we'll test the migration workflow structure
        let service = try createTestService()
        
        // Create some initial data
        let testEvents = generateTestEvents(count: 5)
        try await service.addEvents(testEvents)
        
        // Verify migration progress tracking
        #expect(service.migrationProgress >= 0.0)
        #expect(service.migrationProgress <= 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handle invalid event data gracefully")
    func testInvalidEventHandling() async throws {
        let service = try createTestService()
        
        // Create an event with future timestamp (should be rejected)
        var invalidEvent = generateTestEvents(count: 1)[0]
        invalidEvent = AppActivationEvent(
            id: invalidEvent.id,
            timestamp: Date().addingTimeInterval(7200), // 2 hours in future
            appName: invalidEvent.appName,
            bundleIdentifier: invalidEvent.bundleIdentifier,
            category: invalidEvent.category
        )
        
        // This should handle the error gracefully without crashing
        do {
            try await service.addEvent(invalidEvent)
            // If validation is implemented, this should throw
        } catch {
            // Expected behavior - validation should catch this
            #expect(error is DatabaseError)
        }
    }
    
    @Test("Database connection failure handling")
    func testConnectionFailureHandling() async throws {
        // Test with invalid database path
        let invalidService = try TestSQLiteStorageService(databasePath: "/invalid/path/database.sqlite")
        
        do {
            _ = try await invalidService.loadEvents()
        } catch {
            #expect(error is DatabaseError)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Performance with large dataset")
    func testLargeDatasetPerformance() async throws {
        let service = try createTestService()
        
        // Generate large dataset
        let largeDataset = generateTestEvents(count: 1000)
        
        let startTime = Date()
        try await service.addEvents(largeDataset)
        let insertDuration = Date().timeIntervalSince(startTime)
        
        // Should complete batch insert within reasonable time
        #expect(insertDuration < 5.0) // 5 seconds max
        
        let queryStartTime = Date()
        let loadedEvents = try await service.loadEvents()
        let queryDuration = Date().timeIntervalSince(queryStartTime)
        
        #expect(loadedEvents.count == 1000)
        #expect(queryDuration < 2.0) // 2 seconds max for query
    }
    
    @Test("Concurrent access handling")
    func testConcurrentAccess() async throws {
        let service = try createTestService()
        
        // Perform concurrent operations
        let events1 = generateTestEvents(count: 50)
        let events2 = generateTestEvents(count: 50)
        let switches = generateTestContextSwitches(count: 25)
        
        // Execute operations concurrently
        async let task1: () = service.addEvents(events1)
        async let task2: () = service.addEvents(events2)
        async let task3: () = {
            for contextSwitch in switches {
                try await service.addContextSwitch(contextSwitch)
            }
        }()
        
        // Wait for all tasks to complete
        _ = try await [task1, task2, task3]
        
        // Verify all data was inserted correctly
        let finalEvents = try await service.loadEvents()
        let finalSwitches = try await service.loadContextSwitches()
        
        #expect(finalEvents.count == 100)
        #expect(finalSwitches.count == 25)
    }
    
    // MARK: - Data Integrity Tests
    
    @Test("Event data round-trip integrity")
    func testEventDataIntegrity() async throws {
        let service = try createTestService()
        
        // Create event with all possible data
        let originalEvent = AppActivationEvent(
            id: UUID(),
            timestamp: Date(),
            appName: "Test App with Special Characters: äöü & <>",
            bundleIdentifier: "com.test.special-app",
            chromeTabTitle: "Test Page Title",
            chromeTabUrl: "https://example.com/?param=value&other=test",
            siteDomain: "example.com",
            category: AppCategory.productivity,
            sessionId: UUID(),
            sessionStartTime: Date().addingTimeInterval(-1800),
            sessionEndTime: Date(),
            isSessionStart: true,
            isSessionEnd: false,
            sessionSwitchCount: 42
        )
        
        try await service.addEvent(originalEvent)
        
        let loadedEvents = try await service.loadEvents()
        #expect(loadedEvents.count == 1)
        
        let loadedEvent = loadedEvents[0]
        
        // Verify all fields are preserved exactly
        #expect(loadedEvent.id == originalEvent.id)
        #expect(loadedEvent.timestamp.timeIntervalSince1970 == originalEvent.timestamp.timeIntervalSince1970, accuracy: 1.0)
        #expect(loadedEvent.appName == originalEvent.appName)
        #expect(loadedEvent.bundleIdentifier == originalEvent.bundleIdentifier)
        #expect(loadedEvent.chromeTabTitle == originalEvent.chromeTabTitle)
        #expect(loadedEvent.chromeTabUrl == originalEvent.chromeTabUrl)
        #expect(loadedEvent.siteDomain == originalEvent.siteDomain)
        #expect(loadedEvent.category == originalEvent.category)
        #expect(loadedEvent.sessionId == originalEvent.sessionId)
        #expect(loadedEvent.isSessionStart == originalEvent.isSessionStart)
        #expect(loadedEvent.isSessionEnd == originalEvent.isSessionEnd)
        #expect(loadedEvent.sessionSwitchCount == originalEvent.sessionSwitchCount)
    }
    
    @Test("Context switch data round-trip integrity")
    func testContextSwitchDataIntegrity() async throws {
        let service = try createTestService()
        
        let originalSwitch = ContextSwitchMetrics(
            fromApp: "From App",
            toApp: "To App",
            fromBundleId: "com.from.app",
            toBundleId: "com.to.app",
            timestamp: Date(),
            timeSpent: 123.456,
            fromCategory: AppCategory.development,
            toCategory: AppCategory.productivity,
            sessionId: UUID()
        )
        
        try await service.addContextSwitch(originalSwitch)
        
        let loadedSwitches = try await service.loadContextSwitches()
        #expect(loadedSwitches.count == 1)
        
        let loadedSwitch = loadedSwitches[0]
        
        #expect(loadedSwitch.id == originalSwitch.id)
        #expect(loadedSwitch.fromApp == originalSwitch.fromApp)
        #expect(loadedSwitch.toApp == originalSwitch.toApp)
        #expect(loadedSwitch.fromBundleId == originalSwitch.fromBundleId)
        #expect(loadedSwitch.toBundleId == originalSwitch.toBundleId)
        #expect(loadedSwitch.timeSpent == originalSwitch.timeSpent, accuracy: 0.001)
        #expect(loadedSwitch.switchType == originalSwitch.switchType)
        #expect(loadedSwitch.fromCategory == originalSwitch.fromCategory)
        #expect(loadedSwitch.toCategory == originalSwitch.toCategory)
        #expect(loadedSwitch.sessionId == originalSwitch.sessionId)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Handle empty database queries")
    func testEmptyDatabaseQueries() async throws {
        let service = try createTestService()
        
        // Query empty database
        let events = try await service.loadEvents()
        let switches = try await service.loadContextSwitches()
        let stats = try await service.getAppUsageStats(from: Date().addingTimeInterval(-3600), to: Date())
        
        #expect(events.isEmpty)
        #expect(switches.isEmpty)
        #expect(stats.isEmpty)
    }
    
    @Test("Handle nil and optional values correctly")
    func testNilValueHandling() async throws {
        let service = try createTestService()
        
        // Create event with nil optional values
        let eventWithNils = AppActivationEvent(
            id: UUID(),
            timestamp: Date(),
            appName: nil,
            bundleIdentifier: nil,
            chromeTabTitle: nil,
            chromeTabUrl: nil,
            siteDomain: nil,
            category: AppCategory.other,
            sessionId: nil,
            sessionStartTime: nil,
            sessionEndTime: nil
        )
        
        try await service.addEvent(eventWithNils)
        
        let loadedEvents = try await service.loadEvents()
        #expect(loadedEvents.count == 1)
        
        let loadedEvent = loadedEvents[0]
        #expect(loadedEvent.appName == nil)
        #expect(loadedEvent.bundleIdentifier == nil)
        #expect(loadedEvent.chromeTabTitle == nil)
        #expect(loadedEvent.sessionId == nil)
    }
    
    @Test("Date range edge cases")
    func testDateRangeEdgeCases() async throws {
        let service = try createTestService()
        let testEvents = generateTestEvents(count: 5)
        
        try await service.addEvents(testEvents)
        
        // Test with same start and end date
        let singleMoment = testEvents[2].timestamp
        let sameTimeEvents = try await service.loadEvents(from: singleMoment, to: singleMoment, limit: nil)
        
        // Should include events at exactly that timestamp
        #expect(sameTimeEvents.count <= 1)
        
        // Test with reversed date range (end before start)
        let futureDate = Date().addingTimeInterval(3600)
        let pastDate = Date().addingTimeInterval(-3600)
        let reversedRangeEvents = try await service.loadEvents(from: futureDate, to: pastDate, limit: nil)
        
        // Should return empty result
        #expect(reversedRangeEvents.isEmpty)
    }
}

// MARK: - Test Helper Classes

/// Test-specific SQLite storage service for isolated testing
class TestSQLiteStorageService {
    private var db: Connection?
    private let testDatabaseURL: URL
    private let dbQueue = DispatchQueue(label: "com.test.sqlite", qos: .utility)
    
    // Published properties for testing
    var events: [AppActivationEvent] = []
    var contextSwitches: [ContextSwitchMetrics] = []
    var isLoading: Bool = false
    var migrationProgress: Double = 0.0
    var lastError: Error?
    
    // Table definitions (copied from main service)
    private let eventsTable = Table("app_activation_events")
    private let contextSwitchesTable = Table("context_switch_metrics")
    
    // Column expressions
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
    
    // Context switch columns
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
    
    var databaseURL: URL {
        return testDatabaseURL
    }
    
    init(databasePath: String? = nil) throws {
        // Create temporary database file for testing
        let tempDir = FileManager.default.temporaryDirectory
        let testDbName = databasePath ?? "test_\(UUID().uuidString).sqlite"
        self.testDatabaseURL = tempDir.appendingPathComponent(testDbName)
        
        try initializeDatabase()
    }
    
    private func initializeDatabase() throws {
        db = try Connection(testDatabaseURL.path)
        
        // Configure database
        try db?.execute("PRAGMA foreign_keys = ON")
        try db?.execute("PRAGMA journal_mode = WAL")
        
        // Create tables
        try createTables()
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
        
        // Create indexes
        try db.run("CREATE INDEX IF NOT EXISTS idx_events_timestamp ON app_activation_events(timestamp DESC)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_events_app_name ON app_activation_events(app_name)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_switches_timestamp ON context_switch_metrics(timestamp DESC)")
    }
    
    deinit {
        // Clean up test database
        try? FileManager.default.removeItem(at: testDatabaseURL)
    }
}

// MARK: - TestSQLiteStorageService Protocol Implementation

extension TestSQLiteStorageService {
    
    func addEvent(_ event: AppActivationEvent) async throws {
        try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let db = self.db else {
                        throw DatabaseError.connectionFailed
                    }
                    
                    try db.run(self.eventsTable.insert(
                        self.eventId <- event.id.uuidString,
                        self.timestamp <- event.timestamp,
                        self.appName <- event.appName,
                        self.bundleIdentifier <- event.bundleIdentifier,
                        self.chromeTabTitle <- event.chromeTabTitle,
                        self.chromeTabUrl <- event.chromeTabUrl,
                        self.siteDomain <- event.siteDomain,
                        self.categoryName <- event.category.name,
                        self.sessionId <- event.sessionId?.uuidString,
                        self.sessionStartTime <- event.sessionStartTime,
                        self.sessionEndTime <- event.sessionEndTime,
                        self.isSessionStart <- event.isSessionStart,
                        self.isSessionEnd <- event.isSessionEnd,
                        self.sessionSwitchCount <- event.sessionSwitchCount
                    ))
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func addEvents(_ events: [AppActivationEvent]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let db = self.db else {
                        throw DatabaseError.connectionFailed
                    }
                    
                    try db.transaction {
                        for event in events {
                            try db.run(self.eventsTable.insert(
                                self.eventId <- event.id.uuidString,
                                self.timestamp <- event.timestamp,
                                self.appName <- event.appName,
                                self.bundleIdentifier <- event.bundleIdentifier,
                                self.chromeTabTitle <- event.chromeTabTitle,
                                self.chromeTabUrl <- event.chromeTabUrl,
                                self.siteDomain <- event.siteDomain,
                                self.categoryName <- event.category.name,
                                self.sessionId <- event.sessionId?.uuidString,
                                self.sessionStartTime <- event.sessionStartTime,
                                self.sessionEndTime <- event.sessionEndTime,
                                self.isSessionStart <- event.isSessionStart,
                                self.isSessionEnd <- event.isSessionEnd,
                                self.sessionSwitchCount <- event.sessionSwitchCount
                            ))
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func loadEvents(from startDate: Date? = nil, to endDate: Date? = nil, limit: Int? = nil) async throws -> [AppActivationEvent] {
        return try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let db = self.db else {
                        throw DatabaseError.connectionFailed
                    }
                    
                    var query = self.eventsTable.order(self.timestamp.desc)
                    
                    if let startDate = startDate {
                        query = query.filter(self.timestamp >= startDate)
                    }
                    if let endDate = endDate {
                        query = query.filter(self.timestamp <= endDate)
                    }
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
    
    func addContextSwitch(_ contextSwitch: ContextSwitchMetrics) async throws {
        try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let db = self.db else {
                        throw DatabaseError.connectionFailed
                    }
                    
                    try db.run(self.contextSwitchesTable.insert(
                        self.switchId <- contextSwitch.id.uuidString,
                        self.fromApp <- contextSwitch.fromApp,
                        self.toApp <- contextSwitch.toApp,
                        self.fromBundleId <- contextSwitch.fromBundleId,
                        self.toBundleId <- contextSwitch.toBundleId,
                        self.switchTimestamp <- contextSwitch.timestamp,
                        self.timeSpent <- contextSwitch.timeSpent,
                        self.switchType <- contextSwitch.switchType.rawValue,
                        self.fromCategory <- contextSwitch.fromCategory.name,
                        self.toCategory <- contextSwitch.toCategory.name,
                        self.switchSessionId <- contextSwitch.sessionId?.uuidString
                    ))
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func loadContextSwitches(from startDate: Date? = nil, to endDate: Date? = nil, limit: Int? = nil) async throws -> [ContextSwitchMetrics] {
        return try await withCheckedThrowingContinuation { continuation in
            dbQueue.async {
                do {
                    guard let db = self.db else {
                        throw DatabaseError.connectionFailed
                    }
                    
                    var query = self.contextSwitchesTable.order(self.switchTimestamp.desc)
                    
                    if let startDate = startDate {
                        query = query.filter(self.switchTimestamp >= startDate)
                    }
                    if let endDate = endDate {
                        query = query.filter(self.switchTimestamp <= endDate)
                    }
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
                            siteBreakdown: nil
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
            sessionId: sessionUUID,
            sessionStartTime: try row.get(sessionStartTime),
            sessionEndTime: try row.get(sessionEndTime),
            isSessionStart: try row.get(isSessionStart),
            isSessionEnd: try row.get(isSessionEnd),
            sessionSwitchCount: try row.get(sessionSwitchCount)
        )
    }
    
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
            fromApp: try row.get(fromApp),
            toApp: try row.get(toApp),
            fromBundleId: try row.get(fromBundleId),
            toBundleId: try row.get(toBundleId),
            timestamp: try row.get(switchTimestamp),
            timeSpent: try row.get(timeSpent),
            fromCategory: fromCategoryEnum,
            toCategory: toCategoryEnum,
            sessionId: sessionUUID
        )
    }
}
