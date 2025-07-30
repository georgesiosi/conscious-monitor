import Foundation
import SwiftUI

// MARK: - Report Models Integration
// This file provides additional supporting types and utilities for the report generation system

// MARK: - Report Template

/// Predefined report templates for common use cases
struct ReportTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let category: TemplateCategory
    let configuration: ReportConfiguration
    let tags: Set<String>
    let isBuiltIn: Bool
    let createdAt: Date
    let usageCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: TemplateCategory,
        configuration: ReportConfiguration,
        tags: Set<String> = [],
        isBuiltIn: Bool = false,
        createdAt: Date = Date(),
        usageCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.configuration = configuration
        self.tags = tags
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.usageCount = usageCount
    }
    
    /// Create a new configuration based on this template
    func createConfiguration(withName name: String? = nil) -> ReportConfiguration {
        var config = configuration
        config.name = name ?? "\(configuration.name) Copy"
        config.isTemplate = false
        return config
    }
}

// MARK: - Template Category

enum TemplateCategory: String, CaseIterable, Codable {
    case productivity = "productivity"
    case compliance = "compliance"
    case analysis = "analysis"
    case executive = "executive"
    case technical = "technical"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .compliance: return "CSD Compliance"
        case .analysis: return "Deep Analysis"
        case .executive: return "Executive Summary"
        case .technical: return "Technical Export"
        case .custom: return "Custom"
        }
    }
    
    var description: String {
        switch self {
        case .productivity:
            return "Reports focused on productivity metrics and focus patterns"
        case .compliance:
            return "5:3:1 rule compliance and stack health reports"
        case .analysis:
            return "Comprehensive analysis with AI insights and detailed breakdowns"
        case .executive:
            return "High-level summaries for stakeholders and decision makers"
        case .technical:
            return "Data exports and technical integrations"
        case .custom:
            return "User-created custom report templates"
        }
    }
    
    var icon: String {
        switch self {
        case .productivity: return "chart.line.uptrend.xyaxis"
        case .compliance: return "checkmark.seal"
        case .analysis: return "brain.head.profile"
        case .executive: return "person.3.sequence"
        case .technical: return "terminal"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    var color: Color {
        switch self {
        case .productivity: return .green
        case .compliance: return .blue
        case .analysis: return .purple
        case .executive: return .orange
        case .technical: return .gray
        case .custom: return .pink
        }
    }
}

// MARK: - Report Generation Context

/// Runtime context for report generation
struct ReportGenerationContext {
    let requestId: UUID
    let userId: String?
    let sessionId: UUID?
    let clientInfo: ClientInfo
    let preferences: ReportPreferences
    let constraints: GenerationConstraints
    let startTime: Date
    
    init(
        requestId: UUID = UUID(),
        userId: String? = nil,
        sessionId: UUID? = nil,
        clientInfo: ClientInfo = ClientInfo(),
        preferences: ReportPreferences = ReportPreferences(),
        constraints: GenerationConstraints = GenerationConstraints()
    ) {
        self.requestId = requestId
        self.userId = userId
        self.sessionId = sessionId
        self.clientInfo = clientInfo
        self.preferences = preferences
        self.constraints = constraints
        self.startTime = Date()
    }
}

// MARK: - Client Info

struct ClientInfo: Codable {
    let appVersion: String
    let osVersion: String
    let deviceModel: String
    let locale: String
    let timezone: String
    
    init(
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
        osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString,
        deviceModel: String = "Mac", // Could be enhanced to detect specific Mac model
        locale: String = Locale.current.identifier,
        timezone: String = TimeZone.current.identifier
    ) {
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.locale = locale
        self.timezone = timezone
    }
}

// MARK: - Report Preferences

struct ReportPreferences: Codable {
    var defaultFormat: ReportFormat
    var preferredDateRange: DateRange
    var includeChartsDefault: Bool
    var includeCSDAnalysisDefault: Bool
    var defaultFilters: ReportFilters
    var saveLocation: URL?
    var autoOpenAfterGeneration: Bool
    var notifyOnCompletion: Bool
    
    init(
        defaultFormat: ReportFormat = .pdf,
        preferredDateRange: DateRange = .lastWeek,
        includeChartsDefault: Bool = true,
        includeCSDAnalysisDefault: Bool = true,
        defaultFilters: ReportFilters = ReportFilters(),
        saveLocation: URL? = nil,
        autoOpenAfterGeneration: Bool = true,
        notifyOnCompletion: Bool = true
    ) {
        self.defaultFormat = defaultFormat
        self.preferredDateRange = preferredDateRange
        self.includeChartsDefault = includeChartsDefault
        self.includeCSDAnalysisDefault = includeCSDAnalysisDefault
        self.defaultFilters = defaultFilters
        self.saveLocation = saveLocation
        self.autoOpenAfterGeneration = autoOpenAfterGeneration
        self.notifyOnCompletion = notifyOnCompletion
    }
}

// MARK: - Generation Constraints

struct GenerationConstraints: Codable {
    let maxGenerationTime: TimeInterval // Maximum time allowed for generation
    let maxMemoryUsage: Int64? // Maximum memory usage in bytes
    let maxFileSize: Int64? // Maximum output file size in bytes
    let allowAIProcessing: Bool // Whether AI analysis is allowed
    let allowNetworkAccess: Bool // Whether network access is allowed
    let priority: QueuePriority // Generation priority
    
    init(
        maxGenerationTime: TimeInterval = 300, // 5 minutes default
        maxMemoryUsage: Int64? = nil,
        maxFileSize: Int64? = nil,
        allowAIProcessing: Bool = true,
        allowNetworkAccess: Bool = true,
        priority: QueuePriority = .normal
    ) {
        self.maxGenerationTime = maxGenerationTime
        self.maxMemoryUsage = maxMemoryUsage
        self.maxFileSize = maxFileSize
        self.allowAIProcessing = allowAIProcessing
        self.allowNetworkAccess = allowNetworkAccess
        self.priority = priority
    }
    
    /// Check if a configuration is within constraints
    func validateConfiguration(_ config: ReportConfiguration) -> [String] {
        var violations: [String] = []
        
        // Check AI requirements
        if !allowAIProcessing {
            if config.includeCSDAnalysis {
                violations.append("CSD analysis requires AI processing which is disabled")
            }
            if config.includeInsights {
                violations.append("AI insights require AI processing which is disabled")
            }
            if config.dataTypes.contains(.aiAnalysis) {
                violations.append("AI analysis data type is not allowed")
            }
        }
        
        // Check estimated complexity
        let estimatedSize = config.estimatedSizeCategory
        if let _ = maxFileSize, estimatedSize == .veryLarge {
            violations.append("Report may exceed maximum file size limit")
        }
        
        return violations
    }
}

// MARK: - Report Scheduler

/// Scheduled report configuration
struct ScheduledReport: Identifiable, Codable {
    let id: UUID
    let name: String
    let configuration: ReportConfiguration
    let schedule: ReportSchedule
    let isEnabled: Bool
    let lastRun: Date?
    let nextRun: Date?
    let createdAt: Date
    let runCount: Int
    let lastResult: ReportResult?
    
    init(
        id: UUID = UUID(),
        name: String,
        configuration: ReportConfiguration,
        schedule: ReportSchedule,
        isEnabled: Bool = true,
        lastRun: Date? = nil,
        nextRun: Date? = nil,
        createdAt: Date = Date(),
        runCount: Int = 0,
        lastResult: ReportResult? = nil
    ) {
        self.id = id
        self.name = name
        self.configuration = configuration
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.lastRun = lastRun
        self.nextRun = nextRun
        self.createdAt = createdAt
        self.runCount = runCount
        self.lastResult = lastResult
    }
    
    /// Calculate the next run time based on schedule
    func calculateNextRun(from date: Date = Date()) -> Date? {
        guard isEnabled else { return nil }
        return schedule.nextRunDate(after: date)
    }
    
    /// Check if the report is due to run
    var isDue: Bool {
        guard let nextRun = nextRun else { return false }
        return Date() >= nextRun
    }
}

// MARK: - Report Schedule

enum ReportSchedule: Codable {
    case once(at: Date)
    case daily(at: DateComponents) // hour and minute
    case weekly(dayOfWeek: Int, at: DateComponents) // 1 = Sunday, 2 = Monday, etc.
    case monthly(dayOfMonth: Int, at: DateComponents)
    case custom(cronExpression: String)
    
    var displayName: String {
        switch self {
        case .once(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "Once on \(formatter.string(from: date))"
            
        case .daily(let time):
            return "Daily at \(formatTime(time))"
            
        case .weekly(let dayOfWeek, let time):
            let dayName = Calendar.current.weekdaySymbols[dayOfWeek - 1]
            return "Weekly on \(dayName) at \(formatTime(time))"
            
        case .monthly(let day, let time):
            return "Monthly on day \(day) at \(formatTime(time))"
            
        case .custom(let expression):
            return "Custom schedule: \(expression)"
        }
    }
    
    private func formatTime(_ components: DateComponents) -> String {
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        
        return formatter.string(from: date)
    }
    
    /// Calculate next run date after the given date
    func nextRunDate(after date: Date) -> Date? {
        let calendar = Calendar.current
        
        switch self {
        case .once(let targetDate):
            return targetDate > date ? targetDate : nil
            
        case .daily(let time):
            var nextDate = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: date)
            if let currentNext = nextDate, currentNext <= date {
                nextDate = calendar.date(byAdding: .day, value: 1, to: currentNext)
            }
            return nextDate
            
        case .weekly(let dayOfWeek, let time):
            let currentWeekday = calendar.component(.weekday, from: date)
            let daysUntilTarget = (dayOfWeek - currentWeekday + 7) % 7
            
            var targetDate = calendar.date(byAdding: .day, value: daysUntilTarget, to: date)
            targetDate = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: targetDate ?? date)
            
            if let currentTarget = targetDate, currentTarget <= date {
                targetDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentTarget)
            }
            
            return targetDate
            
        case .monthly(let dayOfMonth, let time):
            let currentDay = calendar.component(.day, from: date)
            var targetDate: Date?
            
            if dayOfMonth >= currentDay {
                // This month
                targetDate = calendar.date(bySetting: .day, value: dayOfMonth, of: date)
            } else {
                // Next month
                if let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) {
                    targetDate = calendar.date(bySetting: .day, value: dayOfMonth, of: nextMonth)
                }
            }
            
            if let currentTarget = targetDate {
                targetDate = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: currentTarget)
            }
            
            return targetDate
            
        case .custom:
            // For now, return nil - would need a cron parser implementation
            return nil
        }
    }
}

// MARK: - Report History

/// Historical record of generated reports
struct ReportHistory: Identifiable, Codable {
    let id: UUID
    let results: [ReportResult]
    let totalGenerated: Int
    let totalSuccessful: Int
    let totalFailed: Int
    let averageGenerationTime: TimeInterval
    let lastUpdated: Date
    
    init(results: [ReportResult] = []) {
        self.id = UUID()
        self.results = results
        self.totalGenerated = results.count
        self.totalSuccessful = results.filter { $0.isSuccess }.count
        self.totalFailed = results.filter { !$0.isSuccess }.count
        self.averageGenerationTime = results.isEmpty ? 0 : results.reduce(0) { $0 + $1.generationDuration } / Double(results.count)
        self.lastUpdated = Date()
    }
    
    /// Success rate as a percentage
    var successRate: Double {
        guard totalGenerated > 0 else { return 0 }
        return Double(totalSuccessful) / Double(totalGenerated) * 100
    }
    
    /// Recent results (last 10)
    var recentResults: [ReportResult] {
        return Array(results.sorted { $0.generatedAt > $1.generatedAt }.prefix(10))
    }
    
    /// Most commonly used configurations
    var popularConfigurations: [ReportConfiguration] {
        let configCounts = Dictionary(grouping: results) { $0.configuration.name }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return Array(configCounts.prefix(5).compactMap { pair in
            results.first { $0.configuration.name == pair.key }?.configuration
        })
    }
}

// MARK: - Report Statistics

/// Usage statistics for the report generation system
struct ReportStatistics: Codable {
    let totalReportsGenerated: Int
    let reportsThisWeek: Int
    let reportsThisMonth: Int
    let mostUsedFormat: ReportFormat?
    let mostUsedDataTypes: [ReportDataType]
    let averageGenerationTime: TimeInterval
    let totalDataProcessed: Int64 // in bytes
    let preferredDateRanges: [DateRange]
    let errorFrequency: [ReportError: Int]
    let generatedAt: Date
    
    init(
        totalReportsGenerated: Int = 0,
        reportsThisWeek: Int = 0,
        reportsThisMonth: Int = 0,
        mostUsedFormat: ReportFormat? = nil,
        mostUsedDataTypes: [ReportDataType] = [],
        averageGenerationTime: TimeInterval = 0,
        totalDataProcessed: Int64 = 0,
        preferredDateRanges: [DateRange] = [],
        errorFrequency: [ReportError: Int] = [:],
        generatedAt: Date = Date()
    ) {
        self.totalReportsGenerated = totalReportsGenerated
        self.reportsThisWeek = reportsThisWeek
        self.reportsThisMonth = reportsThisMonth
        self.mostUsedFormat = mostUsedFormat
        self.mostUsedDataTypes = mostUsedDataTypes
        self.averageGenerationTime = averageGenerationTime
        self.totalDataProcessed = totalDataProcessed
        self.preferredDateRanges = preferredDateRanges
        self.errorFrequency = errorFrequency
        self.generatedAt = generatedAt
    }
    
    /// Formatted total data processed
    var formattedDataProcessed: String {
        return ByteCountFormatter.string(fromByteCount: totalDataProcessed, countStyle: .file)
    }
    
    /// Most common error type
    var mostCommonError: ReportError? {
        return errorFrequency.max { $0.value < $1.value }?.key
    }
}
