import SwiftUI

// MARK: - Enhanced 5:3:1 Category Row

struct Enhanced531CategoryRow: View {
    let metric: CategoryUsageMetrics
    
    // 5:3:1 categorization
    private var categorizedTools: ToolCategorization {
        return categorizeToolsBy531Rule(metric: metric)
    }
    
    private var isEmpty: Bool {
        return metric.allTools.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header with category name and overall status
            CategoryHeader(metric: metric)
            
            // Display content based on whether category is empty
            if isEmpty {
                EmptyCategory531Display(category: metric.category)
            } else {
                SingleRowToolsDisplay(categorization: categorizedTools)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius))
        .shadow(color: DesignSystem.Shadows.card, radius: 2, y: 1)
    }
}

// MARK: - Empty Category Display

struct EmptyCategory531Display: View {
    let category: AppCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Empty state message
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "tray")
                        .font(.system(size: 20))
                        .foregroundColor(category.color.opacity(0.6))
                    
                    Text("No apps assigned to this category")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Text(category.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            
            // Show empty 5:3:1 structure
            EmptyCategory531Structure(category: category)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(category.color.opacity(0.02))
                .stroke(category.color.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }
}

// MARK: - Empty Category 5:3:1 Structure

struct EmptyCategory531Structure: View {
    let category: AppCategory
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Primary slot
            EmptyToolSlotWithLabel(status: .primary, label: "Primary Tool")
            
            StatusDivider()
            
            // Active slots (3)
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Active Tools")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        PlaceholderToolSlot(status: .active)
                    }
                }
            }
            
            StatusDivider()
            
            // Reserve slots (2)
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Strategic Reserve")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<2, id: \.self) { _ in
                        PlaceholderToolSlot(status: .reserve)
                    }
                }
            }
        }
    }
}

// MARK: - Empty Tool Slot with Label

struct EmptyToolSlotWithLabel: View {
    let status: ToolStatus
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            PlaceholderToolSlot(status: status)
        }
    }
}

// MARK: - Category Header

struct CategoryHeader: View {
    let metric: CategoryUsageMetrics
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(metric.category.name)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("\(metric.toolCount) total tools")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                CSDComplianceIndicator(status: metric.compliance, size: 16)
                
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", metric.cognitiveLoad))
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(cognitiveLoadColor)
                    
                    Text("load")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
        }
    }
    
    private var cognitiveLoadColor: Color {
        if metric.cognitiveLoad < 4.0 { return .green }
        else if metric.cognitiveLoad < 7.0 { return .orange }
        else { return .red }
    }
}

// MARK: - Single Row Tools Display

struct SingleRowToolsDisplay: View {
    let categorization: ToolCategorization
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Primary Tool
                if let primaryTool = categorization.primary {
                    SingleRowToolCard(tool: primaryTool, status: .primary)
                }
                
                // Visual divider
                if categorization.primary != nil && (!categorization.active.isEmpty || !categorization.reserve.isEmpty || !categorization.explorationZone.isEmpty) {
                    StatusDivider()
                }
                
                // Active Tools
                ForEach(categorization.active, id: \.bundleIdentifier) { tool in
                    SingleRowToolCard(tool: tool, status: .active)
                }
                
                // Fill remaining active slots with placeholders
                ForEach(categorization.active.count..<3, id: \.self) { _ in
                    PlaceholderToolSlot(status: .active)
                }
                
                // Visual divider
                if !categorization.active.isEmpty && (!categorization.reserve.isEmpty || !categorization.explorationZone.isEmpty) {
                    StatusDivider()
                }
                
                // Strategic Reserve Tools
                ForEach(categorization.reserve, id: \.bundleIdentifier) { tool in
                    SingleRowToolCard(tool: tool, status: .reserve)
                }
                
                // Fill remaining reserve slots with placeholders
                ForEach(categorization.reserve.count..<2, id: \.self) { _ in
                    PlaceholderToolSlot(status: .reserve)
                }
                
                // Visual divider and exploration zone
                if !categorization.explorationZone.isEmpty {
                    StatusDivider()
                    
                    ForEach(categorization.explorationZone, id: \.bundleIdentifier) { tool in
                        SingleRowToolCard(tool: tool, status: .exploration)
                    }
                }
            }
            .padding(.horizontal, 2) // Prevent clipping
        }
    }
}

// MARK: - Tool Status

enum ToolStatus {
    case primary, active, reserve, exploration
    
    var color: Color {
        switch self {
        case .primary: return .green
        case .active: return .blue
        case .reserve: return .orange
        case .exploration: return .red
        }
    }
    
    var name: String {
        switch self {
        case .primary: return "Primary"
        case .active: return "Active"
        case .reserve: return "Reserve"
        case .exploration: return "Exploring"
        }
    }
}

// MARK: - Single Row Tool Card

struct SingleRowToolCard: View {
    let tool: AppUsageStat
    let status: ToolStatus
    @State private var showingTooltip = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // App icon with status indicator
            ZStack(alignment: .topTrailing) {
                if let appIcon = tool.appIcon {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .frame(width: 32, height: 32)
                }
                
                // Status indicator
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .offset(x: 2, y: -2)
            }
            
            // App name
            Text(tool.appName)
                .font(DesignSystem.Typography.caption2)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 60)
            
            // Usage count
            Text("\(tool.activationCount)")
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius / 2)
                .fill(status.color.opacity(0.05))
                .stroke(status.color.opacity(0.2), lineWidth: 1)
        )
        .help(createTooltipText())
        .onTapGesture {
            showingTooltip = true
        }
        .popover(isPresented: $showingTooltip) {
            ToolDetailPopover(tool: tool, status: status)
        }
    }
    
    private func createTooltipText() -> String {
        let lastUsed = RelativeDateTimeFormatter().localizedString(for: tool.lastActiveTimestamp, relativeTo: Date())
        return "\(tool.appName)\n\(status.name) Tool\n\(tool.activationCount) activations\nLast used: \(lastUsed)"
    }
}

// MARK: - Status Divider

struct StatusDivider: View {
    var body: some View {
        Rectangle()
            .fill(DesignSystem.Colors.tertiaryText.opacity(0.3))
            .frame(width: 1, height: 40)
    }
}

// MARK: - Placeholder Tool Slot

struct PlaceholderToolSlot: View {
    let status: ToolStatus
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Placeholder icon
            Image(systemName: "plus.app")
                .font(.system(size: 32))
                .foregroundColor(status.color.opacity(0.4))
                .frame(width: 32, height: 32)
            
            Text("Available")
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(status.color.opacity(0.6))
                .frame(width: 60)
            
            Text("—")
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.tertiaryText.opacity(0.5))
        }
        .padding(DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius / 2)
                .fill(status.color.opacity(0.02))
                .stroke(status.color.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        )
    }
}

// MARK: - Tool Detail Popover

struct ToolDetailPopover: View {
    let tool: AppUsageStat
    let status: ToolStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let appIcon = tool.appIcon {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.appName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 6, height: 6)
                        
                        Text(status.name + " Tool")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(status.color)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Details
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                DetailRow(label: "Activations", value: "\(tool.activationCount)")
                DetailRow(label: "Category", value: tool.category.name)
                DetailRow(label: "Last Used", value: RelativeDateTimeFormatter().localizedString(for: tool.lastActiveTimestamp, relativeTo: Date()))
                
                if let bundleId = tool.bundleIdentifier {
                    DetailRow(label: "Bundle ID", value: bundleId)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(width: 250)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
    }
}


// MARK: - Tool Categorization Logic

struct ToolCategorization {
    let primary: AppUsageStat?
    let active: [AppUsageStat]
    let reserve: [AppUsageStat]
    let explorationZone: [AppUsageStat]
}

func categorizeToolsBy531Rule(metric: CategoryUsageMetrics) -> ToolCategorization {
    let allTools = metric.allTools
    
    // Smart categorization based on usage patterns
    let smartCategorization = smartCategorizeTools(allTools)
    
    return ToolCategorization(
        primary: smartCategorization.primary,
        active: smartCategorization.active,
        reserve: smartCategorization.reserve,
        explorationZone: smartCategorization.exploration
    )
}

// MARK: - Smart Categorization Logic

private func smartCategorizeTools(_ tools: [AppUsageStat]) -> (primary: AppUsageStat?, active: [AppUsageStat], reserve: [AppUsageStat], exploration: [AppUsageStat]) {
    guard !tools.isEmpty else {
        return (nil, [], [], [])
    }
    
    // Sort by composite score: usage frequency + recency
    let scoredTools = tools.map { tool in
        let usageScore = Double(tool.activationCount)
        let recencyScore = calculateRecencyScore(tool.lastActiveTimestamp)
        let compositeScore = (usageScore * 0.7) + (recencyScore * 0.3) // Weight usage more heavily
        
        return (tool: tool, score: compositeScore)
    }.sorted { $0.score > $1.score }
    
    let sortedTools = scoredTools.map { $0.tool }
    
    // Determine primary tool (must have significant usage dominance)
    let primary = determinePrimaryTool(sortedTools)
    let remainingTools = primary != nil ? Array(sortedTools.dropFirst()) : sortedTools
    
    // Active tools: Top 2-3 remaining tools that are actively used
    let activeThreshold = calculateActiveThreshold(remainingTools)
    let activeTools = remainingTools.filter { $0.activationCount >= activeThreshold }.prefix(3)
    
    // Strategic reserve: Next 2 tools with moderate usage
    let usedForActive = Set(activeTools.map { $0.bundleIdentifier })
    let candidatesForReserve = remainingTools.filter { tool in
        !usedForActive.contains(tool.bundleIdentifier) && tool.activationCount >= 2
    }
    let reserveTools = Array(candidatesForReserve.prefix(2))
    
    // Exploration zone: Everything else
    let usedInCoreStack = Set((activeTools + reserveTools).map { $0.bundleIdentifier })
    let explorationTools = remainingTools.filter { tool in
        !usedInCoreStack.contains(tool.bundleIdentifier)
    }
    
    return (
        primary: primary,
        active: Array(activeTools),
        reserve: reserveTools,
        exploration: explorationTools
    )
}

private func determinePrimaryTool(_ tools: [AppUsageStat]) -> AppUsageStat? {
    guard let topTool = tools.first, tools.count > 1 else {
        return tools.first
    }
    
    let totalUsage = tools.reduce(0) { $0 + $1.activationCount }
    let topToolPercentage = Double(topTool.activationCount) / Double(totalUsage)
    
    // Primary tool should have at least 40% of category usage or be significantly ahead
    if topToolPercentage >= 0.4 {
        return topTool
    }
    
    // Check if it's significantly ahead of the second tool
    if tools.count > 1 {
        let secondTool = tools[1]
        let dominanceRatio = Double(topTool.activationCount) / Double(secondTool.activationCount)
        if dominanceRatio >= 2.0 { // At least 2x usage
            return topTool
        }
    }
    
    return nil // No clear primary tool
}

private func calculateActiveThreshold(_ tools: [AppUsageStat]) -> Int {
    guard !tools.isEmpty else { return 0 }
    
    let totalUsage = tools.reduce(0) { $0 + $1.activationCount }
    let averageUsage = Double(totalUsage) / Double(tools.count)
    
    // Active threshold is 20% of average usage, minimum 2
    return max(2, Int(averageUsage * 0.2))
}

private func calculateRecencyScore(_ timestamp: Date) -> Double {
    let now = Date()
    let daysSinceLastUse = now.timeIntervalSince(timestamp) / (24 * 60 * 60)
    
    // Recency score decreases over time, but slowly
    // Score of 10 for today, 5 for 7 days ago, 1 for 30+ days ago
    return max(1.0, 10.0 * exp(-daysSinceLastUse / 10.0))
}

#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Sample with many tools (violation case)
            Enhanced531CategoryRow(metric: CategoryUsageMetrics(
                category: .productivity,
                toolCount: 8,
                activeTools: [
                    AppUsageStat(appName: "Notion", bundleIdentifier: "notion.id", activationCount: 45, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Obsidian", bundleIdentifier: "md.obsidian", activationCount: 32, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Bear", bundleIdentifier: "net.shinyfrog.bear", activationCount: 18, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Drafts", bundleIdentifier: "com.agiletortoise.Drafts-OSX", activationCount: 12, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Ulysses", bundleIdentifier: "com.ulyssesapp.mac", activationCount: 8, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Typora", bundleIdentifier: "abnerworks.Typora", activationCount: 5, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "MarkText", bundleIdentifier: "com.github.marktext", activationCount: 3, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Zettlr", bundleIdentifier: "com.zettlr.app", activationCount: 2, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity)
                ],
                allTools: [
                    AppUsageStat(appName: "Notion", bundleIdentifier: "notion.id", activationCount: 45, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Obsidian", bundleIdentifier: "md.obsidian", activationCount: 32, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Bear", bundleIdentifier: "net.shinyfrog.bear", activationCount: 18, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Drafts", bundleIdentifier: "com.agiletortoise.Drafts-OSX", activationCount: 12, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Ulysses", bundleIdentifier: "com.ulyssesapp.mac", activationCount: 8, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Typora", bundleIdentifier: "abnerworks.Typora", activationCount: 5, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "MarkText", bundleIdentifier: "com.github.marktext", activationCount: 3, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                    AppUsageStat(appName: "Zettlr", bundleIdentifier: "com.zettlr.app", activationCount: 2, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity)
                ],
                primaryTool: AppUsageStat(appName: "Notion", bundleIdentifier: "notion.id", activationCount: 45, appIcon: nil, lastActiveTimestamp: Date(), category: .productivity),
                compliance: .violation,
                cognitiveLoad: 8.2,
                totalActivationCount: 125,
                categoryUsagePercentage: 42.1
            ))
            
            // Sample with optimal tools (healthy case)
            Enhanced531CategoryRow(metric: CategoryUsageMetrics(
                category: .communication,
                toolCount: 3,
                activeTools: [
                    AppUsageStat(appName: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", activationCount: 28, appIcon: nil, lastActiveTimestamp: Date(), category: .communication),
                    AppUsageStat(appName: "Mail", bundleIdentifier: "com.apple.mail", activationCount: 15, appIcon: nil, lastActiveTimestamp: Date(), category: .communication),
                    AppUsageStat(appName: "Messages", bundleIdentifier: "com.apple.MobileSMS", activationCount: 8, appIcon: nil, lastActiveTimestamp: Date(), category: .communication)
                ],
                allTools: [
                    AppUsageStat(appName: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", activationCount: 28, appIcon: nil, lastActiveTimestamp: Date(), category: .communication),
                    AppUsageStat(appName: "Mail", bundleIdentifier: "com.apple.mail", activationCount: 15, appIcon: nil, lastActiveTimestamp: Date(), category: .communication),
                    AppUsageStat(appName: "Messages", bundleIdentifier: "com.apple.MobileSMS", activationCount: 8, appIcon: nil, lastActiveTimestamp: Date(), category: .communication)
                ],
                primaryTool: AppUsageStat(appName: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", activationCount: 28, appIcon: nil, lastActiveTimestamp: Date(), category: .communication),
                compliance: .healthy,
                cognitiveLoad: 3.2,
                totalActivationCount: 51,
                categoryUsagePercentage: 24.3
            ))
            
            // Sample with minimal tools
            Enhanced531CategoryRow(metric: CategoryUsageMetrics(
                category: .design,
                toolCount: 1,
                activeTools: [
                    AppUsageStat(appName: "Figma", bundleIdentifier: "com.figma.Desktop", activationCount: 22, appIcon: nil, lastActiveTimestamp: Date(), category: .design)
                ],
                allTools: [
                    AppUsageStat(appName: "Figma", bundleIdentifier: "com.figma.Desktop", activationCount: 22, appIcon: nil, lastActiveTimestamp: Date(), category: .design)
                ],
                primaryTool: AppUsageStat(appName: "Figma", bundleIdentifier: "com.figma.Desktop", activationCount: 22, appIcon: nil, lastActiveTimestamp: Date(), category: .design),
                compliance: .healthy,
                cognitiveLoad: 2.1,
                totalActivationCount: 22,
                categoryUsagePercentage: 8.7
            ))
            
            // Sample empty category
            Enhanced531CategoryRow(metric: CategoryUsageMetrics(
                category: .education,
                toolCount: 0,
                activeTools: [],
                allTools: [],
                primaryTool: nil,
                compliance: .healthy,
                cognitiveLoad: 0.0,
                totalActivationCount: 0,
                categoryUsagePercentage: 0.0
            ))
        }
        .padding()
    }
    .frame(width: 800, height: 800)
}