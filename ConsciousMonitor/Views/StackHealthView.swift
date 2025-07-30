import SwiftUI

// MARK: - Stack Health Dashboard View

struct StackHealthView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @ObservedObject var categoryManager = CategoryManager.shared
    @State private var selectedTimeRange: SharedTimeRange = .today
    @State private var selectedInsightType: CSDInsight.InsightType? = nil
    @State private var showingInsightDetail = false
    @State private var showAllCategories = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Page header with edge-to-edge card background
            VStack(alignment: .leading, spacing: DesignSystem.Layout.titleSpacing) {
                // Page title - Consistent with other pages
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Stack Health")
                            .font(DesignSystem.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Monitor your conscious technology usage")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Share Stack Health button
                    if #available(macOS 13.0, *) {
                        ShareImageButton(
                            events: filteredActivationEvents,
                            contextSwitches: activityMonitor.contextSwitches,
                            timeRange: selectedTimeRange.toShareableTimeRange(),
                            format: .square,
                            privacyLevel: .detailed,
                            customStartDate: nil,
                            customEndDate: nil
                        )
                    }
                }
                
                // Filter controls - Separate row for consistent title alignment
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                        // Compact time range filter
                        CompactTimeRangeFilter(selectedTimeRange: $selectedTimeRange)
                        
                        // Debug info for filtering
                        Text("\(filteredActivationEvents.count) of \(activityMonitor.activationEvents.count) events")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, DesignSystem.Layout.pageHeaderPadding)
            .padding(.horizontal, DesignSystem.Layout.contentPadding)
            .padding(.bottom, DesignSystem.Layout.contentPadding)
            .background(DesignSystem.Colors.cardBackground)
            
            // Scrollable content section
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.sectionSpacing) {
                
                // Your Stack section
                YourStackView(activityMonitor: activityMonitor, selectedTimeRange: selectedTimeRange)
                    .padding(.horizontal, DesignSystem.Layout.contentPadding)
                
                // Three-column layout: Productivity Gains + Improvement Score + 5:3:1 Rule
                HStack(alignment: .top, spacing: DesignSystem.Spacing.xl) {
                    // Left column: Productivity Gains (40% width)
                    ProductivityGainsCard(metrics: productivityGainMetrics)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Center column: Improvement Score (30% width)
                    ImprovementScoreCard(stackHealthSummary: stackHealthSummary)
                        .frame(maxWidth: .infinity)
                    
                    // Right column: 5:3:1 Rule Compact (30% width)
                    Rule531CompactCard()
                        .frame(maxWidth: .infinity)
                }
                
                // Insights and recommendations
                if !insights.isEmpty {
                    InsightsSection(insights: insights, selectedType: $selectedInsightType)
                }
                
                    // Category breakdown
                    CategoryBreakdownSection(
                        metrics: filteredCategoryMetrics,
                        showAllCategories: $showAllCategories
                    )
                }
                .padding(DesignSystem.Layout.contentPadding)
            }
        }
        .navigationTitle("Stack Health")
    }
    
    // MARK: - Computed Properties
    
    private var filteredActivationEvents: [AppActivationEvent] {
        let filtered = selectedTimeRange.filterEvents(activityMonitor.activationEvents, timestampKeyPath: \.timestamp)
        // Debug logging to verify filtering is working
        print("Stack Health: Time range \(selectedTimeRange.rawValue) - Filtered \(filtered.count) events from \(activityMonitor.activationEvents.count) total")
        
        // Log date range for debugging
        if let dateRange = selectedTimeRange.dateRange() {
            print("Date range: \(dateRange.start) to \(dateRange.end)")
            if filtered.count > 0 {
                let oldestEvent = filtered.min(by: { $0.timestamp < $1.timestamp })?.timestamp
                let newestEvent = filtered.max(by: { $0.timestamp > $1.timestamp })?.timestamp
                print("Event range: \(oldestEvent?.description ?? "none") to \(newestEvent?.description ?? "none")")
            }
        }
        
        return filtered
    }
    
    private var categoryMetrics: [CategoryUsageMetrics] {
        return getCategoryUsageMetrics(for: filteredActivationEvents)
    }
    
    private var filteredCategoryMetrics: [CategoryUsageMetrics] {
        let allMetrics = getCategoryUsageMetrics(for: filteredActivationEvents)
        if showAllCategories {
            return allMetrics
        } else {
            return allMetrics.filter { !$0.allTools.isEmpty }
        }
    }
    
    private var stackHealthSummary: StackHealthSummary {
        return getStackHealthSummary(for: filteredActivationEvents)
    }
    
    private var insights: [CSDInsight] {
        let allInsights = generateCSDInsights(for: filteredActivationEvents)
        return selectedInsightType != nil ? 
            allInsights.filter { $0.type == selectedInsightType } : allInsights
    }
    
    // MARK: - Productivity Gain Metrics
    
    /// Calculate productivity gain metrics comparing current period to previous period
    private var productivityGainMetrics: ProductivityGainMetrics {
        return calculateProductivityGainMetrics(
            for: selectedTimeRange,
            currentEvents: filteredActivationEvents,
            allEvents: activityMonitor.activationEvents,
            contextSwitches: activityMonitor.contextSwitches
        )
    }
    
    // MARK: - Computed Properties for Colors
    // Color computation moved to ImprovementScoreCard component
    
    // MARK: - Helper Methods
    
    private func getCategoryUsageMetrics(for events: [AppActivationEvent]) -> [CategoryUsageMetrics] {
        let categories = categoryManager.allAvailableCategories
        var metrics: [CategoryUsageMetrics] = []
        
        // Create app usage stats from filtered events
        let groupedEvents = Dictionary(grouping: events, by: { $0.bundleIdentifier ?? "unknown.bundle.id" })
        let appStats = groupedEvents.map { bundleId, eventsInGroup -> AppUsageStat in
            let sortedEvents = eventsInGroup.sorted { $0.timestamp > $1.timestamp }
            let mostRecent = sortedEvents.first
            
            return AppUsageStat(
                appName: mostRecent?.appName ?? "Unknown App",
                bundleIdentifier: bundleId,
                activationCount: eventsInGroup.count,
                appIcon: mostRecent?.appIcon,
                lastActiveTimestamp: mostRecent?.timestamp ?? Date(),
                category: categoryManager.getCategory(for: bundleId),
                siteBreakdown: nil
            )
        }
        
        let totalAllActivations = appStats.reduce(0) { $0 + $1.activationCount }
        
        for category in categories {
            let categoryStats = appStats.filter { $0.category == category }
            
            // Handle empty categories - create empty metrics
            if categoryStats.isEmpty {
                let emptyMetric = CategoryUsageMetrics(
                    category: category,
                    toolCount: 0,
                    activeTools: [],
                    allTools: [],
                    primaryTool: nil,
                    compliance: .healthy, // Empty categories are technically "healthy"
                    cognitiveLoad: 0.0,
                    totalActivationCount: 0,
                    categoryUsagePercentage: 0.0
                )
                metrics.append(emptyMetric)
                continue
            }
            
            let totalCategoryActivations = categoryStats.reduce(0) { $0 + $1.activationCount }
            
            // Define "active" tools as those with >10% of category usage
            let threshold = max(1, Int(Double(totalCategoryActivations) * 0.1))
            let activeTools = categoryStats.filter { $0.activationCount >= threshold }
            
            let primaryTool = categoryStats.max { $0.activationCount < $1.activationCount }
            
            let compliance = CategoryUsageMetrics.evaluateCompliance(
                toolCount: categoryStats.count,
                activeToolCount: activeTools.count
            )
            
            let cognitiveLoad = CategoryUsageMetrics.calculateCognitiveLoad(
                activeTools: activeTools,
                totalActivations: totalCategoryActivations
            )
            
            let categoryUsagePercentage = totalAllActivations > 0 ? 
                Double(totalCategoryActivations) / Double(totalAllActivations) * 100.0 : 0.0
            
            let metric = CategoryUsageMetrics(
                category: category,
                toolCount: categoryStats.count,
                activeTools: activeTools,
                allTools: categoryStats,
                primaryTool: primaryTool,
                compliance: compliance,
                cognitiveLoad: cognitiveLoad,
                totalActivationCount: totalCategoryActivations,
                categoryUsagePercentage: categoryUsagePercentage
            )
            
            metrics.append(metric)
        }
        
        return metrics.sorted { $0.categoryUsagePercentage > $1.categoryUsagePercentage }
    }
    
    private func generateCSDInsights(for events: [AppActivationEvent]) -> [CSDInsight] {
        let categoryMetrics = getCategoryUsageMetrics(for: events)
        var insights: [CSDInsight] = []
        
        for metric in categoryMetrics {
            // Rule violation insights
            if metric.compliance == .violation {
                insights.append(createInsightWithActions(
                    type: .ruleViolation,
                    category: metric.category,
                    title: "5:3:1 Rule Violation",
                    message: "You're using \(metric.activeTools.count) active tools in \(metric.category.name)",
                    recommendation: "Consider consolidating to your top 3 most essential \(metric.category.name.lowercased()) tools",
                    potentialImpact: "Could reduce cognitive load by \(String(format: "%.1f", max(0, metric.cognitiveLoad - 5.0))) points",
                    priority: .high,
                    categoryMetrics: categoryMetrics
                ))
            }
            
            // Cognitive overload insights
            if metric.cognitiveLoad > 7.0 {
                insights.append(createInsightWithActions(
                    type: .cognitiveOverload,
                    category: metric.category,
                    title: "High Cognitive Load",
                    message: "Your \(metric.category.name.lowercased()) stack has high cognitive load (\(String(format: "%.1f", metric.cognitiveLoad))/10)",
                    recommendation: "Focus more heavily on your primary tool: \(metric.primaryTool?.appName ?? "your main tool")",
                    potentialImpact: "Better focus and reduced context switching",
                    priority: metric.cognitiveLoad > 8.5 ? .high : .medium,
                    categoryMetrics: categoryMetrics
                ))
            }
            
            // Consolidation opportunities
            if metric.compliance == .warning && metric.activeTools.count == 4 {
                insights.append(createInsightWithActions(
                    type: .consolidationOpportunity,
                    category: metric.category,
                    title: "Consolidation Opportunity",
                    message: "You're close to optimal with 4 active \(metric.category.name.lowercased()) tools",
                    recommendation: "Consider which tool provides the least value and could be replaced or removed",
                    potentialImpact: "Achieve optimal 5:3:1 compliance",
                    priority: .medium,
                    categoryMetrics: categoryMetrics
                ))
            }
        }
        
        return insights.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    /// Helper function to create insights with smart actions
    private func createInsightWithActions(
        type: CSDInsight.InsightType,
        category: AppCategory,
        title: String,
        message: String,
        recommendation: String,
        potentialImpact: String,
        priority: CSDInsight.Priority,
        categoryMetrics: [CategoryUsageMetrics]
    ) -> CSDInsight {
        let baseInsight = CSDInsight(
            type: type,
            category: category,
            title: title,
            message: message,
            recommendation: recommendation,
            potentialImpact: potentialImpact,
            priority: priority,
            actions: []
        )
        
        let actions = CSDRecommendationEngine.generateSmartActions(
            for: baseInsight,
            with: categoryMetrics
        )
        
        return CSDInsight(
            type: type,
            category: category,
            title: title,
            message: message,
            recommendation: recommendation,
            potentialImpact: potentialImpact,
            priority: priority,
            actions: actions
        )
    }
    
    private func getStackHealthSummary(for events: [AppActivationEvent]) -> StackHealthSummary {
        let categoryMetrics = getCategoryUsageMetrics(for: events)
        let insights = generateCSDInsights(for: events)
        
        let healthyCount = categoryMetrics.filter { $0.compliance == .healthy }.count
        let warningCount = categoryMetrics.filter { $0.compliance == .warning }.count
        let violationCount = categoryMetrics.filter { $0.compliance == .violation }.count
        
        let avgCognitiveLoad = categoryMetrics.isEmpty ? 0.0 : 
            categoryMetrics.reduce(0.0) { $0 + $1.cognitiveLoad } / Double(categoryMetrics.count)
        
        let overallCompliance: CSDComplianceStatus
        if violationCount > 0 {
            overallCompliance = .violation
        } else if warningCount > healthyCount {
            overallCompliance = .warning
        } else {
            overallCompliance = .healthy
        }
        
        let improvementScore = StackHealthSummary.calculateImprovementScore(
            healthyCount: healthyCount,
            warningCount: warningCount,
            violationCount: violationCount,
            totalCategories: categoryMetrics.count,
            avgCognitiveLoad: avgCognitiveLoad
        )
        
        return StackHealthSummary(
            overallCompliance: overallCompliance,
            totalCategories: categoryMetrics.count,
            healthyCategories: healthyCount,
            warningCategories: warningCount,
            violationCategories: violationCount,
            averageCognitiveLoad: avgCognitiveLoad,
            insights: insights,
            improvementScore: improvementScore
        )
    }
    
    // MARK: - Productivity Gain Calculation Methods
    
    /// Calculate productivity gain metrics comparing current period to previous period
    private func calculateProductivityGainMetrics(
        for timeRange: SharedTimeRange,
        currentEvents: [AppActivationEvent],
        allEvents: [AppActivationEvent],
        contextSwitches: [ContextSwitchMetrics]
    ) -> ProductivityGainMetrics {
        
        // Check if we have minimum data for meaningful comparisons (14 days)
        guard hasMinimumDataForComparison(allEvents: allEvents) else {
            return ProductivityGainMetrics.insufficientData
        }
        
        // Get previous period events for comparison
        let previousEvents = getPreviousPeriodEvents(for: timeRange, allEvents: allEvents)
        let previousContextSwitches = getPreviousPeriodContextSwitches(for: timeRange, contextSwitches: contextSwitches)
        
        // Calculate the three main metrics
        let appHoppingReduction = calculateAppHoppingReduction(
            currentEvents: currentEvents,
            previousEvents: previousEvents,
            currentSwitches: getContextSwitchesForPeriod(timeRange, contextSwitches),
            previousSwitches: previousContextSwitches
        )
        
        let averageDeepWorkDuration = calculateAverageDeepWorkDuration(
            currentSwitches: getContextSwitchesForPeriod(timeRange, contextSwitches)
        )
        
        let dailyTimeSavings = calculateDailyTimeSavings(
            currentSwitches: getContextSwitchesForPeriod(timeRange, contextSwitches),
            previousSwitches: previousContextSwitches,
            timeRange: timeRange
        )
        
        let comparisonPeriod = getComparisonPeriodDescription(for: timeRange)
        
        return ProductivityGainMetrics(
            appHoppingReduction: appHoppingReduction,
            averageDeepWorkDuration: averageDeepWorkDuration,
            dailyTimeSavings: dailyTimeSavings,
            comparisonPeriod: comparisonPeriod,
            hasMinimumData: true
        )
    }
    
    /// Check if we have minimum data for meaningful comparison (14 days)
    private func hasMinimumDataForComparison(allEvents: [AppActivationEvent]) -> Bool {
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let eventsInLast14Days = allEvents.filter { $0.timestamp > fourteenDaysAgo }
        return eventsInLast14Days.count >= 50 // Minimum threshold for meaningful analysis
    }
    
    /// Get events from the previous period for comparison
    private func getPreviousPeriodEvents(for timeRange: SharedTimeRange, allEvents: [AppActivationEvent]) -> [AppActivationEvent] {
        let calendar = Calendar.current
        
        switch timeRange {
        case .today:
            // Compare with yesterday
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            return allEvents.filter { calendar.isDate($0.timestamp, inSameDayAs: yesterday) }
            
        case .week:
            // Compare with previous week
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            return allEvents.filter { 
                calendar.component(.weekOfYear, from: $0.timestamp) == calendar.component(.weekOfYear, from: lastWeek) &&
                calendar.component(.year, from: $0.timestamp) == calendar.component(.year, from: lastWeek)
            }
            
        case .month:
            // Compare with previous month
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return allEvents.filter { 
                calendar.component(.month, from: $0.timestamp) == calendar.component(.month, from: lastMonth) &&
                calendar.component(.year, from: $0.timestamp) == calendar.component(.year, from: lastMonth)
            }
            
        case .all:
            // For all time, compare with the first half vs second half
            let sortedEvents = allEvents.sorted { $0.timestamp < $1.timestamp }
            let midIndex = sortedEvents.count / 2
            return Array(sortedEvents.prefix(midIndex))
        }
    }
    
    /// Get context switches from the previous period for comparison
    private func getPreviousPeriodContextSwitches(for timeRange: SharedTimeRange, contextSwitches: [ContextSwitchMetrics]) -> [ContextSwitchMetrics] {
        let calendar = Calendar.current
        
        switch timeRange {
        case .today:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            return contextSwitches.filter { calendar.isDate($0.timestamp, inSameDayAs: yesterday) }
            
        case .week:
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            return contextSwitches.filter { 
                calendar.component(.weekOfYear, from: $0.timestamp) == calendar.component(.weekOfYear, from: lastWeek) &&
                calendar.component(.year, from: $0.timestamp) == calendar.component(.year, from: lastWeek)
            }
            
        case .month:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return contextSwitches.filter { 
                calendar.component(.month, from: $0.timestamp) == calendar.component(.month, from: lastMonth) &&
                calendar.component(.year, from: $0.timestamp) == calendar.component(.year, from: lastMonth)
            }
            
        case .all:
            let sortedSwitches = contextSwitches.sorted { $0.timestamp < $1.timestamp }
            let midIndex = sortedSwitches.count / 2
            return Array(sortedSwitches.prefix(midIndex))
        }
    }
    
    /// Get context switches for the current period
    private func getContextSwitchesForPeriod(_ timeRange: SharedTimeRange, _ contextSwitches: [ContextSwitchMetrics]) -> [ContextSwitchMetrics] {
        return activityMonitor.analyticsService.getContextSwitches(from: contextSwitches, for: timeRange)
    }
    
    /// Calculate app-hopping reduction percentage
    private func calculateAppHoppingReduction(
        currentEvents: [AppActivationEvent],
        previousEvents: [AppActivationEvent],
        currentSwitches: [ContextSwitchMetrics],
        previousSwitches: [ContextSwitchMetrics]
    ) -> Double {
        // Count quick switches (< 10 seconds) and normal switches (10s - 2min) as "hopping"
        let currentHopping = currentSwitches.filter { $0.switchType == .quick || $0.switchType == .normal }.count
        let previousHopping = previousSwitches.filter { $0.switchType == .quick || $0.switchType == .normal }.count
        
        guard previousHopping > 0 else { return 0 }
        
        let reduction = Double(previousHopping - currentHopping) / Double(previousHopping) * 100
        return max(0, reduction) // Don't show negative improvements
    }
    
    /// Calculate average deep work session duration
    private func calculateAverageDeepWorkDuration(currentSwitches: [ContextSwitchMetrics]) -> TimeInterval {
        let focusedSwitches = currentSwitches.filter { $0.switchType == .focused }
        guard !focusedSwitches.isEmpty else { return 0 }
        
        let totalFocusTime = focusedSwitches.reduce(0) { $0 + $1.timeSpent }
        return totalFocusTime / Double(focusedSwitches.count)
    }
    
    /// Calculate daily time savings from reduced context switching
    private func calculateDailyTimeSavings(
        currentSwitches: [ContextSwitchMetrics],
        previousSwitches: [ContextSwitchMetrics],
        timeRange: SharedTimeRange
    ) -> TimeInterval {
        // Use the AnalyticsService constant for time lost per switch
        let timeLostPerSwitch = AnalyticsService.minutesLostPerSwitch * 60 // Convert to seconds
        
        let currentSignificantSwitches = currentSwitches.filter { $0.switchType == .normal || $0.switchType == .focused }.count
        let previousSignificantSwitches = previousSwitches.filter { $0.switchType == .normal || $0.switchType == .focused }.count
        
        let switchReduction = previousSignificantSwitches - currentSignificantSwitches
        let totalTimeSaved = Double(switchReduction) * timeLostPerSwitch
        
        // Convert to daily savings based on time range
        switch timeRange {
        case .today:
            return totalTimeSaved // Already daily
        case .week:
            return totalTimeSaved / 7 // Average per day
        case .month:
            return totalTimeSaved / 30 // Average per day
        case .all:
            // For all time, calculate based on days of data
            let calendar = Calendar.current
            let daysSinceFirst = calendar.dateComponents([.day], from: currentSwitches.first?.timestamp ?? Date(), to: Date()).day ?? 1
            return totalTimeSaved / Double(max(1, daysSinceFirst))
        }
    }
    
    /// Get description for comparison period
    private func getComparisonPeriodDescription(for timeRange: SharedTimeRange) -> String {
        switch timeRange {
        case .today:
            return "vs yesterday"
        case .week:
            return "vs last week"
        case .month:
            return "vs last month"
        case .all:
            return "vs earlier period"
        }
    }
}

// MARK: - Insights Section

struct InsightsSection: View {
    let insights: [CSDInsight]
    @Binding var selectedType: CSDInsight.InsightType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Insights & Recommendations")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                // Insight type filter
                Menu {
                    Button("All Insights") { selectedType = nil }
                    Divider()
                    ForEach(CSDInsight.InsightType.allCases, id: \.self) { type in
                        Button(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) {
                            selectedType = type
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedType?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "All")
                            .font(DesignSystem.Typography.caption)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            
            if insights.isEmpty {
                EmptyStateView(
                    "Great Job!",
                    subtitle: "No insights to show - your stack health looks good.",
                    systemImage: "checkmark.circle.fill"
                )
                .frame(height: 150)
            } else {
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(insights) { insight in
                        InsightCard(insight: insight)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius))
        .shadow(color: DesignSystem.Shadows.card, radius: 2, y: 1)
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: CSDInsight
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: insight.type.icon)
                        .font(.system(size: 16))
                        .foregroundColor(insight.priority.color)
                    
                    Text(insight.title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                Spacer()
                
                // Priority badge
                Text(insight.priority.rawValue.uppercased())
                    .font(DesignSystem.Typography.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(insight.priority.color)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(insight.priority.color.opacity(0.1))
                    )
            }
            
            // Category
            Text(insight.category.name)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(insight.category.color.opacity(0.2))
                )
            
            // Message
            Text(insight.message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            // Expandable details
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Recommendation")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text(insight.recommendation)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Potential Impact")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text(insight.potentialImpact)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                    
                    // Actions section
                    if !insight.actions.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Quick Actions")
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.sm), count: 2), spacing: DesignSystem.Spacing.sm) {
                                ForEach(insight.actions.prefix(4)) { action in
                                    CSDActionButton(action: action)
                                }
                            }
                            
                            if insight.actions.count > 4 {
                                Text("+ \(insight.actions.count - 4) more actions")
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                            }
                        }
                    }
                }
            }
            
            // Expand/collapse button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "Show Details")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.contentBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
    }
}

// MARK: - Category Breakdown Section

struct CategoryBreakdownSection: View {
    let metrics: [CategoryUsageMetrics]
    @Binding var showAllCategories: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Category Breakdown")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                // Toggle control
                HStack(spacing: DesignSystem.Spacing.md) {
                    Toggle(isOn: $showAllCategories) {
                        Text("Show all categories")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.accent))
                    .help(showAllCategories ? "Currently showing all 15 categories (including empty ones)" : "Currently showing only categories with apps")
                }
            }
            
            // Second row with legend
            HStack {
                Spacer()
                
                // 5:3:1 Legend
                HStack(spacing: DesignSystem.Spacing.md) {
                    LegendItem(color: .green, text: "Primary")
                    LegendItem(color: .blue, text: "Active (3)")
                    LegendItem(color: .orange, text: "Reserve (2)")
                    LegendItem(color: .red, text: "Exploring")
                }
            }
            
            if metrics.isEmpty {
                EmptyStateView(
                    "No Usage Data",
                    subtitle: "Start using apps to see category breakdown.",
                    systemImage: "chart.bar.xaxis"
                )
                .frame(height: 150)
            } else {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Enhanced 5:3:1 Category rows
                    LazyVStack(spacing: DesignSystem.Spacing.lg) {
                        ForEach(metrics, id: \.id) { metric in
                            Enhanced531CategoryRow(metric: metric)
                        }
                    }
                }
            }
        }
    }
}


// MARK: - CSD Action Button

struct CSDActionButton: View {
    let action: CSDAction
    @State private var isExecuting = false
    @State private var executionResult: CSDActionResult?
    @State private var showingResult = false
    @State private var showingConsolidationWorkflow = false
    
    var body: some View {
        Button(action: {
            executeAction()
        }) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isExecuting {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                } else {
                    Image(systemName: action.type.icon)
                        .font(.system(size: 12))
                        .foregroundColor(action.isDestructive ? .red : DesignSystem.Colors.accent)
                }
                
                Text(action.title)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(action.isDestructive ? .red : DesignSystem.Colors.primaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius / 2)
                    .fill(action.isDestructive ? Color.red.opacity(0.1) : DesignSystem.Colors.hoverBackground)
                    .stroke(action.isDestructive ? Color.red.opacity(0.3) : DesignSystem.Colors.accent.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(isExecuting)
        .help(action.description)
        .alert("Action Result", isPresented: $showingResult) {
            Button("OK") { showingResult = false }
        } message: {
            Text(executionResult?.message ?? "Unknown result")
        }
        .sheet(isPresented: $showingConsolidationWorkflow) {
            if let category = action.category {
                // In a real implementation, we'd get the actual tools from the activity monitor
                // For now, we'll show a placeholder
                ConsolidationWorkflowView(
                    category: category,
                    tools: [], // TODO: Get actual tools from activity monitor
                    activityMonitor: ActivityMonitor() // TODO: Pass actual activity monitor
                )
            }
        }
    }
    
    private func executeAction() {
        // Handle consolidation workflow separately
        if action.type == .consolidateTools {
            showingConsolidationWorkflow = true
            return
        }
        
        isExecuting = true
        
        // Simulate action execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            executionResult = CSDActionExecutor.execute(action: action)
            isExecuting = false
            showingResult = true
        }
    }
}

// MARK: - CSD Action Executor

class CSDActionExecutor {
    static func execute(action: CSDAction) -> CSDActionResult {
        switch action.type {
        case .hideApp:
            return executeHideApp(action: action)
        case .setAppLimit:
            return executeSetAppLimit(action: action)
        case .consolidateTools:
            return executeConsolidateTools(action: action)
        case .setPrimaryTool:
            return executeSetPrimaryTool(action: action)
        case .scheduleReminder:
            return executeScheduleReminder(action: action)
        case .createFocusMode:
            return executeCreateFocusMode(action: action)
        case .exportData:
            return executeExportData(action: action)
        case .learnMore:
            return executeLearnMore(action: action)
        }
    }
    
    private static func executeHideApp(action: CSDAction) -> CSDActionResult {
        // In a real implementation, this would hide the app from the dock/launchpad
        // For now, we'll just show a success message
        let appName = action.targetApps.first ?? "app"
        return CSDActionResult(
            success: true,
            message: "Would hide \(appName) from your dock. This feature is coming soon!",
            updatedInsights: nil
        )
    }
    
    private static func executeSetAppLimit(action: CSDAction) -> CSDActionResult {
        let appName = action.targetApps.first ?? "app"
        return CSDActionResult(
            success: true,
            message: "Would set daily usage limit for \(appName). This feature is coming soon!",
            updatedInsights: nil
        )
    }
    
    private static func executeConsolidateTools(action: CSDAction) -> CSDActionResult {
        return CSDActionResult(
            success: true,
            message: "Would start guided consolidation workflow for \(action.category?.name ?? "this category"). This feature is coming soon!",
            updatedInsights: nil
        )
    }
    
    private static func executeSetPrimaryTool(action: CSDAction) -> CSDActionResult {
        let appName = action.targetApps.first ?? "app"
        return CSDActionResult(
            success: true,
            message: "Would mark \(appName) as your primary tool for \(action.category?.name ?? "this category"). This feature is coming soon!",
            updatedInsights: nil
        )
    }
    
    private static func executeScheduleReminder(action: CSDAction) -> CSDActionResult {
        return CSDActionResult(
            success: true,
            message: "Would schedule weekly stack health review reminder. This feature is coming soon!",
            updatedInsights: nil
        )
    }
    
    private static func executeCreateFocusMode(action: CSDAction) -> CSDActionResult {
        return CSDActionResult(
            success: true,
            message: "Would create focus mode for \(action.category?.name ?? "this category"). This feature is coming soon!",
            updatedInsights: nil
        )
    }
    
    private static func executeExportData(action: CSDAction) -> CSDActionResult {
        return CSDActionResult(
            success: true,
            message: "Would export usage data for analysis. This feature is coming soon!",
            updatedInsights: nil
        )
    }
    
    private static func executeLearnMore(action: CSDAction) -> CSDActionResult {
        // Open the 5:3:1 rule explanation
        return CSDActionResult(
            success: true,
            message: "The 5:3:1 rule helps reduce cognitive load by limiting tools per category to 5 total, 3 active, and 1 primary.",
            updatedInsights: nil
        )
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
}

#Preview {
    StackHealthView(activityMonitor: ActivityMonitor())
        .frame(width: 800, height: 1000)
}
