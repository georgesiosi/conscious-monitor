import SwiftUI
import Charts

struct PieChartView: View {
    let data: [(value: Double, color: Color, label: String)]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            if !title.isEmpty {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            
            ZStack {
                Chart {
                    ForEach(data, id: \.label) { item in
                        SectorMark(
                            angle: .value(item.label, item.value),
                            innerRadius: .ratio(0.5),
                            angularInset: 1
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(4)
                        .annotation(position: .overlay) {
                            if item.value > 0 {
                                Text("\(Int(item.value))")
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 200)
                .padding(DesignSystem.Spacing.lg)
                
                // Center value
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("\(Int(data.reduce(0) { $0 + $1.value }))")
                        .font(DesignSystem.Typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Total Events")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            // Legend
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                ForEach(data, id: \.label) { item in
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        
                        Text(item.label)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Text("\(Int(item.value)) (" + String(format: "%.0f", (item.value / data.reduce(0) { $0 + $1.value }) * 100) + "%)")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.md)
        }
    }
}

// MARK: - Preview

struct PieChartView_Previews: PreviewProvider {
    static var previewData: [(Double, Color, String)] = [
        (15, .blue, "Quick"),
        (25, .orange, "Normal"),
        (60, .green, "Focused")
    ]
    
    static var previews: some View {
        PieChartView(data: previewData, title: "Switch Types")
            .frame(width: 300, height: 400)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
