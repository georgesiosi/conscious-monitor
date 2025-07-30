import SwiftUI

struct ProductivityInsightsView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    
    private var productivityMetrics: ProductivityMetrics {
        activityMonitor.productivityMetrics
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xl) {
                // Productivity Score Card
                productivityScoreCard
                
                // Activity Breakdown
                activityBreakdownCards
                
                // Focus Time Analysis
                focusTimeCard
                
                // Recommendations
                recommendationsCard
            }
            .contentMargins()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Productivity Insights")
    }
    
    // MARK: - Productivity Score Card
    
    private var productivityScoreCard: some View {
        CardView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Score Header
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Today's Productivity Score")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(productivityMetrics.productivityLevel)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Circular Progress
                    ZStack {
                        Circle()
                            .stroke(DesignSystem.Colors.secondaryText.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: productivityMetrics.productivityScore / 100)
                            .stroke(
                                productivityScoreColor,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.8), value: productivityMetrics.productivityScore)
                        
                        Text("\(Int(productivityMetrics.productivityScore))")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                }
                
                // Score Explanation
                Text(productivityScoreExplanation)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Activity Breakdown Cards
    
    private var activityBreakdownCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.lg) {
            
            AccessibleStatCard(
                title: "Quick Checks",
                value: "\(productivityMetrics.quickChecks)",
                systemImage: "eye",
                color: .blue,
                accessibilityHint: "Brief reference checks under 10 seconds"
            )
            
            AccessibleStatCard(
                title: "Task Switches",
                value: "\(productivityMetrics.meaningfulSwitches)",
                systemImage: "arrow.left.arrow.right",
                color: .orange,
                accessibilityHint: "Meaningful task switches between 10 seconds and 2 minutes"
            )
            
            AccessibleStatCard(
                title: "Focus Sessions",
                value: "\(productivityMetrics.focusSessions)",
                systemImage: "target",
                color: .green,
                accessibilityHint: "Deep work sessions longer than 2 minutes"
            )
            
            AccessibleStatCard(
                title: "Rapid Groups",
                value: "\(productivityMetrics.rapidActivationGroups)",
                systemImage: "bolt",
                color: .red,
                accessibilityHint: "Groups of rapid app switches that may indicate scattered attention"
            )
        }
    }
    
    // MARK: - Focus Time Card
    
    private var focusTimeCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                SectionHeaderView(
                    "Focus Time Analysis",
                    subtitle: "Time spent in productive, uninterrupted work"
                )
                
                HStack(spacing: DesignSystem.Spacing.xl) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Total Focus Time")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text(formatFocusTime(productivityMetrics.totalFocusTime))
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: DesignSystem.Spacing.sm) {
                        Text("Average Session")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text(formatAverageSession())
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                }
                
                // Focus efficiency bar
                focusEfficiencyBar
            }
        }
    }
    
    private var focusEfficiencyBar: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Focus Efficiency")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.secondaryText.opacity(0.2))
                        .frame(height: 8)
                    
                    // Focus time bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * focusEfficiencyRatio, height: 8)
                        .animation(.easeInOut(duration: 0.6), value: focusEfficiencyRatio)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(focusEfficiencyRatio * 100))% of time spent in focused work")
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }
    
    // MARK: - Recommendations Card
    
    private var recommendationsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                SectionHeaderView(
                    "Recommendations",
                    subtitle: "Tips to improve your productivity patterns"
                )
                
                LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    ForEach(recommendations, id: \.title) { recommendation in
                        recommendationRow(recommendation)
                    }
                }
            }
        }
    }
    
    private func recommendationRow(_ recommendation: Recommendation) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: recommendation.icon)
                .font(.system(size: DesignSystem.Layout.iconSize))
                .foregroundColor(recommendation.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(recommendation.title)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(recommendation.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    // MARK: - Computed Properties
    
    private var productivityScoreColor: Color {
        switch productivityMetrics.productivityScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private var productivityScoreExplanation: String {
        switch productivityMetrics.productivityScore {
        case 80...100:
            return "Excellent focus today! You're maintaining long work sessions with minimal distractions."
        case 60..<80:
            return "Good productivity with some room for improvement. Try extending your focus sessions."
        case 40..<60:
            return "Mixed focus patterns. Consider reducing quick app switches during deep work."
        case 20..<40:
            return "Scattered attention detected. Try using focus modes or app blockers during work sessions."
        default:
            return "High distraction levels. Consider implementing structured focus techniques and app management."
        }
    }
    
    private var focusEfficiencyRatio: Double {
        let totalActiveTime = max(productivityMetrics.totalFocusTime, 1.0) // Avoid division by zero
        let workingHours = 8.0 * 3600 // 8 hours in seconds
        return min(totalActiveTime / workingHours, 1.0)
    }
    
    private func formatFocusTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatAverageSession() -> String {
        guard productivityMetrics.focusSessions > 0 else { return "0m" }
        let averageMinutes = Int(productivityMetrics.totalFocusTime) / productivityMetrics.focusSessions / 60
        return "\(averageMinutes)m"
    }
    
    // MARK: - Recommendations Logic
    
    private var recommendations: [Recommendation] {
        var recs: [Recommendation] = []
        
        if productivityMetrics.rapidActivationGroups > 5 {
            recs.append(Recommendation(
                title: "Reduce Rapid Switching",
                description: "You have \(productivityMetrics.rapidActivationGroups) rapid app switching patterns. Try batching similar tasks.",
                icon: "bolt.slash",
                color: .orange
            ))
        }
        
        if productivityMetrics.focusSessions < 3 {
            recs.append(Recommendation(
                title: "Increase Focus Sessions",
                description: "Aim for longer work sessions. Try the 25-minute Pomodoro technique.",
                icon: "target",
                color: .green
            ))
        }
        
        if productivityMetrics.quickChecks > 20 {
            recs.append(Recommendation(
                title: "Batch Quick Checks",
                description: "Consider scheduling specific times for checking notifications and messages.",
                icon: "clock.badge.checkmark",
                color: .blue
            ))
        }
        
        if recs.isEmpty {
            recs.append(Recommendation(
                title: "Maintain Good Habits",
                description: "Your productivity patterns look healthy. Keep up the focused work!",
                icon: "checkmark.circle",
                color: .green
            ))
        }
        
        return recs
    }
}

// MARK: - Supporting Types

struct Recommendation {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProductivityInsightsView(activityMonitor: ActivityMonitor())
    }
}