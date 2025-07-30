import Foundation

// MARK: - Analysis Entry Model

struct AnalysisEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let insights: String
    let dataPoints: Int
    
    // Enhanced metadata for better organization and tracking
    let analysisType: String // "workstyle", "productivity", "focus_patterns", etc.
    let timeRangeAnalyzed: String // "Last 7 days", "Today", "This month", etc.
    let tokenCount: Int? // Track API usage for cost monitoring
    let apiModel: String? // Track which AI model was used
    let analysisVersion: String // For future compatibility
    
    // Analysis context for better historical understanding
    let dataContext: AnalysisDataContext
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        insights: String,
        dataPoints: Int,
        analysisType: String = "workstyle",
        timeRangeAnalyzed: String,
        tokenCount: Int? = nil,
        apiModel: String? = nil,
        analysisVersion: String = "1.0",
        dataContext: AnalysisDataContext
    ) {
        self.id = id
        self.timestamp = timestamp
        self.insights = insights
        self.dataPoints = dataPoints
        self.analysisType = analysisType
        self.timeRangeAnalyzed = timeRangeAnalyzed
        self.tokenCount = tokenCount
        self.apiModel = apiModel
        self.analysisVersion = analysisVersion
        self.dataContext = dataContext
    }
}

// MARK: - Analysis Data Context

struct AnalysisDataContext: Codable {
    let totalEvents: Int
    let uniqueApps: Int
    let contextSwitches: Int
    let timeSpanDays: Int
    let categoriesAnalyzed: [String]
    let mostActiveCategory: String?
    let analysisStartDate: Date
    let analysisEndDate: Date
    
    init(
        totalEvents: Int,
        uniqueApps: Int,
        contextSwitches: Int,
        timeSpanDays: Int,
        categoriesAnalyzed: [String],
        mostActiveCategory: String?,
        analysisStartDate: Date,
        analysisEndDate: Date
    ) {
        self.totalEvents = totalEvents
        self.uniqueApps = uniqueApps
        self.contextSwitches = contextSwitches
        self.timeSpanDays = timeSpanDays
        self.categoriesAnalyzed = categoriesAnalyzed
        self.mostActiveCategory = mostActiveCategory
        self.analysisStartDate = analysisStartDate
        self.analysisEndDate = analysisEndDate
    }
}

// MARK: - Analysis Entry Extensions

extension AnalysisEntry {
    /// Human-readable summary of the analysis scope
    var scopeSummary: String {
        let dayText = dataContext.timeSpanDays == 1 ? "day" : "days"
        return "\(dataContext.totalEvents) events across \(dataContext.timeSpanDays) \(dayText)"
    }
    
    /// Short description for UI display
    var shortDescription: String {
        return "\(analysisType.capitalized) analysis • \(timeRangeAnalyzed)"
    }
    
    /// Estimated reading time in minutes
    var estimatedReadingTimeMinutes: Int {
        let wordsPerMinute = 200
        let wordCount = insights.components(separatedBy: .whitespacesAndNewlines).count
        return max(1, wordCount / wordsPerMinute)
    }
    
    /// Check if this analysis is recent (within last 24 hours)
    var isRecent: Bool {
        return timestamp.timeIntervalSinceNow > -24 * 60 * 60
    }
    
    /// Generate a unique filename for this analysis
    var fileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: timestamp)
        return "\(dateString)_\(analysisType)_\(id.uuidString.prefix(8)).json"
    }
}

// MARK: - Analysis Type Helpers

extension AnalysisEntry {
    enum AnalysisTypeEnum: String, CaseIterable {
        case workstyle = "workstyle"
        case productivity = "productivity"
        case focusPatterns = "focus_patterns"
        case contextSwitching = "context_switching"
        case appUsage = "app_usage"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .workstyle: return "Workstyle Analysis"
            case .productivity: return "Productivity Insights"
            case .focusPatterns: return "Focus Patterns"
            case .contextSwitching: return "Context Switching"
            case .appUsage: return "App Usage"
            case .custom: return "Custom Analysis"
            }
        }
        
        var systemImage: String {
            switch self {
            case .workstyle: return "person.circle"
            case .productivity: return "chart.line.uptrend.xyaxis"
            case .focusPatterns: return "eye.circle"
            case .contextSwitching: return "arrow.triangle.swap"
            case .appUsage: return "apps.iphone"
            case .custom: return "wand.and.stars"
            }
        }
    }
    
    var analysisTypeEnum: AnalysisTypeEnum {
        return AnalysisTypeEnum(rawValue: analysisType) ?? .custom
    }
}