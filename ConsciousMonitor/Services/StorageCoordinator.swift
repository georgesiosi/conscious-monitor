//
//  StorageCoordinator.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

/// Coordinates between different storage systems during migration
/// Provides a single interface for ActivityMonitor to use regardless of active storage backend
class StorageCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentBackend: StorageBackend = .json
    @Published var migrationState: MigrationState = .notStarted
    @Published var migrationProgress: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var lastError: Error?
    
    // MARK: - Storage Backends
    enum StorageBackend {
        case json
        case sqlite
        case hybrid // During migration
    }
    
    enum MigrationState {
        case notStarted
        case inProgress
        case completed
        case failed
        case rollback
    }
    
    // MARK: - Current Storage Service
    var currentStorageService: any StorageServiceProtocol {
        switch currentBackend {
        case .json:
            return jsonStorageService
        case .sqlite:
            return sqliteStorageService
        case .hybrid:
            return sqliteStorageService // Use SQLite during hybrid mode
        }
    }
    
    // MARK: - Storage Services
    private let jsonStorageService = EventStorageServiceAdapter()
    private let sqliteStorageService = SQLiteStorageService.shared
    private let migrationService = DatabaseMigrationService()
    
    // MARK: - Properties for External Binding
    @Published var events: [AppActivationEvent] = []
    @Published var contextSwitches: [ContextSwitchMetrics] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupStorageBackend()
        setupBindings()
        checkMigrationStatus()
    }
    
    // MARK: - Setup Methods
    private func setupStorageBackend() {
        // Check if SQLite migration has been completed
        if DatabaseMigrationService.isMigrationCompleted() {
            currentBackend = .sqlite
        } else {
            currentBackend = .json
        }
    }
    
    private func setupBindings() {
        // Bind to current storage service
        bindToCurrentStorageService()
        
        // Monitor backend changes
        $currentBackend
            .sink { [weak self] _ in
                self?.bindToCurrentStorageService()
            }
            .store(in: &cancellables)
        
        // Monitor migration service
        migrationService.$migrationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .notStarted:
                    self?.migrationState = .notStarted
                case .inProgress, .validating:
                    self?.migrationState = .inProgress
                case .completed:
                    self?.migrationState = .completed
                    self?.currentBackend = .sqlite
                case .failed:
                    self?.migrationState = .failed
                case .rolledBack:
                    self?.migrationState = .rollback
                    self?.currentBackend = .json
                }
            }
            .store(in: &cancellables)
        
        migrationService.$progress
            .receive(on: DispatchQueue.main)
            .assign(to: \.migrationProgress, on: self)
            .store(in: &cancellables)
        
        migrationService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastError, on: self)
            .store(in: &cancellables)
    }
    
    private func bindToCurrentStorageService() {
        // Clear existing bindings
        cancellables.removeAll()
        
        let service = currentStorageService
        
        // Bind events
        if let publisher = (service as? any ObservableObject)?.objectWillChange {
            publisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.events = service.events
                    self?.contextSwitches = service.contextSwitches
                    self?.isLoading = service.isLoading
                    self?.lastError = service.lastError
                }
                .store(in: &cancellables)
        }
        
        // Initial data load
        events = service.events
        contextSwitches = service.contextSwitches
        isLoading = service.isLoading
        lastError = service.lastError
        
        // Re-setup migration bindings
        setupBindings()
    }
    
    private func checkMigrationStatus() {
        if DatabaseMigrationService.isMigrationCompleted() {
            migrationState = .completed
        }
    }
    
    // MARK: - Storage Operations (Proxy Methods)
    
    func addEvent(_ event: AppActivationEvent) async throws {
        try await currentStorageService.addEvent(event)
    }
    
    func addEvents(_ events: [AppActivationEvent]) async throws {
        try await currentStorageService.addEvents(events)
    }
    
    func loadEvents(from startDate: Date? = nil, to endDate: Date? = nil, limit: Int? = nil) async throws -> [AppActivationEvent] {
        return try await currentStorageService.loadEvents(from: startDate, to: endDate, limit: limit)
    }
    
    func addContextSwitch(_ contextSwitch: ContextSwitchMetrics) async throws {
        try await currentStorageService.addContextSwitch(contextSwitch)
    }
    
    func loadContextSwitches(from startDate: Date? = nil, to endDate: Date? = nil, limit: Int? = nil) async throws -> [ContextSwitchMetrics] {
        return try await currentStorageService.loadContextSwitches(from: startDate, to: endDate, limit: limit)
    }
    
    func getAppUsageStats(from startDate: Date, to endDate: Date) async throws -> [AppUsageStat] {
        return try await currentStorageService.getAppUsageStats(from: startDate, to: endDate)
    }
    
    // MARK: - Migration Control
    
    /// Start migration from JSON to SQLite
    func startMigration() async {
        guard currentBackend == .json && migrationState == .notStarted else { return }
        
        await MainActor.run {
            currentBackend = .hybrid
            migrationState = .inProgress
        }
        
        await migrationService.performMigration()
    }
    
    /// Check if migration is available
    var canMigrate: Bool {
        return currentBackend == .json && migrationState == .notStarted
    }
    
    /// Check if SQLite is currently active
    var isSQLiteActive: Bool {
        return currentBackend == .sqlite
    }
    
    /// Get current storage type for UI display
    var currentStorageType: StorageType {
        return currentStorageService.storageType
    }
    
    // MARK: - Analytics and Performance
    
    /// Get performance metrics for current storage system
    func getStoragePerformanceMetrics() async -> StoragePerformanceMetrics {
        let eventCount = events.count
        let contextSwitchCount = contextSwitches.count
        let totalItems = eventCount + contextSwitchCount
        
        let memoryUsage = await estimateMemoryUsage()
        
        return StoragePerformanceMetrics(
            storageType: currentStorageType,
            totalEvents: eventCount,
            totalContextSwitches: contextSwitchCount,
            totalItems: totalItems,
            estimatedMemoryUsage: memoryUsage,
            loadingTime: 0.0, // TODO: Measure actual loading time
            queryPerformance: isSQLiteActive ? .excellent : .good
        )
    }
    
    private func estimateMemoryUsage() async -> Double {
        // Rough estimation of memory usage
        let eventSize = MemoryLayout<AppActivationEvent>.size
        let contextSwitchSize = MemoryLayout<ContextSwitchMetrics>.size
        
        let eventsMemory = Double(events.count * eventSize)
        let contextSwitchesMemory = Double(contextSwitches.count * contextSwitchSize)
        
        return (eventsMemory + contextSwitchesMemory) / (1024 * 1024) // Convert to MB
    }
}

// MARK: - Storage Performance Metrics
struct StoragePerformanceMetrics {
    let storageType: StorageType
    let totalEvents: Int
    let totalContextSwitches: Int
    let totalItems: Int
    let estimatedMemoryUsage: Double // MB
    let loadingTime: TimeInterval
    let queryPerformance: QueryPerformance
    
    enum QueryPerformance {
        case excellent
        case good
        case fair
        case poor
        
        var description: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good" 
            case .fair: return "Fair"
            case .poor: return "Poor"
            }
        }
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }
    }
}

// MARK: - Static Utilities
extension StorageCoordinator {
    /// Check if system needs migration
    static func needsMigration() -> Bool {
        return !DatabaseMigrationService.isMigrationCompleted()
    }
    
    /// Get migration completion date if available
    static func getMigrationDate() -> Date? {
        return DatabaseMigrationService.getMigrationDate()
    }
}