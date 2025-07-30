import Foundation
import SwiftUI

// MARK: - Report Data Type Enum

/// Enum for different data types that can be included in reports
enum ReportDataType: String, CaseIterable, Codable, Hashable {
    case appUsage = "app_usage"
    case contextSwitches = "context_switches"
    case categoryMetrics = "category_metrics"
    case csdInsights = "csd_insights"
    case stackHealth = "stack_health"
    case aiAnalysis = "ai_analysis"
    case sessionData = "session_data"
    case chromeData = "chrome_data"
    case productivityMetrics = "productivity_metrics"
    case focusPatterns = "focus_patterns"
    case timeDistribution = "time_distribution"
    case complianceHistory = "compliance_history"
    
    // MARK: - Display Properties
    
    var displayName: String {
        switch self {
        case .appUsage:
            return "App Usage"
        case .contextSwitches:
            return "Context Switches"
        case .categoryMetrics:
            return "Category Metrics"
        case .csdInsights:
            return "CSD Insights"
        case .stackHealth:
            return "Stack Health"
        case .aiAnalysis:
            return "AI Analysis"
        case .sessionData:
            return "Session Data"
        case .chromeData:
            return "Chrome Activity"
        case .productivityMetrics:
            return "Productivity Metrics"
        case .focusPatterns:
            return "Focus Patterns"
        case .timeDistribution:
            return "Time Distribution"
        case .complianceHistory:
            return "Compliance History"
        }
    }
    
    var description: String {
        switch self {
        case .appUsage:
            return "Detailed application usage statistics including activation counts, time spent, and usage patterns"
        case .contextSwitches:
            return "Context switching analysis with metrics on task switching patterns and focus disruptions"
        case .categoryMetrics:
            return "Usage breakdown by application categories with 5:3:1 compliance analysis"
        case .csdInsights:
            return "Conscious Stack Design insights and recommendations for optimizing tool usage"
        case .stackHealth:
            return "Overall tool stack health assessment and improvement opportunities"
        case .aiAnalysis:
            return "AI-generated insights and analysis of productivity patterns and workstyle"
        case .sessionData:
            return "Work session tracking with start/end times and session-based activity grouping"
        case .chromeData:
            return "Chrome browser activity including tab switches, website visits, and browsing patterns"
        case .productivityMetrics:
            return "Quantified productivity measurements including focus scores and efficiency ratings"
        case .focusPatterns:
            return "Deep focus period analysis and concentration pattern identification"
        case .timeDistribution:
            return "Time allocation analysis across different activities, categories, and time periods"
        case .complianceHistory:
            return "Historical 5:3:1 rule compliance tracking and trend analysis over time"
        }
    }
    
    var icon: String {
        switch self {
        case .appUsage:
            return "apps.iphone"
        case .contextSwitches:
            return "arrow.triangle.swap"
        case .categoryMetrics:
            return "chart.pie"
        case .csdInsights:
            return "lightbulb"
        case .stackHealth:
            return "heart.text.square"
        case .aiAnalysis:
            return "brain.head.profile"
        case .sessionData:
            return "clock.arrow.2.circlepath"
        case .chromeData:
            return "globe"
        case .productivityMetrics:
            return "chart.line.uptrend.xyaxis"
        case .focusPatterns:
            return "eye.circle"
        case .timeDistribution:
            return "clock.badge.checkmark"
        case .complianceHistory:
            return "chart.bar.doc.horizontal"
        }
    }
    
    var color: Color {
        switch self {
        case .appUsage:
            return .blue
        case .contextSwitches:
            return .orange
        case .categoryMetrics:
            return .green
        case .csdInsights:
            return .yellow
        case .stackHealth:
            return .red
        case .aiAnalysis:
            return .purple
        case .sessionData:
            return .teal
        case .chromeData:
            return .cyan
        case .productivityMetrics:
            return .indigo
        case .focusPatterns:
            return .pink
        case .timeDistribution:
            return .brown
        case .complianceHistory:
            return .mint
        }
    }
    
    // MARK: - Data Requirements
    
    /// Indicates if this data type requires significant processing time
    var isComputeIntensive: Bool {
        switch self {
        case .aiAnalysis, .csdInsights, .productivityMetrics, .focusPatterns:
            return true
        default:
            return false
        }
    }
    
    /// Indicates if this data type includes large amounts of data
    var isDataIntensive: Bool {
        switch self {
        case .appUsage, .contextSwitches, .sessionData, .chromeData, .complianceHistory:
            return true
        default:
            return false
        }
    }
    
    /// Indicates if this data type requires AI processing
    var requiresAI: Bool {
        switch self {
        case .aiAnalysis, .csdInsights, .productivityMetrics:
            return true
        default:
            return false
        }
    }
    
    /// Indicates if this data type can be exported to CSV format
    var supportsCSVExport: Bool {
        switch self {
        case .appUsage, .contextSwitches, .categoryMetrics, .sessionData, .chromeData, .timeDistribution, .complianceHistory:
            return true
        case .csdInsights, .stackHealth, .aiAnalysis, .productivityMetrics, .focusPatterns:
            return false
        }
    }
    
    /// Indicates if this data type supports chart visualization
    var supportsCharts: Bool {
        switch self {
        case .csdInsights, .aiAnalysis:
            return false
        default:
            return true
        }
    }
    
    // MARK: - Data Dependencies
    
    /// Other data types that this type depends on
    var dependencies: Set<ReportDataType> {
        switch self {
        case .categoryMetrics:
            return [.appUsage]
        case .csdInsights:
            return [.categoryMetrics, .appUsage]
        case .stackHealth:
            return [.categoryMetrics, .csdInsights]
        case .productivityMetrics:
            return [.appUsage, .contextSwitches, .focusPatterns]
        case .focusPatterns:
            return [.sessionData, .contextSwitches]
        case .complianceHistory:
            return [.categoryMetrics]
        default:
            return []
        }
    }
    
    /// Get all data types needed to generate this type (including dependencies)
    func getAllRequiredTypes() -> Set<ReportDataType> {
        var required: Set<ReportDataType> = [self]
        
        for dependency in dependencies {
            required.formUnion(dependency.getAllRequiredTypes())
        }
        
        return required
    }
    
    // MARK: - Grouping and Organization
    
    /// Category for organizing data types in UI
    var category: DataTypeCategory {
        switch self {
        case .appUsage, .sessionData, .chromeData:
            return .usage
        case .contextSwitches, .focusPatterns, .productivityMetrics:
            return .productivity
        case .categoryMetrics, .csdInsights, .stackHealth, .complianceHistory:
            return .analysis
        case .aiAnalysis, .timeDistribution:
            return .insights
        }
    }
    
    /// Recommended data types that work well together
    var recommendedCombinations: Set<ReportDataType> {
        switch self {
        case .appUsage:
            return [.categoryMetrics, .timeDistribution]
        case .contextSwitches:
            return [.focusPatterns, .productivityMetrics]
        case .categoryMetrics:
            return [.csdInsights, .stackHealth]
        case .csdInsights:
            return [.stackHealth, .complianceHistory]
        case .stackHealth:
            return [.csdInsights, .categoryMetrics]
        case .aiAnalysis:
            return [.productivityMetrics, .focusPatterns]
        case .sessionData:
            return [.focusPatterns, .productivityMetrics]
        case .chromeData:
            return [.appUsage, .timeDistribution]
        case .productivityMetrics:
            return [.focusPatterns, .contextSwitches]
        case .focusPatterns:
            return [.productivityMetrics, .sessionData]
        case .timeDistribution:
            return [.appUsage, .categoryMetrics]
        case .complianceHistory:
            return [.stackHealth, .categoryMetrics]
        }
    }
    
    // MARK: - Static Helper Methods
    
    /// Get data types grouped by category
    static func groupedByCategory() -> [DataTypeCategory: [ReportDataType]] {
        return Dictionary(grouping: allCases) { $0.category }
    }
    
    /// Get essential data types for basic reports
    static var essentialTypes: Set<ReportDataType> {
        return [.appUsage, .contextSwitches, .categoryMetrics]
    }
    
    /// Get comprehensive data types for detailed reports
    static var comprehensiveTypes: Set<ReportDataType> {
        return Set(allCases)
    }
    
    /// Get CSD-focused data types
    static var csdTypes: Set<ReportDataType> {
        return [.categoryMetrics, .csdInsights, .stackHealth, .complianceHistory]
    }
    
    /// Get productivity-focused data types
    static var productivityTypes: Set<ReportDataType> {
        return [.contextSwitches, .focusPatterns, .productivityMetrics, .sessionData]
    }
}

// MARK: - Supporting Types

/// Categories for organizing data types
enum DataTypeCategory: String, CaseIterable {
    case usage = "usage"
    case productivity = "productivity"
    case analysis = "analysis"
    case insights = "insights"
    
    var displayName: String {
        switch self {
        case .usage: return "Usage Data"
        case .productivity: return "Productivity"
        case .analysis: return "CSD Analysis"
        case .insights: return "AI Insights"
        }
    }
    
    var description: String {
        switch self {
        case .usage:
            return "Raw usage data and activity tracking"
        case .productivity:
            return "Focus and productivity pattern analysis"
        case .analysis:
            return "Conscious Stack Design framework analysis"
        case .insights:
            return "AI-powered insights and recommendations"
        }
    }
    
    var icon: String {
        switch self {
        case .usage: return "chart.bar"
        case .productivity: return "target"
        case .analysis: return "checkmark.circle"
        case .insights: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .usage: return .blue
        case .productivity: return .green
        case .analysis: return .orange
        case .insights: return .purple
        }
    }
}
