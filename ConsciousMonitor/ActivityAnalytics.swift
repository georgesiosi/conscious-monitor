import Foundation
import AppKit // For NSImage

// MARK: - Analytics Extension
// Updated to use AnalyticsService for better architecture
extension ActivityMonitor {
    
    // MARK: - Computed Analytics Properties
    
    // Computed property to calculate app activations in the last 5 minutes
    var appActivationsInLast5Minutes: Int {
        return analyticsService.appActivationsInLast5Minutes(from: activationEvents)
    }
    
    // Total app activations (all time) - uses cached value if available
    var totalAppActivations: Int {
        return analyticsService.totalAppActivations(from: activationEvents, cachedStats: cachedAllTimeStats)
    }
    
    // Today's Analytics Properties
    var appActivationsToday: Int {
        return analyticsService.appActivationsToday(from: activationEvents)
    }
    
    var contextSwitchesToday: Int {
        return analyticsService.contextSwitchesToday(from: contextSwitches)
    }
    
    // Total context switches (all time) - uses cached value if available
    var actualContextSwitchesAllTime: Int {
        return analyticsService.totalContextSwitches(from: contextSwitches, cachedStats: cachedTotalContextSwitches)
    }
    
    var estimatedTimeLostInMinutes: Double {
        return analyticsService.estimatedTimeLostInMinutes(from: contextSwitches)
    }
    
    var estimatedTimeLostInMinutesToday: Double {
        return analyticsService.estimatedTimeLostInMinutesToday(from: contextSwitches)
    }
    
    var estimatedCostLost: Double {
        return analyticsService.estimatedCostLost(from: contextSwitches, hourlyRate: UserSettings.shared.hourlyRate)
    }
    
    var estimatedCostLostToday: Double {
        return analyticsService.estimatedCostLostToday(from: contextSwitches, hourlyRate: UserSettings.shared.hourlyRate)
    }
    
    var minutesLostToday: Double {
        return estimatedTimeLostInMinutesToday
    }
    
    // MARK: - Enhanced Productivity Analytics
    
    /// Get productivity metrics using smart switch detection
    var productivityMetrics: ProductivityMetrics {
        return getProductivityMetrics()
    }
    
    /// Quick checks that don't impact productivity (< 10 seconds)
    var quickChecksToday: Int {
        return analyticsService.quickChecksToday(from: contextSwitches)
    }
    
    /// Meaningful task switches (10s - 2 minutes)
    var meaningfulSwitchesToday: Int {
        return analyticsService.meaningfulSwitchesToday(from: contextSwitches)
    }
    
    /// Deep focus sessions (> 2 minutes)
    var focusSessionsToday: Int {
        return analyticsService.focusSessionsToday(from: contextSwitches)
    }
    
    /// Total focus time today (estimated)
    var totalFocusTimeToday: TimeInterval {
        return analyticsService.totalFocusTimeToday(from: contextSwitches)
    }
    
    /// Productivity score for today (0-100)
    var todaysProductivityScore: Double {
        return analyticsService.todaysProductivityScore(from: activationEvents)
    }
    
    /// Human-readable productivity level
    var todaysProductivityLevel: String {
        return analyticsService.todaysProductivityLevel(from: activationEvents)
    }
    
    var estimatedFinancialImpactToday: Double {
        return analyticsService.estimatedFinancialImpactToday(from: contextSwitches, hourlyRate: UserSettings.shared.hourlyRate)
    }
    
    // MARK: - Context Switch Analysis Methods
    
    /// Get context switches for a specific time period using SharedTimeRange (preferred)
    func getContextSwitches(for timeRange: SharedTimeRange) -> [ContextSwitchMetrics] {
        return analyticsService.getContextSwitches(from: contextSwitches, for: timeRange)
    }
    
    /// Get context switches for a specific time period using Calendar.Component (legacy - use SharedTimeRange version)
    func getContextSwitches(for timeRange: Calendar.Component) -> [ContextSwitchMetrics] {
        return analyticsService.getContextSwitches(from: contextSwitches, for: timeRange)
    }
    
    /// Get switch statistics by type for a specific time period using SharedTimeRange (preferred)
    func getSwitchStatistics(for timeRange: SharedTimeRange) -> (quick: Int, normal: Int, focused: Int) {
        return analyticsService.getSwitchStatistics(from: contextSwitches, for: timeRange)
    }
    
    /// Get switch statistics by type for a specific time period using Calendar.Component (legacy - use SharedTimeRange version)
    func getSwitchStatistics(for timeRange: Calendar.Component = .year) -> (quick: Int, normal: Int, focused: Int) {
        return analyticsService.getSwitchStatistics(from: contextSwitches, for: timeRange)
    }
    
    /// Get most common app switches (pairs)
    func getMostCommonSwitches(limit: Int = 5) -> [(from: String, to: String, count: Int)] {
        var switchCounts: [String: Int] = [:]
        
        for switchEvent in contextSwitches {
            let key = "\(switchEvent.fromApp) → \(switchEvent.toApp)"
            switchCounts[key, default: 0] += 1
        }
        
        return switchCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (String($0.key.split(separator: "→")[0].trimmingCharacters(in: .whitespaces)),
                    String($0.key.split(separator: "→")[1].trimmingCharacters(in: .whitespaces)),
                    $0.value) }
    }
    
    /// Get average time spent before switching
    func getAverageTimeBeforeSwitch() -> TimeInterval {
        guard !contextSwitches.isEmpty else { return 0 }
        let totalTime = contextSwitches.reduce(0) { $0 + $1.timeSpent }
        return totalTime / Double(contextSwitches.count)
    }
    
    /// Get switches by hour of day
    func getSwitchesByHour() -> [Int: Int] {
        var hourCounts = [Int: Int]()
        let calendar = Calendar.current
        
        for switchEvent in contextSwitches {
            let hour = calendar.component(.hour, from: switchEvent.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        
        return hourCounts
    }
    
    // MARK: - App Usage Statistics
    
    // NOTE: appUsageStats is now a @Published property in ActivityMonitor that updates reactively
}
