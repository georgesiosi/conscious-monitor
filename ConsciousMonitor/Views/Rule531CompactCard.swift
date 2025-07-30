import SwiftUI

// MARK: - 5:3:1 Rule Compact Card

struct Rule531CompactCard: View {
    @State private var showingFullExplanation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
                
                Text("The 5:3:1 Rule")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button(action: {
                    showingFullExplanation = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Learn more")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Compact visual representation
            HStack(spacing: DesignSystem.Spacing.lg) {
                CompactRuleIndicator(number: "5", color: .blue, description: "Max tools")
                CompactRuleIndicator(number: "3", color: .green, description: "Active")
                CompactRuleIndicator(number: "1", color: .orange, description: "Primary")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Brief description
            Text("Conscious tool limits to reduce cognitive load")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius)
                .fill(Color.orange.opacity(0.05))
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .popover(isPresented: $showingFullExplanation) {
            Rule531FullExplanationView()
        }
    }
}

// MARK: - Compact Rule Indicator

struct CompactRuleIndicator: View {
    let number: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(description)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Full Explanation Popover

struct Rule531FullExplanationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("The 5:3:1 Rule")
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Conscious Technology Management")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Detailed rule explanation
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                FullRuleItem(
                    number: "5",
                    title: "Maximum Tools",
                    description: "Never exceed 5 tools per category to prevent tool sprawl",
                    color: .blue
                )
                
                FullRuleItem(
                    number: "3",
                    title: "Active Tools",
                    description: "Keep only 3 tools active at any time to maintain focus",
                    color: .green
                )
                
                FullRuleItem(
                    number: "1",
                    title: "Primary Tool",
                    description: "Designate 1 primary tool that handles 60%+ of your work",
                    color: .orange
                )
            }
            
            Divider()
            
            // Benefits section
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Benefits")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    BenefitItem(text: "Reduced cognitive load from context switching")
                    BenefitItem(text: "Improved focus and deeper work sessions")
                    BenefitItem(text: "Clearer decision-making about tool usage")
                    BenefitItem(text: "More intentional technology relationships")
                }
            }
            
            // Philosophy section
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Philosophy")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("The 5:3:1 rule embodies conscious technology management by creating intentional boundaries. Rather than accumulating tools endlessly, we choose quality over quantity, depth over breadth, and focus over fragmentation.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(width: 400, height: 500)
        .background(DesignSystem.Colors.cardBackground)
    }
}

// MARK: - Full Rule Item

struct FullRuleItem: View {
    let number: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 40, height: 40)
                
                Text(number)
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Benefit Item

struct BenefitItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
                .padding(.top, 2)
            
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Rule531CompactCard()
            .frame(width: 300)
        
        Spacer()
    }
    .padding()
    .frame(width: 400, height: 600)
}