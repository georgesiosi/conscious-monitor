import SwiftUI

// MARK: - Time Range Filter Component

struct TimeRangeFilter: View {
    @Binding var selectedTimeRange: SharedTimeRange
    let iconSize: CGFloat
    
    init(selectedTimeRange: Binding<SharedTimeRange>, iconSize: CGFloat = 16) {
        self._selectedTimeRange = selectedTimeRange
        self.iconSize = iconSize
    }
    
    var body: some View {
        Menu {
            ForEach(SharedTimeRange.allCases) { range in
                Button(action: {
                    selectedTimeRange = range
                }) {
                    HStack {
                        Text(range.displayName)
                        Spacer()
                        if selectedTimeRange == range {
                            Image(systemName: "checkmark")
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    }
                }
            }
        } label: {
            Text(selectedTimeRange.displayName)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius / 2)
                    .fill(DesignSystem.Colors.hoverBackground)
                    .stroke(DesignSystem.Colors.accent.opacity(0.3), lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
        .help("Filter by time range")
    }
}

// MARK: - Compact Time Range Filter (Icon Only)

struct CompactTimeRangeFilter: View {
    @Binding var selectedTimeRange: SharedTimeRange
    let iconSize: CGFloat
    
    init(selectedTimeRange: Binding<SharedTimeRange>, iconSize: CGFloat = 18) {
        self._selectedTimeRange = selectedTimeRange
        self.iconSize = iconSize
    }
    
    var body: some View {
        Menu {
            ForEach(SharedTimeRange.allCases) { range in
                Button(action: {
                    selectedTimeRange = range
                }) {
                    HStack {
                        Text(range.displayName)
                        Spacer()
                        if selectedTimeRange == range {
                            Image(systemName: "checkmark")
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: iconSize))
                .foregroundColor(DesignSystem.Colors.accent)
                .padding(DesignSystem.Spacing.xs)
                .background(
                    Circle()
                        .fill(DesignSystem.Colors.hoverBackground)
                        .stroke(DesignSystem.Colors.accent.opacity(0.3), lineWidth: 0.5)
                )
        }
        .menuStyle(.borderlessButton)
        .help("Filter by time range: \(selectedTimeRange.displayName)")
    }
}

// MARK: - SharedTimeRange Display Extension

extension SharedTimeRange {
    var displayName: String {
        switch self {
        case .today:
            return "Today"
        case .week:
            return "This Week"
        case .month:
            return "This Month"
        case .all:
            return "All Time"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .today:
            return "Today"
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .all:
            return "All"
        }
    }
}


#Preview {
    VStack(spacing: 20) {
        TimeRangeFilter(selectedTimeRange: .constant(.today))
        CompactTimeRangeFilter(selectedTimeRange: .constant(.week))
    }
    .padding()
}