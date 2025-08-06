import Foundation
import Combine
import AppKit

// MARK: - Event Storage Service
// 
// Individual file storage service for AppActivationEvent objects
// Mirrors the successful AnalysisStorageService pattern to provide:
// - Immediate persistence (no debouncing)
// - Individual file per event (prevents data loss during crashes)
// - Directory-based organization
// - Thread-safe operations
// - Comprehensive error handling

class EventStorageService: ObservableObject {
    static let shared = EventStorageService() // Singleton for easy access
    
    @Published var events: [AppActivationEvent] = []
    @Published var isLoading: Bool = false
    @Published var isInitialLoadComplete: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage: String = "Loading events..."
    
    private let eventsDirectory: URL
    private let appDir: URL
    
    // Track whether initial load has started
    private var hasStartedInitialLoad = false
    private let loadLock = NSLock()
    
    // Serial queue for thread-safe file operations
    private let fileQueue = DispatchQueue(label: "com.focusmonitor.eventStorage", qos: .utility)
    
    // MARK: - Storage Error Types
    
    enum EventStorageError: Error {
        case fileCorrupted(String)
        case validationFailed(String)
        case diskSpaceInsufficient
        case eventNotFound(UUID)
        case directoryCreationFailed(String)
        
        var localizedDescription: String {
            switch self {
            case .fileCorrupted(let message):
                return "Event data corrupted: \(message)"
            case .validationFailed(let message):
                return "Event validation failed: \(message)"
            case .diskSpaceInsufficient:
                return "Insufficient disk space for event storage"
            case .eventNotFound(let id):
                return "Event with ID \(id) not found"
            case .directoryCreationFailed(let message):
                return "Failed to create events directory: \(message)"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Get the Application Support directory URL
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to get Application Support directory.")
        }
        
        // Use the same directory as DataStorage for consistency
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.FocusMonitor"
        let appDir = appSupportDir.appendingPathComponent(bundleID, isDirectory: true)
        
        // Create the app-specific directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appDir.path) {
            do {
                try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
                print("EventStorage: Created Application Support directory at: \(appDir.path)")
            } catch {
                fatalError("EventStorage: Unable to create Application Support directory: \(error.localizedDescription)")
            }
        }
        
        self.appDir = appDir
        self.eventsDirectory = appDir.appendingPathComponent("events", isDirectory: true)
        
        // Create events subdirectory if it doesn't exist
        if !FileManager.default.fileExists(atPath: eventsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: eventsDirectory, withIntermediateDirectories: true, attributes: nil)
                print("EventStorage: Created events directory at: \(eventsDirectory.path)")
            } catch {
                print("EventStorage: Failed to create events directory: \(error.localizedDescription)")
            }
        }
        
        // Check for migration from old DataStorage format
        migrateFromDataStorage()
        
        // Start background loading immediately but don't block initialization
        startBackgroundLoading()
    }
    
    // MARK: - Public Methods
    
    /// Ensure events are loaded - call this when you need access to events
    /// This method is safe to call multiple times and won't trigger duplicate loads
    func ensureEventsLoaded() {
        loadLock.lock()
        defer { loadLock.unlock() }
        
        guard !hasStartedInitialLoad else { return }
        hasStartedInitialLoad = true
        
        loadEventsProgressively()
    }
    
    /// Get events but ensure they're loaded first
    /// This is the preferred way to access events to guarantee they're available
    func getEventsAsync(completion: @escaping ([AppActivationEvent]) -> Void) {
        if isInitialLoadComplete {
            completion(events)
            return
        }
        
        ensureEventsLoaded()
        
        // Wait for load completion
        var observer: NSObjectProtocol?
        observer = NotificationCenter.default.addObserver(
            forName: .eventsLoadCompleted,
            object: nil,
            queue: .main
        ) { [weak self, weak observer] _ in
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
            completion(self?.events ?? [])
        }
    }
    
    /// Add a new event and save immediately to disk
    /// This method provides immediate persistence with no debouncing
    func addEvent(_ event: AppActivationEvent) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Validate event before saving
                try self.validateEvent(event)
                
                // Save individual file first
                try self.saveIndividualEvent(event)
                
                // Add to memory only after successful save
                DispatchQueue.main.async {
                    self.events.insert(event, at: 0) // Insert at beginning for chronological order
                    print("EventStorage: Successfully added event \(event.id) to storage")
                }
            } catch {
                print("EventStorage: Failed to save event file: \(error.localizedDescription)")
                // Optionally notify the UI of the error
                self.notifyEventError(error)
            }
        }
    }
    
    /// Add multiple events in batch
    func addEvents(_ events: [AppActivationEvent]) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            var successfullyAdded: [AppActivationEvent] = []
            
            for event in events {
                do {
                    try self.validateEvent(event)
                    try self.saveIndividualEvent(event)
                    successfullyAdded.append(event)
                } catch {
                    print("EventStorage: Failed to save event \(event.id): \(error.localizedDescription)")
                }
            }
            
            // Update memory with successfully added events
            DispatchQueue.main.async {
                let sortedEvents = successfullyAdded.sorted { $0.timestamp > $1.timestamp }
                self.events.insert(contentsOf: sortedEvents, at: 0)
                print("EventStorage: Successfully added \(successfullyAdded.count) out of \(events.count) events")
            }
        }
    }
    
    /// Remove an event by ID
    func removeEvent(withId id: UUID) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Find the event to get its filename
            guard let event = self.events.first(where: { $0.id == id }) else {
                print("EventStorage: Event with ID \(id) not found in memory")
                return
            }
            
            // Delete the file
            let fileURL = self.eventsDirectory.appendingPathComponent(event.fileName)
            do {
                try FileManager.default.removeItem(at: fileURL)
                
                // Remove from memory after successful file deletion
                DispatchQueue.main.async {
                    self.events.removeAll { $0.id == id }
                    print("EventStorage: Successfully removed event \(id)")
                }
            } catch {
                print("EventStorage: Failed to delete event file: \(error.localizedDescription)")
            }
        }
    }
    
    /// Get events filtered by date range
    func getEvents(from startDate: Date, to endDate: Date) -> [AppActivationEvent] {
        return events.filter { 
            $0.timestamp >= startDate && $0.timestamp <= endDate 
        }
    }
    
    /// Get events filtered by app name
    func getEvents(forApp appName: String) -> [AppActivationEvent] {
        return events.filter { $0.appName == appName }
    }
    
    /// Get events filtered by category
    func getEvents(forCategory category: AppCategory) -> [AppActivationEvent] {
        return events.filter { $0.category == category }
    }
    
    /// Get recent events (last N days)
    func getRecentEvents(days: Int = 7) -> [AppActivationEvent] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return events.filter { $0.timestamp > cutoffDate }
    }
    
    /// Get events by session ID
    func getEvents(forSessionId sessionId: UUID) -> [AppActivationEvent] {
        return events.filter { $0.sessionId == sessionId }
    }
    
    /// Force reload from disk
    func reloadEvents() {
        loadEvents()
    }
    
    /// Update an existing event with icon data (for bidirectional icon updates)
    /// This method updates only the in-memory copy since icons are not persisted
    func updateEventIcon(eventId: UUID, appIcon: NSImage?, siteFavicon: NSImage?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let index = self.events.firstIndex(where: { $0.id == eventId }) {
                var updatedEvent = self.events[index]
                updatedEvent.appIcon = appIcon
                updatedEvent.siteFavicon = siteFavicon
                self.events[index] = updatedEvent
                
                print("EventStorageService: Updated icon for event \(eventId)")
            }
        }
    }
    
    /// Update an existing event with Chrome tab data and domain-based category
    func updateEventChromeData(eventId: UUID, tabTitle: String, tabUrl: String, siteDomain: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let index = self.events.firstIndex(where: { $0.id == eventId }) {
                var updatedEvent = self.events[index]
                updatedEvent.chromeTabTitle = tabTitle
                updatedEvent.chromeTabUrl = tabUrl
                updatedEvent.siteDomain = siteDomain
                
                // Update category based on domain (if domain-specific category exists)
                if let domain = siteDomain {
                    let domainCategory = CategoryManager.shared.getCategoryForChromeTab(domain: domain)
                    updatedEvent.category = domainCategory
                    print("EventStorageService: Updated category to '\(domainCategory.name)' for domain '\(domain)'")
                }
                
                self.events[index] = updatedEvent
                
                print("EventStorageService: Updated Chrome data for event \(eventId)")
                print("EventStorageService: Title: '\(tabTitle)', Domain: '\(siteDomain ?? "nil")'")
            } else {
                print("EventStorageService: Could not find event \(eventId) to update Chrome data")
            }
        }
    }
    
    /// Batch update icons for multiple events
    func updateEventIcons(_ iconUpdates: [(eventId: UUID, appIcon: NSImage?, siteFavicon: NSImage?)]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var updatedCount = 0
            for update in iconUpdates {
                if let index = self.events.firstIndex(where: { $0.id == update.eventId }) {
                    var updatedEvent = self.events[index]
                    updatedEvent.appIcon = update.appIcon
                    updatedEvent.siteFavicon = update.siteFavicon
                    self.events[index] = updatedEvent
                    updatedCount += 1
                }
            }
            
            if updatedCount > 0 {
                print("EventStorageService: Updated icons for \(updatedCount) events")
            }
        }
    }
    
    /// Clear all events (use with caution)
    func clearAllEvents() {
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Remove all files in the events directory
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: self.eventsDirectory,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                ).filter { $0.pathExtension == "json" }
                
                for fileURL in fileURLs {
                    try FileManager.default.removeItem(at: fileURL)
                }
                
                // Clear memory
                DispatchQueue.main.async {
                    self.events.removeAll()
                    print("EventStorage: Successfully cleared all events")
                }
            } catch {
                print("EventStorage: Failed to clear events: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveIndividualEvent(_ event: AppActivationEvent) throws {
        // Check disk space
        try checkDiskSpace()
        
        // Create file URL
        let fileURL = eventsDirectory.appendingPathComponent(event.fileName)
        
        // Encode event
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(event)
        
        // Write atomically to prevent corruption
        try data.write(to: fileURL, options: .atomic)
    }
    
    /// Start background loading without blocking initialization
    private func startBackgroundLoading() {
        fileQueue.async { [weak self] in
            // Small delay to let the app fully initialize first
            Thread.sleep(forTimeInterval: 0.1)
            
            DispatchQueue.main.async {
                self?.ensureEventsLoaded()
            }
        }
    }
    
    /// Progressive loading: load recent events first, then older events
    private func loadEventsProgressively() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.loadingProgress = 0.0
            self.loadingMessage = "Loading recent events..."
        }
        
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Phase 1: Load recent events (last 2 hours) for immediate UI responsiveness  
                let initialEvents = try self.loadRecentEventsFromDirectory(hours: 2)
                
                DispatchQueue.main.async {
                    self.events = initialEvents.sorted { $0.timestamp > $1.timestamp }
                    self.loadingProgress = 0.2 // 20% complete after initial load
                    self.loadingMessage = "Loading historical events..."
                    print("EventStorage: Loaded \(initialEvents.count) initial events (last 2h)")
                    
                    // UI is now responsive with initial data
                    if initialEvents.count > 0 {
                        NotificationCenter.default.post(name: .recentEventsLoaded, object: nil)
                    }
                }
                
                // Phase 2: Load remaining events in small batches to avoid UI freeze
                self.loadRemainingEventsInBatches(excludingInitial: initialEvents)
            } catch {
                print("EventStorage: Error loading events: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self.events = []
                    self.isLoading = false
                    self.isInitialLoadComplete = true
                    NotificationCenter.default.post(name: .eventsLoadCompleted, object: nil)
                }
            }
        }
    }
    
    /// Legacy method for compatibility
    private func loadEvents() {
        loadEventsProgressively()
    }
    
    private func loadEventsFromDirectory() throws -> [AppActivationEvent] {
        guard FileManager.default.fileExists(atPath: eventsDirectory.path) else {
            return []
        }
        
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: eventsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "json" }
        
        var events: [AppActivationEvent] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for fileURL in fileURLs {
            do {
                let data = try Data(contentsOf: fileURL)
                let event = try decoder.decode(AppActivationEvent.self, from: data)
                events.append(event)
            } catch {
                print("EventStorage: Failed to load event from \(fileURL.lastPathComponent): \(error.localizedDescription)")
                // Continue loading other files even if one fails
            }
        }
        
        return events
    }
    
    /// Load only recent events from directory for fast initial UI population
    private func loadRecentEventsFromDirectory(hours: Int) throws -> [AppActivationEvent] {
        guard FileManager.default.fileExists(atPath: eventsDirectory.path) else {
            return []
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: eventsDirectory,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ).filter { url in
            guard url.pathExtension == "json" else { return false }
            
            // Quick file date check to avoid parsing old files
            if let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
               let modificationDate = resourceValues.contentModificationDate {
                return modificationDate >= cutoffDate
            }
            
            return true // Include if we can't determine the date
        }
        
        var recentEvents: [AppActivationEvent] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for fileURL in fileURLs {
            do {
                let data = try Data(contentsOf: fileURL)
                let event = try decoder.decode(AppActivationEvent.self, from: data)
                
                // Double-check the event timestamp
                if event.timestamp >= cutoffDate {
                    recentEvents.append(event)
                }
            } catch {
                // Continue loading other files even if one fails
                continue
            }
        }
        
        return recentEvents
    }
    
    /// Load remaining events in small batches to prevent UI freezing
    private func loadRemainingEventsInBatches(excludingInitial initialEvents: [AppActivationEvent]) {
        let initialEventIds = Set(initialEvents.map { $0.id })
        let batchSize = 10
        
        DispatchQueue.main.async {
            self.loadingMessage = "Processing historical data..."
        }
        
        guard FileManager.default.fileExists(atPath: eventsDirectory.path) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.isInitialLoadComplete = true
                NotificationCenter.default.post(name: .eventsLoadCompleted, object: nil)
            }
            return
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: eventsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "json" }
            
            var remainingEvents: [AppActivationEvent] = []
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Pre-load all events but filter out initial ones
            for fileURL in fileURLs {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let event = try decoder.decode(AppActivationEvent.self, from: data)
                    
                    // Skip events we already loaded initially
                    if !initialEventIds.contains(event.id) {
                        remainingEvents.append(event)
                    }
                } catch {
                    // Continue loading other files even if one fails
                    continue
                }
            }
            
            // Sort all remaining events once
            remainingEvents.sort { $0.timestamp > $1.timestamp }
            
            // Process in batches with delays to prevent UI freezing
            self.processBatchedEvents(remainingEvents, batchSize: batchSize, currentIndex: 0, totalCount: remainingEvents.count)
            
        } catch {
            print("EventStorage: Error loading remaining events: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading = false
                self.isInitialLoadComplete = true
                NotificationCenter.default.post(name: .eventsLoadCompleted, object: nil)
            }
        }
    }
    
    /// Process events in small batches with UI updates
    private func processBatchedEvents(_ allEvents: [AppActivationEvent], batchSize: Int, currentIndex: Int, totalCount: Int) {
        guard currentIndex < allEvents.count else {
            // All batches processed
            DispatchQueue.main.async {
                self.isLoading = false
                self.isInitialLoadComplete = true
                self.loadingProgress = 1.0
                self.loadingMessage = "Loading complete"
                print("EventStorage: Successfully loaded all \(self.events.count) events in batches")
                NotificationCenter.default.post(name: .eventsLoadCompleted, object: nil)
            }
            return
        }
        
        let endIndex = min(currentIndex + batchSize, allEvents.count)
        let batch = Array(allEvents[currentIndex..<endIndex])
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Insert batch into existing events while maintaining sort order
            for event in batch {
                // Find insertion point to maintain chronological order
                if let insertIndex = self.events.firstIndex(where: { $0.timestamp < event.timestamp }) {
                    self.events.insert(event, at: insertIndex)
                } else {
                    // Event is oldest, add to end
                    self.events.append(event)
                }
            }
            
            // Update progress
            let progress = 0.2 + (0.8 * Double(endIndex) / Double(totalCount)) // Start from 20% (after initial load)
            self.loadingProgress = progress
            self.loadingMessage = "Loading events... (\(self.events.count) loaded)"
            
            print("EventStorage: Loaded batch \(currentIndex/batchSize + 1), total events now: \(self.events.count)")
            
            // Schedule next batch with small delay to keep UI responsive
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.02) { [weak self] in
                self?.processBatchedEvents(allEvents, batchSize: batchSize, currentIndex: endIndex, totalCount: totalCount)
            }
        }
    }
    
    private func validateEvent(_ event: AppActivationEvent) throws {
        // Check required fields
        guard !event.id.uuidString.isEmpty else {
            throw EventStorageError.validationFailed("Event ID is empty")
        }
        
        // Check app name is not empty (can be nil but not empty string)
        if let appName = event.appName, appName.isEmpty {
            throw EventStorageError.validationFailed("Event app name is empty")
        }
        
        // Check timestamp is reasonable (not too far in the future)
        let futureLimit = Date().addingTimeInterval(60 * 60) // 1 hour in the future
        if event.timestamp > futureLimit {
            throw EventStorageError.validationFailed("Event timestamp is too far in the future")
        }
        
        // Check session consistency
        if event.isSessionStart && event.sessionId == nil {
            throw EventStorageError.validationFailed("Session start event must have a session ID")
        }
        
        if event.isSessionEnd && event.sessionId == nil {
            throw EventStorageError.validationFailed("Session end event must have a session ID")
        }
    }
    
    private func checkDiskSpace() throws {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: appDir.path),
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return // Can't check, assume it's fine
        }
        
        let requiredSpace: Int64 = 10 * 1024 * 1024 // 10 MB minimum
        if freeSpace < requiredSpace {
            throw EventStorageError.diskSpaceInsufficient
        }
    }
    
    private func notifyEventError(_ error: Error) {
        DispatchQueue.main.async {
            // Post notification for UI to handle
            NotificationCenter.default.post(
                name: .eventStorageError,
                object: nil,
                userInfo: ["error": error]
            )
        }
    }
    
    // MARK: - Public Getters for Data Export
    
    var dataDirectoryURL: URL {
        return eventsDirectory
    }
    
    var eventCount: Int {
        return events.count
    }
    
    var oldestEventDate: Date? {
        return events.min(by: { $0.timestamp < $1.timestamp })?.timestamp
    }
    
    var newestEventDate: Date? {
        return events.max(by: { $0.timestamp < $1.timestamp })?.timestamp
    }
}

// MARK: - AppActivationEvent Extensions for File Storage

extension AppActivationEvent {
    /// Generate a unique filename for this event
    /// Pattern: YYYY-MM-DD_HH-mm-ss_appname_sessionInfo_UUID.json
    var fileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: timestamp)
        
        // Clean app name for filename (remove invalid characters)
        let cleanAppName = (appName ?? "unknown")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "*", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "<", with: "_")
            .replacingOccurrences(of: ">", with: "_")
            .replacingOccurrences(of: "|", with: "_")
            .lowercased()
        
        // Add session info if available
        var sessionInfo = ""
        if isSessionStart {
            sessionInfo = "_session_start"
        } else if isSessionEnd {
            sessionInfo = "_session_end"
        }
        
        // Use first 8 characters of UUID for uniqueness
        let shortId = String(id.uuidString.prefix(8))
        
        return "\(dateString)_\(cleanAppName)\(sessionInfo)_\(shortId).json"
    }
    
    /// Human-readable description for logging
    var logDescription: String {
        let appInfo = appName ?? "Unknown App"
        let sessionInfo = isSessionStart ? " [Session Start]" : (isSessionEnd ? " [Session End]" : "")
        return "\(appInfo) at \(timestamp.formatted())\(sessionInfo)"
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let eventStorageError = Notification.Name("EventStorageError")
    static let recentEventsLoaded = Notification.Name("RecentEventsLoaded")
    static let eventsLoadCompleted = Notification.Name("EventsLoadCompleted")
}

// MARK: - Migration Support

extension EventStorageService {
    /// Migrate events from the old DataStorage.swift format
    /// This method reads from the single JSON file and converts to individual files
    func migrateFromDataStorage() {
        let oldEventsURL = appDir.appendingPathComponent("activity_events.json")
        
        guard FileManager.default.fileExists(atPath: oldEventsURL.path) else {
            print("EventStorage: No old events file found for migration")
            return
        }
        
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try Data(contentsOf: oldEventsURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let oldEvents = try decoder.decode([AppActivationEvent].self, from: data)
                
                print("EventStorage: Found \(oldEvents.count) events to migrate")
                
                // Save each event as individual file
                var migratedCount = 0
                for event in oldEvents {
                    do {
                        try self.saveIndividualEvent(event)
                        migratedCount += 1
                    } catch {
                        print("EventStorage: Failed to migrate event \(event.id): \(error.localizedDescription)")
                    }
                }
                
                print("EventStorage: Successfully migrated \(migratedCount) out of \(oldEvents.count) events")
                
                // Create backup of old file before removing
                let backupURL = self.appDir.appendingPathComponent("activity_events_backup_\(Date().timeIntervalSince1970).json")
                try FileManager.default.copyItem(at: oldEventsURL, to: backupURL)
                
                // Remove old file after successful migration
                try FileManager.default.removeItem(at: oldEventsURL)
                
                print("EventStorage: Migration completed. Old file backed up and removed.")
                
                // Reload events to update memory
                self.loadEvents()
                
            } catch {
                print("EventStorage: Migration failed: \(error.localizedDescription)")
            }
        }
    }
}