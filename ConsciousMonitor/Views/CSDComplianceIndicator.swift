import SwiftUI

// MARK: - CSD Compliance Visual Indicators

/// Small compliance indicator for category rows
struct CSDComplianceIndicator: View {
    let status: CSDComplianceStatus
    let size: CGFloat
    
    init(status: CSDComplianceStatus, size: CGFloat = 16) {
        self.status = status
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: status.icon)
                .font(.system(size: size * 0.8))
                .foregroundColor(status.color)
            
            Text(status.rawValue.capitalized)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius / 2)
                .fill(status.color.opacity(0.1))
                .stroke(status.color.opacity(0.3), lineWidth: 0.5)
        )
    }
}

/// Table-style category row for efficient space usage
struct CSDCategoryTableRow: View {
    let metric: CategoryUsageMetrics
    @State private var showingAllTools = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Column 1: Category Name
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(metric.category.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("\(metric.activeTools.count) active")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .frame(minWidth: 120, alignment: .leading)
            
            // Column 2: Primary Tool
            VStack(spacing: DesignSystem.Spacing.sm) {
                if let primaryTool = metric.primaryTool {
                    // App icon
                    if let appIcon = primaryTool.appIcon {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    
                    // Tool name and usage
                    VStack(spacing: 2) {
                        Text(primaryTool.appName)
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .lineLimit(1)
                        
                        Text("\(primaryTool.activationCount) uses")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                } else {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "questionmark.app.dashed")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        Text("No primary tool")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
            .frame(minWidth: 100, alignment: .center)
            
            // Column 3: Active Tools
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                let visibleTools = showingAllTools ? metric.activeTools : Array(metric.activeTools.prefix(4))
                let hasMoreTools = metric.activeTools.count > 4
                
                if visibleTools.isEmpty {
                    Text("No active tools")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                } else {
                    // First row of tools (up to 4)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: min(4, visibleTools.count)), spacing: 4) {
                        ForEach(Array(visibleTools.prefix(4).enumerated()), id: \.offset) { _, tool in
                            ToolIcon(tool: tool)
                        }
                    }
                    
                    // Additional tools if showing all
                    if showingAllTools && visibleTools.count > 4 {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: min(4, visibleTools.count - 4)), spacing: 4) {
                            ForEach(Array(visibleTools.dropFirst(4).enumerated()), id: \.offset) { _, tool in
                                ToolIcon(tool: tool)
                            }
                        }
                    }
                    
                    // Show more/less button
                    if hasMoreTools {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingAllTools.toggle()
                            }
                        }) {
                            Text(showingAllTools ? "Show Less" : "+ \(metric.activeTools.count - 4) more")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(minWidth: 160, alignment: .leading)
            
            Spacer()
            
            // Column 4: Status & Usage
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.sm) {
                CSDComplianceIndicator(status: metric.compliance, size: 14)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f%%", metric.categoryUsagePercentage))
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("usage")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Cognitive load indicator
                HStack(spacing: 2) {
                    Text(String(format: "%.1f", metric.cognitiveLoad))
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(cognitiveLoadColor)
                    
                    Text("load")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            .frame(minWidth: 80, alignment: .trailing)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
        .shadow(color: DesignSystem.Shadows.elevation1, radius: 1, y: 0.5)
    }
    
    private var cognitiveLoadColor: Color {
        if metric.cognitiveLoad < 4.0 {
            return .green
        } else if metric.cognitiveLoad < 7.0 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Small tool icon with app logo and count
struct ToolIcon: View {
    let tool: AppUsageStat
    
    var body: some View {
        VStack(spacing: 2) {
            if let appIcon = tool.appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .frame(width: 20, height: 20)
            }
            
            Text("\(tool.activationCount)")
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .help(tool.appName) // Tooltip on hover
    }
}

/// Header row for the table
struct CSDCategoryTableHeader: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            Text("Category")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(minWidth: 120, alignment: .leading)
            
            Text("Primary Tool")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(minWidth: 100, alignment: .center)
            
            Text("Active Tools")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(minWidth: 160, alignment: .leading)
            
            Spacer()
            
            Text("Status / Usage")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(minWidth: 80, alignment: .trailing)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

/// Legacy detailed compliance card (kept for backwards compatibility)
struct CSDCategoryCard: View {
    let metric: CategoryUsageMetrics
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header with category and compliance
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(metric.category.name)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("\(metric.activeTools.count) active tools")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                CSDComplianceIndicator(status: metric.compliance)
            }
            
            // Usage statistics
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Cognitive Load")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(String(format: "%.1f", metric.cognitiveLoad))
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(cognitiveLoadColor)
                        
                        Text("/ 10")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("Usage")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(String(format: "%.1f%%", metric.categoryUsagePercentage))
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
            
            // Primary tool info
            if let primaryTool = metric.primaryTool {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Primary:")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(primaryTool.appName)
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text("\(primaryTool.activationCount) uses")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            
            // Expandable tool list
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Active Tools")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    ForEach(metric.activeTools.prefix(5), id: \.bundleIdentifier) { tool in
                        HStack {
                            Text(tool.appName)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            Text("\(tool.activationCount)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    }
                }
            }
            
            // Expand/collapse button
            if metric.activeTools.count > 1 {
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(isExpanded ? "Show Less" : "Show All Tools")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius))
        .shadow(color: DesignSystem.Shadows.card, radius: 2, y: 1)
    }
    
    private var cognitiveLoadColor: Color {
        if metric.cognitiveLoad < 4.0 {
            return .green
        } else if metric.cognitiveLoad < 7.0 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Compact compliance badge for list items
struct CSDComplianceBadge: View {
    let status: CSDComplianceStatus
    
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: 8, height: 8)
            .help(status.description)
    }
}

/// Stack health overview widget
struct StackHealthOverview: View {
    let summary: StackHealthSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            HStack {
                Text("Stack Health")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                CSDComplianceIndicator(status: summary.overallCompliance, size: 20)
            }
            
            // Health score
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Improvement Score")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                HStack {
                    Text(String(format: "%.0f", summary.improvementScore))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                    
                    Text("/ 100")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .alignmentGuide(.lastTextBaseline) { d in d[.lastTextBaseline] }
                }
            }
            
            // Category breakdown
            HStack(spacing: DesignSystem.Spacing.lg) {
                HealthMetric(
                    title: "Healthy",
                    count: summary.healthyCategories,
                    color: .green
                )
                
                HealthMetric(
                    title: "Warning",
                    count: summary.warningCategories,
                    color: .orange
                )
                
                HealthMetric(
                    title: "Violation",
                    count: summary.violationCategories,
                    color: .red
                )
            }
            
            // Average cognitive load
            HStack {
                Text("Avg. Cognitive Load:")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text(String(format: "%.1f / 10", summary.averageCognitiveLoad))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(cognitiveLoadColor)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius))
        .shadow(color: DesignSystem.Shadows.card, radius: 2, y: 1)
    }
    
    private var scoreColor: Color {
        if summary.improvementScore >= 80 {
            return .green
        } else if summary.improvementScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var cognitiveLoadColor: Color {
        if summary.averageCognitiveLoad < 4.0 {
            return .green
        } else if summary.averageCognitiveLoad < 7.0 {
            return .orange
        } else {
            return .red
        }
    }
}

// HealthMetric component is now defined in ImprovementScoreCard.swift

#Preview {
    VStack(spacing: 20) {
        // Sample data for preview
        let sampleMetric = CategoryUsageMetrics(
            category: .productivity,
            toolCount: 4,
            activeTools: [
                AppUsageStat(appName: "Notion", bundleIdentifier: "notion.id", activationCount: 25, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                AppUsageStat(appName: "Obsidian", bundleIdentifier: "md.obsidian", activationCount: 15, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                AppUsageStat(appName: "Bear", bundleIdentifier: "net.shinyfrog.bear", activationCount: 8, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity)
            ],
            allTools: [
                AppUsageStat(appName: "Notion", bundleIdentifier: "notion.id", activationCount: 25, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                AppUsageStat(appName: "Obsidian", bundleIdentifier: "md.obsidian", activationCount: 15, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                AppUsageStat(appName: "Bear", bundleIdentifier: "net.shinyfrog.bear", activationCount: 8, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity)
            ],
            primaryTool: AppUsageStat(appName: "Notion", bundleIdentifier: "notion.id", activationCount: 25, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
            compliance: .warning,
            cognitiveLoad: 6.5,
            totalActivationCount: 48,
            categoryUsagePercentage: 35.2
        )
        
        let sampleSummary = StackHealthSummary(
            overallCompliance: .warning,
            totalCategories: 6,
            healthyCategories: 3,
            warningCategories: 2,
            violationCategories: 1,
            averageCognitiveLoad: 5.8,
            insights: [],
            improvementScore: 72.5
        )
        
        StackHealthOverview(summary: sampleSummary)
        CSDCategoryCard(metric: sampleMetric)
    }
    .padding()
    .frame(width: 400)
}