//
//  ActivityMonitor+SQLiteIntegration.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

/// Extension to ActivityMonitor for SQLite integration
/// Provides seamless migration between JSON and SQLite storage systems
extension ActivityMonitor {
    
    // MARK: - Storage Coordinator Integration
    
    /// Initialize the new storage system with backward compatibility
    func setupStorageCoordinator() {
        // Replace existing storage bindings with StorageCoordinator
        setupStorageCoordinatorBindings()
        
        // Monitor migration progress
        setupMigrationMonitoring()
        
        // Check if migration is needed
        checkMigrationStatus()
    }
    
    private func setupStorageCoordinatorBindings() {
        // Create storage coordinator if not exists
        if storageCoordinator == nil {
            storageCoordinator = StorageCoordinator()
        }
        
        guard let coordinator = storageCoordinator else { return }
        
        // Bind events from storage coordinator
        coordinator.$events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                self?.mergeEventsPreservingIcons(newEvents: events)
            }
            .store(in: &cancellables)
        
        // Bind context switches from storage coordinator
        coordinator.$contextSwitches
            .receive(on: DispatchQueue.main)
            .assign(to: \.contextSwitches, on: self)
            .store(in: &cancellables)
        
        // Bind loading state
        coordinator.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                // Update UI loading state if needed
                self?.isStorageLoading = isLoading
            }
            .store(in: &cancellables)
        
        // Bind error state
        coordinator.$lastError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.lastDataError = error.localizedDescription
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupMigrationMonitoring() {
        guard let coordinator = storageCoordinator else { return }
        
        // Monitor migration progress
        coordinator.$migrationProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.migrationProgress = progress
            }
            .store(in: &cancellables)
        
        // Monitor migration state changes
        coordinator.$migrationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleMigrationStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func checkMigrationStatus() {
        if StorageCoordinator.needsMigration() {
            // Show migration prompt to user
            showMigrationPrompt = true
        }
    }
    
    private func handleMigrationStateChange(_ state: StorageCoordinator.MigrationState) {
        switch state {
        case .notStarted:
            migrationStatus = "Ready to migrate"
        case .inProgress:
            migrationStatus = "Migration in progress..."
        case .completed:
            migrationStatus = "Migration completed successfully"
            showMigrationPrompt = false
            // Refresh data bindings for new storage system
            refreshDataBindings()
        case .failed:
            migrationStatus = "Migration failed"
        case .rollback:
            migrationStatus = "Migration rolled back"
        }
    }
    
    private func refreshDataBindings() {
        // Refresh app usage stats after migration
        Task {
            await updateAppUsageStatsAsync()
        }
    }
    
    // MARK: - Migration Control
    
    /// Start migration to SQLite storage
    func startSQLiteMigration() async {
        guard let coordinator = storageCoordinator else { return }
        
        await MainActor.run {
            isMigrating = true
        }
        
        await coordinator.startMigration()
        
        await MainActor.run {
            isMigrating = false
        }
    }
    
    /// Check if migration is available
    var canMigrateToSQLite: Bool {
        return storageCoordinator?.canMigrate ?? false
    }
    
    /// Check if currently using SQLite
    var isUsingSQLite: Bool {
        return storageCoordinator?.isSQLiteActive ?? false
    }
    
    /// Get current storage type
    var currentStorageType: StorageType {
        return storageCoordinator?.currentStorageType ?? .json
    }
    
    // MARK: - Enhanced Storage Operations
    
    /// Add event using new storage system
    private func addEventToStorage(_ event: AppActivationEvent) async {
        do {
            try await storageCoordinator?.addEvent(event)
        } catch {
            await MainActor.run {
                lastDataError = "Failed to save event: \(error.localizedDescription)"
            }
        }
    }
    
    /// Add context switch using new storage system
    private func addContextSwitchToStorage(_ contextSwitch: ContextSwitchMetrics) async {
        do {
            try await storageCoordinator?.addContextSwitch(contextSwitch)
        } catch {
            await MainActor.run {
                lastDataError = "Failed to save context switch: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Performance Optimized Analytics
    
    /// Update app usage stats using optimized storage queries
    private func updateAppUsageStatsAsync() async {
        guard let coordinator = storageCoordinator else { return }
        
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? Date()
            
            let stats = try await coordinator.getAppUsageStats(from: startDate, to: endDate)
            
            await MainActor.run {
                self.appUsageStats = stats
            }
        } catch {
            await MainActor.run {
                self.lastDataError = "Failed to calculate usage stats: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Storage Performance Monitoring
    
    /// Get storage performance metrics
    func getStoragePerformanceMetrics() async -> StoragePerformanceMetrics? {
        return await storageCoordinator?.getStoragePerformanceMetrics()
    }
    
    // MARK: - Backward Compatibility Methods
    
    /// Override existing event saving to use new storage system
    func saveEventToNewStorage(_ event: AppActivationEvent) {
        Task {
            await addEventToStorage(event)
        }
    }
    
    /// Override existing context switch saving to use new storage system
    func saveContextSwitchToNewStorage(_ contextSwitch: ContextSwitchMetrics) {
        Task {
            await addContextSwitchToStorage(contextSwitch)
        }
    }
    
    // MARK: - Advanced Analytics (SQLite-Powered)
    
    /// Get advanced analytics using SQLite queries (when available)
    func getAdvancedAnalytics() async -> AdvancedAnalytics? {
        guard isUsingSQLite else { return nil }
        
        // TODO: Implement advanced analytics using SQLite queries
        // This would include complex aggregations, trends, and insights
        // that are only possible with a relational database
        
        return nil
    }
}

// MARK: - Convenience Methods for SQLite Integration
extension ActivityMonitor {
    
    /// Force save all data using new storage system (for app termination)
    func forceSaveAllDataWithSQLite() {
        // For SQLite, data is automatically saved with transactions
        // For JSON, use the existing batch save mechanism
        if isUsingSQLite {
            print("SQLite storage - data automatically saved with transactions")
        } else {
            performBatchSave()
        }
    }
}

// MARK: - Advanced Analytics Models
struct AdvancedAnalytics {
    let productivityTrends: [ProductivityTrend]
    let focusPatterns: [FocusPattern]
    let contextSwitchAnalysis: ContextSwitchAnalysis
    let appCategoryInsights: [AppCategoryInsight]
    let weeklyComparison: WeeklyComparison
    
    struct ProductivityTrend {
        let date: Date
        let productivityScore: Double
        let focusTime: TimeInterval
        let distractionTime: TimeInterval
    }
    
    struct FocusPattern {
        let timeOfDay: Int // Hour of day
        let averageFocusTime: TimeInterval
        let commonApps: [String]
    }
    
    struct ContextSwitchAnalysis {
        let averageSwitchesPerHour: Double
        let mostDisruptiveApps: [String]
        let optimalFocusBlocks: [TimeInterval]
    }
    
    struct AppCategoryInsight {
        let category: AppCategory
        let timeSpent: TimeInterval
        let trendDirection: TrendDirection
        let weekOverWeekChange: Double
        
        enum TrendDirection {
            case increasing
            case decreasing
            case stable
        }
    }
    
    struct WeeklyComparison {
        let currentWeekFocusTime: TimeInterval
        let previousWeekFocusTime: TimeInterval
        let improvement: Double // Percentage change
    }
}