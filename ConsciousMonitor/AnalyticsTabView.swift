import SwiftUI

struct LegacyAnalyticsTabView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @State private var selectedSegment: AnalyticsSegment = .switchAnalytics
    
    enum AnalyticsSegment: String, CaseIterable, Identifiable {
        case switchAnalytics = "Context Switches"
        case usageStack = "Usage Breakdown" 
        case costAnalysis = "Cost Analysis"
        
        var id: String { rawValue }
        
        var systemImage: String {
            switch self {
            case .switchAnalytics: return "arrow.left.arrow.right"
            case .usageStack: return "chart.bar.xaxis"
            case .costAnalysis: return "dollarsign.circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header with segment picker
            VStack(spacing: DesignSystem.Spacing.lg) {
                SectionHeaderView(
                    "Analytics",
                    subtitle: "Analyze your productivity patterns and context switching behavior"
                )
                
                // Segment picker
                Picker("Analytics Type", selection: $selectedSegment) {
                    ForEach(AnalyticsSegment.allCases) { segment in
                        Label(segment.rawValue, systemImage: segment.systemImage)
                            .tag(segment)
                    }
                }
                .pickerStyle(.segmented)
            }
            .contentMargins()
            
            // Content based on selected segment
            Group {
                switch selectedSegment {
                case .switchAnalytics:
                    ModernSwitchAnalyticsView(activityMonitor: activityMonitor)
                case .usageStack:
                    ModernUsageStackView(activityMonitor: activityMonitor)
                case .costAnalysis:
                    ModernCostAnalysisView(activityMonitor: activityMonitor)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(DesignSystem.Colors.contentBackground)
        .animation(.easeInOut(duration: 0.2), value: selectedSegment)
    }
}

// MARK: - Modern Switch Analytics View

struct ModernSwitchAnalyticsView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xl) {
                // Quick stats cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignSystem.Spacing.lg) {
                    StatCard(
                        title: "Context Switches Today",
                        value: "\(activityMonitor.contextSwitchesToday)",
                        systemImage: "arrow.left.arrow.right",
                        color: DesignSystem.Colors.chartColors[0]
                    )
                    
                    StatCard(
                        title: "App Activations (5 Min)",
                        value: "\(activityMonitor.appActivationsInLast5Minutes)",
                        systemImage: "clock",
                        color: DesignSystem.Colors.chartColors[1]
                    )
                    
                    StatCard(
                        title: "Total App Activations",
                        value: "\(activityMonitor.totalAppActivations)",
                        systemImage: "infinity",
                        color: DesignSystem.Colors.chartColors[2]
                    )
                }
                
                // Original switch analytics content wrapped in card
                CardView {
                    SwitchAnalyticsView(activityMonitor: activityMonitor)
                }
            }
            .contentMargins()
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Modern Usage Stack View

struct ModernUsageStackView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    
    var body: some View {
        ScrollView {
            CardView {
                UsageStackView(activityMonitor: activityMonitor)
            }
            .contentMargins()
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Modern Cost Analysis View

struct ModernCostAnalysisView: View {
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
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xl) {
                // Cost overview cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.lg) {
                    StatCard(
                        title: "Today's Focus Cost",
                        value: currencyFormatter.string(from: NSNumber(value: activityMonitor.estimatedCostLostToday)) ?? "$0.00",
                        systemImage: "dollarsign.circle",
                        color: DesignSystem.Colors.error
                    )
                    
                    StatCard(
                        title: "Total Focus Cost",
                        value: currencyFormatter.string(from: NSNumber(value: activityMonitor.estimatedCostLost)) ?? "$0.00",
                        systemImage: "chart.line.uptrend.xyaxis",
                        color: DesignSystem.Colors.warning
                    )
                }
                
                // Cost breakdown details
                CardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        SectionHeaderView(
                            "Cost Breakdown",
                            subtitle: "Detailed analysis of productivity impact"
                        )
                        
                        VStack(spacing: DesignSystem.Spacing.md) {
                            CostDetailRow(
                                label: "Context Switches Today:",
                                value: "\(activityMonitor.contextSwitchesToday)",
                                detail: "switches"
                            )
                            
                            CostDetailRow(
                                label: "Minutes Lost Today:",
                                value: "\(Int(activityMonitor.minutesLostToday))",
                                detail: "minutes"
                            )
                            
                            CostDetailRow(
                                label: "Hourly Rate:",
                                value: currencyFormatter.string(from: NSNumber(value: userSettings.hourlyRate)) ?? "$0.00",
                                detail: "per hour"
                            )
                            
                            Divider()
                                .padding(.vertical, DesignSystem.Spacing.sm)
                            
                            CostDetailRow(
                                label: "Cost per Switch:",
                                value: String(format: "%.2f", (userSettings.hourlyRate / 60.0) * ActivityMonitor.minutesLostPerSwitch),
                                detail: "dollars"
                            )
                        }
                    }
                }
            }
            .contentMargins()
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: DesignSystem.Layout.iconSize))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(DesignSystem.Typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .cardStyle()
        .frame(minHeight: 80)
    }
}

// MARK: - Cost Detail Row Component

struct CostDetailRow: View {
    let label: String
    let value: String
    let detail: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(detail)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
    }
}

#Preview {
    LegacyAnalyticsTabView(activityMonitor: ActivityMonitor())
}