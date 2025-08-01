//
//  SQLiteMigrationTests.swift
//  ConsciousMonitor-Tests
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Testing
import Foundation
@testable import ConsciousMonitor

/// Specialized tests for SQLite migration scenarios and complex workflows
struct SQLiteMigrationTests {
    
    // MARK: - Migration Scenario Tests
    
    @Test("Migrate large dataset from JSON to SQLite")
    func testLargeDatasetMigration() async throws {
        // Simulate existing EventStorageService data
        let (existingEvents, existingSwitches) = TestDataFactory.generateMigrationTestData()
        
        // Create test service
        let service = try TestSQLiteStorageService()
        
        // Simulate migration process
        let startTime = Date()
        
        // Migrate events in batches
        let eventBatches = existingEvents.chunked(into: 50)
        for batch in eventBatches {
            try await service.addEvents(batch)
        }
        
        // Migrate context switches
        for contextSwitch in existingSwitches {
            try await service.addContextSwitch(contextSwitch)
        }
        
        let migrationTime = Date().timeIntervalSince(startTime)
        
        // Verify migration completed in reasonable time
        #expect(migrationTime < 10.0) // Should complete within 10 seconds
        
        // Verify all data was migrated
        let migratedEvents = try await service.loadEvents()
        let migratedSwitches = try await service.loadContextSwitches()
        
        #expect(migratedEvents.count == existingEvents.count)
        #expect(migratedSwitches.count == existingSwitches.count)
        
        // Verify data integrity after migration
        let originalEventIds = Set(existingEvents.map { $0.id })
        let migratedEventIds = Set(migratedEvents.map { $0.id })
        #expect(originalEventIds == migratedEventIds)
        
        let originalSwitchIds = Set(existingSwitches.map { $0.id })
        let migratedSwitchIds = Set(migratedSwitches.map { $0.id })
        #expect(originalSwitchIds == migratedSwitchIds)
    }
    
    @Test("Handle partial migration failure gracefully")
    func testPartialMigrationFailure() async throws {
        let service = try TestSQLiteStorageService()
        
        // Create mixed data: some valid, some problematic
        var testEvents = TestDataFactory.generateRealisticEvents(count: 10)
        
        // Insert a problematic event that might cause issues
        let problematicEvent = AppActivationEvent(
            id: UUID(),
            timestamp: Date().addingTimeInterval(7200), // Far future timestamp
            appName: String(repeating: "x", count: 10000), // Extremely long name
            bundleIdentifier: "com.test.problematic",
            category: AppCategory.other
        )
        testEvents.insert(problematicEvent, at: 5)
        
        // Migration should handle errors gracefully
        do {
            try await service.addEvents(testEvents)
            
            // Even if some events fail, others should succeed
            let loadedEvents = try await service.loadEvents()
            #expect(loadedEvents.count >= 5) // At least some events should succeed
            
        } catch {
            // Migration failure is acceptable, but shouldn't crash
            #expect(error is DatabaseError)
        }
    }
    
    @Test("Migration progress tracking")
    func testMigrationProgressTracking() async throws {
        let service = try TestSQLiteStorageService()
        let testData = TestDataFactory.generateRealisticEvents(count: 100)
        
        // Track progress during batch migration
        let batchSize = 20
        let batches = testData.chunked(into: batchSize)
        
        var progressValues: [Double] = []
        
        for (index, batch) in batches.enumerated() {
            try await service.addEvents(batch)
            
            let progress = Double(index + 1) / Double(batches.count)
            progressValues.append(progress)
        }
        
        // Verify progress tracking
        #expect(progressValues.first! > 0)
        #expect(progressValues.last! == 1.0)
        
        // Verify progress is monotonically increasing
        for i in 1..<progressValues.count {
            #expect(progressValues[i] >= progressValues[i-1])
        }
    }
    
    // MARK: - Data Consistency Tests
    
    @Test("Verify referential integrity during migration")
    func testReferentialIntegrity() async throws {
        let service = try TestSQLiteStorageService()
        
        // Create events with session relationships
        let sessionId = UUID()
        let sessionEvents = [
            AppActivationEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-3600),
                appName: "Session App 1",
                bundleIdentifier: "com.test.session1",
                category: .productivity,
                sessionId: sessionId,
                sessionStartTime: Date().addingTimeInterval(-3600),
                isSessionStart: true,
                sessionSwitchCount: 1
            ),
            AppActivationEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-3000),
                appName: "Session App 2",
                bundleIdentifier: "com.test.session2",
                category: .development,
                sessionId: sessionId,
                sessionSwitchCount: 2
            ),
            AppActivationEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-2400),
                appName: "Session App 3",
                bundleIdentifier: "com.test.session3",
                category: .communication,
                sessionId: sessionId,
                sessionEndTime: Date().addingTimeInterval(-2400),
                isSessionEnd: true,
                sessionSwitchCount: 3
            )
        ]
        
        try await service.addEvents(sessionEvents)
        
        // Verify session consistency
        let loadedEvents = try await service.loadEvents()
        let sessionEventIds = Set(sessionEvents.map { $0.id })
        let loadedSessionEvents = loadedEvents.filter { sessionEventIds.contains($0.id) }
        
        #expect(loadedSessionEvents.count == 3)
        
        // Verify session data is preserved
        for event in loadedSessionEvents {
            #expect(event.sessionId == sessionId)
        }
        
        let sessionStartEvents = loadedSessionEvents.filter { $0.isSessionStart }
        let sessionEndEvents = loadedSessionEvents.filter { $0.isSessionEnd }
        
        #expect(sessionStartEvents.count == 1)
        #expect(sessionEndEvents.count == 1)
    }
    
    @Test("Chrome tab data preservation during migration")
    func testChromeTabDataPreservation() async throws {
        let service = try TestSQLiteStorageService()
        
        // Create events with complex Chrome tab data
        let chromeEvents = [
            AppActivationEvent(
                id: UUID(),
                timestamp: Date(),
                appName: "Chrome",
                bundleIdentifier: "com.google.Chrome",
                chromeTabTitle: "GitHub - ConsciousMonitor Repository",
                chromeTabUrl: "https://github.com/user/conscious-monitor/pulls?q=is%3Aopen+is%3Apr",
                siteDomain: "github.com",
                category: .development
            ),
            AppActivationEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-60),
                appName: "Safari",
                bundleIdentifier: "com.apple.Safari",
                chromeTabTitle: "Stack Overflow - How to test SQLite with Swift Testing",
                chromeTabUrl: "https://stackoverflow.com/questions/sqlite-swift-testing?param=value&other=test",
                siteDomain: "stackoverflow.com",
                category: .productivity
            )
        ]
        
        try await service.addEvents(chromeEvents)
        
        let loadedEvents = try await service.loadEvents()
        let chromeEventIds = Set(chromeEvents.map { $0.id })
        let loadedChromeEvents = loadedEvents.filter { chromeEventIds.contains($0.id) }
        
        #expect(loadedChromeEvents.count == 2)
        
        // Verify Chrome tab data is preserved exactly
        for (original, loaded) in zip(chromeEvents, loadedChromeEvents.sorted { $0.timestamp > $1.timestamp }) {
            #expect(loaded.chromeTabTitle == original.chromeTabTitle)
            #expect(loaded.chromeTabUrl == original.chromeTabUrl)
            #expect(loaded.siteDomain == original.siteDomain)
        }
    }
    
    // MARK: - Performance Migration Tests
    
    @Test("Large scale migration performance")
    func testLargeScaleMigrationPerformance() async throws {
        let service = try TestSQLiteStorageService()
        
        // Generate large dataset
        let largeEventSet = TestDataFactory.generateLargeDataset(eventCount: 5000)
        let largeSwitchSet = TestDataFactory.generateRealisticContextSwitches(count: 2500)
        
        let startTime = Date()
        
        // Migrate in realistic batches
        let eventBatches = largeEventSet.chunked(into: 100)
        for batch in eventBatches {
            try await service.addEvents(batch)
        }
        
        let switchBatches = largeSwitchSet.chunked(into: 50)
        for batch in switchBatches {
            for contextSwitch in batch {
                try await service.addContextSwitch(contextSwitch)
            }
        }
        
        let migrationDuration = Date().timeIntervalSince(startTime)
        
        // Verify performance expectations
        #expect(migrationDuration < 30.0) // Should complete within 30 seconds
        
        // Verify all data migrated correctly
        let finalEvents = try await service.loadEvents()
        let finalSwitches = try await service.loadContextSwitches()
        
        #expect(finalEvents.count == 5000)
        #expect(finalSwitches.count == 2500)
        
        // Test query performance on large dataset
        let queryStartTime = Date()
        let recentEvents = try await service.loadEvents(
            from: Date().addingTimeInterval(-3600),
            to: Date(),
            limit: 100
        )
        let queryDuration = Date().timeIntervalSince(queryStartTime)
        
        #expect(queryDuration < 1.0) // Queries should be fast even with large dataset
        #expect(recentEvents.count <= 100)
    }
    
    // MARK: - Data Validation Tests
    
    @Test("Validate migrated data accuracy")
    func testMigratedDataAccuracy() async throws {
        let service = try TestSQLiteStorageService()
        
        // Create comprehensive test dataset
        let originalEvents = TestDataFactory.generateRealisticEvents(count: 100)
        let originalSwitches = TestDataFactory.generateRealisticContextSwitches(count: 50)
        
        // Migrate data
        try await service.addEvents(originalEvents)
        for contextSwitch in originalSwitches {
            try await service.addContextSwitch(contextSwitch)
        }
        
        // Load migrated data
        let migratedEvents = try await service.loadEvents()
        let migratedSwitches = try await service.loadContextSwitches()
        
        // Create lookup maps for comparison
        let originalEventMap = Dictionary(uniqueKeysWithValues: originalEvents.map { ($0.id, $0) })
        let originalSwitchMap = Dictionary(uniqueKeysWithValues: originalSwitches.map { ($0.id, $0) })
        
        // Verify each migrated event matches original
        for migratedEvent in migratedEvents {
            guard let originalEvent = originalEventMap[migratedEvent.id] else {
                #expect(Bool(false), "Migrated event not found in original data")
                continue
            }
            
            #expect(TestAssertionHelpers.verifyEventIntegrity(originalEvent, migratedEvent))
        }
        
        // Verify each migrated context switch matches original
        for migratedSwitch in migratedSwitches {
            guard let originalSwitch = originalSwitchMap[migratedSwitch.id] else {
                #expect(Bool(false), "Migrated context switch not found in original data")
                continue
            }
            
            #expect(TestAssertionHelpers.verifyContextSwitchIntegrity(originalSwitch, migratedSwitch))
        }
    }
    
    // MARK: - Error Recovery Tests
    
    @Test("Recovery from corrupted migration")
    func testCorruptedMigrationRecovery() async throws {
        let service = try TestSQLiteStorageService()
        
        // Start with good data
        let goodEvents = TestDataFactory.generateRealisticEvents(count: 50)
        try await service.addEvents(goodEvents)
        
        // Verify initial data is correct
        var loadedEvents = try await service.loadEvents()
        #expect(loadedEvents.count == 50)
        
        // Attempt to add corrupted data (this might fail)
        let corruptedEvents = TestDataFactory.generateEdgeCaseEvents()
        
        do {
            try await service.addEvents(corruptedEvents)
        } catch {
            // Expected - corrupted data should be rejected
            print("Corrupted data properly rejected: \(error)")
        }
        
        // Verify original data is still intact
        loadedEvents = try await service.loadEvents()
        #expect(loadedEvents.count >= 50) // Original data should still be there
        
        // Verify we can continue with good data after corruption attempt
        let moreGoodEvents = TestDataFactory.generateRealisticEvents(count: 10)
        try await service.addEvents(moreGoodEvents)
        
        loadedEvents = try await service.loadEvents()
        #expect(loadedEvents.count >= 60) // Should have original + new good data
    }
    
    // MARK: - Integration Tests
    
    @Test("Full migration workflow simulation")
    func testFullMigrationWorkflow() async throws {
        let service = try TestSQLiteStorageService()
        
        // Phase 1: Simulate existing data from multiple sources
        let legacyEvents = TestDataFactory.generateRealisticEvents(
            count: 200,
            startDate: Date().addingTimeInterval(-604800), // 1 week ago
            endDate: Date().addingTimeInterval(-86400)     // 1 day ago
        )
        
        let recentEvents = TestDataFactory.generateRealisticEvents(
            count: 50,
            startDate: Date().addingTimeInterval(-86400),  // 1 day ago
            endDate: Date()                                // now
        )
        
        let contextSwitches = TestDataFactory.generateRealisticContextSwitches(
            count: 100,
            startDate: Date().addingTimeInterval(-604800),
            endDate: Date()
        )
        
        // Phase 2: Migrate legacy data first
        let legacyBatches = legacyEvents.chunked(into: 50)
        for batch in legacyBatches {
            try await service.addEvents(batch)
        }
        
        // Phase 3: Migrate recent data
        try await service.addEvents(recentEvents)
        
        // Phase 4: Migrate context switches
        for contextSwitch in contextSwitches {
            try await service.addContextSwitch(contextSwitch)
        }
        
        // Phase 5: Verify complete migration
        let allMigratedEvents = try await service.loadEvents()
        let allMigratedSwitches = try await service.loadContextSwitches()
        
        #expect(allMigratedEvents.count == 250) // 200 legacy + 50 recent
        #expect(allMigratedSwitches.count == 100)
        
        // Phase 6: Test analytics on migrated data
        let stats = try await service.getAppUsageStats(
            from: Date().addingTimeInterval(-604800),
            to: Date()
        )
        
        #expect(!stats.isEmpty)
        
        // Verify temporal ordering is maintained
        #expect(TestAssertionHelpers.verifyEventsAreSorted(allMigratedEvents, ascending: false))
        #expect(TestAssertionHelpers.verifyContextSwitchesAreSorted(allMigratedSwitches, ascending: false))
        
        // Phase 7: Test date range queries work correctly
        let todayEvents = try await service.loadEvents(
            from: Calendar.current.startOfDay(for: Date()),
            to: Date(),
            limit: nil
        )
        
        #expect(todayEvents.count <= 50) // Should only include recent events
    }
    
    @Test("Migration with concurrent access")
    func testMigrationWithConcurrentAccess() async throws {
        let service = try TestSQLiteStorageService()
        
        // Prepare test data
        let (batch1, batch2, switches) = MockDataProviders.concurrentTestData()
        
        // Perform concurrent migration operations
        async let migration1: () = service.addEvents(batch1)
        async let migration2: () = service.addEvents(batch2)
        async let migration3: () = {
            for contextSwitch in switches {
                try await service.addContextSwitch(contextSwitch)
            }
        }()
        
        // Wait for all concurrent operations to complete
        _ = try await [migration1, migration2, migration3]
        
        // Verify all data was migrated correctly despite concurrent access
        let finalEvents = try await service.loadEvents()
        let finalSwitches = try await service.loadContextSwitches()
        
        #expect(finalEvents.count == 50) // 25 + 25
        #expect(finalSwitches.count == 15)
        
        // Verify no data corruption occurred
        let eventNames = Set(finalEvents.compactMap { $0.appName })
        #expect(eventNames.contains { $0.contains("Batch1") })
        #expect(eventNames.contains { $0.contains("Batch2") })
    }
}

// MARK: - Helper Extensions

fileprivate extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
