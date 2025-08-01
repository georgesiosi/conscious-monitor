import Foundation
import AppKit // Required for NSWorkspace
import Combine // For ObservableObject
import SwiftUI // For Color and other UI elements

// Class to monitor application activations
class ActivityMonitor: ObservableObject {
    // Published property to hold the list of activation events
    @Published var activationEvents: [AppActivationEvent] = []
    
    // Published property to track context switches between apps
    @Published var contextSwitches: [ContextSwitchMetrics] = []
    
    // Published property for data error notifications
    @Published var lastDataError: String?
    
    // Focus state detector for real-time awareness
    @Published var focusStateDetector = FocusStateDetector()
    
    // Published property for app usage statistics (computed from activationEvents)
    @Published var appUsageStats: [AppUsageStat] = []
    
    // SQLite Migration Properties
    @Published var showMigrationPrompt: Bool = false
    @Published var isMigrating: Bool = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationStatus: String = ""
    @Published var isStorageLoading: Bool = false
    
    // Track the last app switch for context tracking
    internal var lastAppSwitch: (name: String, timestamp: Date, bundleId: String?, category: AppCategory)?
    
    // Smart debouncing state
    private var pendingActivation: (app: String, timestamp: Date, bundleId: String?)?
    private var debounceTimer: Timer?
    
    // Debouncing for batch saves
    private var saveTimer: Timer?
    private let saveDebounceInterval: TimeInterval = 0.5 // Reduced to 0.5 seconds to prevent data loss
    private var pendingContextSwitchSave = false
    
    // Session tracking properties
    internal var lastEventTime: Date?
    internal var currentSessionId: UUID?
    internal var currentSessionStartTime: Date?
    internal var currentSessionSwitchCount: Int = 0
    
    // Subscription storage
    internal var cancellables = Set<AnyCancellable>()
    
    // Removed debouncing infrastructure - now using immediate saves
    
    // Thread safety
    private let dataQueue = DispatchQueue(label: "com.focusmonitor.activityMonitor", qos: .utility)
    
    // Data management
    private var cleanupTimer: Timer?
    private var lastCleanupTime: Date = Date()
    
    // Analytics cache for expensive calculations
    internal var cachedAllTimeStats: (count: Int, lastUpdate: Date)?
    internal var cachedTotalContextSwitches: (count: Int, lastUpdate: Date)?
    
    // Analytics service for calculations
    internal let analyticsService = AnalyticsService()
    
    // MARK: - Smart Analytics Integration
    
    /// Get intelligently processed events for better analytics
    func getProcessedEvents() -> [SmartSwitchDetector.ProcessedEvent] {
        return analyticsService.getProcessedEvents(from: activationEvents)
    }
    
    /// Get productivity metrics based on intelligent event processing
    func getProductivityMetrics() -> ProductivityMetrics {
        return analyticsService.getProductivityMetrics(from: activationEvents)
    }
    
    /// Get intelligently filtered context switches (experimental)
    func getIntelligentContextSwitches() -> [ContextSwitchMetrics] {
        return analyticsService.getIntelligentContextSwitches(from: activationEvents)
    }
    
    // MARK: - Session Management
    // Session management methods are defined in SessionManager.swift extension
    // Chrome integration methods are defined in ChromeIntegration.swift extension
    
    // MARK: - Data Persistence
    
    private let dataStorage = DataStorage.shared
    private let eventStorageService = EventStorageService.shared
    
    // SQLite Storage Coordinator
    private static var _storageCoordinator: StorageCoordinator?
    var storageCoordinator: StorageCoordinator? {
        get {
            if ActivityMonitor._storageCoordinator == nil {
                ActivityMonitor._storageCoordinator = StorageCoordinator()
            }
            return ActivityMonitor._storageCoordinator
        }
        set {
            ActivityMonitor._storageCoordinator = newValue
        }
    }
    
    // Load context switches from disk
    private func loadContextSwitches() {
        dataStorage.loadContextSwitches { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let switches):
                    self?.contextSwitches = switches
                case .failure(let error):
                    print("Failed to load context switches: \(error.localizedDescription)")
                    self?.lastDataError = "Failed to load context switches: \(error.localizedDescription)"
                    // Try migration as fallback
                    self?.dataStorage.migrateFromUserDefaults()
                }
            }
        }
    }
    
    // Save context switches to disk with debouncing
    private func saveContextSwitches() {
        scheduleContextSwitchSave()
    }
    
    private func scheduleContextSwitchSave() {
        pendingContextSwitchSave = true
        scheduleSave()
    }
    
    private func performContextSwitchSave() {
        guard pendingContextSwitchSave else { return }
        pendingContextSwitchSave = false
        
        dataStorage.saveContextSwitches(contextSwitches) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Successfully saved
                    break
                case .failure(let error):
                    print("Failed to save context switches: \(error.localizedDescription)")
                    self?.lastDataError = "Failed to save context switches: \(error.localizedDescription)"
                    self?.dataStorage.notifyDataError(error)
                }
            }
        }
    }
    
    // Debouncing mechanism for batch saves
    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            self?.performBatchSave()
        }
    }
    
    // Load events from disk (now using EventStorageService)
    private func loadEvents() {
        // Set up the binding to EventStorageService events property
        setupEventStorageBinding()
        
        // EventStorageService now handles loading in background automatically
        // Migration is also handled automatically during EventStorageService init
        // No blocking operations here - UI remains responsive
    }
    
    // Save events to disk (now using EventStorageService - immediate persistence)
    private func saveEvents() {
        // EventStorageService handles immediate persistence, no debouncing needed
        // Individual events are saved immediately when added via addEvent()
        // This method is kept for compatibility but does nothing
    }
    
    private func scheduleEventSave() {
        // No longer needed - EventStorageService provides immediate persistence
        // Kept for compatibility
    }
    
    private func performEventSave() {
        // No longer needed - EventStorageService provides immediate persistence  
        // Kept for compatibility
    }
    
    func performBatchSave() {
        // Events are now saved immediately via EventStorageService
        // Only context switches need batch saving
        if pendingContextSwitchSave {
            performContextSwitchSave()
        }
    }
    
    // --- Cost Calculation Properties ---
    static let minutesLostPerSwitch: Double = AnalyticsService.minutesLostPerSwitch // Use value from analytics service
    
    // Constants for session tracking
    static let debounceThreshold: TimeInterval = 0.2 // 200ms debounce period
    static let smartDebounceThreshold: TimeInterval = 8.0 // 8 seconds for intelligent grouping
    static let sessionThreshold: TimeInterval = 300 // 5 minutes between sessions
    static let maxSessionDuration: TimeInterval = 3600 // 1 hour max session duration
    
    // --- Data Management Properties ---
    static let maxInMemoryEvents: Int = 20000 // Maximum events to keep in memory (increased for better analytics)
    static let maxInMemoryContextSwitches: Int = 10000 // Maximum context switches to keep in memory (increased for better analytics)
    static let dataRetentionDays: Int = 2 // Keep last 2 days in memory for real-time features
    static let cleanupInterval: TimeInterval = 300 // 5 minutes between cleanup operations
    
    // --- End Cost Calculation Properties ---

    init() {
        print("ActivityMonitor initialized.")
        
        // Core functionality that must happen immediately
        setupAppActivationObserver()
        setupDataErrorListener()
        
        // Setup reactive updates for appUsageStats (needed for UI binding)
        setupAppUsageStatsUpdates()
        
        // Defer heavy operations to prevent blocking startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.initializeDataSources()
        }
        
        // Defer icon loading and other heavy operations further
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.initializeBackgroundServices()
        }
    }
    
    /// Initialize data sources in background without blocking app startup
    private func initializeDataSources() {
        // Load existing data from storage (now non-blocking)
        loadEvents()
        loadContextSwitches()
        
        // Setup periodic data cleanup
        setupDataCleanup()
    }
    
    /// Initialize background services that can be deferred
    private func initializeBackgroundServices() {
        // Initialize awareness notifications
        _ = AwarenessNotificationService.shared
        AwarenessNotificationService.shared.setupNotificationCategories()
        
        // Setup productivity insights timer
        setupProductivityInsightsTimer()
        
        // Defer icon loading even further to ensure app is fully responsive
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.initializeIconLoading()
        }
    }
    
    /// Initialize icon loading as the final step
    private func initializeIconLoading() {
        // Preload common app icons and load icons for existing events
        IconLoadingService.shared.preloadCommonIcons()
        loadIconsForExistingEvents()
        
        // Set up a timer to retry loading missing icons after app fully loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.retryIconLoadingForMissingIcons()
        }
    }
    
    private func setupAppUsageStatsUpdates() {
        // Watch for changes to activationEvents and update appUsageStats
        $activationEvents
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] events in
                self?.updateAppUsageStats(from: events)
            }
            .store(in: &cancellables)
        
        // Trigger initial update with current events
        updateAppUsageStats(from: activationEvents)
    }
    
    private func updateAppUsageStats(from events: [AppActivationEvent]) {
        self.appUsageStats = analyticsService.generateAppUsageStats(from: events)
    }
    
    private func setupDataErrorListener() {
        NotificationCenter.default.addObserver(
            forName: .dataStorageError,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.userInfo?["error"] as? DataStorage.DataStorageError {
                self?.lastDataError = error.localizedDescription
                print("Data storage error received: \(error.localizedDescription)")
            }
        }
        
        // Also listen for EventStorageService errors
        NotificationCenter.default.addObserver(
            forName: .eventStorageError,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.userInfo?["error"] as? Error {
                self?.lastDataError = error.localizedDescription
                print("Event storage error received: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupEventStorageBinding() {
        // Bind our activationEvents to EventStorageService.shared.events
        // BUT preserve loaded icons during updates
        eventStorageService.$events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                self?.mergeEventsPreservingIcons(newEvents: events)
                print("ActivityMonitor: Updated activationEvents from EventStorageService (\(events.count) events)")
            }
            .store(in: &cancellables)
    }
    
    /// Merge new events from EventStorageService while preserving any loaded icons
    internal func mergeEventsPreservingIcons(newEvents: [AppActivationEvent]) {
        // Create a dictionary of existing events with their icons
        var existingIconMap: [UUID: (appIcon: NSImage?, siteFavicon: NSImage?)] = [:]
        
        for event in activationEvents {
            if event.appIcon != nil || event.siteFavicon != nil {
                existingIconMap[event.id] = (appIcon: event.appIcon, siteFavicon: event.siteFavicon)
            }
        }
        
        // Merge new events with existing icons
        var mergedEvents = newEvents
        for i in 0..<mergedEvents.count {
            if let iconData = existingIconMap[mergedEvents[i].id] {
                mergedEvents[i].appIcon = iconData.appIcon
                mergedEvents[i].siteFavicon = iconData.siteFavicon
            }
        }
        
        // Update the main events array
        activationEvents = mergedEvents
        
        // Log icon preservation stats
        let eventsWithIcons = mergedEvents.filter { $0.appIcon != nil }.count
        if eventsWithIcons > 0 {
            print("ActivityMonitor: Preserved icons for \(eventsWithIcons) events during EventStorageService update")
        }
    }

    deinit {
        // Clean up observers
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        
        // Force save all data immediately on deinit
        // Events are now saved immediately via EventStorageService, no need to force save
        dataStorage.saveContextSwitches(contextSwitches) { _ in }
        
        // Clean up data management timer
        cleanupTimer?.invalidate()
        
        print("ActivityMonitor deinitialized.")
    }

    private func setupAppActivationObserver() {
        // Observe the notification for when an application becomes active
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main) // Process notification on main thread initially
            .sink { [weak self] notification in
                guard let self = self,
                      let activatedApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                    return
                }
                
                // Use smart debouncing to handle rapid app switches intelligently
                self.handleAppActivationWithSmartDebouncing(
                    app: activatedApp,
                    timestamp: Date()
                )
            }
            .store(in: &cancellables)
        
        print("App activation observer set up.")
    }
    
    // MARK: - Smart Debouncing Logic
    
    private func handleAppActivationWithSmartDebouncing(
        app: NSRunningApplication,
        timestamp: Date
    ) {
        let appName = app.localizedName ?? "Unknown"
        let bundleId = app.bundleIdentifier
        
        // Cancel any existing debounce timer
        debounceTimer?.invalidate()
        
        // Check if this is a rapid switch to the same app
        if let pending = pendingActivation,
           pending.app == appName,
           timestamp.timeIntervalSince(pending.timestamp) < Self.smartDebounceThreshold {
            
            // Update the pending activation with the latest timestamp
            pendingActivation = (app: appName, timestamp: timestamp, bundleId: bundleId)
            
            // Reset the debounce timer
            scheduleProcessPendingActivation(for: app, at: timestamp)
            return
        }
        
        // Process any existing pending activation
        if pendingActivation != nil {
            processPendingActivation()
        }
        
        // Set new pending activation
        pendingActivation = (app: appName, timestamp: timestamp, bundleId: bundleId)
        scheduleProcessPendingActivation(for: app, at: timestamp)
    }
    
    private func scheduleProcessPendingActivation(for app: NSRunningApplication, at timestamp: Date) {
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.processPendingActivation()
        }
    }
    
    private func processPendingActivation() {
        guard let pending = pendingActivation else { return }
        
        // Clear pending state
        pendingActivation = nil
        debounceTimer?.invalidate()
        debounceTimer = nil
        
        // Process the activation with a small delay for icon loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            // Create a mock NSRunningApplication for processing
            // (In practice, we'd store the actual app reference)
            self.processAppActivation(
                appName: pending.app,
                bundleId: pending.bundleId,
                timestamp: pending.timestamp
            )
        }
    }
    
    private func processAppActivation(
        appName: String,
        bundleId: String?,
        timestamp: Date
    ) {
        // Get current time for session tracking
        let currentTime = timestamp
        
        // Manage session tracking
        let sessionInfo = self.manageSession(at: currentTime)
        self.updateLastEventTime(currentTime)
        
        let eventId = UUID() // Store the ID for later reference
        // Note: Icon loading would need the actual NSRunningApplication reference
        // For now, we'll handle this limitation
        print("Processing app activation for \(appName) at \(currentTime)")

        let appCategory = CategoryManager.shared.getCategory(for: bundleId)
        
        // Create event first without icon, then load icon asynchronously
        let event = AppActivationEvent(
            id: eventId,
            timestamp: currentTime,
            appName: appName,
            bundleIdentifier: bundleId,
            appIcon: nil, // Will be loaded asynchronously
            category: appCategory,
            sessionId: sessionInfo.sessionId,
            sessionStartTime: sessionInfo.sessionStartTime,
            isSessionStart: sessionInfo.isSessionStart,
            sessionSwitchCount: sessionInfo.switchCount
        )
        
        // Load app icon asynchronously and update the event
        IconLoadingService.shared.loadAppIconAsync(for: bundleId) { [weak self] icon in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Update the event in EventStorageService (which will trigger binding update)
                // This ensures both ActivityMonitor and EventStorageService stay in sync
                self.eventStorageService.updateEventIcon(eventId: eventId, appIcon: icon, siteFavicon: nil as NSImage?)
                
                // Also update local array directly for immediate UI response
                if let eventIndex = self.activationEvents.firstIndex(where: { $0.id == eventId }) {
                    self.activationEvents[eventIndex].appIcon = icon
                }
            }
        }
        
        // Add the event immediately
        // Track context switch if we have a previous app
        if let lastApp = self.lastAppSwitch, 
           lastApp.name != appName {
            let timeSpent = currentTime.timeIntervalSince(lastApp.timestamp)
            
            // Only create context switch if it's meaningful (> 1 second)
            if timeSpent > 1.0 {
                let contextSwitch = ContextSwitchMetrics(
                    fromApp: lastApp.name,
                    toApp: appName,
                    fromBundleId: lastApp.bundleId,
                    toBundleId: bundleId,
                    timestamp: currentTime,
                    timeSpent: timeSpent,
                    fromCategory: lastApp.category,
                    toCategory: appCategory,
                    sessionId: sessionInfo.sessionId
                )
                
                self.dataQueue.async {
                    DispatchQueue.main.async {
                        self.contextSwitches.insert(contextSwitch, at: 0)
                        self.saveContextSwitches()
                        
                        // Record context switch with focus state detector
                        self.focusStateDetector.recordContextSwitch(at: currentTime)
                    }
                }
            }
        }
        
        // Update last app switch
        self.lastAppSwitch = (appName, currentTime, bundleId, appCategory)
        
        // Add event to EventStorageService (immediate persistence)
        self.eventStorageService.addEvent(event)
        
        // Note: activationEvents is now automatically updated via EventStorageService binding
        // No need to manually append or sort - EventStorageService handles this
        print("App Activated: \(appName) (\(bundleId ?? "N/A")) at \(event.timestamp)")

        // Check if the activated app is Google Chrome
        if bundleId == "com.google.Chrome" {
            self.handleChromeActivation(for: eventId)
        }
    }

    // MARK: - Public Methods
    
    /// Add a context switch manually (used for testing/preview)
    func addContextSwitch(_ contextSwitch: ContextSwitchMetrics) {
        contextSwitches.append(contextSwitch)
    }
    
    // Method to manually trigger UI refresh, e.g., after user-defined category changes
    public func refreshDueToCategoryChange() {
        objectWillChange.send()
    }
    
    // Enhanced icon loading that retries failed attempts
    private func retryIconLoadingForMissingIcons() {
        let eventsWithoutIcons = activationEvents.filter { $0.appIcon == nil }
        guard !eventsWithoutIcons.isEmpty else { return }
        
        print("ActivityMonitor: Retrying icon loading for \(eventsWithoutIcons.count) events without icons...")
        
        IconLoadingService.shared.loadIconsForEvents(eventsWithoutIcons) { [weak self] updatedEvents in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Prepare batch icon updates for EventStorageService
                var iconUpdates: [(eventId: UUID, appIcon: NSImage?, siteFavicon: NSImage?)] = []
                
                for updatedEvent in updatedEvents {
                    if updatedEvent.appIcon != nil || updatedEvent.siteFavicon != nil {
                        iconUpdates.append((
                            eventId: updatedEvent.id,
                            appIcon: updatedEvent.appIcon,
                            siteFavicon: updatedEvent.siteFavicon
                        ))
                    }
                    
                    // Also update local array directly for immediate UI response
                    if let index = self.activationEvents.firstIndex(where: { $0.id == updatedEvent.id }) {
                        self.activationEvents[index] = updatedEvent
                    }
                }
                
                // Update EventStorageService with batch icon updates
                if !iconUpdates.isEmpty {
                    self.eventStorageService.updateEventIcons(iconUpdates)
                }
                
                let stillMissing = self.activationEvents.filter { $0.appIcon == nil }.count
                if stillMissing > 0 {
                    print("ActivityMonitor: \(stillMissing) events still missing icons after retry")
                }
            }
        }
    }

    // Method to reload all data from disk (useful for debugging and ensuring data consistency)
    public func reloadAllData() {
        print("ActivityMonitor: Reloading all data from disk...")
        eventStorageService.reloadEvents() // Use EventStorageService reload
        loadContextSwitches()
        
        // Also reload icons after a short delay to ensure events are loaded first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadIconsForExistingEvents()
        }
    }
    
    // Method to force reload all icons (useful for debugging)
    public func forceReloadAllIcons() {
        print("ActivityMonitor: Force reloading all icons...")
        IconLoadingService.shared.forceReloadAllIcons(for: activationEvents) { [weak self] updatedEvents in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Prepare batch icon updates for EventStorageService
                var iconUpdates: [(eventId: UUID, appIcon: NSImage?, siteFavicon: NSImage?)] = []
                
                for updatedEvent in updatedEvents {
                    iconUpdates.append((
                        eventId: updatedEvent.id,
                        appIcon: updatedEvent.appIcon,
                        siteFavicon: updatedEvent.siteFavicon
                    ))
                }
                
                // Update EventStorageService with batch icon updates
                if !iconUpdates.isEmpty {
                    self.eventStorageService.updateEventIcons(iconUpdates)
                }
                
                // Update local array directly for immediate UI response
                self.activationEvents = updatedEvents
                
                let iconCount = updatedEvents.filter { $0.appIcon != nil }.count
                print("ActivityMonitor: Force reload completed. \(iconCount)/\(updatedEvents.count) events have icons")
            }
        }
    }
    
    // Method to get icon loading statistics
    public func getIconLoadingStats() -> (eventsWithIcons: Int, totalEvents: Int, cacheStats: (memoryCount: Int, diskCacheSize: Int)) {
        let eventsWithIcons = activationEvents.filter { $0.appIcon != nil }.count
        let totalEvents = activationEvents.count
        let cacheStats = IconLoadingService.shared.getCacheStats()
        return (eventsWithIcons: eventsWithIcons, totalEvents: totalEvents, cacheStats: cacheStats)
    }
    
    // Method to force save all data immediately
    public func forceSaveAllData() {
        print("ActivityMonitor: Force saving all data...")
        // Events are automatically saved immediately via EventStorageService
        saveContextSwitches()
    }
    
    // Method to get current data retention status
    public func getDataRetentionInfo() -> (inMemoryEvents: Int, inMemoryContextSwitches: Int, hasHistoricalData: Bool) {
        let hasHistoricalData = cachedAllTimeStats != nil || cachedTotalContextSwitches != nil
        return (
            inMemoryEvents: activationEvents.count,
            inMemoryContextSwitches: contextSwitches.count,
            hasHistoricalData: hasHistoricalData
        )
    }
    
    
    // Load icons for existing events that don't have them
    private func loadIconsForExistingEvents() {
        guard !activationEvents.isEmpty else { return }
        
        print("ActivityMonitor: Loading icons for \(activationEvents.count) existing events...")
        
        // Get unique bundle identifiers from events
        let uniqueBundleIds = Set(activationEvents.compactMap { $0.bundleIdentifier })
        
        // First, preload icons for all unique bundle IDs to populate the cache
        IconLoadingService.shared.preloadIcons(for: Array(uniqueBundleIds)) { [weak self] in
            guard let self = self else { return }
            
            // Then load icons for all events
            IconLoadingService.shared.loadIconsForEvents(self.activationEvents) { [weak self] updatedEvents in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    // Prepare batch icon updates for EventStorageService
                    var iconUpdates: [(eventId: UUID, appIcon: NSImage?, siteFavicon: NSImage?)] = []
                    
                    for updatedEvent in updatedEvents {
                        if updatedEvent.appIcon != nil || updatedEvent.siteFavicon != nil {
                            iconUpdates.append((
                                eventId: updatedEvent.id,
                                appIcon: updatedEvent.appIcon,
                                siteFavicon: updatedEvent.siteFavicon
                            ))
                        }
                    }
                    
                    // Update EventStorageService with batch icon updates
                    if !iconUpdates.isEmpty {
                        self.eventStorageService.updateEventIcons(iconUpdates)
                    }
                    
                    // Update local array directly for immediate UI response
                    self.activationEvents = updatedEvents
                    
                    print("ActivityMonitor: Completed loading icons. Events with icons: \(updatedEvents.filter { $0.appIcon != nil }.count)/\(updatedEvents.count)")
                }
            }
        }
    }
    
    // MARK: - Data Management & Cleanup
    
    private func setupDataCleanup() {
        // Setup timer for periodic cleanup
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: Self.cleanupInterval, repeats: true) { [weak self] _ in
            self?.performDataCleanupIfNeeded()
        }
    }
    
    // MARK: - Productivity Insights Timer
    
    private func setupProductivityInsightsTimer() {
        // Check for productivity insights every 30 minutes
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            AwarenessNotificationService.shared.sendProductivityInsight(activityMonitor: self)
        }
    }
    
    private func performDataCleanupIfNeeded() {
        let now = Date()
        
        // Only cleanup if we have too many items or it's been a while
        let shouldCleanupEvents = activationEvents.count > Self.maxInMemoryEvents
        let shouldCleanupSwitches = contextSwitches.count > Self.maxInMemoryContextSwitches
        let timeSinceLastCleanup = now.timeIntervalSince(lastCleanupTime)
        
        if shouldCleanupEvents || shouldCleanupSwitches || timeSinceLastCleanup > Self.cleanupInterval {
            dataQueue.async { [weak self] in
                self?.performSmartDataCleanup()
            }
            lastCleanupTime = now
        }
    }
    
    private func performSmartDataCleanup() {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(Self.dataRetentionDays * 24 * 60 * 60))
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Clean up old events while preserving recent data for analytics
            let originalEventCount = self.activationEvents.count
            
            // NOTE: With EventStorageService, in-memory cleanup is less critical since
            // events are persisted individually and loaded on demand
            // TODO: Consider if this cleanup logic should be moved to EventStorageService
            
            // Keep recent events (last 2 days) + ensure we don't go below a minimum for "All Time" analytics
            let recentEvents = self.activationEvents.filter { $0.timestamp > cutoffDate }
            let keptRecentCount = recentEvents.count
            
            // If recent events exceed our limit, keep the most recent ones
            if keptRecentCount > Self.maxInMemoryEvents {
                self.activationEvents = Array(self.activationEvents.prefix(Self.maxInMemoryEvents))
            } else {
                self.activationEvents = recentEvents
            }
            
            // Clean up old context switches
            let originalSwitchCount = self.contextSwitches.count
            let recentSwitches = self.contextSwitches.filter { $0.timestamp > cutoffDate }
            let keptSwitchCount = recentSwitches.count
            
            if keptSwitchCount > Self.maxInMemoryContextSwitches {
                self.contextSwitches = Array(self.contextSwitches.prefix(Self.maxInMemoryContextSwitches))
            } else {
                self.contextSwitches = recentSwitches
            }
            
            // Update cached analytics if we cleaned up data
            if originalEventCount != self.activationEvents.count {
                self.updateAnalyticsCache(originalEventCount: originalEventCount, originalSwitchCount: originalSwitchCount)
            }
            
            print("DataCleanup: Events \(originalEventCount) → \(self.activationEvents.count), Switches \(originalSwitchCount) → \(self.contextSwitches.count)")
        }
    }
    
    private func updateAnalyticsCache(originalEventCount: Int, originalSwitchCount: Int) {
        // Cache the original all-time totals before cleanup
        cachedAllTimeStats = (count: originalEventCount, lastUpdate: Date())
        cachedTotalContextSwitches = (count: originalSwitchCount, lastUpdate: Date())
    }
}
