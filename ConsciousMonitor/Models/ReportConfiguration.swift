import Foundation
import SwiftUI

// MARK: - Report Configuration Model

/// Configuration model for report generation with comprehensive settings
struct ReportConfiguration: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    var dataTypes: Set<ReportDataType>
    var format: ReportFormat
    var dateRange: DateRange
    var filters: ReportFilters
    var includeCharts: Bool
    var includeRawData: Bool
    var includeCSDAnalysis: Bool
    var includeInsights: Bool
    var createdAt: Date
    var lastModified: Date
    var isTemplate: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        dataTypes: Set<ReportDataType> = [.appUsage, .contextSwitches],
        format: ReportFormat = .pdf,
        dateRange: DateRange = .lastWeek,
        filters: ReportFilters = ReportFilters(),
        includeCharts: Bool = true,
        includeRawData: Bool = false,
        includeCSDAnalysis: Bool = true,
        includeInsights: Bool = true,
        isTemplate: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.dataTypes = dataTypes
        self.format = format
        self.dateRange = dateRange
        self.filters = filters
        self.includeCharts = includeCharts
        self.includeRawData = includeRawData
        self.includeCSDAnalysis = includeCSDAnalysis
        self.includeInsights = includeInsights
        self.createdAt = Date()
        self.lastModified = Date()
        self.isTemplate = isTemplate
    }
    
    // MARK: - Convenience Properties
    
    /// Human-readable summary of what will be included in the report
    var contentSummary: String {
        var components: [String] = []
        
        if includeCharts { components.append("Charts") }
        if includeCSDAnalysis { components.append("CSD Analysis") }
        if includeInsights { components.append("AI Insights") }
        if includeRawData { components.append("Raw Data") }
        
        let dataTypeNames = dataTypes.map { $0.displayName }.joined(separator: ", ")
        return "\(dataTypeNames) • \(components.joined(separator: ", "))"
    }
    
    /// Estimated file size category
    var estimatedSizeCategory: FileSizeCategory {
        var score = 0
        
        // Base score from data types
        score += dataTypes.count * 2
        
        // Additional scoring
        if includeCharts { score += 3 }
        if includeRawData { score += 5 }
        if includeCSDAnalysis { score += 2 }
        if includeInsights { score += 1 }
        
        // Date range impact
        score += dateRange.sizeImpact
        
        switch score {
        case 0...5: return .small
        case 6...12: return .medium
        case 13...20: return .large
        default: return .veryLarge
        }
    }
    
    /// Check if configuration is valid for generation
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !dataTypes.isEmpty &&
               dateRange.isValid
    }
    
    /// Generate a filename for the report
    func generateFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let sanitizedName = name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "", options: .regularExpression)
        
        return "\(sanitizedName)_\(dateString).\(format.fileExtension)"
    }
    
    // MARK: - Template Presets
    
    static let defaultTemplates: [ReportConfiguration] = [
        ReportConfiguration(
            name: "Weekly Summary",
            description: "Comprehensive weekly activity report with CSD analysis",
            dataTypes: [.appUsage, .contextSwitches, .categoryMetrics, .csdInsights],
            format: .pdf,
            dateRange: .lastWeek,
            isTemplate: true
        ),
        
        ReportConfiguration(
            name: "Monthly Analysis",
            description: "Detailed monthly report for productivity trends",
            dataTypes: [.appUsage, .contextSwitches, .categoryMetrics, .csdInsights, .aiAnalysis],
            format: .pdf,
            dateRange: .lastMonth,
            includeRawData: true,
            isTemplate: true
        ),
        
        ReportConfiguration(
            name: "Stack Health Report",
            description: "Focus on 5:3:1 compliance and tool optimization",
            dataTypes: [.categoryMetrics, .csdInsights, .stackHealth],
            format: .pdf,
            dateRange: .lastWeek,
            includeCSDAnalysis: true,
            isTemplate: true
        ),
        
        ReportConfiguration(
            name: "Data Export",
            description: "Raw data export for external analysis",
            dataTypes: [.appUsage, .contextSwitches, .categoryMetrics],
            format: .csv,
            dateRange: .custom(start: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(), end: Date()),
            includeCharts: false,
            includeRawData: true,
            includeCSDAnalysis: false,
            includeInsights: false,
            isTemplate: true
        )
    ]
}

// MARK: - Supporting Types

/// Date range options for reports
enum DateRange: Codable, Hashable, CaseIterable {
    case today
    case yesterday
    case lastWeek
    case lastMonth
    case lastQuarter
    case lastYear
    case custom(start: Date, end: Date)
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .lastWeek: return "Last 7 Days"
        case .lastMonth: return "Last 30 Days"
        case .lastQuarter: return "Last 3 Months"
        case .lastYear: return "Last Year"
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
    
    var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return DateInterval(start: startOfDay, end: now)
            
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            let startOfYesterday = calendar.startOfDay(for: yesterday)
            let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday) ?? startOfYesterday
            return DateInterval(start: startOfYesterday, end: endOfYesterday)
            
        case .lastWeek:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return DateInterval(start: weekAgo, end: now)
            
        case .lastMonth:
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return DateInterval(start: monthAgo, end: now)
            
        case .lastQuarter:
            let quarterAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return DateInterval(start: quarterAgo, end: now)
            
        case .lastYear:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return DateInterval(start: yearAgo, end: now)
            
        case .custom(let start, let end):
            return DateInterval(start: start, end: end)
        }
    }
    
    var isValid: Bool {
        let interval = dateInterval
        return interval.start <= interval.end && interval.end <= Date()
    }
    
    var sizeImpact: Int {
        let days = Calendar.current.dateComponents([.day], from: dateInterval.start, to: dateInterval.end).day ?? 0
        switch days {
        case 0...1: return 1
        case 2...7: return 2
        case 8...30: return 3
        case 31...90: return 4
        default: return 5
        }
    }
    
    // CaseIterable conformance
    static var allCases: [DateRange] {
        return [.today, .yesterday, .lastWeek, .lastMonth, .lastQuarter, .lastYear]
    }
}

/// Report filters for customizing data inclusion
struct ReportFilters: Codable, Hashable {
    var categories: Set<String> // Category names to include (empty = all)
    var apps: Set<String> // Bundle identifiers to include (empty = all)
    var minimumUsageMinutes: Double // Filter out apps with less usage
    var excludeSystemApps: Bool
    var excludeIdleTime: Bool
    var onlyWorkingHours: Bool // Filter to business hours only
    var workingHoursStart: Int // Hour (0-23)
    var workingHoursEnd: Int // Hour (0-23)
    
    init(
        categories: Set<String> = [],
        apps: Set<String> = [],
        minimumUsageMinutes: Double = 0,
        excludeSystemApps: Bool = true,
        excludeIdleTime: Bool = true,
        onlyWorkingHours: Bool = false,
        workingHoursStart: Int = 9,
        workingHoursEnd: Int = 17
    ) {
        self.categories = categories
        self.apps = apps
        self.minimumUsageMinutes = minimumUsageMinutes
        self.excludeSystemApps = excludeSystemApps
        self.excludeIdleTime = excludeIdleTime
        self.onlyWorkingHours = onlyWorkingHours
        self.workingHoursStart = workingHoursStart
        self.workingHoursEnd = workingHoursEnd
    }
    
    var hasActiveFilters: Bool {
        return !categories.isEmpty ||
               !apps.isEmpty ||
               minimumUsageMinutes > 0 ||
               excludeSystemApps ||
               excludeIdleTime ||
               onlyWorkingHours
    }
    
    var filterSummary: String {
        guard hasActiveFilters else { return "No filters applied" }
        
        var components: [String] = []
        
        if !categories.isEmpty {
            components.append("\(categories.count) categories")
        }
        
        if !apps.isEmpty {
            components.append("\(apps.count) specific apps")
        }
        
        if minimumUsageMinutes > 0 {
            components.append("Min \(Int(minimumUsageMinutes))min usage")
        }
        
        if excludeSystemApps {
            components.append("No system apps")
        }
        
        if onlyWorkingHours {
            components.append("Working hours only")
        }
        
        return components.joined(separator: ", ")
    }
}

/// File size categories for user guidance
enum FileSizeCategory: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case veryLarge = "very_large"
    
    var displayName: String {
        switch self {
        case .small: return "Small (< 1MB)"
        case .medium: return "Medium (1-5MB)"
        case .large: return "Large (5-20MB)"
        case .veryLarge: return "Very Large (> 20MB)"
        }
    }
    
    var icon: String {
        switch self {
        case .small: return "doc.text"
        case .medium: return "doc.richtext"
        case .large: return "doc.text.image"
        case .veryLarge: return "archivebox"
        }
    }
    
    var color: Color {
        switch self {
        case .small: return .green
        case .medium: return .blue
        case .large: return .orange
        case .veryLarge: return .red
        }
    }
}
