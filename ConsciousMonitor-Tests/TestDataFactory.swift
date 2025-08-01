//
//  TestDataFactory.swift
//  ConsciousMonitor-Tests
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Foundation
@testable import ConsciousMonitor

/// Factory for creating test data with realistic patterns
struct TestDataFactory {
    
    // MARK: - Realistic App Data
    
    static let commonApps: [(name: String, bundleId: String, category: AppCategory)] = [
        ("Xcode", "com.apple.dt.Xcode", .development),
        ("Safari", "com.apple.Safari", .productivity),
        ("Chrome", "com.google.Chrome", .productivity),
        ("Slack", "com.tinyspeck.slackmacgap", .communication),
        ("Figma", "com.figma.Desktop", .design),
        ("Spotify", "com.spotify.client", .entertainment),
        ("Notion", "notion.id", .productivity),
        ("Terminal", "com.apple.Terminal", .development),
        ("Discord", "com.hnc.Discord", .communication),
        ("Finder", "com.apple.finder", .utilities)
    ]
    
    static let chromeSites: [(title: String, url: String, domain: String)] = [
        ("GitHub - Project Repository", "https://github.com/user/project", "github.com"),
        ("Stack Overflow - Swift Question", "https://stackoverflow.com/questions/swift", "stackoverflow.com"),
        ("Apple Developer Documentation", "https://developer.apple.com/documentation/", "developer.apple.com"),
        ("Medium - Tech Articles", "https://medium.com/tech-articles", "medium.com"),
        ("YouTube - Development Tutorial", "https://youtube.com/watch?v=tutorial", "youtube.com"),
        ("LinkedIn - Professional Network", "https://linkedin.com/feed", "linkedin.com"),
        ("Twitter - Tech News", "https://twitter.com/home", "twitter.com"),
        ("Reddit - Programming Subreddit", "https://reddit.com/r/programming", "reddit.com")
    ]
    
    // MARK: - Event Generation
    
    /// Generate realistic app activation events with temporal patterns
    static func generateRealisticEvents(
        count: Int = 100,
        startDate: Date = Date().addingTimeInterval(-86400), // 24 hours ago
        endDate: Date = Date(),
        includeChromeTabs: Bool = true,
        includeSessions: Bool = true
    ) -> [AppActivationEvent] {
        
        var events: [AppActivationEvent] = []
        let totalDuration = endDate.timeIntervalSince(startDate)
        var currentSessionId: UUID?
        var currentSessionStart: Date?
        var sessionEventCount = 0
        
        for i in 0..<count {
            let progress = Double(i) / Double(count - 1)
            let timestamp = startDate.addingTimeInterval(totalDuration * progress)
            
            // Add some randomness to make it more realistic
            let jitter = Double.random(in: -300...300) // ±5 minutes
            let actualTimestamp = timestamp.addingTimeInterval(jitter)
            
            // Select app with weighted probability (some apps used more often)
            let appIndex = selectWeightedAppIndex()
            let (appName, bundleId, category) = commonApps[appIndex]
            
            // Session management
            let shouldStartNewSession = currentSessionId == nil || sessionEventCount > Int.random(in: 5...15)
            let isSessionStart = shouldStartNewSession
            let isSessionEnd = currentSessionId != nil && shouldStartNewSession
            
            if shouldStartNewSession {
                currentSessionId = UUID()
                currentSessionStart = actualTimestamp
                sessionEventCount = 0
            }
            sessionEventCount += 1
            
            // Chrome tab information
            var chromeTabTitle: String?
            var chromeTabUrl: String?
            var siteDomain: String?
            
            if includeChromeTabs && (appName == "Safari" || appName == "Chrome") && Bool.random() {
                let siteIndex = Int.random(in: 0..<chromeSites.count)
                let (title, url, domain) = chromeSites[siteIndex]
                chromeTabTitle = title
                chromeTabUrl = url
                siteDomain = domain
            }
            
            let event = AppActivationEvent(
                id: UUID(),
                timestamp: actualTimestamp,
                appName: appName,
                bundleIdentifier: bundleId,
                chromeTabTitle: chromeTabTitle,
                chromeTabUrl: chromeTabUrl,
                siteDomain: siteDomain,
                category: category,
                sessionId: includeSessions ? currentSessionId : nil,
                sessionStartTime: includeSessions ? currentSessionStart : nil,
                sessionEndTime: nil, // Will be set when session ends
                isSessionStart: includeSessions ? isSessionStart : false,
                isSessionEnd: includeSessions ? (isSessionEnd && i > 0) : false,
                sessionSwitchCount: sessionEventCount
            )
            
            events.append(event)
        }
        
        // Mark the last event as session end if we have sessions
        if includeSessions && !events.isEmpty {
            var lastEvent = events[events.count - 1]
            lastEvent = AppActivationEvent(
                id: lastEvent.id,
                timestamp: lastEvent.timestamp,
                appName: lastEvent.appName,
                bundleIdentifier: lastEvent.bundleIdentifier,
                chromeTabTitle: lastEvent.chromeTabTitle,
                chromeTabUrl: lastEvent.chromeTabUrl,
                siteDomain: lastEvent.siteDomain,
                category: lastEvent.category,
                sessionId: lastEvent.sessionId,
                sessionStartTime: lastEvent.sessionStartTime,
                sessionEndTime: lastEvent.timestamp,
                isSessionStart: lastEvent.isSessionStart,
                isSessionEnd: true,
                sessionSwitchCount: lastEvent.sessionSwitchCount
            )
            events[events.count - 1] = lastEvent
        }
        
        return events.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Generate realistic context switches based on app patterns
    static func generateRealisticContextSwitches(
        count: Int = 50,
        startDate: Date = Date().addingTimeInterval(-86400),
        endDate: Date = Date()
    ) -> [ContextSwitchMetrics] {
        
        var switches: [ContextSwitchMetrics] = []
        let totalDuration = endDate.timeIntervalSince(startDate)
        
        for i in 0..<count {
            let progress = Double(i) / Double(count - 1)
            let timestamp = startDate.addingTimeInterval(totalDuration * progress)
            
            // Select source and destination apps
            let fromIndex = Int.random(in: 0..<commonApps.count)
            var toIndex = Int.random(in: 0..<commonApps.count)
            
            // Ensure different apps
            while toIndex == fromIndex {
                toIndex = Int.random(in: 0..<commonApps.count)
            }
            
            let (fromName, fromBundleId, fromCategory) = commonApps[fromIndex]
            let (toName, toBundleId, toCategory) = commonApps[toIndex]
            
            // Generate realistic time spent based on app types
            let timeSpent = generateRealisticTimeSpent(fromCategory, toCategory)
            
            let contextSwitch = ContextSwitchMetrics(
                fromApp: fromName,
                toApp: toName,
                fromBundleId: fromBundleId,
                toBundleId: toBundleId,
                timestamp: timestamp,
                timeSpent: timeSpent,
                fromCategory: fromCategory,
                toCategory: toCategory,
                sessionId: UUID()
            )
            
            switches.append(contextSwitch)
        }
        
        return switches.sorted { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Specialized Test Data
    
    /// Generate events for performance testing
    static func generateLargeDataset(eventCount: Int = 10000) -> [AppActivationEvent] {
        return generateRealisticEvents(
            count: eventCount,
            startDate: Date().addingTimeInterval(-604800), // 1 week ago
            endDate: Date(),
            includeChromeTabs: true,
            includeSessions: true
        )
    }
    
    /// Generate events with edge cases for robustness testing
    static func generateEdgeCaseEvents() -> [AppActivationEvent] {
        return [
            // Event with nil optional values
            AppActivationEvent(
                id: UUID(),
                timestamp: Date(),
                appName: nil,
                bundleIdentifier: nil,
                category: AppCategory.other
            ),
            
            // Event with special characters
            AppActivationEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-60),
                appName: "App with Special Chäräcters & Symbols <>",
                bundleIdentifier: "com.test.special-chars",
                chromeTabTitle: "Page with ümläuts änd emojis 🚀",
                chromeTabUrl: "https://example.com/path?param=value&other=test",
                siteDomain: "example.com",
                category: AppCategory.productivity
            ),
            
            // Event with very long strings
            AppActivationEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-120),
                appName: String(repeating: "VeryLongAppName", count: 10),
                bundleIdentifier: "com.test.very.long.bundle.identifier.with.many.components",
                chromeTabTitle: String(repeating: "Very Long Title ", count: 20),
                chromeTabUrl: "https://example.com/" + String(repeating: "very-long-path/", count: 50),
                category: AppCategory.development
            ),
            
            // Event with future timestamp (for validation testing)
            AppActivationEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(3600), // 1 hour in future
                appName: "Future App",
                bundleIdentifier: "com.test.future",
                category: AppCategory.utilities
            ),
            
            // Event with very old timestamp
            AppActivationEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-31536000), // 1 year ago
                appName: "Old App",
                bundleIdentifier: "com.test.old",
                category: AppCategory.other
            )
        ]
    }
    
    /// Generate context switches with edge cases
    static func generateEdgeCaseContextSwitches() -> [ContextSwitchMetrics] {
        return [
            // Quick switch (< 10 seconds)
            ContextSwitchMetrics(
                fromApp: "Quick From",
                toApp: "Quick To",
                timestamp: Date(),
                timeSpent: 5.0,
                fromCategory: AppCategory.productivity,
                toCategory: AppCategory.communication
            ),
            
            // Very long session (> 2 hours)
            ContextSwitchMetrics(
                fromApp: "Long Session App",
                toApp: "Next App",
                timestamp: Date().addingTimeInterval(-60),
                timeSpent: 7200.0, // 2 hours
                fromCategory: AppCategory.development,
                toCategory: AppCategory.entertainment
            ),
            
            // Zero time spent (edge case)
            ContextSwitchMetrics(
                fromApp: "Zero Time From",
                toApp: "Zero Time To",
                timestamp: Date().addingTimeInterval(-120),
                timeSpent: 0.0,
                fromCategory: AppCategory.utilities,
                toCategory: AppCategory.productivity
            ),
            
            // Switch with special characters in app names
            ContextSwitchMetrics(
                fromApp: "App with Spéciäl Characters",
                toApp: "Another App with Symbols & <>",
                timestamp: Date().addingTimeInterval(-180),
                timeSpent: 125.5,
                fromCategory: AppCategory.design,
                toCategory: AppCategory.development
            )
        ]
    }
    
    // MARK: - Migration Test Data
    
    /// Generate data that simulates existing EventStorageService format
    static func generateMigrationTestData() -> (events: [AppActivationEvent], contextSwitches: [ContextSwitchMetrics]) {
        let events = generateRealisticEvents(
            count: 200,
            startDate: Date().addingTimeInterval(-172800), // 2 days ago
            endDate: Date().addingTimeInterval(-3600), // 1 hour ago
            includeChromeTabs: true,
            includeSessions: true
        )
        
        let contextSwitches = generateRealisticContextSwitches(
            count: 100,
            startDate: Date().addingTimeInterval(-172800),
            endDate: Date().addingTimeInterval(-3600)
        )
        
        return (events: events, contextSwitches: contextSwitches)
    }
    
    // MARK: - Helper Methods
    
    /// Select app index with weighted probability (some apps used more frequently)
    private static func selectWeightedAppIndex() -> Int {
        let weights = [0.20, 0.15, 0.15, 0.10, 0.08, 0.08, 0.08, 0.06, 0.05, 0.05]
        let random = Double.random(in: 0...1)
        
        var cumulative = 0.0
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if random <= cumulative {
                return index
            }
        }
        
        return 0 // Default to first app
    }
    
    /// Generate realistic time spent based on app categories
    private static func generateRealisticTimeSpent(
        _ fromCategory: AppCategory,
        _ toCategory: AppCategory
    ) -> TimeInterval {
        
        // Base time ranges by category
        let categoryTimeRanges: [AppCategory: (min: TimeInterval, max: TimeInterval)] = [
            .development: (min: 300, max: 3600), // 5 minutes to 1 hour
            .productivity: (min: 120, max: 1800), // 2 minutes to 30 minutes
            .communication: (min: 30, max: 600), // 30 seconds to 10 minutes
            .entertainment: (min: 180, max: 2400), // 3 minutes to 40 minutes
            .design: (min: 600, max: 5400), // 10 minutes to 1.5 hours
            .utilities: (min: 10, max: 300), // 10 seconds to 5 minutes
            .other: (min: 60, max: 900) // 1 minute to 15 minutes
        ]
        
        let range = categoryTimeRanges[fromCategory] ?? (min: 60, max: 600)
        let timeSpent = Double.random(in: range.min...range.max)
        
        // Add some variation based on destination category
        let multiplier: Double
        switch toCategory {
        case .communication:
            multiplier = 0.7 // Quick switches to communication
        case .entertainment:
            multiplier = 1.3 // Longer sessions before entertainment
        case .development:
            multiplier = 1.1 // Slightly longer for development
        default:
            multiplier = 1.0
        }
        
        return timeSpent * multiplier
    }
}

// MARK: - Test Assertion Helpers

/// Helper functions for common test assertions
struct TestAssertionHelpers {
    
    /// Verify event data integrity after database round-trip
    static func verifyEventIntegrity(_ original: AppActivationEvent, _ loaded: AppActivationEvent) -> Bool {
        return original.id == loaded.id &&
               abs(original.timestamp.timeIntervalSince1970 - loaded.timestamp.timeIntervalSince1970) < 1.0 &&
               original.appName == loaded.appName &&
               original.bundleIdentifier == loaded.bundleIdentifier &&
               original.chromeTabTitle == loaded.chromeTabTitle &&
               original.chromeTabUrl == loaded.chromeTabUrl &&
               original.siteDomain == loaded.siteDomain &&
               original.category == loaded.category &&
               original.sessionId == loaded.sessionId &&
               original.isSessionStart == loaded.isSessionStart &&
               original.isSessionEnd == loaded.isSessionEnd &&
               original.sessionSwitchCount == loaded.sessionSwitchCount
    }
    
    /// Verify context switch data integrity after database round-trip
    static func verifyContextSwitchIntegrity(_ original: ContextSwitchMetrics, _ loaded: ContextSwitchMetrics) -> Bool {
        return original.id == loaded.id &&
               original.fromApp == loaded.fromApp &&
               original.toApp == loaded.toApp &&
               original.fromBundleId == loaded.fromBundleId &&
               original.toBundleId == loaded.toBundleId &&
               abs(original.timestamp.timeIntervalSince1970 - loaded.timestamp.timeIntervalSince1970) < 1.0 &&
               abs(original.timeSpent - loaded.timeSpent) < 0.001 &&
               original.switchType == loaded.switchType &&
               original.fromCategory == loaded.fromCategory &&
               original.toCategory == loaded.toCategory &&
               original.sessionId == loaded.sessionId
    }
    
    /// Verify events are properly sorted by timestamp
    static func verifyEventsAreSorted(_ events: [AppActivationEvent], ascending: Bool = false) -> Bool {
        guard events.count > 1 else { return true }
        
        for i in 0..<(events.count - 1) {
            let current = events[i].timestamp
            let next = events[i + 1].timestamp
            
            if ascending {
                if current > next { return false }
            } else {
                if current < next { return false }
            }
        }
        
        return true
    }
    
    /// Verify context switches are properly sorted by timestamp
    static func verifyContextSwitchesAreSorted(_ switches: [ContextSwitchMetrics], ascending: Bool = false) -> Bool {
        guard switches.count > 1 else { return true }
        
        for i in 0..<(switches.count - 1) {
            let current = switches[i].timestamp
            let next = switches[i + 1].timestamp
            
            if ascending {
                if current > next { return false }
            } else {
                if current < next { return false }
            }
        }
        
        return true
    }
    
    /// Verify all events fall within a date range
    static func verifyEventsInDateRange(_ events: [AppActivationEvent], start: Date, end: Date) -> Bool {
        return events.allSatisfy { event in
            event.timestamp >= start && event.timestamp <= end
        }
    }
    
    /// Verify all context switches fall within a date range
    static func verifyContextSwitchesInDateRange(_ switches: [ContextSwitchMetrics], start: Date, end: Date) -> Bool {
        return switches.allSatisfy { contextSwitch in
            contextSwitch.timestamp >= start && contextSwitch.timestamp <= end
        }
    }
}

// MARK: - Mock Data Providers

/// Mock data providers for testing specific scenarios
struct MockDataProviders {
    
    /// Provide data for testing analytics calculations
    static func analyticsTestData() -> (events: [AppActivationEvent], expectedStats: [String: Int]) {
        let events = [
            // Xcode - 3 activations
            AppActivationEvent(appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", category: .development),
            AppActivationEvent(appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", category: .development),
            AppActivationEvent(appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", category: .development),
            
            // Safari - 2 activations
            AppActivationEvent(appName: "Safari", bundleIdentifier: "com.apple.Safari", category: .productivity),
            AppActivationEvent(appName: "Safari", bundleIdentifier: "com.apple.Safari", category: .productivity),
            
            // Slack - 1 activation
            AppActivationEvent(appName: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", category: .communication)
        ]
        
        let expectedStats = [
            "Xcode": 3,
            "Safari": 2,
            "Slack": 1
        ]
        
        return (events: events, expectedStats: expectedStats)
    }
    
    /// Provide data for testing concurrent operations
    static func concurrentTestData() -> ([AppActivationEvent], [AppActivationEvent], [ContextSwitchMetrics]) {
        let batch1 = generateBatchWithPrefix("Batch1", count: 25)
        let batch2 = generateBatchWithPrefix("Batch2", count: 25)
        let switches = TestDataFactory.generateRealisticContextSwitches(count: 15)
        
        return (batch1, batch2, switches)
    }
    
    private static func generateBatchWithPrefix(_ prefix: String, count: Int) -> [AppActivationEvent] {
        return (0..<count).map { i in
            AppActivationEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(TimeInterval(i * 10)),
                appName: "\(prefix)_App\(i)",
                bundleIdentifier: "com.test.\(prefix.lowercased()).app\(i)",
                category: AppCategory.productivity
            )
        }
    }
}
