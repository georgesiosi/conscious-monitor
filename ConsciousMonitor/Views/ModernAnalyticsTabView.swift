import SwiftUI

struct AnalyticsTabView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @State private var selectedSegment: AnalyticsSegment = .overview
    
    enum AnalyticsSegment: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case switches = "Context Switches"
        case cost = "Cost Analysis"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.doc.horizontal"
            case .switches: return "arrow.left.arrow.right"
            case .cost: return "dollarsign.circle"
            }
        }
        
        var description: String {
            switch self {
            case .overview: return "Key metrics and insights at a glance"
            case .switches: return "Analyze your context switching patterns"
            case .cost: return "Productivity cost analysis"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Page header with edge-to-edge background
            VStack(spacing: DesignSystem.Layout.titleSpacing) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Analytics")
                            .font(DesignSystem.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Understand your productivity patterns and optimize your workflow")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Quick stats
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text("\(activityMonitor.contextSwitchesToday)")
                                .font(DesignSystem.Typography.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.warning)
                            Text("switches")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text(focusScoreString)
                                .font(DesignSystem.Typography.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(focusScoreColor)
                            Text("focus")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                    }
                }
                
                // Segment picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        ForEach(AnalyticsSegment.allCases) { segment in
                            ModernSegmentButton(
                                title: segment.rawValue,
                                icon: segment.icon,
                                description: segment.description,
                                isSelected: selectedSegment == segment
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedSegment = segment
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                }
            }
            .padding(.top, DesignSystem.Layout.pageHeaderPadding)
            .padding(.horizontal, DesignSystem.Layout.contentPadding)
            .padding(.bottom, DesignSystem.Layout.contentPadding)
            .background(DesignSystem.Colors.cardBackground)
            
            // Content based on selected segment
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xl) {
                    switch selectedSegment {
                    case .overview:
                        ModernOverviewView(activityMonitor: activityMonitor)
                    case .switches:
                        SwitchAnalyticsSection(activityMonitor: activityMonitor)
                    case .cost:
                        CostAnalyticsSection(activityMonitor: activityMonitor)
                    }
                }
                .padding(DesignSystem.Layout.contentPadding)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedSegment)
    }
    
    private var focusScoreString: String {
        let score = calculateFocusScore()
        return "\(Int(score))%"
    }
    
    private var focusScoreColor: Color {
        let score = calculateFocusScore()
        if score >= 80 { return DesignSystem.Colors.success }
        else if score >= 60 { return DesignSystem.Colors.warning }
        else { return DesignSystem.Colors.error }
    }
    
    private func calculateFocusScore() -> Double {
        let todaysSwitches = activityMonitor.contextSwitchesToday
        let idealSwitches = 30 // Ideal number of switches per day
        
        if todaysSwitches <= idealSwitches {
            return 100.0
        } else {
            let excess = Double(todaysSwitches - idealSwitches)
            let penalty = min(excess / Double(idealSwitches) * 50, 80)
            return max(100.0 - penalty, 0.0)
        }
    }
}

// MARK: - Modern Segment Button

struct ModernSegmentButton: View {
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.secondaryText)
                    
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
                }
                
                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 160, height: 70)
            .padding(DesignSystem.Spacing.md)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return DesignSystem.Colors.accent.opacity(0.1)
        } else if isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return DesignSystem.Colors.cardBackground
        }
    }
    
    private var borderColor: Color {
        isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiaryText.opacity(0.2)
    }
}

// MARK: - Modern Overview View

struct ModernOverviewView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @State private var expandedSections: Set<OverviewSection> = [.focus, .activity] // Default to showing key sections
    
    enum OverviewSection: String, CaseIterable {
        case focus = "Current Focus"
        case activity = "Today's Activity" 
        case productivity = "Productivity Impact"
        case patterns = "Recent Patterns"
        
        var icon: String {
            switch self {
            case .focus: return "brain.head.profile"
            case .activity: return "clock"
            case .productivity: return "dollarsign.circle"
            case .patterns: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Primary Focus Card - Always visible
            AnalyticsCard(title: "Current Focus State", icon: "brain.head.profile") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Circle()
                            .fill(focusStateColor)
                            .frame(width: 12, height: 12)
                        
                        Text(activityMonitor.focusStateDetector.currentFocusState.rawValue)
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                    }
                    
                    Text(activityMonitor.focusStateDetector.currentFocusState.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(3)
                }
            }
            
            // Collapsible sections for secondary information
            VStack(spacing: DesignSystem.Spacing.md) {
                // Today's Activity Section
                CollapsibleAnalyticsSection(
                    title: "Today's Activity",
                    icon: "clock",
                    isExpanded: .constant(true) // Always expanded for key metrics
                ) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(activityMonitor.contextSwitchesToday)")
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("Context Switches")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(activityMonitor.totalAppActivations)")
                                .font(DesignSystem.Typography.title3)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("App Activations")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    }
                }
                
                // Productivity Impact Section - Collapsible
                CollapsibleAnalyticsSection(
                    title: "Productivity Impact",
                    icon: "dollarsign.circle",
                    isExpanded: Binding(
                        get: { expandedSections.contains(.productivity) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert(.productivity)
                            } else {
                                expandedSections.remove(.productivity)
                            }
                        }
                    )
                ) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatCurrency(activityMonitor.estimatedCostLostToday))
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.error)
                            
                            Text("Today's Cost")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(activityMonitor.minutesLostToday))")
                                .font(DesignSystem.Typography.title3)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.warning)
                            
                            Text("Minutes Lost")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    }
                }
                
                // Recent Patterns Section - Collapsible
                CollapsibleAnalyticsSection(
                    title: "Recent Patterns",
                    icon: "chart.line.uptrend.xyaxis",
                    isExpanded: Binding(
                        get: { expandedSections.contains(.patterns) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert(.patterns)
                            } else {
                                expandedSections.remove(.patterns)
                            }
                        }
                    )
                ) {
                    if activityMonitor.focusStateDetector.switchingVelocity > 0 {
                        HStack {
                            Text("\(String(format: "%.1f", activityMonitor.focusStateDetector.switchingVelocity))")
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(velocityColor)
                            
                            Text("switches/min")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Spacer()
                        }
                        
                        Text(velocityDescription)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(2)
                    } else {
                        Text("No recent activity")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
        }
    }
    
    private var focusStateColor: Color {
        switch activityMonitor.focusStateDetector.currentFocusState {
        case .deepFocus: return DesignSystem.Colors.success
        case .focused: return DesignSystem.Colors.accent
        case .scattered: return DesignSystem.Colors.warning
        case .overloaded: return DesignSystem.Colors.error
        }
    }
    
    private var velocityColor: Color {
        let velocity = activityMonitor.focusStateDetector.switchingVelocity
        if velocity < 2 { return DesignSystem.Colors.success }
        else if velocity < 4 { return DesignSystem.Colors.warning }
        else { return DesignSystem.Colors.error }
    }
    
    private var velocityDescription: String {
        let velocity = activityMonitor.focusStateDetector.switchingVelocity
        if velocity < 2 { return "Healthy switching pattern" }
        else if velocity < 4 { return "Moderate switching activity" }
        else { return "High switching frequency detected" }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Switch Analytics Section

struct SwitchAnalyticsSection: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            AnalyticsCard(title: "Context Switch Analysis", icon: "arrow.left.arrow.right") {
                SwitchAnalyticsView(activityMonitor: activityMonitor)
            }
        }
    }
}


// MARK: - Cost Analytics Section

struct CostAnalyticsSection: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @ObservedObject var userSettings = UserSettings.shared
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            AnalyticsCard(title: "Productivity Cost Analysis", icon: "dollarsign.circle") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Cost metrics
                    VStack(spacing: DesignSystem.Spacing.md) {
                        CostMetricRow(
                            label: "Today's Cost Lost:",
                            value: formatCurrency(activityMonitor.estimatedCostLostToday),
                            color: DesignSystem.Colors.error
                        )
                        
                        CostMetricRow(
                            label: "Total Cost Lost:",
                            value: formatCurrency(activityMonitor.estimatedCostLost),
                            color: DesignSystem.Colors.warning
                        )
                        
                        CostMetricRow(
                            label: "Context Switches Today:",
                            value: "\(activityMonitor.contextSwitchesToday)",
                            color: DesignSystem.Colors.accent
                        )
                        
                        CostMetricRow(
                            label: "Minutes Lost Today:",
                            value: "\(Int(activityMonitor.minutesLostToday)) min",
                            color: DesignSystem.Colors.warning
                        )
                    }
                    
                    Divider()
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    
                    // Calculation basis
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Calculation Basis:")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        HStack {
                            Text("Hourly Rate:")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Spacer()
                            Text(formatCurrency(userSettings.hourlyRate))
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        
                        HStack {
                            Text("Minutes Lost per Switch:")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Spacer()
                            Text("\(Int(ActivityMonitor.minutesLostPerSwitch))")
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct CostMetricRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Analytics Card Component

struct AnalyticsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            content
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.Layout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius)
                .stroke(DesignSystem.Colors.tertiaryText.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Collapsible Analytics Section

struct CollapsibleAnalyticsSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with expand/collapse button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground)
            }
            .buttonStyle(.plain)
            
            // Expandable content
            if isExpanded {
                VStack {
                    content
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius)
                .stroke(DesignSystem.Colors.tertiaryText.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    AnalyticsTabView(activityMonitor: ActivityMonitor())
}
