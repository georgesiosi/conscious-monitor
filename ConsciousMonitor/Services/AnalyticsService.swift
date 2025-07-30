import Foundation
import AppKit

// MARK: - Analytics Service
/// Dedicated service for handling all analytics calculations
/// Separated from ActivityMonitor for better architecture and testability
class AnalyticsService {
    
    // MARK: - Constants
    public static let minutesLostPerSwitch: Double = 3.0
    private static let significantSwitchThreshold: TimeInterval = 30.0 // 30 seconds
    private static let cacheValidityDuration: TimeInterval = 3600 // 1 hour
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Core Analytics Methods
    
    /// Calculate app activations in the last 5 minutes
    func appActivationsInLast5Minutes(from events: [AppActivationEvent]) -> Int {
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        return events.filter { $0.timestamp > fiveMinutesAgo }.count
    }
    
    /// Get total app activations with cache support
    func totalAppActivations(
        from events: [AppActivationEvent], 
        cachedStats: (count: Int, lastUpdate: Date)?
    ) -> Int {
        // Use cached value if we have cleaned up data and cache is recent
        if let cached = cachedStats,
           Date().timeIntervalSince(cached.lastUpdate) < Self.cacheValidityDuration {
            return max(cached.count, events.count)
        }
        return events.count
    }
    
    /// Calculate today's app activations
    func appActivationsToday(from events: [AppActivationEvent]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return events.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }.count
    }
    
    /// Calculate today's context switches
    func contextSwitchesToday(from switches: [ContextSwitchMetrics]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return switches.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }.count
    }
    
    /// Get total context switches with cache support
    func totalContextSwitches(
        from switches: [ContextSwitchMetrics], 
        cachedStats: (count: Int, lastUpdate: Date)?
    ) -> Int {
        // Use cached value if we have cleaned up data and cache is recent
        if let cached = cachedStats,
           Date().timeIntervalSince(cached.lastUpdate) < Self.cacheValidityDuration {
            return max(cached.count, switches.count)
        }
        return switches.count
    }
    
    // MARK: - Time & Cost Analytics
    
    /// Calculate estimated time lost in minutes (all time)
    func estimatedTimeLostInMinutes(from switches: [ContextSwitchMetrics]) -> Double {
        let significantSwitches = switches.filter { $0.timeSpent > Self.significantSwitchThreshold }
        return Double(significantSwitches.count) * Self.minutesLostPerSwitch
    }
    
    /// Calculate estimated time lost today
    func estimatedTimeLostInMinutesToday(from switches: [ContextSwitchMetrics]) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let significantSwitchesToday = switches.filter { 
            calendar.isDate($0.timestamp, inSameDayAs: today) && $0.timeSpent > Self.significantSwitchThreshold
        }
        return Double(significantSwitchesToday.count) * Self.minutesLostPerSwitch
    }
    
    /// Calculate estimated cost lost (all time)
    func estimatedCostLost(from switches: [ContextSwitchMetrics], hourlyRate: Double) -> Double {
        let hoursLost = estimatedTimeLostInMinutes(from: switches) / 60.0
        return hoursLost * hourlyRate
    }
    
    /// Calculate estimated cost lost today
    func estimatedCostLostToday(from switches: [ContextSwitchMetrics], hourlyRate: Double) -> Double {
        let hoursLost = estimatedTimeLostInMinutesToday(from: switches) / 60.0
        return hoursLost * hourlyRate
    }
    
    // MARK: - Enhanced Productivity Analytics
    
    /// Calculate quick checks (< 10 seconds) today
    func quickChecksToday(from switches: [ContextSwitchMetrics]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return switches.filter { 
            calendar.isDate($0.timestamp, inSameDayAs: today) && 
            $0.switchType == .quick 
        }.count
    }
    
    /// Calculate meaningful task switches (10s - 2 minutes) today
    func meaningfulSwitchesToday(from switches: [ContextSwitchMetrics]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return switches.filter { 
            calendar.isDate($0.timestamp, inSameDayAs: today) && 
            $0.switchType == .normal 
        }.count
    }
    
    /// Calculate deep work interruptions (> 2 minutes) today  
    func deepWorkInterruptionsToday(from switches: [ContextSwitchMetrics]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return switches.filter { 
            calendar.isDate($0.timestamp, inSameDayAs: today) && 
            $0.switchType == .focused 
        }.count
    }
    
    /// Calculate focus sessions today
    func focusSessionsToday(from switches: [ContextSwitchMetrics]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return switches.filter { 
            calendar.isDate($0.timestamp, inSameDayAs: today) && 
            $0.switchType == .focused 
        }.count
    }
    
    /// Calculate total focus time today
    func totalFocusTimeToday(from switches: [ContextSwitchMetrics]) -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return switches
            .filter { 
                calendar.isDate($0.timestamp, inSameDayAs: today) && 
                $0.switchType == .focused 
            }
            .reduce(0) { $0 + $1.timeSpent }
    }
    
    /// Get productivity score for today (0-100)
    func todaysProductivityScore(from events: [AppActivationEvent]) -> Double {
        return getProductivityMetrics(from: events).productivityScore
    }
    
    /// Get human-readable productivity level
    func todaysProductivityLevel(from events: [AppActivationEvent]) -> String {
        return getProductivityMetrics(from: events).productivityLevel
    }
    
    /// Calculate estimated financial impact today
    func estimatedFinancialImpactToday(from switches: [ContextSwitchMetrics], hourlyRate: Double) -> Double {
        let hoursLost = estimatedTimeLostInMinutesToday(from: switches) / 60.0
        return hoursLost * hourlyRate
    }
    
    // MARK: - Smart Analytics Integration
    
    /// Get productivity metrics using smart switch detection
    func getProductivityMetrics(from events: [AppActivationEvent]) -> ProductivityMetrics {
        let processedEvents = SmartSwitchDetector.processEvents(events)
        return SmartSwitchDetector.generateProductivityMetrics(from: processedEvents)
    }
    
    /// Get processed events for analytics
    func getProcessedEvents(from events: [AppActivationEvent]) -> [SmartSwitchDetector.ProcessedEvent] {
        return SmartSwitchDetector.processEvents(events)
    }
    
    /// Get intelligent context switches
    func getIntelligentContextSwitches(from events: [AppActivationEvent]) -> [ContextSwitchMetrics] {
        let processedEvents = getProcessedEvents(from: events)
        return SmartSwitchDetector.createIntelligentContextSwitches(from: processedEvents)
    }
    
    // MARK: - App Usage Statistics
    
    /// Generate app usage statistics from activation events
    func generateAppUsageStats(from events: [AppActivationEvent]) -> [AppUsageStat] {
        // Group events by bundle identifier
        let groupedEvents = Dictionary(grouping: events, by: { $0.bundleIdentifier ?? "unknown.bundle.id" })
        
        let stats = groupedEvents.map { bundleId, eventsInGroup -> AppUsageStat in
            // Sort events in group by timestamp descending to get the most recent one
            let sortedEventsInGroup = eventsInGroup.sorted { $0.timestamp > $1.timestamp }
            let mostRecentEvent = sortedEventsInGroup.first
            
            var topLevelFavicon: NSImage? = nil
            var chromeSiteBreakdown: [SiteUsageStat]? = nil
            
            if bundleId == "com.google.Chrome" {
                topLevelFavicon = mostRecentEvent?.siteFavicon
                
                // Further group Chrome events by siteDomain to create SiteUsageStat
                let chromeDomainGroups = Dictionary(grouping: eventsInGroup, by: { $0.siteDomain ?? "unknown.domain" })
                
                var breakdown: [SiteUsageStat] = []
                for (domain, domainEvents) in chromeDomainGroups {
                    let sortedDomainEvents = domainEvents.sorted { $0.timestamp > $1.timestamp }
                    let mostRecentDomainEvent = sortedDomainEvents.first
                    let siteStat = SiteUsageStat(
                        siteDomain: domain,
                        displayTitle: mostRecentDomainEvent?.chromeTabTitle ?? domain,
                        siteFavicon: mostRecentDomainEvent?.siteFavicon,
                        activationCount: domainEvents.count,
                        lastActiveTimestamp: mostRecentDomainEvent?.timestamp ?? Date()
                    )
                    breakdown.append(siteStat)
                }
                
                // Sort the site breakdown by activation count, descending
                chromeSiteBreakdown = breakdown.sorted { $0.activationCount > $1.activationCount }
            }
            
            return AppUsageStat(
                appName: mostRecentEvent?.appName ?? "Unknown App",
                bundleIdentifier: bundleId,
                activationCount: sortedEventsInGroup.count,
                appIcon: bundleId == "com.google.Chrome" ? topLevelFavicon : mostRecentEvent?.appIcon,
                lastActiveTimestamp: mostRecentEvent?.timestamp ?? Date(),
                category: mostRecentEvent?.category ?? .other,
                siteBreakdown: chromeSiteBreakdown
            )
        }
        .sorted { $0.activationCount > $1.activationCount }
        
        return stats
    }
    
    // MARK: - Context Switch Analysis Methods
    
    /// Get context switches for a specific time period using SharedTimeRange (preferred)
    func getContextSwitches(from switches: [ContextSwitchMetrics], for timeRange: SharedTimeRange) -> [ContextSwitchMetrics] {
        return timeRange.filterEvents(switches, timestampKeyPath: \.timestamp)
    }
    
    /// Get context switches for a specific time period using Calendar.Component (legacy - use SharedTimeRange version)
    func getContextSwitches(from switches: [ContextSwitchMetrics], for timeRange: Calendar.Component) -> [ContextSwitchMetrics] {
        let calendar = Calendar.current
        let now = Date()
        
        return switches.filter { switchEvent in
            switch timeRange {
            case .day:
                return calendar.isDate(switchEvent.timestamp, inSameDayAs: now)
            case .weekOfYear:
                // Check both week and year to ensure we're in the same week of the current year
                return calendar.component(.weekOfYear, from: switchEvent.timestamp) == calendar.component(.weekOfYear, from: now) &&
                       calendar.component(.year, from: switchEvent.timestamp) == calendar.component(.year, from: now)
            case .month:
                // Check both month and year to ensure we're in the same month of the current year
                return calendar.component(.month, from: switchEvent.timestamp) == calendar.component(.month, from: now) &&
                       calendar.component(.year, from: switchEvent.timestamp) == calendar.component(.year, from: now)
            default:
                return true // All time
            }
        }
    }
    
    /// Get switch statistics by type for a specific time period using SharedTimeRange (preferred)
    func getSwitchStatistics(from switches: [ContextSwitchMetrics], for timeRange: SharedTimeRange) -> (quick: Int, normal: Int, focused: Int) {
        let filteredSwitches = getContextSwitches(from: switches, for: timeRange)
        
        let quickSwitches = filteredSwitches.filter { $0.switchType == .quick }.count
        let normalSwitches = filteredSwitches.filter { $0.switchType == .normal }.count
        let focusedSwitches = filteredSwitches.filter { $0.switchType == .focused }.count
        
        return (quick: quickSwitches, normal: normalSwitches, focused: focusedSwitches)
    }
    
    /// Get switch statistics by type for a specific time period using Calendar.Component (legacy - use SharedTimeRange version)
    func getSwitchStatistics(from switches: [ContextSwitchMetrics], for timeRange: Calendar.Component = .year) -> (quick: Int, normal: Int, focused: Int) {
        let filteredSwitches = getContextSwitches(from: switches, for: timeRange)
        
        let quickSwitches = filteredSwitches.filter { $0.switchType == .quick }.count
        let normalSwitches = filteredSwitches.filter { $0.switchType == .normal }.count
        let focusedSwitches = filteredSwitches.filter { $0.switchType == .focused }.count
        
        return (quick: quickSwitches, normal: normalSwitches, focused: focusedSwitches)
    }
}