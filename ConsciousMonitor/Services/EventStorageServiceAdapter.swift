//
//  EventStorageServiceAdapter.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Foundation
import Combine

/// Adapter to make EventStorageService conform to StorageServiceProtocol
/// Provides compatibility layer during SQLite migration
class EventStorageServiceAdapter: ObservableObject, StorageServiceProtocol {
    
    // MARK: - Dependencies
    private let eventStorageService = EventStorageService.shared
    private let dataStorage = DataStorage.shared
    
    // MARK: - Published Properties
    @Published var events: [AppActivationEvent] = []
    @Published var contextSwitches: [ContextSwitchMetrics] = []
    @Published var isLoading: Bool = false
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - StorageServiceProtocol Compliance
    var storageType: StorageType { return .json }
    var supportsMigrationFrom: [StorageType] { return [] }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadInitialData()
    }
    
    private func setupBindings() {
        // Bind to EventStorageService events
        eventStorageService.$events
            .receive(on: DispatchQueue.main)
            .assign(to: \.events, on: self)
            .store(in: &cancellables)
        
        // Bind to EventStorageService loading state
        eventStorageService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        // Load context switches from DataStorage
        loadContextSwitchesFromDataStorage()
    }
    
    private func loadInitialData() {
        // EventStorageService loads events automatically
        // Just need to trigger context switches loading
        loadContextSwitchesFromDataStorage()
    }
    
    private func loadContextSwitchesFromDataStorage() {
        dataStorage.loadContextSwitches { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let switches):
                    self?.contextSwitches = switches
                case .failure(let error):
                    self?.lastError = error
                    print("Failed to load context switches: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Event Operations
    func addEvent(_ event: AppActivationEvent) async throws {
        await MainActor.run {
            eventStorageService.addEvent(event)
        }
    }
    
    func addEvents(_ events: [AppActivationEvent]) async throws {
        for event in events {
            try await addEvent(event)
        }
    }
    
    func loadEvents(from startDate: Date? = nil, to endDate: Date? = nil, limit: Int? = nil) async throws -> [AppActivationEvent] {
        return await MainActor.run {
            var filteredEvents = eventStorageService.events
            
            // Apply date range filter
            if let startDate = startDate {
                filteredEvents = filteredEvents.filter { $0.timestamp >= startDate }
            }
            if let endDate = endDate {
                filteredEvents = filteredEvents.filter { $0.timestamp <= endDate }
            }
            
            // Apply limit
            if let limit = limit {
                filteredEvents = Array(filteredEvents.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
            }
            
            return filteredEvents
        }
    }
    
    // MARK: - Context Switch Operations
    func addContextSwitch(_ contextSwitch: ContextSwitchMetrics) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                // Add to local array
                self.contextSwitches.append(contextSwitch)
                
                // Save to DataStorage
                self.dataStorage.saveContextSwitches(self.contextSwitches) { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        // Remove from local array on failure
                        self.contextSwitches.removeAll { $0.id == contextSwitch.id }
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func loadContextSwitches(from startDate: Date? = nil, to endDate: Date? = nil, limit: Int? = nil) async throws -> [ContextSwitchMetrics] {
        return await MainActor.run {
            var filteredSwitches = self.contextSwitches
            
            // Apply date range filter
            if let startDate = startDate {
                filteredSwitches = filteredSwitches.filter { $0.timestamp >= startDate }
            }
            if let endDate = endDate {
                filteredSwitches = filteredSwitches.filter { $0.timestamp <= endDate }
            }
            
            // Apply limit
            if let limit = limit {
                filteredSwitches = Array(filteredSwitches.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
            }
            
            return filteredSwitches
        }
    }
    
    // MARK: - Analytics Support
    func getAppUsageStats(from startDate: Date, to endDate: Date) async throws -> [AppUsageStat] {
        let filteredEvents = try await loadEvents(from: startDate, to: endDate)
        
        return await MainActor.run {
            // Group events by app using string key
            let groupedEvents = Dictionary(grouping: filteredEvents) { event in
                "\(event.appName ?? "Unknown")|\(event.bundleIdentifier ?? "")"
            }
            
            // Create usage stats
            return groupedEvents.compactMap { (key, events) -> AppUsageStat? in
                let components = key.split(separator: "|", maxSplits: 1)
                let appName = String(components.first ?? "Unknown")
                let bundleId = components.count > 1 ? String(components[1]) : ""
                guard !appName.isEmpty && appName != "Unknown" else { return nil }
                
                let lastEvent = events.max { $0.timestamp < $1.timestamp }
                let category = events.first?.category ?? AppCategory.other
                
                return AppUsageStat(
                    id: UUID(),
                    appName: appName,
                    bundleIdentifier: bundleId.isEmpty ? nil : bundleId,
                    activationCount: events.count,
                    lastActiveTimestamp: lastEvent?.timestamp ?? Date(),
                    category: category,
                    siteBreakdown: nil // TODO: Implement if needed
                )
            }.sorted { $0.activationCount > $1.activationCount }
        }
    }
}