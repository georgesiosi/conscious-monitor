import SwiftUI

// MARK: - Improvement Score Card Component

/// Reusable component for displaying improvement score and stack health metrics
struct ImprovementScoreCard: View {
    let stackHealthSummary: StackHealthSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            HStack {
                Text("Stack Health")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                CSDComplianceIndicator(status: stackHealthSummary.overallCompliance, size: 20)
            }
            
            // Health score
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Improvement Score")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                HStack {
                    Text(String(format: "%.0f", stackHealthSummary.improvementScore))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(improvementScoreColor)
                    
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
                    count: stackHealthSummary.healthyCategories,
                    color: .green
                )
                
                HealthMetric(
                    title: "Warning",
                    count: stackHealthSummary.warningCategories,
                    color: .orange
                )
                
                HealthMetric(
                    title: "Violation",
                    count: stackHealthSummary.violationCategories,
                    color: .red
                )
            }
            
            // Average cognitive load
            HStack {
                Text("Avg. Cognitive Load:")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text(String(format: "%.1f / 10", stackHealthSummary.averageCognitiveLoad))
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
    
    // MARK: - Computed Properties for Colors
    
    private var improvementScoreColor: Color {
        if stackHealthSummary.improvementScore >= 80 {
            return .green
        } else if stackHealthSummary.improvementScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var cognitiveLoadColor: Color {
        if stackHealthSummary.averageCognitiveLoad <= 3 {
            return .green
        } else if stackHealthSummary.averageCognitiveLoad <= 6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Helper Components

/// Health metric display component
struct HealthMetric: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("\(count)")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Sample data for preview
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
        
        ImprovementScoreCard(stackHealthSummary: sampleSummary)
        
        // Another example with different data
        let healthySummary = StackHealthSummary(
            overallCompliance: .healthy,
            totalCategories: 5,
            healthyCategories: 5,
            warningCategories: 0,
            violationCategories: 0,
            averageCognitiveLoad: 2.3,
            insights: [],
            improvementScore: 95.0
        )
        
        ImprovementScoreCard(stackHealthSummary: healthySummary)
    }
    .padding()
    .frame(width: 350)
}