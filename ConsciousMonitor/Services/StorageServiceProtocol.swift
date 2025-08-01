//
//  StorageServiceProtocol.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Foundation
import Combine

/// Protocol defining the interface for storage services
/// Allows ActivityMonitor to work with both JSON and SQLite storage seamlessly
protocol StorageServiceProtocol: ObservableObject {
    // MARK: - Published Properties
    var events: [AppActivationEvent] { get }
    var contextSwitches: [ContextSwitchMetrics] { get }
    var isLoading: Bool { get }
    var lastError: Error? { get }
    
    // MARK: - Event Operations
    /// Add a single app activation event
    func addEvent(_ event: AppActivationEvent) async throws
    
    /// Add multiple events in a batch
    func addEvents(_ events: [AppActivationEvent]) async throws
    
    /// Load events with optional date range and limit
    func loadEvents(from startDate: Date?, to endDate: Date?, limit: Int?) async throws -> [AppActivationEvent]
    
    /// Load all events (default implementation)
    func loadEvents() async throws -> [AppActivationEvent]
    
    // MARK: - Context Switch Operations
    /// Add a single context switch metric
    func addContextSwitch(_ contextSwitch: ContextSwitchMetrics) async throws
    
    /// Load context switches with optional date range and limit
    func loadContextSwitches(from startDate: Date?, to endDate: Date?, limit: Int?) async throws -> [ContextSwitchMetrics]
    
    /// Load all context switches (default implementation)
    func loadContextSwitches() async throws -> [ContextSwitchMetrics]
    
    // MARK: - Analytics Support
    /// Get app usage statistics for a date range
    func getAppUsageStats(from startDate: Date, to endDate: Date) async throws -> [AppUsageStat]
    
    // MARK: - Data Management
    /// Get storage type identifier
    var storageType: StorageType { get }
    
    /// Check if migration is available from this storage type
    var supportsMigrationFrom: [StorageType] { get }
}

/// Storage system types
enum StorageType: String, CaseIterable {
    case json = "JSON"
    case sqlite = "SQLite"
    case hybrid = "Hybrid"
    
    var displayName: String {
        switch self {
        case .json: return "JSON Files"
        case .sqlite: return "SQLite Database"
        case .hybrid: return "Hybrid (Migration)"
        }
    }
}

// MARK: - Default Implementations
extension StorageServiceProtocol {
    /// Default implementation for loading all events
    func loadEvents() async throws -> [AppActivationEvent] {
        return try await loadEvents(from: nil, to: nil, limit: nil)
    }
    
    /// Default implementation for loading all context switches
    func loadContextSwitches() async throws -> [ContextSwitchMetrics] {
        return try await loadContextSwitches(from: nil, to: nil, limit: nil)
    }
}