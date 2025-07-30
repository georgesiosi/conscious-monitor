import Foundation
import SwiftUI

// MARK: - Extensions

extension SharedTimeRange {
    func toShareableTimeRange() -> ShareableStackTimeRange {
        switch self {
        case .today:
            return .today
        case .week:
            return .thisWeek
        case .month:
            return .thisMonth
        case .all:
            return .thisMonth // Default to month for "all time" sharing
        }
    }
}

// MARK: - Shareable Stack Data Models

enum ShareableStackTimeRange: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case custom = "Custom"
    
    var displayName: String {
        return self.rawValue
    }
}

enum ShareableStackFormat: String, CaseIterable {
    case square = "Square"
    case landscape = "Landscape"
    case story = "Story"
    
    var displayName: String {
        return self.rawValue
    }
    
    var dimensions: CGSize {
        switch self {
        case .square:
            return CGSize(width: 1080, height: 1080)
        case .landscape:
            return CGSize(width: 1200, height: 675)
        case .story:
            return CGSize(width: 1080, height: 1920)
        }
    }
}

enum ShareableStackPrivacyLevel: String, CaseIterable {
    case detailed = "Detailed"
    case categoryOnly = "Category Only"
    case minimal = "Minimal"
    
    var displayName: String {
        return self.rawValue
    }
}

struct ShareableStackData {
    let timeRange: ShareableStackTimeRange
    let customStartDate: Date?
    let customEndDate: Date?
    let focusScore: Double
    let contextSwitches: Int
    let deepFocusSessions: Int
    let longestFocusSession: TimeInterval
    let productivityCostSavings: Double
    let categoryBreakdown: [CategoryUsageData]
    let topApps: [AppUsageData]
    let achievements: [Achievement]
    let privacyLevel: ShareableStackPrivacyLevel
    
    struct CategoryUsageData {
        let name: String
        let percentage: Double
        let color: Color
    }
    
    struct AppUsageData {
        let name: String
        let displayName: String // For privacy - may be generic
        let activationCount: Int
        let percentage: Double
        let icon: NSImage?
        let category: AppCategory
    }
    
    struct Achievement {
        let title: String
        let value: String
        let icon: String
    }
}

// MARK: - Shareable Stack Service

class ShareableStackService {
    private let analyticsService: AnalyticsService
    
    init(analyticsService: AnalyticsService = AnalyticsService()) {
        self.analyticsService = analyticsService
    }
    
    // MARK: - Public Methods
    
    /// Generate shareable stack data for the specified time range and privacy level
    func generateShareableData(
        from events: [AppActivationEvent],
        contextSwitches: [ContextSwitchMetrics],
        timeRange: ShareableStackTimeRange,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil,
        privacyLevel: ShareableStackPrivacyLevel = .detailed
    ) -> ShareableStackData {
        
        // Filter events based on time range
        let filteredEvents = filterEvents(events, for: timeRange, customStartDate: customStartDate, customEndDate: customEndDate)
        let filteredSwitches = filterSwitches(contextSwitches, for: timeRange, customStartDate: customStartDate, customEndDate: customEndDate)
        
        // Calculate core metrics
        let focusScore = calculateFocusScore(from: filteredEvents, switches: filteredSwitches)
        let contextSwitchCount = filteredSwitches.count
        let deepFocusSessions = calculateDeepFocusSessions(from: filteredSwitches)
        let longestFocusSession = calculateLongestFocusSession(from: filteredSwitches)
        let costSavings = calculateProductivityCostSavings(from: filteredSwitches)
        
        // Generate category breakdown
        let categoryBreakdown = generateCategoryBreakdown(from: filteredEvents, privacyLevel: privacyLevel)
        
        // Generate top apps
        let topApps = generateTopApps(from: filteredEvents, privacyLevel: privacyLevel)
        
        // Generate achievements
        let achievements = generateAchievements(
            focusScore: focusScore,
            contextSwitches: contextSwitchCount,
            deepFocusSessions: deepFocusSessions,
            longestFocusSession: longestFocusSession,
            costSavings: costSavings
        )
        
        return ShareableStackData(
            timeRange: timeRange,
            customStartDate: customStartDate,
            customEndDate: customEndDate,
            focusScore: focusScore,
            contextSwitches: contextSwitchCount,
            deepFocusSessions: deepFocusSessions,
            longestFocusSession: longestFocusSession,
            productivityCostSavings: costSavings,
            categoryBreakdown: categoryBreakdown,
            topApps: topApps,
            achievements: achievements,
            privacyLevel: privacyLevel
        )
    }
    
    // MARK: - Private Methods
    
    private func filterEvents(
        _ events: [AppActivationEvent],
        for timeRange: ShareableStackTimeRange,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil
    ) -> [AppActivationEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return events.filter { $0.timestamp >= startOfDay }
            
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return events.filter { $0.timestamp >= startOfWeek }
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return events.filter { $0.timestamp >= startOfMonth }
            
        case .custom:
            guard let startDate = customStartDate else { return events }
            let endDate = customEndDate ?? now
            return events.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
        }
    }
    
    private func filterSwitches(
        _ switches: [ContextSwitchMetrics],
        for timeRange: ShareableStackTimeRange,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil
    ) -> [ContextSwitchMetrics] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return switches.filter { $0.timestamp >= startOfDay }
            
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return switches.filter { $0.timestamp >= startOfWeek }
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return switches.filter { $0.timestamp >= startOfMonth }
            
        case .custom:
            guard let startDate = customStartDate else { return switches }
            let endDate = customEndDate ?? now
            return switches.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
        }
    }
    
    private func calculateFocusScore(from events: [AppActivationEvent], switches: [ContextSwitchMetrics]) -> Double {
        guard !events.isEmpty else { return 0 }
        
        // Use existing analytics service to get productivity metrics
        let metrics = analyticsService.getProductivityMetrics(from: events)
        return metrics.productivityScore
    }
    
    private func calculateDeepFocusSessions(from switches: [ContextSwitchMetrics]) -> Int {
        return switches.filter { $0.switchType == .focused }.count
    }
    
    private func calculateLongestFocusSession(from switches: [ContextSwitchMetrics]) -> TimeInterval {
        let focusedSwitches = switches.filter { $0.switchType == .focused }
        return focusedSwitches.map { $0.timeSpent }.max() ?? 0
    }
    
    private func calculateProductivityCostSavings(from switches: [ContextSwitchMetrics]) -> Double {
        let timeLostInMinutes = analyticsService.estimatedTimeLostInMinutes(from: switches)
        let hourlyRate = 50.0 // Default rate - could be user configurable
        return (timeLostInMinutes / 60.0) * hourlyRate
    }
    
    private func generateCategoryBreakdown(from events: [AppActivationEvent], privacyLevel: ShareableStackPrivacyLevel) -> [ShareableStackData.CategoryUsageData] {
        let usageStats = analyticsService.generateAppUsageStats(from: events)
        
        // Group by category
        let categoryGroups = Dictionary(grouping: usageStats, by: { $0.category })
        
        let totalActivations = usageStats.reduce(0) { $0 + $1.activationCount }
        guard totalActivations > 0 else { return [] }
        
        let categoryData = categoryGroups.map { category, stats in
            let categoryActivations = stats.reduce(0) { $0 + $1.activationCount }
            let percentage = Double(categoryActivations) / Double(totalActivations) * 100
            
            return ShareableStackData.CategoryUsageData(
                name: category.name,
                percentage: percentage,
                color: category.color
            )
        }
        
        return categoryData
            .sorted { $0.percentage > $1.percentage }
            .prefix(5) // Top 5 categories
            .map { $0 }
    }
    
    private func generateTopApps(from events: [AppActivationEvent], privacyLevel: ShareableStackPrivacyLevel) -> [ShareableStackData.AppUsageData] {
        let usageStats = analyticsService.generateAppUsageStats(from: events)
        let totalActivations = usageStats.reduce(0) { $0 + $1.activationCount }
        
        guard totalActivations > 0 else { return [] }
        
        let topApps = usageStats.prefix(5).map { stat in
            let percentage = Double(stat.activationCount) / Double(totalActivations) * 100
            let displayName = getPrivacyAwareAppName(stat.appName, category: stat.category, privacyLevel: privacyLevel)
            
            return ShareableStackData.AppUsageData(
                name: stat.appName,
                displayName: displayName,
                activationCount: stat.activationCount,
                percentage: percentage,
                icon: stat.appIcon,
                category: stat.category
            )
        }
        
        return topApps
    }
    
    private func getPrivacyAwareAppName(_ appName: String, category: AppCategory, privacyLevel: ShareableStackPrivacyLevel) -> String {
        switch privacyLevel {
        case .detailed:
            return appName
        case .categoryOnly:
            return "\(category.name) Tool"
        case .minimal:
            return "App"
        }
    }
    
    private func generateAchievements(
        focusScore: Double,
        contextSwitches: Int,
        deepFocusSessions: Int,
        longestFocusSession: TimeInterval,
        costSavings: Double
    ) -> [ShareableStackData.Achievement] {
        var achievements: [ShareableStackData.Achievement] = []
        
        // Focus Score Achievement
        if focusScore >= 80 {
            achievements.append(ShareableStackData.Achievement(
                title: "Focus Champion",
                value: "\(Int(focusScore))% Focus Score",
                icon: "🎯"
            ))
        } else if focusScore >= 60 {
            achievements.append(ShareableStackData.Achievement(
                title: "Solid Focus",
                value: "\(Int(focusScore))% Focus Score",
                icon: "🔥"
            ))
        }
        
        // Deep Focus Sessions
        if deepFocusSessions > 0 {
            achievements.append(ShareableStackData.Achievement(
                title: "Deep Work Sessions",
                value: "\(deepFocusSessions) sessions",
                icon: "🧠"
            ))
        }
        
        // Longest Focus Session
        if longestFocusSession > 3600 { // More than 1 hour
            let hours = Int(longestFocusSession / 3600)
            let minutes = Int((longestFocusSession.truncatingRemainder(dividingBy: 3600)) / 60)
            achievements.append(ShareableStackData.Achievement(
                title: "Focus Marathon",
                value: "\(hours)h \(minutes)m streak",
                icon: "⏰"
            ))
        }
        
        // Cost Savings
        if costSavings > 0 {
            achievements.append(ShareableStackData.Achievement(
                title: "Productivity Savings",
                value: "$\(String(format: "%.0f", costSavings))",
                icon: "💰"
            ))
        }
        
        // Context Switches (positive spin)
        if contextSwitches < 50 {
            achievements.append(ShareableStackData.Achievement(
                title: "Focused Workflow",
                value: "\(contextSwitches) switches",
                icon: "🎯"
            ))
        }
        
        return achievements
    }
}