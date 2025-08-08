import Foundation
import AppKit
import UniformTypeIdentifiers
import Combine

// MARK: - Report Generation Service

/// Comprehensive service for generating structured reports from ConsciousMonitor data
/// Integrates with existing DataStorage, AnalyticsService, and export infrastructure
class ReportGenerationService: ObservableObject {
    static let shared = ReportGenerationService()
    
    // MARK: - Published Properties for Progress Tracking
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var currentTask = ""
    @Published var lastGeneratedReport: GeneratedReport?
    
    // MARK: - Dependencies
    private let analyticsService = AnalyticsService()
    private let dataExportService = DataExportService.shared
    private let analysisStorage = AnalysisStorageService.shared
    private let eventStorage = EventStorageService.shared
    
    // MARK: - Configuration
    private let processingQueue = DispatchQueue(label: "com.consciousmonitor.reportGeneration", qos: .userInitiated)
    private let maxReportSize: Int64 = 50 * 1024 * 1024 // 50MB limit
    
    private init() {}
    
    // MARK: - Public Report Generation Methods
    
    /// Generate a comprehensive report with selected data types and formats
    func generateReport(
        config: ReportConfiguration,
        completion: @escaping (Result<GeneratedReport, ReportGenerationError>) -> Void
    ) {
        DispatchQueue.main.async {
            self.isGenerating = true
            self.generationProgress = 0.0
            self.currentTask = "Initializing report generation..."
        }
        
        processingQueue.async {
            do {
                let report = try self.performReportGeneration(config: config)
                
                DispatchQueue.main.async {
                    self.lastGeneratedReport = report
                    self.isGenerating = false
                    self.generationProgress = 1.0
                    self.currentTask = "Report generation completed"
                    completion(.success(report))
                }
            } catch let error as ReportGenerationError {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.generationProgress = 0.0
                    self.currentTask = "Report generation failed"
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.generationProgress = 0.0
                    self.currentTask = "Report generation failed"
                    completion(.failure(.unknown(error.localizedDescription)))
                }
            }
        }
    }
    
    /// Async/await version of report generation
    func generateReport(config: ReportConfiguration) async throws -> GeneratedReport {
        return try await withCheckedThrowingContinuation { continuation in
            generateReport(config: config) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Export generated report to file with user selection
    func exportReport(
        _ report: GeneratedReport,
        format: ReportExportFormat,
        completion: @escaping (Result<URL, ReportGenerationError>) -> Void
    ) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [format.contentType]
        savePanel.nameFieldStringValue = generateExportFileName(for: report, format: format)
        savePanel.title = "Export Report"
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else {
                return // User cancelled
            }
            
            self.processingQueue.async {
                do {
                    let exportData = try self.serializeReport(report, format: format)
                    try exportData.write(to: url)
                    
                    DispatchQueue.main.async {
                        completion(.success(url))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(.exportFailed(error.localizedDescription)))
                    }
                }
            }
        }
    }
    
    // MARK: - Private Report Generation Logic
    
    private func performReportGeneration(config: ReportConfiguration) throws -> GeneratedReport {
        updateProgress(0.1, task: "Loading data...")
        
        // Load all required data based on configuration
        let reportData = try loadReportData(config: config)
        
        updateProgress(0.3, task: "Analyzing data...")
        
        // Generate executive summary
        let executiveSummary = try generateExecutiveSummary(data: reportData, config: config)
        
        updateProgress(0.5, task: "Processing analytics...")
        
        // Generate detailed analytics
        let _ = try generateDetailedAnalytics(data: reportData, config: config)
        
        updateProgress(0.7, task: "Analyzing context switching...")
        
        // Generate context switching analysis
        let contextSwitchAnalysis = try generateContextSwitchAnalysis(data: reportData, config: config)
        
        updateProgress(0.8, task: "Calculating costs...")
        
        // Generate cost calculations
        let costAnalysis = try generateCostAnalysis(data: reportData, config: config)
        
        updateProgress(0.9, task: "Compiling AI insights...")
        
        // Compile AI insights if available
        let aiInsights = try compileAIInsights(data: reportData, config: config)
        
        updateProgress(1.0, task: "Finalizing report...")
        
        // Create final report structure
        let report = GeneratedReport(
            id: UUID(),
            generatedAt: Date(),
            executiveSummary: executiveSummary,
            contextSwitchAnalysis: contextSwitchAnalysis,
            costAnalysis: costAnalysis,
            aiInsights: aiInsights
        )
        
        return report
    }
    
    private func loadReportData(config: ReportConfiguration) throws -> ReportData {
        var events: [AppActivationEvent] = []
        var contextSwitches: [ContextSwitchMetrics] = []
        var aiAnalyses: [AnalysisEntry] = []
        
        // Load events if requested
        if config.dataTypes.contains(.appUsage) {
            events = filterEventsByDateRange(eventStorage.events, dateRange: config.dateRange)
        }
        
        // Load context switches if requested
        if config.dataTypes.contains(.contextSwitches) {
            do {
                let allSwitches = try loadContextSwitchesFromStorage()
                contextSwitches = filterContextSwitchesByDateRange(allSwitches, dateRange: config.dateRange)
            } catch {
                // If we can't load context switches, generate them from events
                if !events.isEmpty {
                    contextSwitches = analyticsService.getIntelligentContextSwitches(from: events)
                }
            }
        }
        
        // Load AI analyses if requested
        if config.dataTypes.contains(.aiAnalysis) {
            aiAnalyses = filterAnalysesByDateRange(analysisStorage.analyses, dateRange: config.dateRange)
        }
        
        return ReportData(
            events: events,
            contextSwitches: contextSwitches,
            aiAnalyses: aiAnalyses
        )
    }
    
    private func generateExecutiveSummary(data: ReportData, config: ReportConfiguration) throws -> ExecutiveSummary {
        let timeRange = config.dateRange
        let totalEvents = data.events.count
        let totalSwitches = data.contextSwitches.count
        
        // Calculate key metrics
        let productivityMetrics = analyticsService.getProductivityMetrics(from: data.events)
        let timeLostMinutes = analyticsService.estimatedTimeLostInMinutes(from: data.contextSwitches)
        let costLost = UserSettings.shared.hourlyRate > 0 ? analyticsService.estimatedCostLost(from: data.contextSwitches, hourlyRate: UserSettings.shared.hourlyRate) : 0
        
        // Generate app usage stats
        let appStats = analyticsService.generateAppUsageStats(from: data.events)
        let topApps = Array(appStats.prefix(5))
        
        // Calculate focus metrics
        let focusTime = analyticsService.totalFocusTimeToday(from: data.contextSwitches)
        let focusSessions = analyticsService.focusSessionsToday(from: data.contextSwitches)
        
        return ExecutiveSummary(
            reportPeriod: timeRange.displayName,
            totalActivations: totalEvents,
            totalContextSwitches: totalSwitches,
            productivityScore: productivityMetrics.productivityScore,
            productivityLevel: productivityMetrics.productivityLevel,
            timeLostHours: timeLostMinutes / 60.0,
            estimatedCostLoss: costLost,
            topApplications: topApps,
            focusTimeHours: focusTime / 3600.0,
            focusSessions: focusSessions,
            keyInsights: generateKeyInsights(data: data, metrics: productivityMetrics)
        )
    }
    
    private func generateDetailedAnalytics(data: ReportData, config: ReportConfiguration) throws -> DetailedAnalytics {
        // App usage breakdown
        let appUsageStats = analyticsService.generateAppUsageStats(from: data.events)
        
        // Category analysis
        let categoryBreakdown = generateCategoryBreakdown(from: data.events)
        
        // Time-based patterns
        let hourlyDistribution = generateHourlyDistribution(from: data.events)
        let dailyPatterns = generateDailyPatterns(from: data.events, config: config)
        
        // Chrome-specific analysis if applicable
        let chromeAnalysis = generateChromeAnalysis(from: data.events)
        
        return DetailedAnalytics(
            appUsageStats: appUsageStats,
            categoryBreakdown: categoryBreakdown,
            hourlyDistribution: hourlyDistribution,
            dailyPatterns: dailyPatterns,
            chromeAnalysis: chromeAnalysis,
            visualizationData: generateVisualizationData(from: data)
        )
    }
    
    private func generateContextSwitchAnalysis(data: ReportData, config: ReportConfiguration) throws -> ContextSwitchAnalysis {
        let switches = data.contextSwitches
        
        // Switch type breakdown
        let quickSwitches = switches.filter { $0.switchType == .quick }
        let normalSwitches = switches.filter { $0.switchType == .normal }
        let focusedSwitches = switches.filter { $0.switchType == .focused }
        
        // Most disruptive switches
        let mostDisruptive = switches
            .filter { $0.timeSpent > 60 } // More than 1 minute
            .sorted { $0.timeSpent > $1.timeSpent }
            .prefix(10)
        
        // Switch patterns by time of day
        let hourlyBreakdown = generateHourlySwitchBreakdown(switches)
        
        // Productivity impact analysis
        let productivityImpact = calculateProductivityImpact(switches)
        
        return ContextSwitchAnalysis(
            totalSwitches: switches.count,
            quickSwitches: quickSwitches.count,
            normalSwitches: normalSwitches.count,
            focusedSwitches: focusedSwitches.count,
            averageSwitchTime: switches.isEmpty ? 0 : switches.map(\.timeSpent).reduce(0, +) / Double(switches.count),
            mostDisruptiveSwitches: Array(mostDisruptive),
            hourlyBreakdown: hourlyBreakdown,
            productivityImpact: productivityImpact,
            recommendations: generateSwitchRecommendations(switches)
        )
    }
    
    private func generateCostAnalysis(data: ReportData, config: ReportConfiguration) throws -> CostAnalysis {
        let hourlyRate = UserSettings.shared.hourlyRate
        
        guard hourlyRate > 0 else {
            return CostAnalysis(
                hourlyRate: 0,
                totalTimeLostHours: 0,
                totalCostLoss: 0,
                dailyAverageCost: 0,
                costByCategory: [:],
                costBySwitchType: [:],
                projectedMonthlyCost: 0,
                projectedYearlyCost: 0
            )
        }
        
        let switches = data.contextSwitches
        let timeLostMinutes = analyticsService.estimatedTimeLostInMinutes(from: switches)
        let timeLostHours = timeLostMinutes / 60.0
        let totalCostLoss = timeLostHours * hourlyRate
        
        // Calculate cost by category
        let events = data.events
        var costByCategory: [String: Double] = [:]
        for category in [AppCategory.productivity, AppCategory.development, AppCategory.communication, AppCategory.entertainment, AppCategory.utilities, AppCategory.other] {
            let categoryEvents = events.filter { $0.category == category }
            let categorySwitches = switches.filter { switchEvent in
                categoryEvents.contains { $0.appName == switchEvent.toApp }
            }
            let categoryTimeLost = analyticsService.estimatedTimeLostInMinutes(from: categorySwitches) / 60.0
            costByCategory[category.name] = categoryTimeLost * hourlyRate
        }
        
        // Calculate cost by switch type
        let costBySwitchType: [String: Double] = [
            "Quick Checks": Double(switches.filter { $0.switchType == .quick }.count) * AnalyticsService.minutesLostPerSwitch * hourlyRate / 60.0,
            "Normal Switches": Double(switches.filter { $0.switchType == .normal }.count) * AnalyticsService.minutesLostPerSwitch * hourlyRate / 60.0,
            "Focus Interruptions": Double(switches.filter { $0.switchType == .focused }.count) * AnalyticsService.minutesLostPerSwitch * hourlyRate / 60.0
        ]
        
        // Project costs
        let daysInPeriod = max(1, Calendar.current.dateComponents([.day], from: config.dateRange.dateInterval.start, to: config.dateRange.dateInterval.end).day ?? 1)
        let dailyAverageCost = daysInPeriod > 0 ? totalCostLoss / Double(daysInPeriod) : 0
        let projectedMonthlyCost = dailyAverageCost * 30
        let projectedYearlyCost = dailyAverageCost * 365
        
        return CostAnalysis(
            hourlyRate: hourlyRate,
            totalTimeLostHours: timeLostHours,
            totalCostLoss: totalCostLoss,
            dailyAverageCost: dailyAverageCost,
            costByCategory: costByCategory,
            costBySwitchType: costBySwitchType,
            projectedMonthlyCost: projectedMonthlyCost,
            projectedYearlyCost: projectedYearlyCost
        )
    }
    
    private func compileAIInsights(data: ReportData, config: ReportConfiguration) throws -> AIInsightsCompilation? {
        let analyses = data.aiAnalyses
        
        guard !analyses.isEmpty else {
            return nil
        }
        
        // Group analyses by type
        let analysesByType = Dictionary(grouping: analyses, by: { $0.analysisType })
        
        // Extract key themes and patterns
        let keyThemes = extractKeyThemes(from: analyses)
        let patterns = extractPatterns(from: analyses)
        let recommendations = extractRecommendations(from: analyses)
        
        // Generate summary insights
        let summaryInsights = generateSummaryInsights(from: analyses)
        
        return AIInsightsCompilation(
            totalAnalyses: analyses.count,
            analysesByType: analysesByType.mapValues { $0.count },
            dateRange: config.dateRange.displayName,
            keyThemes: keyThemes,
            patterns: patterns,
            recommendations: recommendations,
            summaryInsights: summaryInsights,
            detailedAnalyses: analyses.sorted { $0.timestamp > $1.timestamp }
        )
    }
    
    // MARK: - Data Filtering Methods
    
    private func filterEventsByDateRange(_ events: [AppActivationEvent], dateRange: DateRange) -> [AppActivationEvent] {
        let interval = dateRange.dateInterval
        return events.filter { event in
            event.timestamp >= interval.start && event.timestamp <= interval.end
        }
    }
    
    private func filterContextSwitchesByDateRange(_ switches: [ContextSwitchMetrics], dateRange: DateRange) -> [ContextSwitchMetrics] {
        let interval = dateRange.dateInterval
        return switches.filter { switchEvent in
            switchEvent.timestamp >= interval.start && switchEvent.timestamp <= interval.end
        }
    }
    
    private func filterAnalysesByDateRange(_ analyses: [AnalysisEntry], dateRange: DateRange) -> [AnalysisEntry] {
        let interval = dateRange.dateInterval
        return analyses.filter { analysis in
            analysis.timestamp >= interval.start && analysis.timestamp <= interval.end
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadContextSwitchesFromStorage() throws -> [ContextSwitchMetrics] {
        // Try to load from DataStorage (legacy system)
        guard let switchesData = try? Data(contentsOf: DataStorage.shared.contextSwitchesURL) else {
            throw ReportGenerationError.dataLoadFailed("Could not read context switches file")
        }
        
        guard let switches = try? JSONDecoder().decode([ContextSwitchMetrics].self, from: switchesData) else {
            throw ReportGenerationError.dataLoadFailed("Could not decode context switches data")
        }
        
        return switches
    }
    
    private func updateProgress(_ progress: Double, task: String) {
        DispatchQueue.main.async {
            self.generationProgress = progress
            self.currentTask = task
        }
    }
    
    private func estimateDataSize(_ data: ReportData) -> Int64 {
        // Rough estimation of data size in bytes
        let eventSize = data.events.count * 500 // ~500 bytes per event
        let switchSize = data.contextSwitches.count * 300 // ~300 bytes per switch
        let analysisSize = data.aiAnalyses.count * 2000 // ~2KB per analysis
        
        return Int64(eventSize + switchSize + analysisSize)
    }
    
    private func generateKeyInsights(data: ReportData, metrics: ProductivityMetrics) -> [String] {
        var insights: [String] = []
        
        // Productivity insights
        if metrics.productivityScore < 60 {
            insights.append("Productivity score of \(Int(metrics.productivityScore))% suggests room for improvement")
        } else if metrics.productivityScore > 80 {
            insights.append("Strong productivity score of \(Int(metrics.productivityScore))% indicates effective focus management")
        }
        
        // Context switching insights
        let switchCount = data.contextSwitches.count
        if switchCount > 100 {
            insights.append("High context switching activity (\(switchCount) switches) may be impacting focus")
        }
        
        // Time-based insights
        let focusTime = analyticsService.totalFocusTimeToday(from: data.contextSwitches)
        if focusTime < 3600 { // Less than 1 hour
            insights.append("Limited deep focus time detected - consider blocking distractions")
        }
        
        return insights
    }
    
    private func generateCategoryBreakdown(from events: [AppActivationEvent]) -> [String: Int] {
        let categoryGroups = Dictionary(grouping: events, by: { $0.category.name })
        return categoryGroups.mapValues { $0.count }
    }
    
    private func generateHourlyDistribution(from events: [AppActivationEvent]) -> [Int: Int] {
        let hourGroups = Dictionary(grouping: events, by: { Calendar.current.component(.hour, from: $0.timestamp) })
        return hourGroups.mapValues { $0.count }
    }
    
    private func generateDailyPatterns(from events: [AppActivationEvent], config: ReportConfiguration) -> [String: Int] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dailyGroups = Dictionary(grouping: events, by: { dateFormatter.string(from: $0.timestamp) })
        return dailyGroups.mapValues { $0.count }
    }
    
    private func generateChromeAnalysis(from events: [AppActivationEvent]) -> ChromeAnalysis? {
        let chromeEvents = events.filter { $0.bundleIdentifier == "com.google.Chrome" }
        
        guard !chromeEvents.isEmpty else {
            return nil
        }
        
        let totalTabSwitches = chromeEvents.count
        let uniqueDomains = Set(chromeEvents.compactMap { $0.siteDomain }).count
        let mostVisitedDomains = Dictionary(grouping: chromeEvents, by: { $0.siteDomain ?? "unknown" })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(10)
        
        return ChromeAnalysis(
            totalTabSwitches: totalTabSwitches,
            uniqueDomains: uniqueDomains,
            mostVisitedDomains: Dictionary(uniqueKeysWithValues: mostVisitedDomains.map { ($0.key, $0.value) })
        )
    }
    
    private func generateVisualizationData(from data: ReportData) -> VisualizationData {
        // Generate data suitable for charts and graphs
        let appUsageStats = analyticsService.generateAppUsageStats(from: data.events)
        let categoryBreakdown = generateCategoryBreakdown(from: data.events)
        
        return VisualizationData(
            appUsageChartData: appUsageStats.prefix(10).map { ChartDataPoint($0.appName, $0.activationCount) },
            categoryPieChartData: categoryBreakdown.map { ChartDataPoint($0.key, $0.value) },
            timelineData: generateTimelineData(from: data.events).map { ChartDataPoint($0.0, $0.1) }
        )
    }
    
    private func generateHourlySwitchBreakdown(_ switches: [ContextSwitchMetrics]) -> [Int: Int] {
        let hourGroups = Dictionary(grouping: switches, by: { Calendar.current.component(.hour, from: $0.timestamp) })
        return hourGroups.mapValues { $0.count }
    }
    
    private func calculateProductivityImpact(_ switches: [ContextSwitchMetrics]) -> ProductivityImpact {
        let _ = switches.count
        let timeLost = analyticsService.estimatedTimeLostInMinutes(from: switches)
        
        let impactLevel: String
        if timeLost < 30 {
            impactLevel = "Low"
        } else if timeLost < 120 {
            impactLevel = "Moderate"
        } else {
            impactLevel = "High"
        }
        
        return ProductivityImpact(
            impactLevel: impactLevel,
            timeLostMinutes: timeLost,
            efficiencyScore: max(0, 100 - (timeLost / 5.0)), // Rough efficiency calculation
            mostDisruptivePattern: identifyMostDisruptivePattern(switches)
        )
    }
    
    private func generateSwitchRecommendations(_ switches: [ContextSwitchMetrics]) -> [String] {
        var recommendations: [String] = []
        
        let quickSwitches = switches.filter { $0.switchType == .quick }.count
        if quickSwitches > 50 {
            recommendations.append("Consider batching quick checks to reduce frequent interruptions")
        }
        
        let focusInterruptions = switches.filter { $0.switchType == .focused }.count
        if focusInterruptions > 10 {
            recommendations.append("Try using focus modes or notification blocking during deep work sessions")
        }
        
        // Time-based recommendations
        let hourlyBreakdown = generateHourlySwitchBreakdown(switches)
        let peakHour = hourlyBreakdown.max { $0.value < $1.value }?.key ?? 0
        if hourlyBreakdown[peakHour] ?? 0 > 20 {
            recommendations.append("Peak switching activity at \(peakHour):00 - consider scheduling focused work for other times")
        }
        
        return recommendations
    }
    
    private func extractKeyThemes(from analyses: [AnalysisEntry]) -> [String] {
        // Extract common themes from AI insights
        var themes: [String] = []
        
        let allInsights = analyses.map { $0.insights }.joined(separator: " ")
        
        // Simple keyword extraction (in a real implementation, this could be more sophisticated)
        let keywords = ["productivity", "focus", "distraction", "efficiency", "workflow", "interruption"]
        
        for keyword in keywords {
            if allInsights.lowercased().contains(keyword) {
                themes.append(keyword.capitalized)
            }
        }
        
        return themes
    }
    
    private func extractPatterns(from analyses: [AnalysisEntry]) -> [String] {
        // Extract behavioral patterns from analyses
        var patterns: [String] = []
        
        if analyses.count > 1 {
            patterns.append("\(analyses.count) AI analyses generated, showing consistent monitoring")
        }
        
        let recentAnalyses = analyses.filter { $0.isRecent }
        if !recentAnalyses.isEmpty {
            patterns.append("\(recentAnalyses.count) recent analyses indicate active engagement with insights")
        }
        
        return patterns
    }
    
    private func extractRecommendations(from analyses: [AnalysisEntry]) -> [String] {
        // Extract actionable recommendations from AI insights
        var recommendations: [String] = []
        
        for analysis in analyses {
            let insights = analysis.insights.lowercased()
            
            if insights.contains("reduce") || insights.contains("minimize") {
                recommendations.append("Focus on reducing identified distractions")
            }
            
            if insights.contains("schedule") || insights.contains("plan") {
                recommendations.append("Implement better scheduling and planning practices")
            }
            
            if insights.contains("block") || insights.contains("notification") {
                recommendations.append("Consider using notification blocking during focus periods")
            }
        }
        
        return Array(Set(recommendations)) // Remove duplicates
    }
    
    private func generateSummaryInsights(from analyses: [AnalysisEntry]) -> String {
        guard !analyses.isEmpty else {
            return "No AI insights available for this period."
        }
        
        let totalWords = analyses.reduce(0) { $0 + $1.insights.components(separatedBy: .whitespacesAndNewlines).count }
        let avgDataPoints = analyses.reduce(0) { $0 + $1.dataPoints } / analyses.count
        
        return "Generated \(analyses.count) AI analyses covering \(totalWords) words of insights, analyzing an average of \(avgDataPoints) data points each. Key themes focus on productivity optimization and behavioral pattern recognition."
    }
    
    private func generateTimelineData(from events: [AppActivationEvent]) -> [(String, Int)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:00"
        
        let hourlyGroups = Dictionary(grouping: events, by: { dateFormatter.string(from: $0.timestamp) })
        return hourlyGroups.map { ($0.key, $0.value.count) }.sorted { $0.0 < $1.0 }
    }
    
    private func identifyMostDisruptivePattern(_ switches: [ContextSwitchMetrics]) -> String {
        let hourlyBreakdown = generateHourlySwitchBreakdown(switches)
        let peakHour = hourlyBreakdown.max { $0.value < $1.value }?.key ?? 0
        
        return "Peak switching activity occurs at \(peakHour):00 with \(hourlyBreakdown[peakHour] ?? 0) switches"
    }
    
    private func generateExportFileName(for report: GeneratedReport, format: ReportExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: report.generatedAt)
        
        let periodDescription = "report"
        
        return "ConsciousMonitor_Report_\(periodDescription)_\(timestamp).\(format.fileExtension)"
    }
    
    private func serializeReport(_ report: GeneratedReport, format: ReportExportFormat) throws -> Data {
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(report)
            
        case .csv:
            return try generateCSVReport(report)
            
        case .pdf:
            return try generatePDFReport(report)
            
        case .markdown:
            return try generateMarkdownReport(report)
        }
    }
    
    private func generateCSVReport(_ report: GeneratedReport) throws -> Data {
        var csvContent = "ConsciousMonitor Report\n\n"
        
        // Executive Summary section
        csvContent += "Executive Summary\n"
        csvContent += "Metric,Value\n"
        csvContent += "Total Activations,\(report.executiveSummary.totalActivations)\n"
        csvContent += "Total Context Switches,\(report.executiveSummary.totalContextSwitches)\n"
        csvContent += "Productivity Score,\(report.executiveSummary.productivityScore)\n"
        csvContent += "Time Lost (Hours),\(String(format: "%.2f", report.executiveSummary.timeLostHours))\n"
        csvContent += "Estimated Cost Loss,$\(String(format: "%.2f", report.executiveSummary.estimatedCostLoss))\n\n"
        
        // Top Applications section
        csvContent += "Top Applications\n"
        csvContent += "App Name,Activations\n"
        for app in report.executiveSummary.topApplications {
            csvContent += "\(app.appName),\(app.activationCount)\n"
        }
        
        guard let data = csvContent.data(using: String.Encoding.utf8) else {
            throw ReportGenerationError.exportFailed("Failed to convert CSV to data")
        }
        
        return data
    }
    
    private func generatePDFReport(_ report: GeneratedReport) throws -> Data {
        return try generateSimplePDFReport(report)
    }
    
    private func generateSimplePDFReport(_ report: GeneratedReport) throws -> Data {
        let attributedString = createAttributedStringForReport(report)
        
        // Create print info for Letter size
        let printInfo = NSPrintInfo()
        printInfo.paperSize = NSSize(width: 612, height: 792)
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72
        printInfo.topMargin = 72
        printInfo.bottomMargin = 72
        
        // Create a simple text view
        let textStorage = NSTextStorage(attributedString: attributedString)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: 468, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 468, height: 1000))
        textView.textContainer = textContainer
        textView.isEditable = false
        textView.backgroundColor = .white
        textView.textStorage?.setAttributedString(attributedString)
        
        // Calculate required height
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        textView.frame = NSRect(x: 0, y: 0, width: 468, height: max(usedRect.height, 648))
        
        // Generate PDF using dataWithPDF
        let pdfData = textView.dataWithPDF(inside: textView.bounds)
        
        return pdfData
    }
    
    private func createAttributedStringForReport(_ report: GeneratedReport) -> NSAttributedString {
        let mutableString = NSMutableAttributedString()
        
        // Define enhanced styles with better typography
        let titleStyle: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: NSColor.systemBlue,
            .paragraphStyle: createParagraphStyle(alignment: .center, spacing: 24)
        ]
        
        let headingStyle: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: NSColor.black,
            .paragraphStyle: createParagraphStyle(alignment: .left, spacing: 16)
        ]
        
        let subheadingStyle: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.darkGray,
            .paragraphStyle: createParagraphStyle(alignment: .left, spacing: 8)
        ]
        
        let bodyStyle: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.black,
            .paragraphStyle: createParagraphStyle(alignment: .left, spacing: 6)
        ]
        
        let captionStyle: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.darkGray,
            .paragraphStyle: createParagraphStyle(alignment: .center, spacing: 4)
        ]
        
        let metricLabelStyle: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.darkGray,
            .paragraphStyle: createParagraphStyle(alignment: .left, spacing: 4)
        ]
        
        let metricValueStyle: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.black,
            .paragraphStyle: createParagraphStyle(alignment: .left, spacing: 4)
        ]
        
        let highlightStyle: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: NSColor.systemBlue,
            .paragraphStyle: createParagraphStyle(alignment: .left, spacing: 8)
        ]
        
        // Header Section with Professional Styling
        mutableString.append(NSAttributedString(string: "📊 ConsciousMonitor Report\n\n", attributes: titleStyle))
        
        // Add decorative line
        let decorativeLine = String(repeating: "▔", count: 50)
        mutableString.append(NSAttributedString(string: "\(decorativeLine)\n\n", attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.systemBlue.withAlphaComponent(0.7),
            .paragraphStyle: createParagraphStyle(alignment: .center, spacing: 12)
        ]))
        
        // Metadata with better formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        mutableString.append(NSAttributedString(string: "Generated: \(dateFormatter.string(from: report.generatedAt))\n", attributes: captionStyle))
        mutableString.append(NSAttributedString(string: "Report ID: \(String(report.id.uuidString.prefix(8)))...\n\n", attributes: captionStyle))
        
        // Executive Summary with enhanced formatting
        mutableString.append(NSAttributedString(string: "📋 Executive Summary\n", attributes: headingStyle))
        addSectionDivider(to: mutableString)
        
        let summary = report.executiveSummary
        
        // Key highlight metrics in a box-like format
        mutableString.append(NSAttributedString(string: "🎯 Key Performance Indicators\n", attributes: subheadingStyle))
        
        let highlightMetrics = [
            ("Productivity Score", "\(Int(summary.productivityScore))% (\(summary.productivityLevel))"),
            ("Time Lost", String(format: "%.1f hours", summary.timeLostHours)),
            ("Focus Time", String(format: "%.1f hours", summary.focusTimeHours))
        ]
        
        for (label, value) in highlightMetrics {
            mutableString.append(NSAttributedString(string: "  • \(label): ", attributes: metricLabelStyle))
            mutableString.append(NSAttributedString(string: "\(value)\n", attributes: highlightStyle))
        }
        
        mutableString.append(NSAttributedString(string: "\n📊 Detailed Metrics\n", attributes: subheadingStyle))
        
        let detailMetrics = [
            ("Report Period", summary.reportPeriod),
            ("Total App Activations", "\(summary.totalActivations)"),
            ("Context Switches", "\(summary.totalContextSwitches)"),
            ("Estimated Cost Impact", String(format: "$%.2f", summary.estimatedCostLoss)),
            ("Focus Sessions", "\(summary.focusSessions)")
        ]
        
        for (label, value) in detailMetrics {
            mutableString.append(NSAttributedString(string: "  • \(label): ", attributes: metricLabelStyle))
            mutableString.append(NSAttributedString(string: "\(value)\n", attributes: metricValueStyle))
        }
        
        // Key Insights Section
        mutableString.append(NSAttributedString(string: "\n💡 Key Insights\n", attributes: headingStyle))
        addSectionDivider(to: mutableString)
        
        if summary.keyInsights.isEmpty {
            mutableString.append(NSAttributedString(string: "  📝 No specific insights generated for this period.\n", attributes: bodyStyle))
        } else {
            for insight in summary.keyInsights {
                mutableString.append(NSAttributedString(string: "  ✓ \(insight)\n", attributes: bodyStyle))
            }
        }
        
        // Top Applications Section
        mutableString.append(NSAttributedString(string: "\n🏆 Top Applications\n", attributes: headingStyle))
        addSectionDivider(to: mutableString)
        
        if summary.topApplications.isEmpty {
            mutableString.append(NSAttributedString(string: "  📱 No application data available for this period.\n", attributes: bodyStyle))
        } else {
            for (index, app) in summary.topApplications.prefix(8).enumerated() {
                let rankEmoji = getRankEmoji(for: index)
                mutableString.append(NSAttributedString(string: "  \(rankEmoji) \(app.appName): ", attributes: metricLabelStyle))
                mutableString.append(NSAttributedString(string: "\(app.activationCount) activations\n", attributes: metricValueStyle))
            }
        }
        
        // Context Switch Analysis Section
        mutableString.append(NSAttributedString(string: "\n🔄 Context Switch Analysis\n", attributes: headingStyle))
        addSectionDivider(to: mutableString)
        
        let switchAnalysis = report.contextSwitchAnalysis
        
        // Visual breakdown of switch types
        mutableString.append(NSAttributedString(string: "Switch Type Breakdown:\n", attributes: subheadingStyle))
        
        let switchItems = [
            ("⚡ Quick Checks", "\(switchAnalysis.quickSwitches)", "Short interruptions under 30 seconds"),
            ("🔀 Normal Switches", "\(switchAnalysis.normalSwitches)", "Standard app transitions"),
            ("⚠️ Focus Interruptions", "\(switchAnalysis.focusedSwitches)", "Disruptions during focused work"),
            ("⏱️ Average Switch Time", String(format: "%.1f seconds", switchAnalysis.averageSwitchTime), "Time spent per context switch")
        ]
        
        for (label, value, _) in switchItems {
            mutableString.append(NSAttributedString(string: "  \(label): ", attributes: metricLabelStyle))
            mutableString.append(NSAttributedString(string: "\(value)\n", attributes: metricValueStyle))
        }
        
        // Recommendations Section
        if !switchAnalysis.recommendations.isEmpty {
            mutableString.append(NSAttributedString(string: "\n💡 Recommendations\n", attributes: subheadingStyle))
            for recommendation in switchAnalysis.recommendations {
                mutableString.append(NSAttributedString(string: "  🎯 \(recommendation)\n", attributes: bodyStyle))
            }
        }
        
        // Cost Analysis Section
        if let costAnalysis = report.costAnalysis, costAnalysis.hourlyRate > 0 {
            mutableString.append(NSAttributedString(string: "\n💰 Cost Analysis\n", attributes: headingStyle))
            addSectionDivider(to: mutableString)
            
            // Financial impact summary
            mutableString.append(NSAttributedString(string: "Financial Impact Summary:\n", attributes: subheadingStyle))
            
            let costItems = [
                ("💵 Hourly Rate", String(format: "$%.2f", costAnalysis.hourlyRate), "Your configured hourly value"),
                ("📉 Total Cost Loss", String(format: "$%.2f", costAnalysis.totalCostLoss), "Lost productivity value this period"),
                ("📅 Daily Average", String(format: "$%.2f", costAnalysis.dailyAverageCost), "Average daily productivity loss"),
                ("📊 Projected Monthly", String(format: "$%.2f", costAnalysis.projectedMonthlyCost), "Estimated monthly impact"),
                ("📈 Projected Yearly", String(format: "$%.2f", costAnalysis.projectedYearlyCost), "Estimated annual impact")
            ]
            
            for (label, value, _) in costItems {
                mutableString.append(NSAttributedString(string: "  \(label): ", attributes: metricLabelStyle))
                mutableString.append(NSAttributedString(string: "\(value)\n", attributes: highlightStyle))
            }
        }
        
        // AI Insights Section
        if let aiInsights = report.aiInsights {
            mutableString.append(NSAttributedString(string: "\n🤖 AI Insights Summary\n", attributes: headingStyle))
            addSectionDivider(to: mutableString)
            
            mutableString.append(NSAttributedString(string: "Analysis Overview:\n", attributes: subheadingStyle))
            mutableString.append(NSAttributedString(string: "  📊 Total Analyses: \(aiInsights.totalAnalyses)\n", attributes: bodyStyle))
            mutableString.append(NSAttributedString(string: "  🏷️ Key Themes: \(aiInsights.keyThemes.joined(separator: ", "))\n", attributes: bodyStyle))
            mutableString.append(NSAttributedString(string: "\n📝 Summary:\n", attributes: subheadingStyle))
            mutableString.append(NSAttributedString(string: "  \(aiInsights.summaryInsights)\n", attributes: bodyStyle))
            
            if !aiInsights.recommendations.isEmpty {
                mutableString.append(NSAttributedString(string: "\n🎯 AI Recommendations:\n", attributes: subheadingStyle))
                for recommendation in aiInsights.recommendations {
                    mutableString.append(NSAttributedString(string: "  ✨ \(recommendation)\n", attributes: bodyStyle))
                }
            }
        }
        
        // Professional Footer
        mutableString.append(NSAttributedString(string: "\n", attributes: bodyStyle))
        let footerLine = String(repeating: "▔", count: 50)
        mutableString.append(NSAttributedString(string: "\(footerLine)\n", attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.systemBlue.withAlphaComponent(0.7),
            .paragraphStyle: createParagraphStyle(alignment: .center, spacing: 12)
        ]))
        
        mutableString.append(NSAttributedString(string: "Generated by ConsciousMonitor • Professional Productivity Analytics", attributes: captionStyle))
        
        return mutableString
    }
    
    private func generateHTMLForReport(_ report: GeneratedReport) -> String {
        // This method would generate clean HTML, but we're using the NSAttributedString approach instead
        // Keeping this stub for potential future enhancement
        return ""
    }
    
    // MARK: - PDF Formatting Helper Methods
    
    private func createParagraphStyle(alignment: NSTextAlignment, spacing: CGFloat) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineSpacing = spacing * 0.3
        paragraphStyle.paragraphSpacing = spacing
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 0
        paragraphStyle.tailIndent = 0
        return paragraphStyle
    }
    
    private func addSectionDivider(to mutableString: NSMutableAttributedString) {
        let dividerStyle: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .light),
            .foregroundColor: NSColor.systemBlue.withAlphaComponent(0.5),
            .paragraphStyle: createParagraphStyle(alignment: .left, spacing: 8)
        ]
        
        let divider = String(repeating: "─", count: 40)
        mutableString.append(NSAttributedString(string: "\(divider)\n", attributes: dividerStyle))
    }
    
    private func getRankEmoji(for index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        case 3: return "4️⃣"
        case 4: return "5️⃣"
        case 5: return "6️⃣"
        case 6: return "7️⃣"
        case 7: return "8️⃣"
        default: return "📱"
        }
    }
    
    private func generateMarkdownReport(_ report: GeneratedReport) throws -> Data {
        var markdown = "# ConsciousMonitor Report\n\n"
        markdown += "**Generated:** \(report.generatedAt.formatted(date: .complete, time: .shortened))  \n"
        markdown += "**Report ID:** \(report.id.uuidString)  \n\n"
        
        // Executive Summary
        markdown += "## Executive Summary\n\n"
        let summary = report.executiveSummary
        markdown += "- **Total Activations:** \(summary.totalActivations)\n"
        markdown += "- **Context Switches:** \(summary.totalContextSwitches)\n"
        markdown += "- **Productivity Score:** \(Int(summary.productivityScore))% (\(summary.productivityLevel))\n"
        markdown += "- **Time Lost:** \(String(format: "%.1f", summary.timeLostHours)) hours\n"
        markdown += "- **Estimated Cost:** $\(String(format: "%.2f", summary.estimatedCostLoss))\n"
        markdown += "- **Focus Time:** \(String(format: "%.1f", summary.focusTimeHours)) hours\n\n"
        
        // Key Insights
        markdown += "### Key Insights\n\n"
        for insight in summary.keyInsights {
            markdown += "- \(insight)\n"
        }
        
        // Top Applications
        markdown += "\n## Top Applications\n\n"
        markdown += "| App | Activations |\n"
        markdown += "|-----|-------------|\n"
        for app in summary.topApplications {
            markdown += "| \(app.appName) | \(app.activationCount) |\n"
        }
        
        // Context Switch Analysis
        markdown += "\n## Context Switch Analysis\n\n"
        let switchAnalysis = report.contextSwitchAnalysis
        markdown += "- **Quick Checks:** \(switchAnalysis.quickSwitches)\n"
        markdown += "- **Normal Switches:** \(switchAnalysis.normalSwitches)\n"
        markdown += "- **Focus Interruptions:** \(switchAnalysis.focusedSwitches)\n"
        markdown += "- **Average Switch Time:** \(String(format: "%.1f", switchAnalysis.averageSwitchTime)) seconds\n\n"
        
        // Recommendations
        markdown += "### Recommendations\n\n"
        for recommendation in switchAnalysis.recommendations {
            markdown += "- \(recommendation)\n"
        }
        
        // Cost Analysis
        if let costAnalysis = report.costAnalysis, costAnalysis.hourlyRate > 0 {
            markdown += "\n## Cost Analysis\n\n"
            markdown += "- **Hourly Rate:** $\(String(format: "%.2f", costAnalysis.hourlyRate))\n"
            markdown += "- **Total Cost Loss:** $\(String(format: "%.2f", costAnalysis.totalCostLoss))\n"
            markdown += "- **Daily Average:** $\(String(format: "%.2f", costAnalysis.dailyAverageCost))\n"
            markdown += "- **Projected Monthly:** $\(String(format: "%.2f", costAnalysis.projectedMonthlyCost))\n"
            markdown += "- **Projected Yearly:** $\(String(format: "%.2f", costAnalysis.projectedYearlyCost))\n\n"
        }
        
        // AI Insights
        if let aiInsights = report.aiInsights {
            markdown += "\n## AI Insights Summary\n\n"
            markdown += "**Total Analyses:** \(aiInsights.totalAnalyses)\n\n"
            markdown += "**Key Themes:** \(aiInsights.keyThemes.joined(separator: ", "))\n\n"
            markdown += "**Summary:** \(aiInsights.summaryInsights)\n\n"
            
            markdown += "### Recommendations\n\n"
            for recommendation in aiInsights.recommendations {
                markdown += "- \(recommendation)\n"
            }
        }
        
        markdown += "\n---\n*Generated by ConsciousMonitor*\n"
        
        guard let data = markdown.data(using: .utf8) else {
            throw ReportGenerationError.exportFailed("Failed to convert markdown to data")
        }
        
        return data
    }
}

// MARK: - Supporting Data Structures

enum ReportExportFormat: String, CaseIterable {
    case json = "json"
    case csv = "csv"
    case pdf = "pdf"
    case markdown = "markdown"
    
    var displayName: String {
        switch self {
        case .json: return "JSON"
        case .csv: return "CSV"
        case .pdf: return "PDF"
        case .markdown: return "Markdown"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
    
    var contentType: UTType {
        switch self {
        case .json: return .json
        case .csv: return .commaSeparatedText
        case .pdf: return .pdf
        case .markdown: return .data // Markdown doesn't have a specific UTType
        }
    }
}

struct ReportData {
    let events: [AppActivationEvent]
    let contextSwitches: [ContextSwitchMetrics]
    let aiAnalyses: [AnalysisEntry]
}

struct GeneratedReport: Codable {
    let id: UUID
    let generatedAt: Date
    let executiveSummary: ExecutiveSummary
    let contextSwitchAnalysis: ContextSwitchAnalysis
    let costAnalysis: CostAnalysis?
    let aiInsights: AIInsightsCompilation?
}

struct ExecutiveSummary: Codable {
    let reportPeriod: String
    let totalActivations: Int
    let totalContextSwitches: Int
    let productivityScore: Double
    let productivityLevel: String
    let timeLostHours: Double
    let estimatedCostLoss: Double
    let topApplications: [AppUsageStat]
    let focusTimeHours: Double
    let focusSessions: Int
    let keyInsights: [String]
}

struct DetailedAnalytics {
    let appUsageStats: [AppUsageStat]
    let categoryBreakdown: [String: Int]
    let hourlyDistribution: [Int: Int]
    let dailyPatterns: [String: Int]
    let chromeAnalysis: ChromeAnalysis?
    let visualizationData: VisualizationData
}

struct ContextSwitchAnalysis: Codable {
    let totalSwitches: Int
    let quickSwitches: Int
    let normalSwitches: Int
    let focusedSwitches: Int
    let averageSwitchTime: Double
    let mostDisruptiveSwitches: [ContextSwitchMetrics]
    let hourlyBreakdown: [Int: Int]
    let productivityImpact: ProductivityImpact
    let recommendations: [String]
}

struct CostAnalysis: Codable {
    let hourlyRate: Double
    let totalTimeLostHours: Double
    let totalCostLoss: Double
    let dailyAverageCost: Double
    let costByCategory: [String: Double]
    let costBySwitchType: [String: Double]
    let projectedMonthlyCost: Double
    let projectedYearlyCost: Double
}

struct AIInsightsCompilation: Codable {
    let totalAnalyses: Int
    let analysesByType: [String: Int]
    let dateRange: String
    let keyThemes: [String]
    let patterns: [String]
    let recommendations: [String]
    let summaryInsights: String
    let detailedAnalyses: [AnalysisEntry]
}


struct ChromeAnalysis: Codable {
    let totalTabSwitches: Int
    let uniqueDomains: Int
    let mostVisitedDomains: [String: Int]
}

struct VisualizationData {
    let appUsageChartData: [ChartDataPoint]
    let categoryPieChartData: [ChartDataPoint]
    let timelineData: [ChartDataPoint]
}

struct ChartDataPoint: Codable {
    let label: String
    let value: Int
    
    init(_ label: String, _ value: Int) {
        self.label = label
        self.value = value
    }
}

struct ProductivityImpact: Codable {
    let impactLevel: String
    let timeLostMinutes: Double
    let efficiencyScore: Double
    let mostDisruptivePattern: String
}

// MARK: - Error Types

enum ReportGenerationError: Error {
    case dataLoadFailed(String)
    case processingFailed(String)
    case exportFailed(String)
    case configurationInvalid(String)
    case diskSpaceInsufficient
    case reportTooLarge
    case unknown(String)
    
    var localizedDescription: String {
        switch self {
        case .dataLoadFailed(let message):
            return "Failed to load data: \(message)"
        case .processingFailed(let message):
            return "Report processing failed: \(message)"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .configurationInvalid(let message):
            return "Invalid configuration: \(message)"
        case .diskSpaceInsufficient:
            return "Insufficient disk space for report generation"
        case .reportTooLarge:
            return "Report size exceeds maximum limit"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}


