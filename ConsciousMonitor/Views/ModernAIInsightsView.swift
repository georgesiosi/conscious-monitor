import SwiftUI
import MarkdownUI

struct ModernAIInsightsView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @ObservedObject var userSettings = UserSettings.shared
    @StateObject private var analysisStorage = AnalysisStorageService.shared
    
    @State private var insights: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showChat: Bool = false
    @StateObject private var chatManager = ChatManager()
    
    private let openAIService = OpenAIService()
    
    var body: some View {
        VStack(spacing: 0) {
            // Page header with edge-to-edge card background
            VStack(spacing: DesignSystem.Layout.titleSpacing) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("AI Insights")
                            .font(DesignSystem.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Discover patterns in your digital behavior with AI-powered workstyle analysis")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Status indicator - Condensed format
                    if hasValidAPIKey {
                        HStack(spacing: DesignSystem.Spacing.lg) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Text("\(activityMonitor.appUsageStats.count)")
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.accent)
                                Text("data points")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Text("\(analysisStorage.analyses.count)")
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.success)
                                Text("analyses")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                    } else {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "gear")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.warning)
                            Text("Setup required")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                    }
                }
            }
            .padding(.top, DesignSystem.Layout.pageHeaderPadding)
            .padding(.horizontal, DesignSystem.Layout.contentPadding)
            .padding(.bottom, DesignSystem.Layout.contentPadding)
            .background(DesignSystem.Colors.cardBackground)
            
            // Two-column layout for analysis and chat
            if !hasValidAPIKey {
                // Setup required state - full width
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.xl) {
                        SetupCard()
                    }
                    .padding(DesignSystem.Layout.contentPadding)
                }
            } else if activityMonitor.appUsageStats.isEmpty {
                // No data state - full width
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.xl) {
                        NoDataCard()
                    }
                    .padding(DesignSystem.Layout.contentPadding)
                }
            } else {
                // Two-column layout
                HStack(alignment: .top, spacing: DesignSystem.Spacing.xl) {
                    // Left column - Analysis
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.xl) {
                            // Analysis interface
                            AnalysisCard(
                                isLoading: isLoading,
                                onAnalyze: { 
                                    Task { await analyzeWorkstyle() }
                                }
                            )
                            
                            // Current insights or error
                            if isLoading {
                                LoadingCard()
                            } else if let error = errorMessage {
                                ErrorCard(error: error)
                            } else if !insights.isEmpty {
                                InsightsCard(insights: insights)
                            }
                            
                            // Analysis history - always show, let the card handle empty state
                            AnalysisHistoryCard(history: analysisStorage.analyses)
                        }
                        .padding(DesignSystem.Layout.contentPadding)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right column - Chat
                    VStack(spacing: 0) {
                        if !insights.isEmpty && showChat {
                            // Chat interface header
                            HStack {
                                Text("Ask Questions")
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Button(action: { showChat = false }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(DesignSystem.Spacing.lg)
                            .background(DesignSystem.Colors.cardBackground)
                            
                            // Chat interface
                            ChatInterface(chatManager: chatManager)
                                .background(DesignSystem.Colors.cardBackground)
                                .cornerRadius(DesignSystem.Layout.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                        .stroke(DesignSystem.Colors.tertiaryText.opacity(0.2), lineWidth: 1)
                                )
                        } else if !insights.isEmpty {
                            // Show chat button when analysis is done but chat is hidden
                            VStack(spacing: DesignSystem.Spacing.lg) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                
                                VStack(spacing: DesignSystem.Spacing.md) {
                                    Text("Chat About Your Analysis")
                                        .font(DesignSystem.Typography.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    Text("Start a conversation to get personalized insights and recommendations about your productivity patterns.")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: { showChat = true }) {
                                        HStack(spacing: DesignSystem.Spacing.sm) {
                                            Image(systemName: "bubble.left.and.bubble.right")
                                                .font(.system(size: 16))
                                            Text("Start Conversation")
                                                .font(DesignSystem.Typography.body)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, DesignSystem.Spacing.xl)
                                        .padding(.vertical, DesignSystem.Spacing.md)
                                        .background(DesignSystem.Colors.accent)
                                        .cornerRadius(DesignSystem.Layout.cornerRadius)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(DesignSystem.Spacing.xl)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.Layout.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                    .stroke(DesignSystem.Colors.tertiaryText.opacity(0.2), lineWidth: 1)
                            )
                        } else {
                            // Placeholder for when no analysis is done yet
                            VStack(spacing: DesignSystem.Spacing.lg) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 48))
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                
                                VStack(spacing: DesignSystem.Spacing.md) {
                                    Text("Waiting for Analysis")
                                        .font(DesignSystem.Typography.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    Text("Run an analysis to start chatting about your productivity patterns and get personalized recommendations.")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(DesignSystem.Spacing.xl)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.Layout.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                    .stroke(DesignSystem.Colors.tertiaryText.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, DesignSystem.Layout.contentPadding)
                    .padding(.top, DesignSystem.Layout.contentPadding)
                }
            }
        }
    }
    
    private var hasValidAPIKey: Bool {
        !userSettings.openAIAPIKey.isEmpty
    }
    
    private func analyzeWorkstyle() async {
        isLoading = true
        errorMessage = nil
        insights = ""
        
        let appStats = activityMonitor.appUsageStats
        let result = await openAIService.analyzeUsage(apiKey: userSettings.openAIAPIKey, appUsageStats: appStats)
        
        switch result {
        case .success(let analysisResult):
            insights = analysisResult
            
            // Create enhanced analysis entry with rich metadata
            let analysisContext = AnalysisDataContext(
                totalEvents: activityMonitor.activationEvents.count,
                uniqueApps: appStats.count,
                contextSwitches: activityMonitor.contextSwitches.count,
                timeSpanDays: calculateAnalysisTimeSpan(),
                categoriesAnalyzed: getAnalyzedCategories(),
                mostActiveCategory: getMostActiveCategory(),
                analysisStartDate: getAnalysisStartDate(),
                analysisEndDate: Date()
            )
            
            let entry = AnalysisEntry(
                timestamp: Date(),
                insights: analysisResult,
                dataPoints: appStats.count,
                analysisType: "workstyle",
                timeRangeAnalyzed: getTimeRangeDescription(),
                tokenCount: nil, // TODO: Get from OpenAI response when available
                apiModel: "gpt-4", // TODO: Get from OpenAI service
                analysisVersion: "1.0",
                dataContext: analysisContext
            )
            
            // Add to persistent storage
            do {
                try await analysisStorage.addAnalysis(entry)
            } catch {
                print("Failed to save analysis: \(error.localizedDescription)")
            }
            
            // Initialize chat session with analysis results
            initializeChatSession(analysisResult: analysisResult, entry: entry)
            
        case .failure(let error):
            errorMessage = formatError(error)
        }
        
        isLoading = false
    }
    
    private func formatError(_ error: OpenAIService.OpenAIServiceError) -> String {
        switch error {
        case .apiError(let message):
            return "API Error: \(message)"
        case .decodingError(let underlyingError):
            return "Failed to decode response: \(underlyingError.localizedDescription)"
        case .noData:
            return "No data received from the server."
        case .noChoices:
            return "No analysis choices returned."
        case .noMessageContent:
            return "No message content found in the analysis."
        case .requestFailed(let underlyingError):
            return "Network request failed: \(underlyingError.localizedDescription)"
        case .invalidURL:
            return "Invalid URL configuration."
        }
    }
    
    private func initializeChatSession(analysisResult: String, entry: AnalysisEntry) {
        let analysisId = entry.id.uuidString
        
        // Check if a session already exists for this analysis
        if !chatManager.loadSessionIfExists(for: analysisId) {
            // Create new session with CSD context
            let csdInsights = activityMonitor.generateCSDInsights()
            let categoryMetrics = activityMonitor.getCategoryUsageMetrics()
            
            chatManager.startNewSession(
                analysisId: analysisId,
                originalAnalysis: analysisResult,
                csdInsights: csdInsights,
                categoryMetrics: categoryMetrics
            )
        }
        
        // Show chat interface
        showChat = true
    }
    
    // MARK: - Analysis Context Helper Methods
    
    private func calculateAnalysisTimeSpan() -> Int {
        guard let oldestEvent = activityMonitor.activationEvents.min(by: { $0.timestamp < $1.timestamp }) else {
            return 1
        }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: oldestEvent.timestamp, to: Date()).day ?? 1
        return max(1, days)
    }
    
    private func getAnalyzedCategories() -> [String] {
        let categories = Set(activityMonitor.appUsageStats.map { $0.category.name })
        return Array(categories).sorted()
    }
    
    private func getMostActiveCategory() -> String? {
        let categoryUsage = Dictionary(grouping: activityMonitor.appUsageStats, by: { $0.category.name })
        let categoryTotals = categoryUsage.mapValues { stats in
            stats.reduce(0) { $0 + $1.activationCount }
        }
        
        return categoryTotals.max(by: { $0.value < $1.value })?.key
    }
    
    private func getAnalysisStartDate() -> Date {
        return activityMonitor.activationEvents.min(by: { $0.timestamp < $1.timestamp })?.timestamp ?? Date()
    }
    
    private func getTimeRangeDescription() -> String {
        let timeSpan = calculateAnalysisTimeSpan()
        if timeSpan == 1 {
            return "Today"
        } else if timeSpan <= 7 {
            return "Last \(timeSpan) days"
        } else if timeSpan <= 30 {
            return "Last \(timeSpan) days"
        } else {
            return "Last \(timeSpan) days"
        }
    }
    
}

// MARK: - Setup Required Card

struct SetupRequiredCard: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.warning)
            
            Text("Setup Required")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
        .padding(DesignSystem.Spacing.md)
        .frame(width: 120, height: 80)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Setup Card

struct SetupCard: View {
    var body: some View {
        AnalyticsCard(title: "API Configuration Required", icon: "gear") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Text("To use AI insights, you need to configure your OpenAI API key in the Settings tab.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Steps to get started:")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Text("1.")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.accent)
                                .fontWeight(.medium)
                            
                            Text("Get an API key from OpenAI (platform.openai.com)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Text("2.")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.accent)
                                .fontWeight(.medium)
                            
                            Text("Add your API key in Settings → AI & Personalization")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Text("3.")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.accent)
                                .fontWeight(.medium)
                            
                            Text("Return here to analyze your usage patterns")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - No Data Card

struct NoDataCard: View {
    var body: some View {
        AnalyticsCard(title: "Insufficient Data", icon: "chart.bar.xaxis") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("No app usage data available to analyze yet.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text("Use your Mac normally and ConsciousMonitor will collect data for meaningful AI insights about your productivity patterns.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
    }
}

// MARK: - Analysis Card

struct AnalysisCard: View {
    let isLoading: Bool
    let onAnalyze: () -> Void
    
    var body: some View {
        AnalyticsCard(title: "Workstyle DNA Analysis", icon: "brain.head.profile") {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("Get AI-powered insights into your digital behavior patterns and productivity habits.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Button(action: onAnalyze) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                        }
                        
                        Text(isLoading ? "Analyzing Your Data..." : "Analyze My Workstyle")
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(isLoading ? DesignSystem.Colors.tertiaryText : DesignSystem.Colors.accent)
                    .cornerRadius(DesignSystem.Layout.cornerRadius)
                }
                .disabled(isLoading)
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Loading Card

struct LoadingCard: View {
    var body: some View {
        AnalyticsCard(title: "Analyzing", icon: "brain") {
            VStack(spacing: DesignSystem.Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
                
                Text("AI is analyzing your usage patterns...")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(minHeight: 100)
        }
    }
}

// MARK: - Error Card

struct ErrorCard: View {
    let error: String
    
    var body: some View {
        AnalyticsCard(title: "Analysis Error", icon: "exclamationmark.triangle") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text(error)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text("Please check your API key and try again. If the problem persists, check your internet connection.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
}

// MARK: - Insights Card

struct InsightsCard: View {
    let insights: String
    
    var body: some View {
        AnalyticsCard(title: "Analysis Results", icon: "doc.text") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Markdown(insights)
                    .markdownTextStyle(\.text) {
                        ForegroundColor(DesignSystem.Colors.primaryText)
                    }
                    .markdownTextStyle(\.strong) {
                        ForegroundColor(DesignSystem.Colors.primaryText)
                        FontWeight(.semibold)
                    }
                    .markdownTextStyle(\.emphasis) {
                        ForegroundColor(DesignSystem.Colors.primaryText)
                        FontStyle(.italic)
                    }
                    .markdownTextStyle(\.code) {
                        ForegroundColor(DesignSystem.Colors.primaryText)
                        BackgroundColor(DesignSystem.Colors.hoverBackground)
                    }
                    .markdownBlockStyle(\.codeBlock) { configuration in
                        configuration.label
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.hoverBackground)
                            .cornerRadius(DesignSystem.Layout.cornerRadius)
                    }
                    .markdownBlockStyle(\.blockquote) { configuration in
                        configuration.label
                            .padding(.leading, DesignSystem.Spacing.md)
                            .overlay(
                                Rectangle()
                                    .fill(DesignSystem.Colors.accent)
                                    .frame(width: 3),
                                alignment: .leading
                            )
                    }
                    .textSelection(.enabled)
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.contentBackground)
                    .cornerRadius(DesignSystem.Layout.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .stroke(DesignSystem.Colors.tertiaryText.opacity(0.2), lineWidth: 1)
                    )
                
                Text("💡 This analysis is based on your recent app usage patterns and can help identify areas for productivity improvement.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .padding(.top, DesignSystem.Spacing.sm)
            }
        }
    }
}

// MARK: - Analysis History Card

struct AnalysisHistoryCard: View {
    let history: [AnalysisEntry]
    @State private var selectedEntry: AnalysisEntry?
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        AnalyticsCard(title: "Analysis History", icon: "clock.arrow.circlepath") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                ForEach(history) { entry in
                    Button(action: { selectedEntry = entry }) {
                        HStack {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text(timeFormatter.string(from: entry.timestamp))
                                    .font(DesignSystem.Typography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                Text("\(entry.dataPoints) data points analyzed")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.hoverBackground)
                        .cornerRadius(DesignSystem.Layout.cornerRadius)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Analysis from \(timeFormatter.string(from: entry.timestamp))")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Button("Done") {
                        selectedEntry = nil
                    }
                    .buttonStyle(.bordered)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.contentBackground)
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        Markdown(entry.insights)
                            .markdownTextStyle(\.text) {
                                ForegroundColor(DesignSystem.Colors.primaryText)
                            }
                            .markdownTextStyle(\.strong) {
                                ForegroundColor(DesignSystem.Colors.primaryText)
                                FontWeight(.semibold)
                            }
                            .markdownTextStyle(\.emphasis) {
                                ForegroundColor(DesignSystem.Colors.primaryText)
                                FontStyle(.italic)
                            }
                            .markdownTextStyle(\.code) {
                                ForegroundColor(DesignSystem.Colors.primaryText)
                                BackgroundColor(DesignSystem.Colors.hoverBackground)
                            }
                            .markdownBlockStyle(\.codeBlock) { configuration in
                                configuration.label
                                    .padding(DesignSystem.Spacing.sm)
                                    .background(DesignSystem.Colors.hoverBackground)
                                    .cornerRadius(DesignSystem.Layout.cornerRadius)
                            }
                            .textSelection(.enabled)
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
                .background(DesignSystem.Colors.primaryBackground)
            }
            .frame(
                minWidth: 600,
                idealWidth: 700,
                maxWidth: .infinity,
                minHeight: 500,
                idealHeight: 600,
                maxHeight: .infinity
            )
        }
    }
    
    private func exportAnalyses(format: DataExportService.ExportFormat) {
        DataExportService.shared.exportAnalyses(format: format) { result in
            switch result {
            case .success:
                print("Successfully exported analyses in \(format) format")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
                // TODO: Show error to user
            }
        }
    }
    
    private func exportSingleAnalysis(_ analysis: AnalysisEntry, format: DataExportService.ExportFormat) {
        DataExportService.shared.exportSingleAnalysis(analysis: analysis, format: format) { result in
            switch result {
            case .success:
                print("Successfully exported analysis in \(format) format")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
                // TODO: Show error to user
            }
        }
    }
}

// MARK: - Enhanced Analysis Detail View

struct EnhancedAnalysisDetailView: View {
    let entry: AnalysisEntry
    let onDismiss: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header with metadata
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Analysis Details")
                            .font(DesignSystem.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(timeFormatter.string(from: entry.timestamp))
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Menu {
                            Button("Export as JSON") {
                                exportAnalysis(format: .analysisJSON)
                            }
                            Button("Export as Text") {
                                exportAnalysis(format: .analysisText)
                            }
                            Button("Export as Markdown") {
                                exportAnalysis(format: .analysisMarkdown)
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        .buttonStyle(.plain)
                        
                        Button("Done") {
                            onDismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Metadata cards
                HStack(spacing: DesignSystem.Spacing.md) {
                    MetadataCard(title: "Analysis Type", value: entry.analysisType.capitalized, icon: "brain.head.profile")
                    MetadataCard(title: "Data Points", value: "\(entry.dataPoints)", icon: "chart.bar")
                    MetadataCard(title: "Time Range", value: entry.timeRangeAnalyzed, icon: "calendar")
                    MetadataCard(title: "Reading Time", value: "\(entry.estimatedReadingTimeMinutes) min", icon: "clock")
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.contentBackground)
            
            Divider()
            
            // Enhanced Content with better formatting
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Scope summary
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Analysis Scope")
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(entry.scopeSummary)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.hoverBackground)
                            .cornerRadius(DesignSystem.Layout.cornerRadius)
                    }
                    
                    Divider()
                    
                    // Main insights
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("AI Insights")
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Markdown(entry.insights)
                            .markdownTextStyle(\.text) {
                                ForegroundColor(DesignSystem.Colors.primaryText)
                            }
                            .markdownTextStyle(\.strong) {
                                ForegroundColor(DesignSystem.Colors.primaryText)
                                FontWeight(.semibold)
                            }
                            .markdownTextStyle(\.emphasis) {
                                ForegroundColor(DesignSystem.Colors.primaryText)
                                FontStyle(.italic)
                            }
                            .markdownTextStyle(\.code) {
                                ForegroundColor(DesignSystem.Colors.primaryText)
                                BackgroundColor(DesignSystem.Colors.hoverBackground)
                            }
                            .markdownBlockStyle(\.codeBlock) { configuration in
                                configuration.label
                                    .padding(DesignSystem.Spacing.sm)
                                    .background(DesignSystem.Colors.hoverBackground)
                                    .cornerRadius(DesignSystem.Layout.cornerRadius)
                            }
                            .markdownBlockStyle(\.blockquote) { configuration in
                                configuration.label
                                    .padding(.leading, DesignSystem.Spacing.md)
                                    .overlay(
                                        Rectangle()
                                            .fill(DesignSystem.Colors.accent)
                                            .frame(width: 3),
                                        alignment: .leading
                                    )
                            }
                            .textSelection(.enabled)
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.primaryBackground)
        }
        .frame(
            minWidth: 700,
            idealWidth: 800,
            maxWidth: .infinity,
            minHeight: 600,
            idealHeight: 700,
            maxHeight: .infinity
        )
    }
    
    private func exportAnalysis(format: DataExportService.ExportFormat) {
        DataExportService.shared.exportSingleAnalysis(analysis: entry, format: format) { result in
            switch result {
            case .success:
                print("Successfully exported analysis in \(format) format")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Metadata Card Component

struct MetadataCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.accent)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.hoverBackground)
        .cornerRadius(DesignSystem.Layout.cornerRadius)
    }
}

#Preview {
    ModernAIInsightsView(activityMonitor: ActivityMonitor())
}
