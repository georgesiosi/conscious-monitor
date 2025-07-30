import Foundation
import SwiftUI

// MARK: - CSD Framework Implementation
// Conscious Stack Design 5:3:1 Rule Implementation
// Learn more: https://consciousstack.com
// Future CSTACK platform: https://cstack.ai

/// Compliance status for the 5:3:1 rule
enum CSDComplianceStatus: String, CaseIterable {
    case healthy = "healthy"      // Following 5:3:1 rule
    case warning = "warning"      // 4+ active tools
    case violation = "violation"  // 5+ active tools or other violations
    
    var color: Color {
        switch self {
        case .healthy:
            return .green
        case .warning:
            return .orange
        case .violation:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .healthy:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .violation:
            return "xmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .healthy:
            return "Following 5:3:1 rule - good stack health"
        case .warning:
            return "Consider consolidating tools in this category"
        case .violation:
            return "Too many active tools - high cognitive load"
        }
    }
}

/// Category usage metrics for CSD analysis
struct CategoryUsageMetrics: Identifiable {
    let id = UUID()
    let category: AppCategory
    let toolCount: Int                    // Total tools used
    let activeTools: [AppUsageStat]      // Tools with >10% category usage
    let allTools: [AppUsageStat]         // ALL tools in category (for 5:3:1 display)
    let primaryTool: AppUsageStat?       // Tool with highest usage
    let compliance: CSDComplianceStatus  // 5:3:1 rule compliance
    let cognitiveLoad: Double           // 1-10 scale
    let totalActivationCount: Int       // Total activations in category
    let categoryUsagePercentage: Double // % of total app usage
    
    /// Check if this category follows the 5:3:1 rule
    static func evaluateCompliance(toolCount: Int, activeToolCount: Int) -> CSDComplianceStatus {
        if activeToolCount <= 3 && toolCount <= 5 {
            return .healthy
        } else if activeToolCount == 4 || toolCount == 6 {
            return .warning
        } else {
            return .violation
        }
    }
    
    /// Calculate cognitive load based on tool distribution
    static func calculateCognitiveLoad(activeTools: [AppUsageStat], totalActivations: Int) -> Double {
        guard !activeTools.isEmpty && totalActivations > 0 else { return 0.0 }
        
        // Calculate entropy - more scattered usage = higher cognitive load
        let entropy = activeTools.reduce(0.0) { result, tool in
            let percentage = Double(tool.activationCount) / Double(totalActivations)
            guard percentage > 0 else { return result }
            return result - (percentage * log2(percentage))
        }
        
        // Normalize to 1-10 scale
        // Max entropy for 5 tools would be log2(5) ≈ 2.32
        let maxEntropy = log2(5.0)
        let normalizedEntropy = min(entropy / maxEntropy, 1.0)
        
        // Convert to 1-10 scale where 1 = low load, 10 = high load
        return 1.0 + (normalizedEntropy * 9.0)
    }
}

/// CSD insights and recommendations with actionable items
struct CSDInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let category: AppCategory
    let title: String
    let message: String
    let recommendation: String
    let potentialImpact: String
    let priority: Priority
    let actions: [CSDAction]
    
    enum InsightType: String, CaseIterable {
        case ruleViolation = "rule_violation"
        case consolidationOpportunity = "consolidation_opportunity"
        case valuesAlignment = "values_alignment"
        case cognitiveOverload = "cognitive_overload"
        
        var icon: String {
            switch self {
            case .ruleViolation:
                return "exclamationmark.triangle.fill"
            case .consolidationOpportunity:
                return "arrow.triangle.merge"
            case .valuesAlignment:
                return "heart.circle.fill"
            case .cognitiveOverload:
                return "brain.head.profile"
            }
        }
    }
    
    enum Priority: String, CaseIterable {
        case high = "high"
        case medium = "medium"
        case low = "low"
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
    }
}

/// Actionable items that users can take from insights
struct CSDAction: Identifiable {
    let id = UUID()
    let type: ActionType
    let title: String
    let description: String
    let targetApps: [String] // Bundle identifiers
    let category: AppCategory?
    let isDestructive: Bool
    
    enum ActionType: String, CaseIterable {
        case hideApp = "hide_app"
        case setAppLimit = "set_app_limit"
        case consolidateTools = "consolidate_tools"
        case setPrimaryTool = "set_primary_tool"
        case scheduleReminder = "schedule_reminder"
        case createFocusMode = "create_focus_mode"
        case exportData = "export_data"
        case learnMore = "learn_more"
        
        var icon: String {
            switch self {
            case .hideApp: return "eye.slash"
            case .setAppLimit: return "timer"
            case .consolidateTools: return "arrow.triangle.merge"
            case .setPrimaryTool: return "star.fill"
            case .scheduleReminder: return "bell"
            case .createFocusMode: return "moon.circle"
            case .exportData: return "square.and.arrow.up"
            case .learnMore: return "info.circle"
            }
        }
        
        var isQuickAction: Bool {
            switch self {
            case .hideApp, .setAppLimit, .setPrimaryTool, .scheduleReminder:
                return true
            case .consolidateTools, .createFocusMode, .exportData, .learnMore:
                return false
            }
        }
    }
}

/// Results of executing an action
struct CSDActionResult {
    let success: Bool
    let message: String
    let updatedInsights: [CSDInsight]?
}

/// Smart recommendation engine for generating contextual suggestions
class CSDRecommendationEngine {
    
    /// Generate smart recommendations based on usage patterns and time context
    static func generateSmartActions(
        for insight: CSDInsight,
        with categoryMetrics: [CategoryUsageMetrics],
        at timeOfDay: Date = Date()
    ) -> [CSDAction] {
        var actions: [CSDAction] = []
        
        switch insight.type {
        case .ruleViolation:
            actions.append(contentsOf: generateViolationActions(for: insight, with: categoryMetrics))
            
        case .consolidationOpportunity:
            actions.append(contentsOf: generateConsolidationActions(for: insight, with: categoryMetrics))
            
        case .cognitiveOverload:
            actions.append(contentsOf: generateOverloadActions(for: insight, with: categoryMetrics))
            
        case .valuesAlignment:
            actions.append(contentsOf: generateAlignmentActions(for: insight, with: categoryMetrics))
        }
        
        // Add universal actions
        actions.append(CSDAction(
            type: .learnMore,
            title: "Learn About 5:3:1 Rule",
            description: "Understand how the Conscious Stack Design framework works",
            targetApps: [],
            category: nil,
            isDestructive: false
        ))
        
        return actions
    }
    
    private static func generateViolationActions(
        for insight: CSDInsight,
        with categoryMetrics: [CategoryUsageMetrics]
    ) -> [CSDAction] {
        guard let metric = categoryMetrics.first(where: { $0.category == insight.category }) else {
            return []
        }
        
        var actions: [CSDAction] = []
        
        // Suggest hiding least-used active tools
        let leastUsedTools = metric.activeTools.sorted { $0.activationCount < $1.activationCount }
        if let leastUsed = leastUsedTools.first {
            actions.append(CSDAction(
                type: .hideApp,
                title: "Hide \(leastUsed.appName)",
                description: "Temporarily hide your least-used \(insight.category.name.lowercased()) tool",
                targetApps: [leastUsed.bundleIdentifier ?? "unknown.bundle.id"],
                category: insight.category,
                isDestructive: false
            ))
        }
        
        // Suggest consolidation workflow
        actions.append(CSDAction(
            type: .consolidateTools,
            title: "Start Consolidation Workflow",
            description: "Guided process to reduce \(insight.category.name.lowercased()) tools to 3 active ones",
            targetApps: metric.activeTools.compactMap { $0.bundleIdentifier },
            category: insight.category,
            isDestructive: false
        ))
        
        return actions
    }
    
    private static func generateConsolidationActions(
        for insight: CSDInsight,
        with categoryMetrics: [CategoryUsageMetrics]
    ) -> [CSDAction] {
        guard let metric = categoryMetrics.first(where: { $0.category == insight.category }) else {
            return []
        }
        
        var actions: [CSDAction] = []
        
        // Suggest setting primary tool if not clear
        if let primaryTool = metric.primaryTool,
           Double(primaryTool.activationCount) / Double(metric.totalActivationCount) < 0.6 {
            actions.append(CSDAction(
                type: .setPrimaryTool,
                title: "Set \(primaryTool.appName) as Primary",
                description: "Designate your main \(insight.category.name.lowercased()) tool for better focus",
                targetApps: [primaryTool.bundleIdentifier ?? "unknown.bundle.id"],
                category: insight.category,
                isDestructive: false
            ))
        }
        
        // Suggest app limits for secondary tools
        let secondaryTools = metric.activeTools.filter { $0.bundleIdentifier != metric.primaryTool?.bundleIdentifier }
        if let secondaryTool = secondaryTools.first {
            actions.append(CSDAction(
                type: .setAppLimit,
                title: "Limit \(secondaryTool.appName) Usage",
                description: "Set daily usage limit to reduce cognitive switching",
                targetApps: [secondaryTool.bundleIdentifier ?? "unknown.bundle.id"],
                category: insight.category,
                isDestructive: false
            ))
        }
        
        return actions
    }
    
    private static func generateOverloadActions(
        for insight: CSDInsight,
        with categoryMetrics: [CategoryUsageMetrics]
    ) -> [CSDAction] {
        guard let metric = categoryMetrics.first(where: { $0.category == insight.category }) else {
            return []
        }
        
        var actions: [CSDAction] = []
        
        // Suggest focus mode creation
        if let primaryTool = metric.primaryTool {
            actions.append(CSDAction(
                type: .createFocusMode,
                title: "Create \(insight.category.name) Focus Mode",
                description: "Hide distracting tools and focus on \(primaryTool.appName)",
                targetApps: [primaryTool.bundleIdentifier ?? "unknown.bundle.id"],
                category: insight.category,
                isDestructive: false
            ))
        }
        
        // Suggest reminder to check stack health
        actions.append(CSDAction(
            type: .scheduleReminder,
            title: "Schedule Weekly Review",
            description: "Set reminder to review and optimize your \(insight.category.name.lowercased()) stack",
            targetApps: [],
            category: insight.category,
            isDestructive: false
        ))
        
        return actions
    }
    
    private static func generateAlignmentActions(
        for insight: CSDInsight,
        with categoryMetrics: [CategoryUsageMetrics]
    ) -> [CSDAction] {
        var actions: [CSDAction] = []
        
        // Suggest data export for reflection
        actions.append(CSDAction(
            type: .exportData,
            title: "Export Usage Report",
            description: "Review detailed usage patterns for better alignment decisions",
            targetApps: [],
            category: insight.category,
            isDestructive: false
        ))
        
        return actions
    }
}

/// Overall stack health summary
struct StackHealthSummary {
    let overallCompliance: CSDComplianceStatus
    let totalCategories: Int
    let healthyCategories: Int
    let warningCategories: Int
    let violationCategories: Int
    let averageCognitiveLoad: Double
    let insights: [CSDInsight]
    let improvementScore: Double // 0-100, higher is better
    
    /// Calculate overall health score
    static func calculateImprovementScore(
        healthyCount: Int,
        warningCount: Int,
        violationCount: Int,
        totalCategories: Int,
        avgCognitiveLoad: Double
    ) -> Double {
        guard totalCategories > 0 else { return 0.0 }
        
        // Category compliance score (0-70 points)
        let healthyPoints = Double(healthyCount) * 70.0 / Double(totalCategories)
        let warningPenalty = Double(warningCount) * 20.0 / Double(totalCategories)
        let violationPenalty = Double(violationCount) * 40.0 / Double(totalCategories)
        
        let complianceScore = max(0, healthyPoints - warningPenalty - violationPenalty)
        
        // Cognitive load score (0-30 points)
        // Lower cognitive load = higher score
        let cognitiveScore = max(0, 30.0 - (avgCognitiveLoad * 3.0))
        
        return min(100.0, complianceScore + cognitiveScore)
    }
}

// MARK: - CSD Framework Extension for ActivityMonitor
extension ActivityMonitor {
    
    /// Get category usage metrics for CSD analysis
    func getCategoryUsageMetrics() -> [CategoryUsageMetrics] {
        let categories = AppCategory.defaultCases
        var metrics: [CategoryUsageMetrics] = []
        
        for category in categories {
            let categoryStats = appUsageStats.filter { $0.category == category }
            
            guard !categoryStats.isEmpty else { continue }
            
            let totalCategoryActivations = categoryStats.reduce(0) { $0 + $1.activationCount }
            let totalAllActivations = appUsageStats.reduce(0) { $0 + $1.activationCount }
            
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
    
    /// Generate CSD insights and recommendations
    func generateCSDInsights() -> [CSDInsight] {
        let categoryMetrics = getCategoryUsageMetrics()
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
    
    /// Get overall stack health summary
    func getStackHealthSummary() -> StackHealthSummary {
        let categoryMetrics = getCategoryUsageMetrics()
        let insights = generateCSDInsights()
        
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
}